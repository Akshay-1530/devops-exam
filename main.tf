
# Fetch the existing NAT Gateway
data "aws_nat_gateway" "nat" {
  id = "nat-0a34a8efd5e420945"
}

# Fetch the existing VPC
data "aws_vpc" "vpc" {
  id = "vpc-06b326e20d7db55f9"
}

# Fetch the existing IAM Role for Lambda
data "aws_iam_role" "lambda" {
  name = "DevOps-Candidate-Lambda-Role"
}

# Create a Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet"
  }
}

# Create a Route Table for the Private Subnet
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.vpc.id
}

# Create a Route to NAT Gateway for outbound internet access from the private subnet
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = data.aws_nat_gateway.nat.id
}

# Associate Route Table with the Private Subnet
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create a Security Group for Lambda (to control inbound/outbound traffic)
resource "aws_security_group" "lambda_sg" {
  name   = "lambda_security_group"
  vpc_id = data.aws_vpc.vpc.id

  # Allow inbound traffic (e.g., HTTP requests) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic to any destination
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the Lambda function
resource "aws_lambda_function" "example" {
  function_name = "my_lambda_function"
  role          = data.aws_iam_role.lambda.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.8"
  timeout       = 15

  # Assuming you have a zip file of your Lambda function code stored in S3
  s3_bucket = "467.devops.candidate.exam"
  s3_key    = "Akshay.Pawar"

  environment {
    variables = {
      SUBNET_ID = aws_subnet.private.id
      NAME      = "<Your Full Name>"
      EMAIL     = "<Your Email Address>"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# Output the Subnet ID and Lambda ARN
output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "lambda_function_arn" {
  value = aws_lambda_function.example.arn
}
