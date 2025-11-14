 DevOps Intern Stage 2 Task -  Blue/Green with Nginx Upstreams (Auto-Failover + Manual Toggle)
Hey Cool Keeds! :wave:
:dart: Overview
Your task is to deploy a Blue/Green Nodejs service behind Nginx using pre-built container images (no application code changes, no image rebuilds). You will configure routing, health-based failover, and automated verification via CI.
:hammer_and_spanner: Task Breakdown
What you’re deploying
Two identical Nodejs services shipped as ready-to-run images:
Blue (active) and Green (backup) instances
Expose these endpoints (already implemented in the image):
GET /version → returns JSON and headers
POST /chaos/start → simulates downtime (500s or timeout)
POST /chaos/stop → ends simulated downtime
GET /healthz → process liveness
You must place Nginx in front of them and ensure:
Normal state: all traffic goes to Blue
On Blue’s failure: Nginx automatically switches to Green with zero failed client requests
If Blue fails a request (timeout or 5xx), Nginx retries to Green within the same client request so the client still receives 200.
Blue is active by default, Green is backup.
Do not strip upstream headers; forward app headers to clients.
Failover mechanics (conceptual requirements):
Primary/backup upstreams (use the backup role).
Tight timeouts so failures are detected quickly.
Retry policy that considers error, timeout, and http_5xx retriable.
Mark primary with a low max_fails + short fail_timeout.
Headers
On every successful response, the apps include:
X-App-Pool: blue|green (literal pool identity)
X-Release-Id: <string> (a release identifier)
You must ensure Nginx forwards these headers unchanged.
Environment, ports, and parameterization
Run everything with Docker Compose:
Nginx public entrypoint: http://localhost:8080
Blue direct port (grader triggers chaos here): http://localhost:8081
Green direct port: http://localhost:8082
Your Compose file must be fully parameterized via a .env:
BLUE_IMAGE — image reference for Blue - Image link
GREEN_IMAGE — image reference for Green - Image link
ACTIVE_POOL — blue or green (controls Nginx template)
RELEASE_ID_BLUE, RELEASE_ID_GREEN — passed into the app containers so they return these in X-Release-Id
(Optional) PORT -To determine the port the application should run on
The CI/grader will set these variables.
Required behavior
Baseline (Blue active)
GET <http://localhost:8080/version> → 200, headers show:
X-App-Pool: blue ($APP_POOL)
X-Release-Id: $RELEASE_ID
 consecutive requests: all 200, all indicate blue.
Induce downtime on the active app (Blue)
 POST <http://localhost:8081/chaos/start?mode=error> (or a timeout mode)
Immediate switch to Green
Next GET <http://localhost:8080/version> → 200 with headers:
X-App-Pool: green ($APP_POOL)
X-Release-Id: $RELEASE_ID
4.   Stability under failure
Requests to http://localhost:8080/version within ~10s:
0 non-200s allowed
≥95% responses must be from green (with recommended timeouts this should be ~100%)
Fail conditions
Any non-200 after chaos during the request loop.
Headers don’t match the expected pool/release before/after failover.
No switch observed after chaos.
Constraints (do’s & don’ts)
:white_tick: Use Docker Compose to orchestrate nginx, app_blue, app_green.
:white_tick: Template the Nginx config from ACTIVE_POOL (e.g., envsubst) and support nginx -s reload.
:white_tick: Expose Blue/Green on 8081/8082 so the grader can call /chaos/* directly.
:x: No Kubernetes, no swarm, no service meshes.
:x: No building or modifying app images; no Docker build in CI.
:x: Do not bypass Nginx for the main service endpoint.
:x: A request should not be more than 10 seconds
Part B:
DevOps Research Task – Infrastructure Setup & CLI Flow for Backend.im
:dart: Task Objective:
Research and propose how to set up the infrastructure and workflow that enables developers to push and deploy backend code directly to Backend.im via the Claude Code CLI and other AI tools, using mostly open-source tools and requiring minimal configuration. The sample of what this research is to accomplish, is demonstrated in this video.
:hammer_and_spanner: Core Problem to Solve:
Design a simple, cost-efficient setup where a developer can go from having code locally to having it deployed and live on Backend.im—entirely through the Claude Code CLI and other AI tools—without relying on complex manual setup or proprietary services.
:compass: Guidelines:
Prioritize open-source, lightweight, and cost-free tooling where possible.
The goal is not to implement but to show how you would structure and reason through it.
Think of this like designing the “plumbing” that makes a one-command deployment possible.
:scroll: Deliverable:
A short report or presentation covering:
Proposed architecture and reasoning
Tools or frameworks you’d use (and why)
Local setup flow
High-level deployment sequence diagram
Where minimal custom code would be required
:package: Submission Requirements
For Part A of the Task:
Ensure your repo contains your docker-compose.yml, .env.example, and a README.md explaining how to run it.
Your template nginx config should also be in your repo.
(optional) In your repo, add a DECISION.md file explaining your thought process or anything you would like us to know about your implementation. This has no negative implication on your final score.
For Part B of the Task:
Link to your Google Doc.
Ensure you give general view access to anyone with the link to your Google Doc.
:drawing_pin: Submission Process
Go to the stage-2-devops channel in Slack
Run the command:  “/stage-two-devops”
Submit:
Your full name
Slack Display name
IP Address
Your GitHub repo URL in this format: https://github.com/username/repo
Link to your Google Doc containing your research [Make it accessible].
:alarm_clock: Deadline & Attempts
Deadline: 11:59 PM GMT, 29th October 2025
Attempts Allowed: 1
Late Submissions: :x: Not accepted
