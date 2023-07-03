resource "aws_s3_bucket" "sink" {
  bucket = var.s3_sink_bucket_name
}

resource "aws_s3_bucket" "athena_output" {
  bucket = "${var.athena_workgroup_name}-athena-output"
}