#!/bin/bash

# Test script for S3-Lambda-DynamoDB pipeline
# This script tests the complete pipeline by uploading files and checking results

set -e

echo "🚀 Testing S3-Lambda-DynamoDB Pipeline"
echo "======================================"

# Get resource names from Terraform outputs
echo "📋 Getting resource information..."
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
TABLE_NAME=$(terraform output -raw dynamodb_table_name)
FUNCTION_NAME=$(terraform output -raw lambda_function_name)

echo "✅ S3 Bucket: $BUCKET_NAME"
echo "✅ DynamoDB Table: $TABLE_NAME"
echo "✅ Lambda Function: $FUNCTION_NAME"
echo ""

# Create test files
echo "📝 Creating test files..."
mkdir -p test_files

# Create a text file
echo "Hello World! This is a test text file created at $(date)" > test_files/test.txt

# Create a JSON file
cat > test_files/data.json << EOF
{
  "message": "This is a test JSON file",
  "timestamp": "$(date -Iseconds)",
  "data": {
    "numbers": [1, 2, 3, 4, 5],
    "text": "Sample data for testing"
  }
}
EOF

# Create a CSV file
cat > test_files/sample.csv << EOF
name,age,city
John Doe,30,New York
Jane Smith,25,Los Angeles
Bob Johnson,35,Chicago
EOF

echo "✅ Created test files: test.txt, data.json, sample.csv"
echo ""

# Upload files to S3
echo "📤 Uploading files to S3..."
aws s3 cp test_files/test.txt s3://$BUCKET_NAME/
aws s3 cp test_files/data.json s3://$BUCKET_NAME/
aws s3 cp test_files/sample.csv s3://$BUCKET_NAME/

echo "✅ Files uploaded successfully"
echo ""

# Wait for Lambda processing
echo "⏳ Waiting 10 seconds for Lambda processing..."
sleep 10

# Check Lambda logs
echo "📋 Checking Lambda logs..."
LOG_GROUP="/aws/lambda/$FUNCTION_NAME"
aws logs describe-log-streams --log-group-name "$LOG_GROUP" --order-by LastEventTime --descending --max-items 1 > /tmp/log_streams.json

if [ -s /tmp/log_streams.json ]; then
    LATEST_STREAM=$(cat /tmp/log_streams.json | jq -r '.logStreams[0].logStreamName')
    if [ "$LATEST_STREAM" != "null" ]; then
        echo "📄 Latest Lambda execution logs:"
        aws logs get-log-events --log-group-name "$LOG_GROUP" --log-stream-name "$LATEST_STREAM" --limit 20 | jq -r '.events[].message'
    else
        echo "⚠️  No log streams found yet"
    fi
else
    echo "⚠️  No logs available yet"
fi
echo ""

# Check DynamoDB entries
echo "🔍 Checking DynamoDB entries..."
aws dynamodb scan --table-name "$TABLE_NAME" --max-items 10 > /tmp/dynamo_results.json

ITEM_COUNT=$(cat /tmp/dynamo_results.json | jq '.Items | length')
echo "📊 Found $ITEM_COUNT items in DynamoDB table"

if [ "$ITEM_COUNT" -gt 0 ]; then
    echo "📋 Sample entries:"
    cat /tmp/dynamo_results.json | jq -r '.Items[] | "File: \(.file_key.S), Size: \(.file_size.N) bytes, Type: \(.content_type.S), Processed: \(.processed_at.S)"'
else
    echo "⚠️  No items found in DynamoDB yet. Lambda might still be processing or there might be an issue."
fi
echo ""

# List S3 bucket contents
echo "📁 S3 Bucket contents:"
aws s3 ls s3://$BUCKET_NAME/
echo ""

# Clean up test files
echo "🧹 Cleaning up local test files..."
rm -rf test_files
rm -f /tmp/log_streams.json /tmp/dynamo_results.json

echo "✅ Pipeline test completed!"
echo ""
echo "💡 To view more detailed logs:"
echo "   aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
echo ""
echo "💡 To query DynamoDB:"
echo "   aws dynamodb scan --table-name $TABLE_NAME"
echo ""
echo "💡 To clean up AWS resources:"
echo "   terraform destroy"