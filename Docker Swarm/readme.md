First read-out the Docker DevOps/Class/docker swarm notes then => in the docker-stack file use the correct images name , volume path for avoing the scaling up and replication error . 

#if we run the docker-stack.yml no need to run the docker-compose.yml file . 

1. To run the docker-stack.yml :
2. -----------------------------
3. >>> docker stack deploy -c docker-stack.yml laravel


4. to remove the stack :
5. >>> docker stack rm laravel

   #after delete the stack need to run the sleep command either getting the network error .

   >>> sleep 15

7. Checking the service :
8. >>> docker service ls

9. detail check the service node :
10. >>> docker inspect container_id

