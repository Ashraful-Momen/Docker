First readout the Docker DevOps/Class/docker swarm notes then => in the docker-stack file use the correct images name , volume path for avoing the scaling up and replication error . 


1. To run the docker-stack.yml :
2. -----------------------------
3. >>> docker stack deploy -c docker-stack.yml laravel


4. to remove the stack :
5. >>> docker stack rm laravel

6. Checking the service :
7. >>> docker service ls

8. detail check the service node :
9. >>> docker inspect container_id

