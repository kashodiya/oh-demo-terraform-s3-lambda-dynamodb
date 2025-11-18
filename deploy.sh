#!/bin/bash

# Deployment script for S3-Lambda-DynamoDB pipeline

set -e

echo "🚀 Deploying S3-Lambda-DynamoDB Pipeline"
echo "========================================"

# Check if AWS CLI is configured
echo "🔍 Checking AWS configuration..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI is not configured or credentials are invalid"
    echo "Please ensure you're running on an EC2 instance with appropriate IAM role"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")
echo "✅ AWS Account: $ACCOUNT_ID"
echo "✅ AWS Region: $REGION"
echo ""

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
    echo ""
fi

# Validate Terraform configuration
echo "✅ Validating Terraform configuration..."
terraform validate
echo ""

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan
echo ""

# Apply deployment
echo "🚀 Deploying infrastructure..."
read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply tfplan
    echo ""
    
    echo "✅ Deployment completed successfully!"
    echo ""
    
    # Display outputs
    echo "📋 Resource Information:"
    echo "======================="
    echo "S3 Bucket: $(terraform output -raw s3_bucket_name)"
    echo "DynamoDB Table: $(terraform output -raw dynamodb_table_name)"
    echo "Lambda Function: $(terraform output -raw lambda_function_name)"
    echo ""
    
    echo "🧪 To test the pipeline, run:"
    echo "   ./test_pipeline.sh"
    echo ""
    
    echo "🧹 To destroy resources when done:"
    echo "   terraform destroy"
    
else
    echo "❌ Deployment cancelled"
    rm -f tfplan
fi