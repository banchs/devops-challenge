terraform {
  required_version = "1.1.9"
  backend "s3" {
    bucket = ""
    key    = ""
    # NOTE: This is the region the state s3 bucket is in,
    # not the region the aws provider will deploy into
    region = "us-east-1"
    #dynamodb_table = "terraform-locks"
    encrypt = true
  }
}
