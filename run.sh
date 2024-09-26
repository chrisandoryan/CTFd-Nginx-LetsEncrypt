#!/bin/bash

# Function to check if Docker Swarm is initialized
check_swarm() {
    local SWARM_STATUS=$(docker info --format '{{.Swarm.LocalNodeState}}')

    if [ "$SWARM_STATUS" != "active" ]; then
        echo "Docker Swarm is not initialized. Initializing Swarm..."
        docker swarm init --advertise-addr 127.0.0.1
        if [ $? -eq 0 ]; then
            echo "Swarm initialized successfully."
        else
            echo "Failed to initialize Swarm."
            exit 1
        fi
    else
        echo "Docker Swarm is already initialized."
    fi
}

# Function to check if a Docker network exists
check_network() {
    local NETWORK_NAME="ctfd-traefik-network"
    local NETWORK_EXISTS=$(docker network ls --filter name=${NETWORK_NAME} --format="{{ .Name }}")

    if [ "$NETWORK_EXISTS" == "$NETWORK_NAME" ]; then
        echo "Network '$NETWORK_NAME' already exists."
        docker network rm ctfd-traefik-network
    else
        echo "Network '$NETWORK_NAME' does not exist. Creating network..."
        docker network create --driver overlay $NETWORK_NAME
        if [ $? -eq 0 ]; then
            echo "Network '$NETWORK_NAME' created successfully."
        else
            echo "Failed to create network '$NETWORK_NAME'."
            exit 1
        fi
    fi
}

check_swarm
check_network
docker stack deploy -c docker-compose.yml ctfdtraefik