# S3-Lambda-DynamoDB Data Processing Pipeline

> **🤖 AI-Generated Project**: This entire project was created using a single prompt with OpenHands! The AI generated all Terraform configurations, Lambda code, deployment scripts, and documentation in one shot.

## Original Prompt

This project has 2 sub components:

1. Write Terraform script to create a S3 bucket in which data files will be uploaded. When file arrive it should trigger a Lambda. Lambda should store the data in DynamoDB.
2. Write that Lambda code.

### AWS Environment Setup Requirements

**Authentication:**
- You are executing on an EC2 instance with an IAM role that has permissions for all required AWS services
- Do not use or reference AWS access keys, secret keys, or credential files
- Rely solely on the EC2 instance's IAM role for AWS API authentication

**Infrastructure Management:**
- Use Terraform exclusively for creating all AWS resources
- Ensure all AWS resources are defined in Terraform configuration files
- The environment must be completely destroyable using `terraform destroy` without leaving any orphaned resources

**Clean Deployment Goal:**
- After running `terraform destroy`, no AWS resources should remain active or incur charges
- All resources must be properly tracked in Terraform state
- Use local state

---

## Project Overview

This project creates an AWS infrastructure that automatically processes files uploaded to an S3 bucket using Lambda functions and stores the metadata in DynamoDB.

## Architecture

1. **S3 Bucket**: Receives uploaded files and triggers Lambda function
2. **Lambda Function**: Processes S3 events, reads file metadata, and stores data in DynamoDB
3. **DynamoDB Table**: Stores file metadata and processing information

## Components

### Terraform Infrastructure
- `main.tf`: Main Terraform configuration with all AWS resources
- `variables.tf`: Input variables for customization
- `outputs.tf`: Output values after deployment
- `lambda_function.py.tpl`: Template for Lambda function code

### Lambda Function
- Processes S3 ObjectCreated events
- Extracts file metadata (size, content type, etc.)
- Reads content preview for text files
- Stores all information in DynamoDB with timestamp

## Deployment Instructions

### Prerequisites
- AWS CLI configured or running on EC2 instance with appropriate IAM role
- Terraform installed

### Deploy Infrastructure

1. Initialize Terraform:
```bash
terraform init
```

2. Plan the deployment:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

4. Note the output values (S3 bucket name, DynamoDB table name, Lambda function name)

### Test the Pipeline

1. Upload a test file to the S3 bucket:
```bash
# Get the bucket name from terraform output
BUCKET_NAME=$(terraform output -raw s3_bucket_name)

# Upload a test file
echo "Hello, World! This is a test file." > test.txt
aws s3 cp test.txt s3://$BUCKET_NAME/
```

2. Check DynamoDB for the processed data:
```bash
# Get the table name from terraform output
TABLE_NAME=$(terraform output -raw dynamodb_table_name)

# Query the table
aws dynamodb scan --table-name $TABLE_NAME
```

3. Check Lambda logs:
```bash
# Get the function name from terraform output
FUNCTION_NAME=$(terraform output -raw lambda_function_name)

# View recent logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/$FUNCTION_NAME"
```

### Clean Up

To destroy all resources:
```bash
terraform destroy
```

## DynamoDB Schema

The DynamoDB table stores the following information for each processed file:

- `file_key` (Hash Key): S3 object key
- `timestamp` (Range Key): Processing timestamp
- `bucket_name`: Source S3 bucket
- `file_size`: File size in bytes
- `content_type`: MIME type of the file
- `last_modified`: File's last modified timestamp
- `etag`: S3 ETag of the file
- `event_name`: S3 event type (e.g., ObjectCreated:Put)
- `processed_at`: When the Lambda processed the file
- `content_preview`: First 500 characters (for text files only)

## Customization

You can customize the deployment by modifying variables in `variables.tf` or by passing them during terraform apply:

```bash
terraform apply -var="aws_region=us-west-2" -var="environment=prod"
```

## Security Features

- S3 bucket has public access blocked
- Server-side encryption enabled on S3 bucket
- IAM roles follow principle of least privilege
- Lambda function has minimal required permissions

## Monitoring

- Lambda function logs are automatically sent to CloudWatch
- DynamoDB metrics are available in CloudWatch
- S3 access logs can be enabled if needed