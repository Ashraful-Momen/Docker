Docker networking offers several types of network drivers, including `macvlan` and `ipvlan`. These drivers provide advanced networking setups and are commonly used in cases where you need greater control over how containers communicate with the external network or each other.

### 1. **`macvlan` Mode**

`macvlan` mode creates a new MAC address for each container, making the container appear as a physical device on the network. This can be useful if you want your containers to appear directly on the local network (bypassing the Docker host), with each container acting as an independent machine.

#### When to Use `macvlan`:
- **Use case**: When you want containers to behave as if they are on the same physical network as the host machine, each with its own MAC and IP address.
- **Scenario**: Containers need to be reachable directly from your LAN and require their own MAC addresses (e.g., connecting to specific external network hardware or needing broadcast functionality).

#### Example:

```
+----------------------------+     +-----------------+
|  Host Machine               |     |   External LAN  |
|  (Docker)                   |     |                 |
|  +-----------------------+  |     | +-------------+ |
|  | Container1 (MAC: AA)  |  |     | |   Router    | |
|  | IP: 192.168.1.2        |  |     | | 192.168.1.1 | |
|  +-----------------------+  |     | +-------------+ |
|  +-----------------------+  |
|  | Container2 (MAC: BB)  |  |
|  | IP: 192.168.1.3        |  |
|  +-----------------------+  |
+----------------------------+
```

- **Container1 and Container2** have their own unique MAC and IP addresses.
- They can be accessed directly on the network like physical machines.
  
##### Command to create `macvlan` network:
```bash
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan_net
```

You can then run a container on this network:
```bash
docker run -d --name container1 --network macvlan_net alpine
```

### 2. **`ipvlan` Mode**

The `ipvlan` driver is similar to `macvlan`, but it doesn't assign a new MAC address to each container. Instead, containers share the MAC address of the host's network interface. `ipvlan` can operate in two modes: **L2 (Layer 2)** and **L3 (Layer 3)**.

#### **Layer 2 (`ipvlan` L2)**:
In this mode, containers behave similarly to `macvlan`, where they are directly accessible on the LAN, but they share the same MAC address as the host. Each container gets its own IP address, but they communicate using the same MAC address.

#### When to Use `ipvlan L2`:
- **Use case**: You want containers to have different IP addresses but not different MAC addresses. It can be useful if your network has strict limits on the number of MAC addresses allowed per physical interface (e.g., virtualized environments).
  
#### Example:

```
+----------------------------+     +-----------------+
|  Host Machine (MAC: AA)     |     |   External LAN  |
|  (Docker)                   |     |                 |
|  +-----------------------+  |     | +-------------+ |
|  | Container1 (IP: 192.168.1.2)  |  | |   Router    | |
|  | MAC: Host MAC (AA)       |     | | 192.168.1.1 | |
|  +-----------------------+  |     | +-------------+ |
|  +-----------------------+  |
|  | Container2 (IP: 192.168.1.3)  |
|  | MAC: Host MAC (AA)       |
|  +-----------------------+  |
+----------------------------+
```

- **Container1** and **Container2** have separate IP addresses but share the same MAC address as the host.
  
##### Command to create `ipvlan L2` network:
```bash
docker network create -d ipvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  ipvlan_net
```

You can then run a container on this network:
```bash
docker run -d --name container1 --network ipvlan_net alpine
```

#### **Layer 3 (`ipvlan` L3)**:
In `L3` mode, containers operate in different subnets and communicate via routing. Containers on the same Docker host communicate through layer 3 routing, and each container gets its own IP address within its subnet.

#### When to Use `ipvlan L3`:
- **Use case**: Useful when you want to isolate different networks and route traffic between them, where containers do not need to appear as if they are on the same physical network.
  
#### Example:

```
+----------------------------+     +-----------------+
|  Host Machine (MAC: AA)     |     |   External LAN  |
|  (Docker)                   |     |                 |
|  +-----------------------+  |     | +-------------+ |
|  | Container1 (10.0.0.2)  |  |     | |   Router    | |
|  | MAC: Host MAC (AA)      |     | | 192.168.1.1 | |
|  +-----------------------+  |     | +-------------+ |
|  +-----------------------+  |
|  | Container2 (10.0.1.2)  |  |
|  | MAC: Host MAC (AA)      |
|  +-----------------------+  |
+----------------------------+
```

- **Container1** and **Container2** are in different subnets (e.g., `10.0.0.0/24` and `10.0.1.0/24`), but they share the same MAC address as the host.
- Communication between them happens via routing, not switching.

##### Command to create `ipvlan L3` network:
```bash
docker network create -d ipvlan \
  --subnet=10.0.0.0/24 \
  --gateway=10.0.0.1 \
  -o ipvlan_mode=l3 \
  -o parent=eth0 \
  ipvlan_net
```

You can run containers on this network, and you would need a router to handle cross-subnet communication.

---

### Summary Table

| Network Driver | Layer | MAC Address   | IP Address  | Use Case                                |
|----------------|-------|---------------|-------------|-----------------------------------------|
| `macvlan`      | L2    | Unique per container | Unique per container | When you want containers to be fully exposed on the local network, each with its own MAC and IP. |
| `ipvlan` L2    | L2    | Same as host  | Unique per container | When you need separate IP addresses but want to avoid multiple MACs (e.g., MAC restrictions). |
| `ipvlan` L3    | L3    | Same as host  | Unique per container | When you want containers on different subnets and prefer routing between them. |

Let me know if you need further clarification or examples!
