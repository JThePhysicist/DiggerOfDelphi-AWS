variable "google_api_key" {
  description = "Google API key for the Lambda function"
  type        = string
}

provider "aws" {
  region = "us-west-1"
}

resource "aws_s3_bucket" "photos" {
  bucket = "photo-bucket-3df2er5tsd"  # Ensure this name is unique
  acl    = "private"
}

resource "aws_dynamodb_table" "label_table" {
  name         = "ImageLabels"
  billing_mode = "PROVISIONED"
  read_capacity  = 25  # Free Tier limit for read capacity units
  write_capacity = 25  # Free Tier limit for write capacity units
  hash_key     = "filename"

  attribute {
    name = "filename"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name   = "lambda-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:*",
            "dynamodb:*",
            "logs:*",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_lambda_function" "process_images" {
  filename         = "lambda_function.zip"
  function_name    = "ProcessImages"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      S3_BUCKET  = aws_s3_bucket.photos.bucket
      DYNAMODB_TABLE = aws_dynamodb_table.label_table.name
      GOOGLE_API_KEY = var.google_api_key
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.photos.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_images.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_s3]  
}


resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_images.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.photos.arn
}
