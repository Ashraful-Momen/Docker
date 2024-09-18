Here’s a Docker Swarm cheatsheet with detailed commands and explanations, including ASCII diagrams for better visualization:

---

# Docker Swarm Cheatsheet

Docker Swarm is Docker's native clustering and orchestration tool for managing multiple containers on different hosts. Below is a quick reference guide with diagrams.

---

### 1. **Initialize a Swarm**
- Start a Docker Swarm on the current node.

**Command**:
```
docker swarm init
```

**Diagram**:

```
+-----------------------+
| Host Machine (Manager) |
|  Initialized as Swarm  |
+-----------------------+
```

---

### 2. **Join a Node to the Swarm**
- A worker or manager node can join the swarm by running a token from the manager node.

**Command**:
```
docker swarm join --token <token> <manager_ip:port>
```

**Diagram**:

```
+-----------------------+    +-------------------+
| Swarm Manager         | <---- Worker Node 1     |
+-----------------------+    +-------------------+
                             +-------------------+
                             | Worker Node 2     |
                             +-------------------+
```

---

### 3. **List Nodes in the Swarm**
- View all nodes in the swarm (managers and workers).

**Command**:
```
docker node ls
```

**Diagram**:

```
+----------------------------------+
|  Node ID   |  Hostname   |  Role |
+----------------------------------+
|  abc123    |  manager1   |  Leader |
|  def456    |  worker1    |  Worker |
+----------------------------------+
```

---

### 4. **Deploy a Service**
- Deploy a service on the swarm. A service runs one or more tasks, which are containerized applications.

**Command**:
```
docker service create --name <service_name> <image>
```

**Diagram**:

```
+-------------------------------+
|  Service: web_app             |
|  Running on Multiple Nodes     |
+-------------------------------+
```

---

### 5. **List Services**
- See the list of all services currently running in the swarm.

**Command**:
```
docker service ls
```

**Diagram**:

```
+----------------------------------+
|  ID   |  Name        |  Mode     |
+----------------------------------+
|  xyz  |  web_app     |  Replicated |
|  abc  |  db_service  |  Global     |
+----------------------------------+
```

---

### 6. **Scale a Service**
- Increase or decrease the number of tasks (containers) for a specific service.

**Command**:
```
docker service scale <service_name>=<replicas>
```

**Diagram**:

```
+-------------------------------+
|  Service: web_app             |
|  3 Replicas Running            |
+-------------------------------+
```

---

### 7. **Inspect a Service**
- View details about a specific service, including its configuration and status.

**Command**:
```
docker service inspect <service_name>
```

**Diagram**:

```
+-------------------------------+
|  Service: web_app             |
|  Mode: Replicated             |
|  Replicas: 3                  |
+-------------------------------+
```

---

### 8. **Remove a Service**
- Stop and remove a running service from the swarm.

**Command**:
```
docker service rm <service_name>
```

**Diagram**:

```
+-------------------------------+
|  Service Removed: web_app      |
+-------------------------------+
```

---

### 9. **Check Service Logs**
- View the logs of a running service.

**Command**:
```
docker service logs <service_name>
```

**Diagram**:

```
+-------------------------------+
|  Logs of web_app Service       |
|  [INFO] Service Started        |
|  [ERROR] Connection Failed     |
+-------------------------------+
```

---

### 10. **Promote/Demote a Node**
- Promote a worker node to a manager node or demote a manager to a worker.

**Promote Command**:
```
docker node promote <node_id>
```

**Demote Command**:
```
docker node demote <node_id>
```

**Diagram**:

```
+--------------------+           +------------------+
|  Worker Node       |  Promoted  |  Manager Node    |
+--------------------+  ------->  +------------------+
```

---

### 11. **Drain a Node**
- Drain a node to prevent any new tasks from being scheduled on it. The node will still be part of the swarm.

**Command**:
```
docker node update --availability drain <node_id>
```

**Diagram**:

```
+-------------------+                +------------------+
|  Worker Node      |  Drained       |  No New Tasks     |
+-------------------+  -------->     +------------------+
```

---

### 12. **Create an Overlay Network**
- Overlay networks enable swarm services to communicate across multiple Docker hosts.

**Command**:
```
docker network create -d overlay <network_name>
```

**Diagram**:

```
+-----------------------+
|  Overlay Network       |
+-----------------------+
| Container1 | Container2 |
| Container3 | Container4 |
+-----------------------+
```

---

### 13. **List Services on a Node**
- List all services that are currently running on a specific node.

**Command**:
```
docker node ps <node_id>
```

**Diagram**:

```
+----------------------------+
|  Node: worker1             |
|  Running Services:          |
|  - web_app                 |
|  - db_service              |
+----------------------------+
```

---

### 14. **Roll Back a Service**
- Roll back a service to a previous version.

**Command**:
```
docker service rollback <service_name>
```

**Diagram**:

```
+-------------------------------+
|  Rollback web_app to v1.0      |
+-------------------------------+
```

---

### 15. **Update a Service**
- Update an existing service, such as changing its image or resource limits.

**Command**:
```
docker service update <service_name> --image <new_image>
```

**Diagram**:

```
+-------------------------------+
|  Service: web_app updated      |
|  New Image: v2.0               |
+-------------------------------+
```

---

This Docker Swarm cheatsheet with ASCII diagrams should help software engineers understand the main commands and workflows. Let me know if you need further clarifications or more topics covered!
