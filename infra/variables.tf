variable "myip" {
  type    = string
  default = "185.200.83.162/32" # curl ifconfig.io
}

# Athena
variable "athena_workgroup_name" {
  type    = string
  default = "kozlovski"
}

# Glue
variable "glue_catalog_db_name" {
  type    = string
  default = "kozlovski"
}

# Cloudwatch
variable "cloudwatch_log_group" {
  type    = string
  default = "kozlovski"
}

# S3
variable "s3_sink_bucket_name" {
  type    = string
  default = "kozlovski-data"
}

# Kinesis
variable "kinesis_delivery_cloudwatch_log_stream" {
  type    = string
  default = "events_delivery"
}

variable "firehose_stream_name" {
  type    = string
  default = "events_stream"
}