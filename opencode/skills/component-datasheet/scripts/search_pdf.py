#!/usr/bin/env python3
"""Search a PDF with a regular expression and return page-level hits.

Usage:
    .venv/bin/python search_pdf.py "file.pdf" "absolute maximum|recommended operating"
    .venv/bin/python search_pdf.py "file.pdf" "VDD" --pages 1-40 --context 120
"""

import argparse
import json
import re

from _common import emit, fail, open_pdf, page_text, parse_pages, normalize_ws


def main():
    ap = argparse.ArgumentParser(description="PDF 文本检索")
    ap.add_argument("pdf", help="PDF 文件路径")
    ap.add_argument("pattern", help="正则表达式或字面量")
    ap.add_argument("--pages", default=None, help="页码范围，如 '1-40,80'；默认全部")
    ap.add_argument("--context", type=int, default=80, help="命中前后的上下文字符数")
    ap.add_argument("--max-hits", type=int, default=50, help="最多返回多少条命中")
    ap.add_argument("--case-sensitive", action="store_true", help="区分大小写")
    ap.add_argument("--literal", action="store_true", help="把 pattern 当作普通字符串")
    ap.add_argument("--password", default=None, help="加密 PDF 的密码")
    ap.add_argument("--out", default=None, help="同时写入 JSON 文件")
    args = ap.parse_args()

    if args.max_hits <= 0:
        fail("--max-hits 必须大于 0")
    if args.context < 0:
        fail("--context 不能为负数")

    expr = re.escape(args.pattern) if args.literal else args.pattern
    flags = 0 if args.case_sensitive else re.IGNORECASE
    try:
        regex = re.compile(expr, flags)
    except re.error as exc:
        fail(f"正则表达式错误: {exc}")

    warnings = []
    doc = open_pdf(args.pdf, args.password)
    if not args.pages and doc.page_count > 200:
        warnings.append("文档较大，建议用 --pages 限定检索范围")
    pages = parse_pages(args.pages, doc.page_count, warnings) if args.pages else list(range(doc.page_count))

    hits = []
    scanned = 0
    truncated = False
    for index in pages:
        text = page_text(doc[index], layout=True)
        if not text.strip():
            continue
        scanned += 1
        for match in regex.finditer(text):
            start, end = match.span()
            line = text.count("\n", 0, start) + 1
            left = max(0, start - args.context)
            right = min(len(text), end + args.context)
            hits.append(
                {
                    "page": index + 1,
                    "line": line,
                    "match": normalize_ws(match.group(0))[:300],
                    "context": normalize_ws(text[left:right])[:1000],
                }
            )
            if len(hits) >= args.max_hits:
                truncated = True
                break
        if truncated:
            break

    result = {
        "error": None,
        "pdf": args.pdf,
        "pattern": args.pattern,
        "count": len(hits),
        "scanned_pages": scanned,
        "truncated": truncated,
        "hits": hits,
        "warnings": warnings,
    }
    if args.out:
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(json.dumps(result, ensure_ascii=False, indent=2))
    emit(result)


if __name__ == "__main__":
    main()
