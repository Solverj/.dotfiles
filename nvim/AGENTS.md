# Repository Guidelines

## Project Structure & Module Organization
- `init.lua` bootstraps the configuration and delegates to the modular files under `lua/`.
- Core behaviors live in `lua/options.lua`, `lua/keymaps.lua`, and `lua/lazy-plugins.lua`; adjust these when changing defaults shared by every setup.
- Reusable health checks and upstream defaults reside in `lua/kickstart/`, while local-only overrides belong in `lua/custom/plugins/` (each file returns a Lazy plugin spec).
- Docs that mirror the upstream reference live in `doc/`; update them when you add notable capabilities.

## Build, Test, and Development Commands
- `nvim` inside this repo loads the configuration with your current `NVIM_APPNAME`; use `NVIM_APPNAME=nvim-kickstart nvim` for sandboxed trials.
- `nvim --headless "+Lazy sync" +qa` installs or updates plugins without touching your UI session.
- `nvim --headless "+checkhealth" +qa` validates core tooling; pair it with `:Mason` inside a session to install LSP and formatter binaries if needed.

## Coding Style & Naming Conventions
- Lua files follow `.stylua.toml` (2-space indent, Unix line endings, prefer single quotes); run `stylua --check .` before raising a PR.
- Name modules with `snake_case.lua` and keep plugin specs as small tables that return immediately.
- Group related keymaps and options in dedicated files rather than inline plugin specs to keep diffs focused.

## Testing Guidelines
- There is no automated test suite; rely on `nvim --headless "+checkhealth" +qa` and `nvim --headless "+lua require('kickstart.health').check()" +qa` to catch regressions.
- When adding plugins, ensure they support headless startup (no blocking prompts) and document manual verification steps in commit notes.

## Commit & Pull Request Guidelines
- Follow the existing Conventional Commit style (`feat:`, `fix:`, `chore:`) with concise imperative summaries.
- Keep commits scoped to one logical change; include config reload instructions when behavior changes.
- Pull requests should describe the motivation, key changes, and any manual test commands; attach screenshots or logs when the change affects UI elements like statuslines or floating windows.

## Configuration Tips
- Prefer adding experimental plugins under `lua/custom/plugins/NAME.lua` so they can be toggled independently.
- Avoid storing secrets; defer to environment variables or user-local files ignored by Git for credentials and tokens.
