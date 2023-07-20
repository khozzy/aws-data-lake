import argparse
import datetime
import json
import random
import time

import boto3

# aws-vault exec personal-tf -- poetry run python gen_temp.py sensor_stream_json

NUM_SENSORS = 10
N_SAMPLES = 25000
LAST_N_DAYS = 3
HIVE_DATA_FMT = "%Y-%m-%d %H:%M:%S.%f"


class Sensor:
    def __init__(self, sensor_id: int, ):
        self.sensor_id = sensor_id
        self.mean_measure = 10 + random.random() * 170

    def random_signal(self):
        measure = random.gauss(self.mean_measure, self.mean_measure / 10)

        return {
            "sensor_id": self.sensor_id,
            "measure": round(measure, 2),
            "event_time": self._random_date(LAST_N_DAYS).strftime(HIVE_DATA_FMT),
        }

    def _random_date(self, last_n_days: int):
        now = datetime.datetime.utcnow()
        past = now - datetime.timedelta(days=-last_n_days)

        tstamps = map(int, map(time.mktime, [now.timetuple(), past.timetuple()]))
        random_tstamp = random.randint(*tstamps)

        return datetime.datetime.fromtimestamp(random_tstamp)


sensors = [Sensor(sensor_id) for sensor_id in range(NUM_SENSORS)]


def send_data(stream_name, client):
    for i in range(1, N_SAMPLES + 1):
        random_sensor = random.choice(sensors)
        data = random_sensor.random_signal()
        print(f"[{i}/{N_SAMPLES}]\n\t{data}")

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
