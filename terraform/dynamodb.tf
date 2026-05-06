# Create the DynamoDB Table to store URLs
resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = var.db_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "short_code"

  attribute {
    name = "short_code"
    type = "S"
  }

  attribute {
    name = "long_url"
    type = "S"
  }

  # Time To Live configuration, you can set this to true if you want to delete items after a certain amount of time
  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }


  # With a GSI on long_url, DynamoDB creates what's essentially a second lookup table behind the scenes, letting you query directly by the long URL in O(1) time.
  global_secondary_index {
    name            = "LongUrlIndex"
    hash_key        = "long_url"
    projection_type = "KEYS_ONLY"
  }

  tags = {
    Name        = "dynamodb-table"
    Environment = "URLShortener"
  }
}
