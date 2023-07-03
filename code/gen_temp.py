import datetime
import json
import random
import argparse

import boto3

# aws-vault exec personal-tf -- poetry run python gen_temp.py sensor_stream

HIVE_DATA_FMT = "%Y-%m-%d %H:%M:%S.%f"


def get_random_data():
    current_temperature = round(10 + random.random() * 170, 2)
    if current_temperature > 160:
        status = "ERROR"
    elif current_temperature > 140 or random.randrange(1, 100) > 80:
        status = random.choice(["WARNING", "ERROR"])
    else:
        status = "OK"
    return {
        "sensor_id": random.randrange(1, 100),
        "current_temperature": current_temperature,
        "status": status,
        "event_time": datetime.datetime.utcnow().strftime(HIVE_DATA_FMT),
    }


def send_data(stream_name, client):
    while True:
        data = get_random_data()
        print(data)
        client.put_record(
            DeliveryStreamName=stream_name, Record={"Data": json.dumps(data)}
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Emits random temperature measurements to Kinesis Data Firehose Delivery Stream."
    )
    parser.add_argument("stream_name", help="Kinesis Data Stream Name")
    args = parser.parse_args()

    firehose_client = boto3.client("firehose")
    send_data(args.stream_name, firehose_client)
