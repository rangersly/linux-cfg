#!/usr/bin/env python3
"""Generate a tiny datasheet and verify every bundled script end to end.

Usage:
    .venv/bin/python scripts/selftest.py
"""

import json
import os
import subprocess
import sys
import tempfile
import traceback

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def import_pymupdf():
    try:
        import pymupdf
        return pymupdf
    except ImportError:
        import fitz as pymupdf
        return pymupdf


def draw_table(page, x, y, headers, rows, widths, row_height=18):
    all_rows = [headers] + rows
    for row_index, row in enumerate(all_rows):
        offset = 0
        for column_index, cell in enumerate(row):
            page.insert_text(
                (x + offset + 3, y + row_index * row_height + 13),
                str(cell),
                fontsize=9,
            )
            offset += widths[column_index]
    total_width = sum(widths)
    for column_index in range(len(headers) + 1):
        line_x = x + sum(widths[:column_index])
        page.draw_line(
            (line_x, y),
            (line_x, y + len(all_rows) * row_height),
            color=(0, 0, 0),
            width=0.7,
        )
    for row_index in range(len(all_rows) + 1):
        line_y = y + row_index * row_height
        page.draw_line((x, line_y), (x + total_width, line_y), color=(0, 0, 0), width=0.7)


def build_sample(path):
    pymupdf = import_pymupdf()
    doc = pymupdf.open()

    page = doc.new_page()
    page.insert_text((72, 72), "ACME XYZ123 3.3 V LDO Regulator", fontsize=16)
    page.insert_text((72, 94), "Data Sheet - Rev. 1.2", fontsize=10)
    page.insert_text((72, 120), "Absolute Maximum Ratings", fontsize=12)
    draw_table(
        page,
        72,
        132,
        ["Parameter", "Min", "Max", "Unit"],
        [["VIN", "-0.3", "6.0", "V"], ["TJ", "-40", "125", "C"]],
        [120, 60, 60, 50],
    )

    page = doc.new_page()
    page.insert_text((72, 72), "Electrical Characteristics", fontsize=12)
    draw_table(
        page,
        72,
        84,
        ["Parameter", "Min", "Typ", "Max", "Unit"],
        [["VOUT", "3.234", "3.3", "3.366", "V"], ["IQ", "", "1.2", "2.0", "mA"]],
        [120, 60, 60, 60, 50],
    )

    page = doc.new_page()
    page.insert_text((72, 72), "Pin Configuration", fontsize=12)
    page.insert_text((72, 100), "1 GND   2 VOUT   3 VIN", fontsize=10)
    page.insert_text((72, 120), "Package: SOT-23-5", fontsize=10)

    doc.set_toc(
        [
            [1, "Absolute Maximum Ratings", 1],
            [1, "Electrical Characteristics", 2],
            [1, "Pin Configuration", 3],
        ]
    )
    doc.save(path)
    doc.close()


def run_script(name, args):
    command = [sys.executable, os.path.join(HERE, name)] + args
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        raise AssertionError(
            f"{name} 退出码 {result.returncode}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def run_json(name, args):
    result = run_script(name, args)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise AssertionError(f"{name} 未返回合法 JSON: {exc}\n{result.stdout[:2000]}")


def main():
    checks = []

    def check(name, condition, detail=""):
        checks.append((name, bool(condition), detail))

    with tempfile.TemporaryDirectory(prefix="component-datasheet-") as temp_dir:
        pdf_path = os.path.join(temp_dir, "xyz123.pdf")
        build_sample(pdf_path)

        try:
            setup = run_script("setup_env.py", ["--check"])
            check("setup_env --check", setup.returncode == 0)
        except AssertionError as exc:
            check("setup_env --check", False, str(exc))

        try:
            parsed = run_json("parse_pdf.py", [pdf_path, "--toc", "--pages", "1-3"])
            check("parse_pdf pages", parsed["meta"]["pages"] == 3)
            check("parse_pdf toc", len(parsed["toc"]) == 3, f"toc={parsed['toc']}")
            check("parse_pdf text", "XYZ123" in parsed["text"].get("1", ""))
            check("parse_pdf extractable", parsed["meta"]["text_extractable"] is True)
        except Exception as exc:
            check("parse_pdf", False, f"{exc}\n{traceback.format_exc()}")

        try:
            search = run_json("search_pdf.py", [pdf_path, "VOUT", "--pages", "1-3"])
            check("search_pdf hits", search["count"] >= 1, f"count={search['count']}")
        except Exception as exc:
            check("search_pdf", False, f"{exc}\n{traceback.format_exc()}")

        try:
            tables = run_json("extract_tables.py", [pdf_path, "--pages", "1-2"])
            check("extract_tables count", tables["table_count"] >= 2, f"count={tables['table_count']}")
            headers = []
            for page in tables.get("pages", []):
                for table in page.get("tables", []):
                    headers.extend(table.get("headers", []))
            check("extract_tables header", "Parameter" in headers, f"headers={headers}")
        except Exception as exc:
            check("extract_tables", False, f"{exc}\n{traceback.format_exc()}")

        try:
            image_path = os.path.join(temp_dir, "page1.png")
            images = run_json(
                "extract_images.py",
                [pdf_path, "--page", "1", "--dpi", "72", "--out", image_path],
            )
            check("extract_images file", images["files"] and os.path.exists(images["files"][0]))
        except Exception as exc:
            check("extract_images", False, f"{exc}\n{traceback.format_exc()}")

    failed = [item for item in checks if not item[1]]
    for name, ok, detail in checks:
        print(f"[{'PASS' if ok else 'FAIL'}] {name}")
        if not ok and detail:
            print(f"       {detail}")
    print(f"\n{len(checks) - len(failed)}/{len(checks)} checks passed")
    raise SystemExit(1 if failed else 0)


if __name__ == "__main__":
    main()
