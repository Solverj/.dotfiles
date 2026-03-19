# ✅ OpenCode Config Updated for Phase 2

## Configuration Changed

Updated `~/.config/opencode/opencode.json`:

**Before:**
```json
"CHECKPOINT_API_URL": "http://localhost:8080"
```

**After:**
```json
"CHECKPOINT_API_URL": "http://localhost:8180"
```

## Why This Change?

- **Port 8080**: Local mock API (in-memory, data lost on restart)
- **Port 8180**: Docker-based Checkpoint API (persistent storage, full Phase 2 features)

## ✅ What's Running

| Service | URL | Status |
|---------|-----|--------|
| Checkpoint API (Docker) | http://localhost:8180 | ✅ Running |
| Excalidraw Room (Docker) | http://localhost:3002 | ✅ Running |
| Excalidraw UI (Docker) | http://localhost:3000 | ✅ Running |
| Local MCP | Configured | ✅ Ready |

## 🧪 Test It Now

Your OpenCode config is already set up! Just start a new chat and try:

```
Create a diagram with a rectangle at position (100, 100)
```

Then test Phase 2 features:

```
Add a circle to the diagram and show me the diff
```

```
Move the rectangle to position (500, 500) and check for conflicts
```

```
Create a change proposal to add a triangle
```

## 🔧 If You Need to Switch Back

To use the local mock API instead:
1. Edit `~/.config/opencode/opencode.json`
2. Change `CHECKPOINT_API_URL` back to `http://localhost:8080`
3. Restart OpenCode

## 📊 Docker Management

```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Restart all services
docker-compose up -d
```

---

**Ready to test Phase 2 features!** 🎉
