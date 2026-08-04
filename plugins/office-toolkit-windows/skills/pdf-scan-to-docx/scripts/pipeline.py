"""Local, checkpointed PDF scan preparation and DOCX export."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

import fitz
from docx import Document
from PIL import Image, ImageFilter, ImageOps


MARKER = ".pdf-scan-to-docx-workspace"
WORKSPACE_DIRS = ("01.input", "02.process", "03.output")
REPARSE_POINT = 0x400


class PipelineError(RuntimeError):
    pass


def is_reparse(path: Path) -> bool:
    if path.is_symlink():
        return True
    attributes = getattr(os.lstat(path), "st_file_attributes", 0)
    return bool(attributes & REPARSE_POINT)


def require_real(path: Path, kind: str) -> Path:
    if not path.exists() or is_reparse(path):
        raise PipelineError(f"{kind} is missing or a symlink/reparse target: {path}")
    return path.resolve(strict=True)


def workspace_paths(workspace: str | Path) -> dict[str, Path]:
    root = require_real(Path(workspace), "workspace")
    if not root.is_dir():
        raise PipelineError(f"workspace is not a directory: {root}")
    marker = root / MARKER
    if not marker.is_file() or is_reparse(marker):
        raise PipelineError(f"workspace marker is missing or unsafe: {marker}")
    paths = {"root": root}
    for name in WORKSPACE_DIRS:
        child = root / name
        if not child.is_dir() or is_reparse(child):
            raise PipelineError(f"workspace child is missing or a symlink/reparse target: {child}")
        paths[name] = child
    return paths


def require_direct_file(path: str | Path, directory: Path, label: str) -> Path:
    candidate = Path(path)
    resolved = require_real(candidate, label)
    if not resolved.is_file() or resolved.parent != directory:
        raise PipelineError(f"{label} must be a direct file inside {directory}")
    return resolved


def safe_child(directory: Path, name: str, required: bool = False) -> Path:
    child = directory / name
    if child.exists() and is_reparse(child):
        raise PipelineError(f"symlink/reparse target is not allowed: {child}")
    if required and not child.is_file():
        raise PipelineError(f"required output is missing: {child}")
    return child


def source_info(paths: dict[str, Path]) -> dict[str, str]:
    manifest = safe_child(paths["02.process"], "source.json", required=True)
    try:
        info = json.loads(manifest.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise PipelineError(f"source manifest is invalid: {manifest}") from error
    stem = info.get("stem")
    if not isinstance(stem, str) or not stem:
        raise PipelineError(f"source manifest has no output stem: {manifest}")
    return info


def prepare(workspace: str | Path) -> None:
    root = Path(workspace)
    if root.exists():
        if is_reparse(root):
            raise PipelineError(f"workspace is a symlink/reparse target: {root}")
        if any(root.iterdir()):
            workspace_paths(root)
            return
    root.mkdir(parents=True, exist_ok=True)
    (root / MARKER).write_text("pdf-scan-to-docx\n", encoding="utf-8")
    for name in WORKSPACE_DIRS:
        (root / name).mkdir(exist_ok=True)


def render(workspace: str | Path, pdf: str | Path) -> int:
    paths = workspace_paths(workspace)
    source = require_direct_file(pdf, paths["01.input"], "PDF source")
    if source.suffix.lower() != ".pdf":
        raise PipelineError(f"PDF source must end in .pdf: {source}")
    document = fitz.open(source)
    try:
        rendered = 0
        for number, page in enumerate(document, start=1):
            target = safe_child(paths["02.process"], f"page-{number:04d}.png")
            if target.exists():
                continue
            pixmap = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
            pixmap.save(target)
            rendered += 1
    finally:
        document.close()
    manifest = safe_child(paths["02.process"], "source.json")
    manifest.write_text(json.dumps({"stem": source.stem}, ensure_ascii=False), encoding="utf-8")
    return rendered


def preprocess(workspace: str | Path) -> int:
    paths = workspace_paths(workspace)
    destination = safe_child(paths["02.process"], "preprocessed")
    destination.mkdir(exist_ok=True)
    processed = 0
    for source in sorted(paths["02.process"].glob("page-????.png")):
        source = require_direct_file(source, paths["02.process"], "rendered page")
        target = safe_child(destination, source.name)
        if target.exists():
            continue
        with Image.open(source) as image:
            prepared = ImageOps.autocontrast(image.convert("RGB")).filter(ImageFilter.SHARPEN)
            prepared.save(target, "PNG")
        processed += 1
    if not list(paths["02.process"].glob("page-????.png")):
        raise PipelineError("no rendered pages in 02.process")
    return processed


def expected_pages(process: Path) -> list[int]:
    pages = [path for path in process.glob("page-????.png") if path.is_file()]
    if not pages:
        raise PipelineError("no rendered pages in 02.process")
    return [int(path.stem.rsplit("-", 1)[1]) for path in sorted(pages)]


def merge(workspace: str | Path) -> Path:
    paths = workspace_paths(workspace)
    info = source_info(paths)
    ocr = safe_child(paths["02.process"], "ocr")
    if not ocr.is_dir() or is_reparse(ocr):
        raise PipelineError(f"OCR checkpoint directory is missing or unsafe: {ocr}")
    checkpoints: list[Path] = []
    for number in expected_pages(paths["02.process"]):
        checkpoint = safe_child(ocr, f"page-{number:04d}.md")
        if not checkpoint.is_file():
            raise PipelineError(f"missing OCR checkpoint: {checkpoint}")
        if is_reparse(checkpoint):
            raise PipelineError(f"symlink/reparse target is not allowed: {checkpoint}")
        checkpoints.append(checkpoint)
    output = safe_child(paths["03.output"], f"{info['stem']}.md")
    output.write_text("\n\n".join(item.read_text(encoding="utf-8").strip() for item in checkpoints) + "\n", encoding="utf-8")
    return output


def export_docx(workspace: str | Path) -> Path:
    paths = workspace_paths(workspace)
    info = source_info(paths)
    markdown = safe_child(paths["03.output"], f"{info['stem']}.md", required=True)
    document = Document()
    for paragraph in markdown.read_text(encoding="utf-8").strip().split("\n\n"):
        document.add_paragraph(paragraph.strip().lstrip("#").strip())
    output = safe_child(paths["03.output"], f"{info['stem']}.docx")
    document.save(output)
    return output


def reject_reparse_tree(directory: Path) -> None:
    with os.scandir(directory) as entries:
        for entry in entries:
            child = Path(entry.path)
            if is_reparse(child):
                raise PipelineError(f"symlink/reparse target is not allowed: {child}")
            if entry.is_dir(follow_symlinks=False):
                reject_reparse_tree(child)


def cleanup(workspace: str | Path, confirmed: bool) -> None:
    if not confirmed:
        raise PipelineError("cleanup requires --confirm")
    paths = workspace_paths(workspace)
    markdown = {path.stem for path in paths["03.output"].glob("*.md") if path.is_file() and not is_reparse(path)}
    documents = {path.stem for path in paths["03.output"].glob("*.docx") if path.is_file() and not is_reparse(path)}
    if not markdown.intersection(documents):
        raise PipelineError("required output pair (.md and .docx) is missing")
    for name in ("01.input", "02.process"):
        reject_reparse_tree(paths[name])
    for name in ("01.input", "02.process"):
        shutil.rmtree(paths[name])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("prepare", "preprocess", "merge", "export"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument("workspace")
    render_parser = subparsers.add_parser("render")
    render_parser.add_argument("workspace")
    render_parser.add_argument("pdf")
    cleanup_parser = subparsers.add_parser("cleanup")
    cleanup_parser.add_argument("workspace")
    cleanup_parser.add_argument("--confirm", action="store_true")
    args = parser.parse_args()
    try:
        if args.command == "prepare":
            prepare(args.workspace)
        elif args.command == "render":
            print(f"rendered={render(args.workspace, args.pdf)}")
        elif args.command == "preprocess":
            print(f"preprocessed={preprocess(args.workspace)}")
        elif args.command == "merge":
            print(merge(args.workspace))
        elif args.command == "export":
            print(export_docx(args.workspace))
        else:
            cleanup(args.workspace, args.confirm)
    except (PipelineError, OSError, fitz.FileDataError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
