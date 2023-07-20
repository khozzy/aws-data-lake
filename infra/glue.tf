resource "aws_glue_catalog_database" "glue_db" {
  name = var.glue_catalog_db_name
}

resource "aws_glue_catalog_table" "sensors_json" {
  database_name = aws_glue_catalog_database.glue_db.name
  name          = "sensors_json"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL" : "true",
    "classification" : "json"
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
    location      = "s3://${aws_s3_bucket.sink.id}/sensors_raw/json/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "measure"
      type = "float"
    }

    columns {
      name = "event_time"
      type = "timestamp"
    }
  }
}

resource "aws_glue_catalog_table" "sensors_parquet" {
  database_name = aws_glue_catalog_database.glue_db.name
  name          = "sensors_parquet"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
    #    "parquet.compression" = "GZIP"
    "classification" : "parquet"
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
    location      = "s3://${aws_s3_bucket.sink.id}/sensors_raw/parquet/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "measure"
      type = "float"
    }

    columns {
      name = "event_time"
      type = "timestamp"
    }
  }
}