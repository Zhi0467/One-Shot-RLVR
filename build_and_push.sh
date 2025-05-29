#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Set your Docker Hub username or organization, and the base image name
DOCKER_USERNAME="zzzzhi" # Replace with your Docker Hub username or org
IMAGE_BASENAME="reproduce-one-shot-rlvr"
TARGET_PLATFORM="linux/amd64" # Specify the target platform

# --- Script Logic ---
# Check if a tag is provided
if [ -z "$1" ]; then
  echo "ERROR: No tag provided."
  echo "Usage: $0 <tag>"
  echo "Example: $0 latest"
  echo "Example: $0 v1.2"
  echo "Example: $0 $(git rev-parse --short HEAD)" # To use current git commit short hash
  exit 1
fi

TAG=$1
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_BASENAME}:${TAG}"

echo "--------------------------------------------------"
echo "Building Docker image: ${FULL_IMAGE_NAME}"
echo "Target Platform: ${TARGET_PLATFORM}"
echo "--------------------------------------------------"

# Build the image for the specified platform
# Use docker buildx build
docker buildx build --platform ${TARGET_PLATFORM} -t ${FULL_IMAGE_NAME} .

echo "--------------------------------------------------"
echo "Build complete for ${FULL_IMAGE_NAME}"
echo "--------------------------------------------------"

# Ask user if they want to push
read -p "Do you want to push ${FULL_IMAGE_NAME} to Docker Hub? (y/N): " confirm_push

if [[ "$confirm_push" =~ ^[Yy]$ ]]; then
  echo "Pushing ${FULL_IMAGE_NAME} to Docker Hub..."
  docker push ${FULL_IMAGE_NAME}
  echo "--------------------------------------------------"
  echo "Successfully pushed ${FULL_IMAGE_NAME}"
  echo "--------------------------------------------------"
else
  echo "Skipping push. Image built locally: ${FULL_IMAGE_NAME}"
  echo "If you built for a non-native platform (e.g., amd64 on ARM Mac),"
  echo "you might load it to Docker Desktop using 'docker buildx build --platform ... --load .'"
  echo "or inspect it using 'docker buildx imagetools inspect ${FULL_IMAGE_NAME}' (if pushed to registry first)."
fi