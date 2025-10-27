# ==============================
# DynamoDB Table (Final Clean Version)
# ==============================

resource "aws_dynamodb_table" "tanvora_table" {
  name           = var.table_name
  billing_mode   = var.billing_mode
  hash_key       = var.hash_key

  # Only add sort key if provided
  range_key = var.sort_key != "" ? var.sort_key : null

  # ========================
  # Attribute Definitions
  # ========================
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  # Optional sort key attribute
  dynamic "attribute" {
    for_each = var.sort_key != "" ? [1] : []
    content {
      name = var.sort_key
      type = var.sort_key_type
    }
  }

  # ========================
  # Features
  # ========================
  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-dynamodb-${var.table_name}"
    }
  )
}
