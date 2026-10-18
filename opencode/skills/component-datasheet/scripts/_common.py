"""Shared helpers for the component-datasheet scripts."""

import json
import os
import re
import sys


def fail(message, code=1):
    print(json.dumps({"error": message}, ensure_ascii=False), file=sys.stderr)
    raise SystemExit(code)


def emit(data):
    print(json.dumps(data, ensure_ascii=False, indent=2))


def import_pymupdf():
    try:
        import pymupdf
        return pymupdf
    except ImportError:
        try:
            import fitz
            return fitz
        except ImportError:
            fail("PyMuPDF 未安装，请先运行 scripts/setup_env.py")


def open_pdf(path, password=None):
    pymupdf = import_pymupdf()
    if not os.path.exists(path):
        fail(f"文件不存在: {path}")
    try:
        doc = pymupdf.open(path)
    except Exception as exc:
        fail(f"无法打开 PDF: {exc}")
    if doc.needs_pass:
        if not password:
            fail("PDF 已加密，请用 --password 提供密码")
        if not doc.authenticate(password):
            fail("PDF 密码错误")
    return doc


def parse_pages(spec, page_count, warnings=None):
    if not spec:
        return list(range(page_count))
    selected = set()
    for part in spec.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            left, right = part.split("-", 1)
            try:
                start, end = int(left), int(right)
            except ValueError:
                fail(f"页码范围格式错误: {part}")
            if start > end:
                start, end = end, start
            candidates = range(start, end + 1)
        else:
            try:
                candidates = [int(part)]
            except ValueError:
                fail(f"页码格式错误: {part}")
        for page in candidates:
            if 1 <= page <= page_count:
                selected.add(page - 1)
            elif warnings is not None:
                warnings.append(f"页码超出范围，已忽略: {page}")
    return sorted(selected)


def page_text(page, layout=False):
    if layout:
        return page.get_text("text", sort=True) or ""
    return page.get_text("text") or ""


def normalize_ws(text):
    return re.sub(r"\s+", " ", text or "").strip()


def markdown_cell(value):
    text = "" if value is None else str(value)
    text = text.replace("\r", " ").replace("\n", "<br>")
    return text.replace("|", "\\|").strip()


def markdown_table(headers, rows):
    headers = [markdown_cell(h) for h in headers]
    if not headers:
        return ""
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join(["---"] * len(headers)) + " |",
    ]
    for row in rows:
        cells = [markdown_cell(c) for c in row]
        if len(cells) < len(headers):
            cells.extend([""] * (len(headers) - len(cells)))
        lines.append("| " + " | ".join(cells[: len(headers)]) + " |")
    return "\n".join(lines)


def clean_metadata(metadata):
    if not metadata:
        return {}
    return {k: v for k, v in metadata.items() if v not in (None, "")}
