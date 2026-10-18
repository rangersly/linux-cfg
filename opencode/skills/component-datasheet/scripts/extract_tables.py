#!/usr/bin/env python3
"""Extract tables from datasheet pages as JSON or Markdown.

Usage:
    .venv/bin/python extract_tables.py "file.pdf" --pages 12-15
    .venv/bin/python extract_tables.py "file.pdf" --pages 12-15 --strategy text
    .venv/bin/python extract_tables.py "file.pdf" --pages 12-15 --out tables.md
"""

import argparse
import contextlib
import json
import os
import sys

from _common import emit, markdown_table, open_pdf, parse_pages


def find_caption(page, bbox):
    best = None
    try:
        blocks = page.get_text("blocks")
    except Exception:
        return None
    for block in blocks:
        if len(block) < 5:
            continue
        text = (block[4] or "").strip()
        if not text:
            continue
        if block[3] <= bbox[1] + 1 and bbox[1] - block[3] < 90:
            if best is None or block[3] > best[0]:
                best = (block[3], text)
    if best:
        text = " ".join(best[1].split())
        if "table" in text.lower() or "表" in text:
            return text[:200]
    return None


def table_to_dict(table, page, index):
    headers = []
    try:
        if table.header and table.header.names:
            headers = ["" if name is None else str(name).strip() for name in table.header.names]
    except Exception:
        headers = []

    try:
        raw_rows = table.extract() or []
    except Exception:
        raw_rows = []
    rows = [
        ["" if cell is None else str(cell).strip() for cell in row]
        for row in raw_rows
    ]

    if headers:
        if rows and rows[0] == headers:
            rows = rows[1:]
    elif rows:
        headers = rows[0]
        rows = rows[1:]

    rows = [row for row in rows if any(cell for cell in row)]

    if rows:
        width = max([len(headers)] + [len(row) for row in rows])
        headers = headers + [""] * (width - len(headers))
        rows = [row + [""] * (width - len(row)) for row in rows]

    return {
        "index": index,
        "caption": find_caption(page, table.bbox),
        "headers": headers,
        "rows": rows,
        "row_count": len(rows),
        "col_count": len(headers),
        "bbox": [round(value, 1) for value in table.bbox],
    }


def to_markdown(payload, strategy):
    lines = [
        "# PDF 表格提取",
        "",
        f"- 文件: {payload['pdf']}",
        f"- 策略: {strategy}",
        f"- 表格数: {payload['table_count']}",
        "",
    ]
    for page in payload["pages"]:
        lines.append(f"## p.{page['page']}")
        lines.append("")
        for table in page["tables"]:
            title = table.get("caption") or f"Table {table['index']}"
            lines.append(f"### {title}")
            lines.append("")
            rendered = markdown_table(table["headers"], table["rows"])
            if rendered:
                lines.append(rendered)
            else:
                lines.append("_空表格_")
            lines.append("")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="PDF 表格提取")
    ap.add_argument("pdf", help="PDF 文件路径")
    ap.add_argument("--pages", default=None, help="页码范围，如 '12-15'；默认全部")
    ap.add_argument(
        "--strategy",
        default="lines",
        choices=["lines", "lines_strict", "text", "explicit"],
        help="表格识别策略；无框线表格可尝试 text",
    )
    ap.add_argument("--min-rows", type=int, default=1, help="最少数据行数")
    ap.add_argument("--min-cols", type=int, default=2, help="最少列数")
    ap.add_argument("--format", default="json", choices=["json", "md"], help="输出格式；--out 为 .md/.json 时以扩展名为准")
    ap.add_argument("--password", default=None, help="加密 PDF 的密码")
    ap.add_argument("--out", default=None, help="写入文件（.json 或 .md）")
    args = ap.parse_args()

    warnings = []
    doc = open_pdf(args.pdf, args.password)
    pages = parse_pages(args.pages, doc.page_count, warnings) if args.pages else list(range(doc.page_count))
    if len(pages) > 100:
        warnings.append("扫描页数较多，建议用 --pages 限定到参数表所在页")

    page_results = []
    errors = []
    total = 0
    for index in pages:
        page = doc[index]
        try:
            with contextlib.redirect_stdout(sys.stderr):
                finder = page.find_tables(strategy=args.strategy)
        except Exception as exc:
            errors.append({"page": index + 1, "error": str(exc)})
            continue
        tables = []
        for table_index, table in enumerate(finder.tables, 1):
            info = table_to_dict(table, page, table_index)
            if info["row_count"] < args.min_rows or info["col_count"] < args.min_cols:
                continue
            tables.append(info)
        if tables:
            page_results.append({"page": index + 1, "tables": tables})
            total += len(tables)

    payload = {
        "error": None,
        "pdf": args.pdf,
        "strategy": args.strategy,
        "table_count": total,
        "pages_with_tables": len(page_results),
        "pages": page_results,
        "errors": errors,
        "warnings": warnings,
    }
    if total == 0:
        warnings.append("未检测到表格；无框线表格可尝试 --strategy text，复杂表格建议渲染页面用视觉读取")

    if args.out:
        extension = os.path.splitext(args.out)[1].lower()
        if extension == ".md":
            target_format = "md"
        elif extension == ".json":
            target_format = "json"
        else:
            target_format = args.format
        if target_format == "md":
            text = to_markdown(payload, args.strategy)
        else:
            text = json.dumps(payload, ensure_ascii=False, indent=2)
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(text)
        emit(
            {
                "error": None,
                "out": args.out,
                "format": target_format,
                "table_count": total,
                "pages_with_tables": len(page_results),
                "warnings": warnings,
            }
        )
    elif args.format == "md":
        print(to_markdown(payload, args.strategy))
    else:
        emit(payload)


if __name__ == "__main__":
    main()
