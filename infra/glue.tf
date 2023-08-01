resource "aws_glue_catalog_database" "glue_db" {
  name = var.glue_catalog_db_name
}

resource "aws_glue_catalog_table" "events_json" {
  database_name = aws_glue_catalog_database.glue_db.name
  name          = "events_json"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL" : "true",
    "classification" : "json"
  }

  partition_keys {
    name = "name"
    type = "string"
  }

  partition_keys {
    name = "d"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.sink.id}/events_raw/json/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "tstamp"
      type = "timestamp"
    }

    columns {
      name = "payload"
      type = "string"
    }

    columns {
      name = "payload_md5"
      type = "string"
    }
  }
}

resource "aws_glue_catalog_table" "events_parquet" {
  database_name = aws_glue_catalog_database.glue_db.name
  name          = "events_parquet"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
    "classification" : "parquet"
  }

  partition_keys {
    name = "name"
    type = "string"
  }

  partition_keys {
    name = "d"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.sink.id}/events_raw/parquet/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "tstamp"
      type = "timestamp"
    }

    columns {
      name = "payload"
      type = "string"
    }

    columns {
      name = "payload_md5"
      type = "string"
    }
  }
}
