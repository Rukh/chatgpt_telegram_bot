#!/bin/bash

# Variables
PROJECT_ID="sharp-oxide-430310-b7"
REGION="europe-west10"
SERVICE_NAME="chatgpt-telegram-bot"
IMAGE_NAME="europe-west10-docker.pkg.dev/$PROJECT_ID/cloud-run-source-deploy/$SERVICE_NAME"
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

# Step 2: Check for the presence of env file
if [ ! -f "$ENV_FILE" ]; then
    error_exit "Env file not found: $ENV_FILE"
fi

# Step 3: Build Docker image and tag it for GCR
echo "Building Docker image..."
docker buildx build --platform linux/amd64 -t $IMAGE_NAME:$TAG . || error_exit "Docker build failed"

# Step 4: Authenticate Docker to Google Container Registry
echo "Authenticating Docker to Google Container Registry..."
gcloud auth configure-docker europe-west10-docker.pkg.dev || error_exit "gcloud auth configure-docker failed"

# Step 5: Push Docker image to Google Container Registry
echo "Pushing Docker image..."
docker push $IMAGE_NAME:$TAG || error_exit "Docker push failed"

# Step 6: Deploy Docker image to Google Cloud Run
echo "Deploying Docker image to Google Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_NAME:$TAG \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory 512Mi || error_exit "gcloud run deploy failed"

# gcloud run deploy \
#   --image $IMAGE_NAME:$TAG \
#   --max-instances=3 \
#   --port 8080 || error_exit "gcloud run deploy failed"

echo "Deployment complete!"
