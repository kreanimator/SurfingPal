#!/usr/bin/env bash
set -e

# Configuration
BUCKET_NAME="app-control-$(aws sts get-caller-identity --query Account --output text)"
NAME="pandas-numpy"
ZIP_FILE="/tmp/${NAME}-stable.zip"
LAYER_DIR="/tmp/layer-${NAME}"

echo "Building Lambda Layer: ${NAME}"
echo "S3 Bucket: ${BUCKET_NAME}"

# Clean up old artifacts
rm -rf "${LAYER_DIR}"
rm -f "${ZIP_FILE}"
echo "Cleaned old artifacts"

# Create layer directory structure
mkdir -p "${LAYER_DIR}/python"
echo "Created layer directory structure"

# Install pandas and numpy to the layer directory
echo "Installing pandas and numpy..."
pip install pandas numpy -t "${LAYER_DIR}/python" --no-cache-dir

# Remove unnecessary files to reduce size
echo "Removing unnecessary files..."
find "${LAYER_DIR}/python" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "${LAYER_DIR}/python" -type f -name "*.pyc" -delete 2>/dev/null || true
find "${LAYER_DIR}/python" -type f -name "*.pyo" -delete 2>/dev/null || true
find "${LAYER_DIR}/python" -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find "${LAYER_DIR}/python" -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true

# Create zip file
cd "${LAYER_DIR}"
zip -r "${ZIP_FILE}" . -q
cd /tmp

# Show zip contents summary
echo "Created layer package:"
unzip -l "${ZIP_FILE}" | head -20
ZIP_SIZE=$(du -h "${ZIP_FILE}" | cut -f1)
echo "Package size: ${ZIP_SIZE}"

# Upload to S3
echo "Uploading to S3..."
aws s3 cp "${ZIP_FILE}" "s3://${BUCKET_NAME}/lambda_layers/" --no-progress
echo "Uploaded ${NAME}-stable.zip to S3 bucket: ${BUCKET_NAME}/lambda_layers/"

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
cd "$(dirname "$0")"
sam build
sam deploy --config-env default --parameter-overrides "FileName=${NAME}-stable.zip"

echo "Layer deployment complete!"
echo "SSM Parameter: lambda-layer-pandas-numpy-latest"
