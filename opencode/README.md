# OpenCode AI Agent Configuration

This directory contains the configuration for the OpenCode AI agent system, including custom prompts, plugins, and provider settings.

## Structure

```
opencode/
├── opencode.json          # Main config (template with placeholders)
├── prompts/               # Agent prompts
│   ├── plan.txt          # Planning agent prompt
│   ├── build.txt         # Build agent prompt
│   ├── researcher.txt    # Research subagent prompt
│   └── rigormortis.txt   # Rigor review subagent prompt
├── plugins/               # Custom tool plugins
│   ├── index.mjs         # Plugin registry
│   ├── searxng.mjs       # Web search plugin
│   └── ytt.mjs           # YouTube transcript plugin
├── PHASE2_READY.md       # Setup and testing guide
└── vllm-*.md            # vLLM reference documentation
```

## Configuration

### Environment Variables

The `opencode.json` template uses environment variable placeholders. Set these in your shell profile or `.env` file:

```bash
# API Provider Configuration
export OPENCODE_API_URL="https://your-ai-api-server/v1"

# Excalidraw MCP Server (optional, for diagram features)
export EXCALIDRAW_MCP_PATH="/path/to/excalidraw/local-mcp/dist/index.js"
export CHECKPOINT_API_URL="http://localhost:8180"
export ROOM_SERVER_URL="http://localhost:3002"
export TEAM_ID="your-team-id"
export DEVELOPER_NAME="your-name"
```

### Host-Specific Overrides

Machine-specific configurations (like actual API URLs and paths) should be placed in:

```
hosts-local/<hostname>/opencode/opencode.json
```

The `symlink.sh` script automatically uses these overrides when deploying.

## Installation

1. Run the symlink script:
   ```bash
   ./symlink.sh
   ```

2. Install dependencies:
   ```bash
   cd ~/.config/opencode
   npm install  # or bun install
   ```

3. Configure environment variables (see above)

4. Test the configuration:
   ```bash
   opencode
   ```

## Agents

- **plan**: Planning agent (read-only, creates plans)
- **build**: Build agent (executes changes)
- **researcher**: Web search subagent
- **rigormortis**: Code review subagent

## Plugins

- **searxng**: Web search via SearxNG
- **ytt**: YouTube transcript extraction

## Documentation

- `PHASE2_READY.md` - Phase 2 features and testing guide
- `vllm-quick-reference.md` - vLLM quick reference
- `vllm-options-reference.md` - vLLM configuration options

## Security

The configuration includes strict read permissions to prevent accidental access to:
- Environment files (`.env`, `.envrc`)
- SSH keys and certificates
- Credentials and secrets
- Docker config
- npm registry credentials
