#!/usr/bin/env python3
"""Inspect a datasheet PDF: metadata, outline, identity hints and page text.

Usage:
    .venv/bin/python parse_pdf.py "path/to/file.pdf" --toc --pages 1-3
    .venv/bin/python parse_pdf.py "path/to/file.pdf" --pages 12-18 --layout
    .venv/bin/python parse_pdf.py "path/to/file.pdf" --all --out full.json
"""

import argparse
import json
import os
import re

from _common import clean_metadata, emit, open_pdf, page_text, parse_pages

REFERENCE_WORDS = ("register", "memory map", "programming manual", "reference manual")
DATASHEET_WORDS = ("data sheet", "datasheet", "electrical characteristics", "absolute maximum")
APP_NOTE_WORDS = ("application note", "app note")
PART_RE = re.compile(
    r"\b(?=[A-Z0-9][A-Z0-9/_-]{4,}\b)"
    r"(?=[A-Z0-9/_-]*[A-Z])(?=[A-Z0-9/_-]*\d)"
    r"[A-Z0-9][A-Z0-9/_-]{4,}\b"
)


def parse_bookmarks(doc):
    entries = []
    try:
        raw = doc.get_toc(simple=True)
    except Exception:
        return entries
    for level, title, page in raw:
        entries.append(
            {
                "level": level,
                "title": (title or "").strip(),
                "page": page if page and page > 0 else None,
            }
        )
    return entries


def detect_type(doc, toc, first_text):
    page_count = doc.page_count
    toc_titles = " ".join((entry["title"] or "").lower() for entry in toc)
    first = (first_text or "")[:3000].lower()
    blob = f"{toc_titles} {first}"
    if any(word in blob for word in APP_NOTE_WORDS):
        return "application_note"
    if page_count >= 300 or any(word in toc_titles for word in REFERENCE_WORDS):
        return "reference_manual"
    if any(word in blob for word in DATASHEET_WORDS):
        return "data_sheet"
    if page_count <= 120 and (first.strip() or toc_titles.strip()):
        return "data_sheet"
    return "unknown"


def first_lines(text, limit=8):
    result = []
    for line in (text or "").splitlines():
        line = line.strip()
        if line:
            result.append(line[:200])
        if len(result) >= limit:
            break
    return result


def part_candidates(text, limit=12):
    result = []
    for match in PART_RE.findall(text or ""):
        value = match.strip("_-/")
        if value and value not in result:
            result.append(value)
        if len(result) >= limit:
            break
    return result


def main():
    ap = argparse.ArgumentParser(description="PDF 元信息、目录与文本抽取")
    ap.add_argument("pdf", help="PDF 文件路径")
    ap.add_argument("--pages", default=None, help="页码范围，如 '1-3,5'；默认前三页")
    ap.add_argument("--all", action="store_true", help="返回全部页文本（大文件慎用）")
    ap.add_argument("--layout", action="store_true", help="按页面阅读顺序整理文本")
    ap.add_argument("--no-text", action="store_true", help="只输出元信息和目录")
    ap.add_argument("--toc", action="store_true", help="解析目录（默认已开启，保留此参数兼容旧命令）")
    ap.add_argument("--no-toc", action="store_true", help="跳过目录解析")
    ap.add_argument("--password", default=None, help="加密 PDF 的密码")
    ap.add_argument("--out", default=None, help="同时写入 JSON 文件")
    args = ap.parse_args()

    warnings = []
    doc = open_pdf(args.pdf, args.password)
    metadata = clean_metadata(doc.metadata)

    if args.all:
        pages = list(range(doc.page_count))
        if doc.page_count > 100:
            warnings.append("文档较大，--all 会返回大量文本；建议用 --pages 限定范围")
    elif args.pages:
        pages = parse_pages(args.pages, doc.page_count, warnings)
    else:
        pages = list(range(min(3, doc.page_count)))

    toc = [] if args.no_toc else parse_bookmarks(doc)
    if not toc and not args.no_toc:
        warnings.append("未找到书签目录，建议用 search_pdf.py 按关键词建立页码地图")

    texts = {}
    page_index = {}
    low_text_pages = []
    if not args.no_text:
        for index in pages:
            content = page_text(doc[index], args.layout)
            texts[str(index + 1)] = content
            chars = len(re.sub(r"\s", "", content))
            page_index[str(index + 1)] = {"chars": chars, "low_text": chars < 20}
            if chars < 20:
                low_text_pages.append(index + 1)

    first_page_text = texts.get("1")
    if first_page_text is None:
        first_page_text = page_text(doc[0]) if doc.page_count else ""

    total_chars = sum(entry["chars"] for entry in page_index.values())
    if args.no_text:
        text_extractable = None
    else:
        text_extractable = bool(page_index) and total_chars >= max(40, 20 * len(page_index))
        if not text_extractable:
            warnings.append("文本抽取为空或过少，疑似扫描件；请用 extract_images.py 渲染页面后用视觉读取")

    title = None
    for line in (first_page_text or "").splitlines():
        if line.strip():
            title = line.strip()[:200]
            break
    if not title:
        title = metadata.get("title")

    identity_text = "\n".join([title or "", first_page_text or "", metadata.get("title", "")])

    result = {
        "error": None,
        "meta": {
            "filename": os.path.basename(args.pdf),
            "pages": doc.page_count,
            "type": detect_type(doc, toc, first_page_text),
            "pdf_version": _pdf_version(doc) or metadata.get("format"),
            "encrypted": bool(metadata.get("encryption")) or bool(getattr(doc, "is_encrypted", False)),
            "text_extractable": text_extractable,
            "low_text_pages": low_text_pages,
            "toc_source": "bookmarks" if toc else "none",
            "metadata": metadata,
        },
        "toc": toc,
        "first_page_title": title,
        "first_page_lines": first_lines(first_page_text),
        "part_number_candidates": part_candidates(identity_text),
        "text": texts,
        "page_index": page_index,
        "warnings": warnings,
    }

    payload = json.dumps(result, ensure_ascii=False, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(payload)
    emit(result)


def _pdf_version(doc):
    try:
        return doc.pdf_version()
    except Exception:
        return None


if __name__ == "__main__":
    main()
