#  MSCK REPAIR TABLE sensors;

resource "aws_glue_catalog_database" "glue_db" {
  name = var.glue_catalog_db_name
}

resource "aws_glue_catalog_table" "glue_sensor_table" {
  database_name = aws_glue_catalog_database.glue_db.name
  name          = "sensors"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "GZIP"
  }

  partition_keys {
    name = "sensor_id"
    type = "int"
  }

  partition_keys {
    name = "dt"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.sink.id}/sensors_raw"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "current_temperature"
      type = "float"
    }

    columns {
      name = "status"
      type = "string"
    }

    columns {
      name = "event_time"
      type = "timestamp"
    }
  }
}