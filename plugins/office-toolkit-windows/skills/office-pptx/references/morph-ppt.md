# Morph PPT

Use shared wrapper `../../scripts/invoke-officecli.ps1` for every OfficeCLI action. Follow its help surface for transition and shape schemas. Never run a network installer, download a CLI, call `officecli` directly, or use a legacy Python/Node Office runtime.

Use Morph only when adjacent slides share a visual element that transforms. Give persistent actors identical names across adjacent slides. Prefix names consistently; move exiting `!!` actors off-canvas instead of deleting them. Plan displacement or rotation large enough to be visible.

Validate structural readback and visual preview through the wrapper. PowerPoint supports Morph; other renderers may show a fade, so report that runtime limit honestly.

For visual direction, use [Bundled styles](styles.md). Keep style guidance separate from runtime execution.
