# nginx-rotate-app

A Dockerized nginx web server that automatically rotates between three HTML pages every 5 seconds using a bash script. Great for digital signage, demo displays, or learning Docker + nginx fundamentals.

---

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Testing the Project](#testing-the-project)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project runs an nginx web server inside Docker that cycles through three styled HTML pages:

| Page | Background Color | Title  |
|------|-----------------|--------|
| Page 1 | Light Blue | Page 1 |
| Page 2 | Light Green | Page 2 |
| Page 3 | Light Coral | Page 3 |

Each page is displayed for 5 seconds before switching to the next. The rotation runs for 300 seconds (5 minutes) total, then stops.

---

## Project Structure

```
nginx-rotate-app/
├── docker-compose.yml       # Docker Compose service definition
├── Dockerfile               # Container build instructions
├── start.sh                 # Entrypoint: launches rotation script + nginx
└── webpages/
    ├── index1.html          # Page 1 (light blue)
    ├── index2.html          # Page 2 (light green)
    ├── index3.html          # Page 3 (light coral)
    └── rotate_pages.sh      # Bash script that rotates pages via symlink
```

---

## How It Works

```
Docker Container Startup
        │
        ▼
   start.sh runs
        │
        ├──► rotate_pages.sh (background process)
        │         │
        │         └── Symlinks index.html → index1/2/3.html every 5s
        │
        └──► nginx starts (foreground, daemon off)
                  │
                  └── Serves /usr/share/nginx/html/index.html
```

1. **`start.sh`** is the container entrypoint. It launches `rotate_pages.sh` in the background, then starts nginx in the foreground so Docker keeps the container alive.

2. **`rotate_pages.sh`** loops through `index1.html`, `index2.html`, and `index3.html`, using `ln -sf` to atomically update a symlink at `index.html` every 5 seconds. It runs for 300 seconds total.

3. **nginx** serves whatever `index.html` points to. Each HTML page also includes a `<meta http-equiv="refresh" content="5">` tag so the browser auto-reloads, ensuring the visitor always sees the latest page.

---

## Prerequisites

Make sure the following are installed on your machine:

- [Docker](https://docs.docker.com/get-docker/) (v20+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2+ — included with Docker Desktop)

Verify your installation:

```bash
docker --version
docker compose version
```

---

## Getting Started

### 1. Clone or create the project

```bash
mkdir nginx-rotate-app && cd nginx-rotate-app
# Create all files as described in the Project Structure above
```

### 2. Build and start the container

```bash
docker compose up --build
```

You should see output like:

```
[+] Building ...
...
nginx-rotate  | Starting page rotation...
nginx-rotate  | Starting nginx...
```

### 3. Open your browser

Navigate to:

```
http://localhost
```

The page will automatically change every 5 seconds.

### 4. Stop the container

```bash
# Press Ctrl+C in the terminal running docker compose, or in another terminal:
docker compose down
```

---

## Testing the Project

### ✅ Basic Browser Test

1. Run `docker compose up --build`
2. Open `http://localhost` in your browser
3. Wait and observe — the page background should cycle:
   - **Light Blue** (Page 1) → **Light Green** (Page 2) → **Light Coral** (Page 3) → repeat

### ✅ Verify the Container is Running

```bash
docker ps
```

Expected output:

```
CONTAINER ID   IMAGE                  COMMAND       STATUS         PORTS
xxxxxxxxxxxx   nginx-rotate-app-...   "/start.sh"   Up X seconds   0.0.0.0:80->80/tcp
```

### ✅ Check Logs

```bash
docker logs nginx-rotate
```

You should see nginx access logs updating every 5 seconds (one per browser auto-refresh).

### ✅ Inspect the Symlink Live

Exec into the running container and watch the symlink change:

```bash
docker exec -it nginx-rotate bash

# Inside the container — run this to watch the symlink update live:
watch -n 1 ls -la /usr/share/nginx/html/index.html
```

You'll see `index.html -> index1.html`, then `-> index2.html`, etc., updating every 5 seconds.

### ✅ Test with curl

From your host machine, poll the page title every few seconds:

```bash
for i in {1..10}; do
  curl -s http://localhost | grep "<title>" 
  sleep 3
done
```

Output will alternate between `<title>Page 1</title>`, `<title>Page 2</title>`, and `<title>Page 3</title>`.

### ✅ Verify Port Binding

```bash
curl -I http://localhost
```

You should get `HTTP/1.1 200 OK` with nginx headers.

---

## Configuration

| Setting | Location | Default | Description |
|---------|----------|---------|-------------|
| Page display duration | `rotate_pages.sh` → `INTERVAL` | `5` seconds | How long each page is shown |
| Total rotation time | `rotate_pages.sh` → `DURATION` | `300` seconds | How long the script runs |
| Host port | `docker-compose.yml` → `ports` | `80:80` | Change left side to use a different host port |

**Example: Change rotation interval to 10 seconds**

In `webpages/rotate_pages.sh`:
```bash
INTERVAL=10
```

**Example: Run on port 8080 instead of 80**

In `docker-compose.yml`:
```yaml
ports:
  - "8080:80"
```

Then access via `http://localhost:8080`.

---

## Troubleshooting

**Port 80 already in use**

```bash
# Find what's using port 80
sudo lsof -i :80

# Or change the host port in docker-compose.yml to e.g. 8080
```

**Pages not rotating**

```bash
# Check if the rotation script is running inside the container
docker exec -it nginx-rotate ps aux | grep rotate
```

**Container exits immediately**

```bash
# Check logs for errors
docker logs nginx-rotate
```

Ensure `start.sh` has Unix line endings (LF, not CRLF) and is executable. On Windows, you may need to run:

```bash
sed -i 's/\r//' start.sh
```

**Rebuild after making changes**

```bash
docker compose down
docker compose up --build
```

---

## Notes

- The rotation script stops after **5 minutes** (`DURATION=300`). nginx continues running, but the page will no longer change. Restart the container to reset rotation.
- Each HTML page includes `<meta http-equiv="refresh" content="5">` as a client-side fallback to ensure the browser reloads even if the symlink changes between reloads.
- The symlink approach (`ln -sf`) is atomic on Linux filesystems, so nginx always serves a complete, valid file — there's no risk of serving a partially-written page.
