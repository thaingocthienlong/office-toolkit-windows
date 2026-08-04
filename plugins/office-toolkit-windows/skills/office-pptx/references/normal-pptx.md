# Normal PPTX

Use shared wrapper `../../scripts/invoke-officecli.ps1` for every OfficeCLI action. Follow its help surface for arguments and schemas. Never run a network installer, download a CLI, call `officecli` directly, or use a legacy Python/Node Office runtime.

Inspect existing `.pptx` structure before editing: slide order, masters, layouts, theme, notes, hyperlinks, and media. Preserve template conventions.

Build one idea per slide. Set title/body sizes explicitly, keep contrast readable, use at most two fonts and one coherent palette, and include an informative visual except on legitimate quote/code/summary slides. Add speaker notes to content slides.

Validate through the wrapper: structure, text, and available visual/annotated preview. Check placeholders, clipping, overflow, slide order, notes, hyperlinks, and escaped text before delivery.
