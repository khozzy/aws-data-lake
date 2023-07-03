resource "aws_cloudwatch_log_group" "log_group" {
  name = var.cloudwatch_log_group
}

resource "aws_cloudwatch_log_stream" "kinesis_delivery_log_stream" {
  name           = var.kinesis_delivery_cloudwatch_log_stream
  log_group_name = aws_cloudwatch_log_group.log_group.name
}