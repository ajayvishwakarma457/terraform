# resource "aws_iam_role" "flow_logs_role" {
#   name = "${var.project}-${var.environment}-flowlogs-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = "sts:AssumeRole",
#       Effect = "Allow",
#       Principal = {
#         Service = "vpc-flow-logs.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "flow_logs_policy" {
#   role       = aws_iam_role.flow_logs_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
# }

# resource "aws_cloudwatch_log_group" "flow_logs" {
#   name              = "/aws/vpc/${var.project}-${var.environment}-flowlogs"
#   retention_in_days = 30  # industry standard: 30–90 days in CloudWatch, then archive to S3
# }

# resource "aws_flow_log" "this" {
#   vpc_id              = aws_vpc.this.id
#   log_destination     = aws_cloudwatch_log_group.flow_logs.arn
#   log_destination_type = "cloud-watch-logs"
#   iam_role_arn        = aws_iam_role.flow_logs_role.arn
#   traffic_type        = "ALL"

#   tags = {
#     Name = "${var.project}-${var.environment}-vpc-flowlogs"
#   }
# }



# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.project}-${var.environment}-flowlogs"
  retention_in_days = 30
}

# IAM Role for Flow Logs
resource "aws_iam_role" "flow_logs_role" {
  name = "${var.project}-${var.environment}-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "flow_logs_policy" {
  role       = aws_iam_role.flow_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# VPC Flow Log
resource "aws_flow_log" "this" {
  vpc_id               = aws_vpc.this.id
  log_destination      = aws_cloudwatch_log_group.flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
  traffic_type         = "ALL"

  tags = {
    Name = "${var.project}-${var.environment}-vpc-flowlogs"
  }
}
