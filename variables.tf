variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Base name for the S3 bucket (will have random suffix appended)"
  type        = string
  default     = "data-processing-bucket"
}

variable "table_name" {
  description = "Base name for the DynamoDB table (will have random suffix appended)"
  type        = string
  default     = "data-processing-table"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}