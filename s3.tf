resource "aws_s3_bucket" "secure_bucket" {
  bucket = "secure-ha-stack-file-bucket-dduckett"

  tags = {
    Name        = "Secure HA Stack File Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block_bucket_from_public" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "app_python_script" {
  bucket = aws_s3_bucket.secure_bucket.id
  key    = "app/app.py"
  source = "app.py"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("app.py")
}