#!/usr/bin/env python3
"""Create and verify the skill virtual environment.

Usage:
    python setup_env.py
    python setup_env.py --check
    python setup_env.py --force
"""

import argparse
import os
import shutil
import subprocess
import venv

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
VENV_DIR = os.path.join(ROOT, ".venv")
REQUIREMENTS = os.path.join(ROOT, "requirements.txt")


def log(message):
    print(f"[setup_env] {message}", flush=True)


def venv_python():
    if os.name == "nt":
        return os.path.join(VENV_DIR, "Scripts", "python.exe")
    return os.path.join(VENV_DIR, "bin", "python")


def ensure_venv():
    python = venv_python()
    if os.path.exists(python):
        return python
    log(f"创建虚拟环境: {VENV_DIR}")
    try:
        venv.create(VENV_DIR, with_pip=True, clear=False)
    except Exception as exc:
        log(f"虚拟环境创建失败: {exc}")
        log("Linux 上可先安装 python3-venv 后重试")
        raise SystemExit(1)
    if not os.path.exists(python):
        log("虚拟环境创建失败")
        raise SystemExit(1)
    return python


def install_requirements(python):
    if not os.path.exists(REQUIREMENTS):
        log(f"缺少依赖清单: {REQUIREMENTS}")
        raise SystemExit(1)
    log("安装依赖...")
    result = subprocess.run(
        [
            python,
            "-m",
            "pip",
            "install",
            "--disable-pip-version-check",
            "--upgrade",
            "-r",
            REQUIREMENTS,
        ]
    )
    if result.returncode != 0:
        log("依赖安装失败")
        raise SystemExit(result.returncode)


def check(python):
    code = (
        "try:\n"
        "    import pymupdf\n"
        "except ImportError:\n"
        "    import fitz as pymupdf\n"
        "print(pymupdf.__version__)\n"
    )
    result = subprocess.run([python, "-c", code], capture_output=True, text=True)
    if result.returncode != 0:
        return False, result.stderr.strip() or "PyMuPDF 导入失败"
    version = result.stdout.strip()
    parts = []
    for chunk in version.split("."):
        digits = "".join(ch for ch in chunk if ch.isdigit())
        parts.append(int(digits) if digits else 0)
    if parts and (parts[0], parts[1] if len(parts) > 1 else 0) < (1, 24):
        return False, f"PyMuPDF {version} 过旧，需要 >= 1.24"
    return True, version


def main():
    ap = argparse.ArgumentParser(description="初始化 component-datasheet 运行环境")
    ap.add_argument("--check", action="store_true", help="只检查，不创建或安装")
    ap.add_argument("--force", action="store_true", help="删除并重建虚拟环境")
    args = ap.parse_args()

    if args.force and args.check:
        log("--force 与 --check 不能同时使用")
        raise SystemExit(2)

    if args.check and not os.path.exists(venv_python()):
        log("环境未初始化，请先运行: python setup_env.py")
        raise SystemExit(1)

    if args.force and os.path.isdir(VENV_DIR):
        log(f"删除旧虚拟环境: {VENV_DIR}")
        shutil.rmtree(VENV_DIR, ignore_errors=True)

    python = venv_python() if args.check else ensure_venv()

    if not args.check:
        install_requirements(python)

    ok, detail = check(python)
    if not ok:
        log(f"依赖检查未通过: {detail}")
        log("请先运行: python setup_env.py 安装依赖；仍失败再用 --force 重建")
        raise SystemExit(1)

    log(f"环境就绪，PyMuPDF {detail}")
    log(f"Python: {python}")
    if os.name != "nt":
        log("后续调用示例: .venv/bin/python scripts/parse_pdf.py <file.pdf>")


if __name__ == "__main__":
    main()
