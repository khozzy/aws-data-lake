import argparse

import boto3
from tqdm import tqdm

# aws-vault exec personal-tf -- poetry run python emitter.py events.data --stream_name events_stream_json

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Emits random data to Kinesis Data Firehose Delivery Stream."
    )
    parser.add_argument("file", type=str, help="Data file")
    parser.add_argument("--stream_name", type=str, help="Kinesis Data Stream Name")
    parser.add_argument("--batch", type=int, default=500)
    args = parser.parse_args()

    with open(args.file, "r", encoding="UTF-8") as f:
        events = f.readlines()

    firehose_client = boto3.client("firehose")

    for i in tqdm(range(0, len(events), args.batch), unit=" batch"):
        records = [{"Data": e} for e in events[i:i + args.batch]]
        firehose_client.put_record_batch(
            DeliveryStreamName=args.stream_name, Records=records
        )
