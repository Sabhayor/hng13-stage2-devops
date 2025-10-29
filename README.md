# Blue-Green Deployment with Nginx and Docker Compose

## 🧠 Step 1: Understand What You’re Building
You are setting up a mini production-like environment that has:

- **Two Node.js services** — one called **Blue** and the other **Green**.  
- Both are identical apps, just different versions.  
- You don’t build them; they are already containerized (Docker images).  
- **Nginx** — a reverse proxy sitting in front of them.  
  It receives requests from users and decides which app (Blue or Green) to send traffic to.  
  It also handles failover (if Blue fails, send traffic to Green automatically).  

### Your setup must:
- Send all traffic to Blue normally.  
- When Blue fails (error or timeout), Nginx automatically switches to Green.  
- All of this happens without clients noticing any errors (they still get HTTP 200 OK).  
- You can also manually tell Nginx to switch to Green if you want.  

---

## ⚙️ Step 2: The Tools You’ll Use

| Tool | Purpose |
|------|----------|
| Docker | Runs applications in isolated containers |
| Docker Compose | Manages multiple containers together |
| Nginx | Routes traffic between Blue and Green |
| .env file | Stores environment variables (images, ports, release IDs) |

You won’t write or edit any Node.js code — you’ll only set up how Docker and Nginx handle them.

---

## 🧩 Step 3: The Architecture

```
        ┌─────────────────────────────────┐
        │        NGINX (Port 8080)        │
        │    ┌───────────────────────┐    │
Client →│→→ │ http://localhost:8080 │ →→ │
        │    └───────────────────────┘    │
        │        |               |        │
        │        v               v        │
        │   app_blue:8081     app_green:8082
        │      (Primary)          (Backup)
        └─────────────────────────────────┘
```

- Client talks to **Nginx (localhost:8080)**  
- Nginx sends requests to **Blue (localhost:8081)**  
- If Blue fails, Nginx sends to **Green (localhost:8082)**  

---

## 🗂️ Step 4: Setting Up the Project Files

```
blue-green-nginx/
│
├── docker-compose.yml
├── .env
└── nginx/
    ├── nginx.conf.template
    └── start-nginx.sh
```

### 🔹 1. `.env` file — holds all your configuration
```env
# Node.js images
BLUE_IMAGE=nodejs-blue:latest
GREEN_IMAGE=nodejs-green:latest

# Which one should be active first
ACTIVE_POOL=blue

# Release IDs — just to identify versions
RELEASE_ID_BLUE=blue-v1
RELEASE_ID_GREEN=green-v1

# App port inside container
PORT=3000
```

### 🔹 2. `docker-compose.yml` — defines the 3 containers
- **nginx** → front door for all traffic (uses `start-nginx.sh` to generate config).  
- **app_blue** → runs Blue Node.js service (port 8081).  
- **app_green** → runs Green Node.js service (port 8082).  

All are connected in one mini-network using Docker Compose.

### 🔹 3. `nginx.conf.template` — blueprint for routing rules
```nginx
upstream backend_upstream {
    server ${PRIMARY_HOST}:${PORT} max_fails=1 fail_timeout=2s;
    server ${BACKUP_HOST}:${PORT} backup;
}
```
**Meaning:** “Try Blue once, and if it fails even once within 2 seconds, switch to Green.”

### 🔹 4. `start-nginx.sh` — script to launch Nginx
When the container starts, this script:
1. Checks which pool is active.
2. Decides which is PRIMARY and BACKUP.
3. Substitutes values into the Nginx template.
4. Starts Nginx.

---

## 🚀 Step 5: Running It All

### 🧾 Step 1: Start the containers
```bash
docker compose up -d
```

This starts:
- Nginx → port 8080  
- Blue → port 8081  
- Green → port 8082  

### 🧾 Step 2: Check if Blue is active
```bash
curl -i http://localhost:8080/version
```
Expected output:
```
X-App-Pool: blue
X-Release-Id: blue-v1
```

### 🧾 Step 3: Simulate a failure (chaos)
```bash
curl -X POST http://localhost:8081/chaos/start?mode=error
```

### 🧾 Step 4: Check Nginx again
```bash
curl -i http://localhost:8080/version
```
Expected output:
```
X-App-Pool: green
X-Release-Id: green-v1
```

✅ That means Nginx automatically switched to Green when Blue failed.

### 🧾 Step 5: Stop the chaos (optional)
```bash
curl -X POST http://localhost:8081/chaos/stop
```

---

## 🛠 Step 6: Manual Toggle Between Blue and Green

To manually switch active version:
1. Edit `.env` → set `ACTIVE_POOL=green`  
2. Regenerate config and reload Nginx:

```bash
docker compose exec nginx /bin/sh -c 'export ACTIVE_POOL=green; envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && nginx -s reload'
```

Now `curl localhost:8080/version` should show **Green** as active.

---

## 🔄 Step 7: How Failover Works Internally

1. Try Blue first.  
2. If Blue fails (timeout or 5xx), retry same request on Green.  
3. If Green succeeds, client still gets **200 OK** — no downtime.  
4. Nginx marks Blue as “down” for a few seconds (`fail_timeout=2s`).  
5. After Blue recovers, Nginx can send traffic back.  

All this happens seamlessly within one client request.

---

## ✅ Step 8: Verification Script (Optional in CI)
You can automate checks with a simple bash script that:
1. Confirms Blue is active.
2. Starts chaos on Blue.
3. Waits for failover to Green.
4. Confirms no 500s or timeouts.

---

## 🧭 Step 9: What You’ve Learned

You’ve just built a **Blue/Green failover setup** — the same concept real companies use for **zero-downtime deployments**.

You learned:
- How to run multiple services with Docker Compose.
- How to use Nginx to balance between primary and backup.
- How to detect failures automatically with timeouts.
- How to preserve headers and keep client responses clean.
