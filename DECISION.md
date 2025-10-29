##  Project: Blue-Green Node.js Deployment with Nginx (Auto-Failover + Manual Toggle)

---

### **1. Objective**
The purpose of this setup is to deploy two identical Node.js services — **Blue** (active) and **Green** (standby) — behind an **Nginx reverse proxy** using **Docker Compose**.  
Nginx automatically detects if the active (Blue) service fails and switches to the backup (Green) without any failed client requests or downtime.

---

### **2. Key Design Choices**

#### **a. Blue/Green Deployment Model**
I used a **Blue/Green deployment pattern** because it allows:
- Zero-downtime updates and rollbacks  
- Side-by-side version testing  
- Immediate recovery on failure  

In normal state, **Blue** serves traffic while **Green** waits in standby.  
When Blue fails, Nginx reroutes requests to Green automatically.

---

#### **b. Docker Compose for Orchestration**
Docker Compose was chosen because:
- It’s lightweight and simple to run locally or in CI/CD environments  
- Supports environment variable substitution from a `.env` file  
- Meets the project constraint (no Kubernetes or Swarm allowed)

The Compose file defines:
- `app_blue` container (port 8081)  
- `app_green` container (port 8082)  
- `nginx` container (port 8080 public entrypoint)

---

#### **c. Environment Parameterization**
All configuration values are stored in a `.env` file:
```env
BLUE_IMAGE=nodejs-blue:latest
GREEN_IMAGE=nodejs-green:latest
ACTIVE_POOL=blue
RELEASE_ID_BLUE=1.0.0
RELEASE_ID_GREEN=1.0.1
PORT=3000
````

This allows dynamic substitution in:

* Docker Compose services
* Nginx template via `envsubst`
* CI/CD pipelines (the grader or Jenkins can inject values)

---

#### **d. Nginx Failover Logic**

Nginx is configured with two upstreams:

```nginx
upstream app_pool {
    server app_blue:3000 max_fails=1 fail_timeout=5s;
    server app_green:3000 backup;
}
```

Key mechanics:

* Blue is **primary**, Green is **backup**
* `max_fails` + `fail_timeout` ensures quick detection of Blue’s failure
* `proxy_next_upstream` retries failed requests on Green
* No failed requests are exposed to clients
* Headers like `X-App-Pool` and `X-Release-Id` are forwarded unchanged

This ensures seamless automatic failover within the same client request.

---

#### **e. Nginx Template & Reload**

A startup script `start-nginx.sh` is used to:

* Substitute environment variables in `nginx.conf.template`
* Generate `nginx.conf` dynamically
* Start or reload Nginx gracefully

This allows easy toggling between Blue and Green:

```bash
ACTIVE_POOL=green ./nginx/start-nginx.sh
sudo nginx -s reload
```

---

#### **f. Chaos Simulation**

Both app containers expose:

* `POST /chaos/start` → Simulate failure (5xx or timeout)
* `POST /chaos/stop` → Restore normal operation

This helps validate that failover works:

```bash
curl -X POST http://localhost:8081/chaos/start?mode=error
```

After this, Nginx should instantly route requests to Green with `200 OK`.

---

#### **g. Health & Stability**

* `/healthz` endpoint for liveness checking
* Passive health monitoring (based on timeout and 5xx responses)
* No downtime allowed during failover (<10s detection window)

---



### **4. Testing Summary**

1. **Baseline**

   ```bash
   curl http://localhost:8080/version
   → X-App-Pool: blue
   ```
2. **Chaos Simulation**

   ```bash
   curl -X POST http://localhost:8081/chaos/start
   curl http://localhost:8080/version
   → X-App-Pool: green
   ```
3. **Recovery**

   ```bash
   curl -X POST http://localhost:8081/chaos/stop
   # Optional manual toggle to switch back to Blue
   ```

All tests should result in continuous `200 OK` responses even during failover.




