

# **Docker Swarm - Simplified Guide**

Docker Swarm is a tool to manage **clusters of Docker nodes**. It helps create a scalable, fault-tolerant environment to deploy and manage containerized services.

---

## **Steps to Set up Docker Swarm**

### 1. **Initialize Swarm**
Start by creating the **Swarm Manager** node.

```bash
docker swarm init
```

After this command, the current node becomes the **Swarm Manager**.

```
+-------------------+
| Swarm Manager     |
| (Node-1)          |
|  IP: 192.168.1.10 |
+-------------------+
```

---

### 2. **Add Worker Nodes to the Swarm**
Run the following command on the **manager node** to generate a **join token** for workers.

```bash
docker swarm join-token worker
```

On the **worker nodes**, use the generated token to join:

```bash
docker swarm join --token <worker-token> <manager-ip>:2377
```

Example:

```
docker swarm join --token SWMTKN-1-xxxxx 192.168.1.10:2377
```

```
+-------------------+          +-------------------+
| Swarm Manager     |          | Worker Node       |
| (Node-1)          |   --->   | (Node-2)          |
|  IP: 192.168.1.10 |          |  IP: 192.168.1.11 |
+-------------------+          +-------------------+
```

To **list nodes** in the swarm:

```bash
docker node ls
```

---

### 3. **Promote a Worker to Manager (Optional)**
If you want a **worker node** to also manage the cluster, **promote** it:

```bash
docker node promote <node-ID>
```

If needed, **demote** the manager back to a worker:

```bash
docker node demote <node-ID>
```

---

### 4. **Deploy a Service to the Swarm**
Deploy a **service** across the swarm with **replicas**:

```bash
docker service create --name flask-todo-service --replicas 3 -p 80:5000 nahid0002/flask-todo-app:v1
```

```
+-------------------+   
| Service: Flask    | 
| Replicas: 3       |
+-------------------+
```

To **list services**:

```bash
docker service ls
```

---

### 5. **Scaling the Service**
Increase the number of replicas to **scale** the service:

```bash
docker service scale flask-todo-service=10
```

---

### 6. **Update or Roll Back a Service**
- **Update the service** to a new image version:

  ```bash
  docker service update --image nahid0002/flask-todo-app:v2 flask-todo-service
  ```

- **Rollback** to a previous version:

  ```bash
  docker service rollback flask-todo-service
  ```

---

### 7. **Monitor Services**
- **View logs** of a service:

  ```bash
  docker service logs flask-todo-service
  ```

- **List running containers**:

  ```bash
  docker ps
  ```

---

### 8. **Visualize the Swarm (Optional)**
Run a **Visualizer** to see the cluster in a web browser:

```bash
docker run -it -d -p 8080:8080 \
-v /var/run/docker.sock:/var/run/docker.sock dockersamples/visualizer
```

Access the visualizer at: `http://<manager-ip>:8080`

---

## **Summary of Commands**

| Command                            | Description                          |
|------------------------------------|--------------------------------------|
| `docker swarm init`                | Initialize the swarm                |
| `docker node ls`                   | List all nodes                      |
| `docker swarm join-token worker`   | Get token for worker nodes          |
| `docker service create`            | Deploy a service                    |
| `docker service scale`             | Scale replicas of a service         |
| `docker service update`            | Update service image                |
| `docker service rollback`          | Roll back a service to a previous state |
| `docker service logs`              | View service logs                   |

