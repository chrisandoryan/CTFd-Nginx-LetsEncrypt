#!/bin/bash

if ! [ -x "$(command -v docker compose)" ]; then
    echo 'Error: docker compose is not installed.' >&2
    exit 1
fi

# # # # # # # # # # # # # # # # 
# CUSTOMIZABLE CONFIGURATION  #
# # # # # # # # # # # # # # # # 
email="admin@idcyberskills.com" 
domains=(ctfd.idcyberskills.com www.ctfd.idcyberskills.com)

prepare_compose_file() {
    local compose_file="docker-compose.yml"

    cp "${compose_file}.template" "$compose_file"
    
    for domain in "${domains[@]}"; do
        if [[ -z "$domain_rule" ]]; then
            domain_rule="Host(\`${domain}\`)"
        else
            domain_rule="${domain_rule} || Host(\`${domain}\`)"
        fi
    done

    sed -i "s/postmaster@idcyberskills\.com/${email}/g" "$compose_file"
    sed -i "s/Host(\`ctfd\.idcyberskills\.com\`)/${domain_rule}/g" "$compose_file"

    echo "Created docker-compose.yml with new domain(s): ${domains[*]}"
}

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

check_network() {
    local NETWORK_NAME="ctfd-traefik-network"
    local NETWORK_EXISTS=$(docker network ls --filter name=${NETWORK_NAME} --format="{{ .Name }}")

    if [ "$NETWORK_EXISTS" == "$NETWORK_NAME" ]; then
        echo "Network '$NETWORK_NAME' already exists."
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

prepare_compose_file
check_swarm
check_network
docker stack deploy -c docker-compose.yml scaled_ctfd_traefik