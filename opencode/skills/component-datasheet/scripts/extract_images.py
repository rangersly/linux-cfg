#!/usr/bin/env python3
"""Render selected PDF pages to images for visual inspection.

Usage:
    .venv/bin/python extract_images.py "file.pdf" --pages 4-5 --dpi 200
    .venv/bin/python extract_images.py "file.pdf" --page 1 --out ./page1.png
    .venv/bin/python extract_images.py "file.pdf" --all --dpi 150 --out ./pages
"""

import argparse
import os

from _common import emit, fail, open_pdf, parse_pages


def main():
    ap = argparse.ArgumentParser(description="PDF 页面渲染")
    ap.add_argument("pdf", help="PDF 文件路径")
    ap.add_argument("--pages", default=None, help="页码范围，如 '4-5,12'")
    ap.add_argument("--page", type=int, default=None, help="单页页码（1-based）")
    ap.add_argument("--all", action="store_true", help="导出全部页面")
    ap.add_argument("--out", default=None, help="输出目录；单页时可给出 .png/.jpg 文件路径")
    ap.add_argument("--dpi", type=int, default=200, help="分辨率，建议 150-300")
    ap.add_argument("--format", default="png", choices=["png", "jpg"], help="图片格式")
    ap.add_argument("--quality", type=int, default=90, help="JPG 质量")
    ap.add_argument("--password", default=None, help="加密 PDF 的密码")
    args = ap.parse_args()

    if not 50 <= args.dpi <= 600:
        fail("--dpi 需在 50-600 之间")
    if not 1 <= args.quality <= 100:
        fail("--quality 需在 1-100 之间")

    warnings = []
    doc = open_pdf(args.pdf, args.password)

    if args.page is not None:
        if not 1 <= args.page <= doc.page_count:
            fail(f"页码超出范围: {args.page}（共 {doc.page_count} 页）")
        pages = [args.page - 1]
    elif args.pages:
        pages = parse_pages(args.pages, doc.page_count, warnings)
    elif args.all:
        pages = list(range(doc.page_count))
        if len(pages) > 100:
            warnings.append("导出页数较多，建议用 --pages 限定范围")
    else:
        fail("请用 --pages 指定页码，或用 --all 导出全部页面")

    if not pages:
        fail("没有可导出的页面")

    single_image_path = None
    out_extension = os.path.splitext(args.out)[1].lower() if args.out else ""
    if len(pages) > 1 and out_extension in (".png", ".jpg", ".jpeg"):
        fail("多页导出时 --out 必须是目录，不能是单个图片文件")
    if len(pages) == 1 and args.out:
        if out_extension in (".png", ".jpg", ".jpeg"):
            single_image_path = args.out
            out_dir = os.path.dirname(os.path.abspath(args.out))
            if out_extension in (".jpg", ".jpeg"):
                args.format = "jpg"
        else:
            out_dir = args.out
    else:
        out_dir = args.out or os.path.join(
            os.getcwd(), os.path.splitext(os.path.basename(args.pdf))[0] + "_pages"
        )

    os.makedirs(out_dir, exist_ok=True)

    files = []
    errors = []
    for index in pages:
        page = doc[index]
        target = single_image_path or os.path.join(out_dir, f"p{index + 1:04d}.{args.format}")
        try:
            pixmap = page.get_pixmap(dpi=args.dpi, alpha=False)
            pixmap.save(target, jpg_quality=args.quality)
            files.append(target)
        except Exception as exc:
            errors.append({"page": index + 1, "error": str(exc)})

    emit(
        {
            "error": None,
            "pdf": args.pdf,
            "dpi": args.dpi,
            "format": args.format,
            "pages": [index + 1 for index in pages],
            "out_dir": out_dir,
            "files": files,
            "errors": errors,
            "warnings": warnings,
        }
    )


if __name__ == "__main__":
    main()
