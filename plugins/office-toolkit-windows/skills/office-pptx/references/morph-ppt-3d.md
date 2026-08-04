# Morph 3D

Use shared wrapper `../../scripts/invoke-officecli.ps1` for every OfficeCLI action. Follow its help surface for 3D schemas. Never run a network installer, download a CLI, call `officecli` directly, or use a legacy Python/Node Office runtime.

Require a `.glb` model. If the input is `.fbx`, `.obj`, `.blend`, `.usdz`, or another format, ask for conversion before generation; do not silently substitute it. Keep model, deck, and any build inputs together.

Combine Morph actor naming with a restrained model-content layout. Validate model presence, slide structure, notes, transitions, clipping, contrast, and visual preview through the wrapper. Report viewer-dependent 3D/Morph limits honestly.

Read [Bundled styles](styles.md) only for visual direction; it does not authorize direct runtime commands.
