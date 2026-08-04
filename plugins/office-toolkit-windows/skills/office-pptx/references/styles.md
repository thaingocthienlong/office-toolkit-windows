# Bundled Styles

Use bundled style assets for visual direction only. Select a preset from `../../assets/vendor/xu-ly-van-phong-cli/references/skills/morph-ppt/reference/styles/`; read its `style.md` and use its `.pptx` asset when useful. Do not read or execute `build.sh` as a runtime path.

Use shared wrapper `../../scripts/invoke-officecli.ps1` for all deck operations. Never run a network installer, download a CLI, call `officecli` directly, or use a legacy Python/Node Office runtime.

User-provided brand assets take precedence. Never use the vendor `example/` brand kit for a real deliverable. Preserve readable contrast, spacing, type hierarchy, and template integrity; style assets are references, not coordinates to copy blindly.
