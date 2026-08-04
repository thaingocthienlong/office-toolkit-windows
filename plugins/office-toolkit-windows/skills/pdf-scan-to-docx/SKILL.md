---
name: pdf-scan-to-docx
description: "Use when converting scanned PDFs, Vietnamese scan documents, or image-only PDFs into page OCR checkpoints, Markdown, or DOCX; Dùng khi OCR PDF scan, số hóa tài liệu tiếng Việt, ghép checkpoint từng trang, hoặc xuất PDF scan sang Markdown/DOCX."
---

# PDF Scan to DOCX

Keep one workspace root with direct children `01.input`, `02.process`, and `03.output`. Run `scripts/pipeline.py prepare <workspace>` first; put the source PDF directly in `01.input`.

| Step | Command / location |
|---|---|
| Render | `render <workspace> <01.input\\file.pdf>` writes `02.process\\page-####.png` |
| Prepare images | `preprocess <workspace>` writes `02.process\\preprocessed` |
| OCR checkpoint | Codex reads images and writes `02.process\\ocr\\page-####.md` |
| Merge / DOCX | `merge <workspace>`, then `export <workspace>` writes `03.output\\<stem>.md/.docx` |
| Retry / cleanup | Re-run render to skip existing pages. Run `cleanup <workspace> --confirm` only after checking both outputs. |

Use the current Python environment with locked dependencies. Do not install packages at runtime, call an OCR API/network service, run vendor scripts, or copy raw source assets outside `01.input`.

Read [OCR checkpoints](references/ocr-checkpoints.md) before transcribing pages. Stop on any missing marker, missing checkpoint/output, path outside `01.input`, or symlink/reparse target.
