resource "aws_athena_workgroup" "workgroup" {
  name = var.athena_workgroup_name
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_output.bucket}"
    }
  }
}