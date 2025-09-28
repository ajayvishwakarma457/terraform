# Enable GuardDuty Detector
resource "aws_guardduty_detector" "this" {
  enable = true

  tags = {
    Name = "${var.project}-${var.environment}-guardduty"
  }
}


resource "aws_sns_topic" "guardduty_alerts" {
  name = "${var.project}-${var.environment}-guardduty-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com" # 🔹 Replace with your email
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project}-${var.environment}-guardduty-findings"
  description = "Capture GuardDuty findings"
  event_pattern = jsonencode({
    source = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_alerts.arn
}

resource "aws_iam_role" "guardduty_events_role" {
  name = "${var.project}-${var.environment}-gd-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "guardduty_events_policy" {
  role = aws_iam_role.guardduty_events_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "sns:Publish",
      Resource = aws_sns_topic.guardduty_alerts.arn
    }]
  })
}

resource "aws_cloudwatch_event_target" "send_to_sns_with_role" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_alerts.arn
  role_arn  = aws_iam_role.guardduty_events_role.arn
}
