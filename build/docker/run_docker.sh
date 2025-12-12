#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Navigate to the directory containing docker-compose.yml
cd "$SCRIPT_DIR"

echo "Building and running in Docker..."
docker-compose up --build builder

echo "Docker build complete."
