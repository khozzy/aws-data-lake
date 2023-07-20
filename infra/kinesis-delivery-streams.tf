data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "kinesis_firehose_delivery_policy" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.sink.arn,
      "${aws_s3_bucket.sink.arn}/*",
    ]
  }
  statement {
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [
      "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.firehose_sensor_stream_name}"
    ]
  }
  statement {
    actions = [
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.glue_db.name}",
      aws_glue_catalog_table.sensors_parquet.arn,
      aws_glue_catalog_table.sensors_json.arn,
    ]
  }

  statement {
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.cloudwatch_log_group}:log-stream:${var.kinesis_delivery_cloudwatch_log_stream}"
    ]
  }
}

resource "aws_iam_role" "firehose_delivery_role" {
  name               = "firehose_delivery_assume_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
  inline_policy {
    name   = "s3_access"
    policy = data.aws_iam_policy_document.kinesis_firehose_delivery_policy.json
  }
}

resource "aws_kinesis_firehose_delivery_stream" "json_firehose_stream" {
  name        = "${var.firehose_sensor_stream_name}_json"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_delivery_role.arn
    bucket_arn = aws_s3_bucket.sink.arn

    buffer_size     = 64 # mb
    buffer_interval = 60 # sec

    prefix              = "sensors_raw/json/sensor_id=!{partitionKeyFromQuery:sensor_id}/dt=!{timestamp:yyyy-MM-dd}/"
    error_output_prefix = "errors/json/dt=!{timestamp:yyyy-MM-dd}/!{firehose:error-output-type}/"

    dynamic_partitioning_configuration {
      enabled = "true"
    }

    processing_configuration {
      enabled = "true"

      processors {
        type = "AppendDelimiterToRecord"
      }

      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{sensor_id:.sensor_id}"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.log_group.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_delivery_log_stream.name
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "parquet_firehose_stream" {
  name        = "${var.firehose_sensor_stream_name}_parquet"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_delivery_role.arn
    bucket_arn = aws_s3_bucket.sink.arn

    buffer_size     = 64 # mb
    buffer_interval = 60 # sec

    dynamic_partitioning_configuration {
      enabled = "true"
    }

    prefix              = "sensors_raw/parquet/sensor_id=!{partitionKeyFromQuery:sensor_id}/dt=!{timestamp:yyyy-MM-dd}/"
    error_output_prefix = "errors/parquet/dt=!{timestamp:yyyy-MM-dd}/!{firehose:error-output-type}/"

    processing_configuration {
      enabled = "true"

      processors {
        type = "AppendDelimiterToRecord"
      }

      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{sensor_id:.sensor_id}"
        }
      }
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {
            #            compression = "GZIP"
          }
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_database.glue_db.name
        table_name    = aws_glue_catalog_table.sensors_parquet.name
        role_arn      = aws_iam_role.firehose_delivery_role.arn
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.log_group.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_delivery_log_stream.name
    }
  }
}