#!/bin/bash

# Variables
PROJECT_ID="sharp-oxide-430310-b7"
REGION="europe-west10"
SERVICE_NAME="chatgpt-telegram-bot"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"
TAG="latest"
ENV_FILE="config/config.env"

# Function to exit with an error message and read logs
function error_exit {
    echo "$1" 1>&2
    exit 1
}

# Step 1: Install gcloud CLI and Docker (if not installed)
if ! command -v gcloud &> /dev/null; then
    echo "gcloud CLI not installed. Installing..."
    curl https://sdk.cloud.google.com | bash
    exec -l $SHELL
    gcloud init
fi

if ! command -v docker &> /dev/null; then
    echo "Docker not installed. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    exec -l $SHELL
fi

if ! command -v docker-compose &> /dev/null; then
    echo "docker-compose not installed. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    exec -l $SHELL
fi

# Step 2: Check for the presence of env file
if [ ! -f "$ENV_FILE" ]; then
    error_exit "Env file not found: $ENV_FILE"
fi

# Step 3: Build Docker image using docker-compose
echo "Building Docker image..."
docker-compose build || error_exit "docker-compose build failed"

# Step 4: Authenticate Docker to Google Container Registry
echo "Authenticating Docker to Google Container Registry..."
gcloud auth configure-docker gcr.io || error_exit "gcloud auth configure-docker failed"

# Step 5: Push Docker image to Google Container Registry
echo "Pushing Docker image..."
docker-compose push || error_exit "docker-compose push failed"

# # Step 6: Deploy Docker image to Google Cloud Run
# echo "Deploying Docker image to Google Cloud Run..."
# gcloud run deploy $SERVICE_NAME \
#   --region $REGION \
#   --image $IMAGE_NAME:$TAG \
#   --max-instances=3 \
#   --allow-unauthenticated || error_exit "gcloud run deploy failed"

# echo "Deployment complete!"