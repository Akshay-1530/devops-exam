terraform {
  backend "s3" {
    bucket = "467.devops.candidate.exam"
    key    = "akshay.pawar"
    region = "ap-south-1"
  }
}
