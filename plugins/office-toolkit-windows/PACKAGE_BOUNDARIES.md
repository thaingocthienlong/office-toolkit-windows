# Package boundaries

Included in the v0.1.0 package:

- local marketplace entry
- plugin manifest and four public skills
- vendored reference assets with provenance notices
- locked PDF runtime requirements
- PATH/fallback OfficeCLI wrapper
- root `setup.ps1`

Excluded from the v0.1.0 package:

- MCP server, app, hook, network installer, or runtime `pip install`
- repository tests and release staging output

The `assets/vendor` tree is retained for provenance and is an active local runtime/reference surface only where the four public skills route to it. The editorial folder `assets/viet-chuyen-nghiep-v3.1` remains repository-only.
