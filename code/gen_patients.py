import hashlib
import json
import random
from datetime import datetime

import numpy as np
from faker import Faker
from tqdm import tqdm

HIVE_DATA_FMT = "%Y-%m-%d %H:%M:%S.%f"


def event_generator(cum_probs):
    state = 0  # we always start at state '0'
    yield state

    while state != 3:
        sample = np.random.rand()
        state = (sample < cum_probs[state]).argmax()
        yield state


def build_event(name: str, tstamp: datetime, payload: dict):
    if payload is None:
        payload = {}

    event = {"name": name, "tstamp": tstamp.strftime(HIVE_DATA_FMT), "payload": payload}

    return event | {
        "payload_md5": hashlib.md5(
            json.dumps(payload, sort_keys=True).encode("utf-8")
        ).hexdigest()
    }


def enhance(gen):
    fake = Faker()

    base_params = {"session_id": fake.pystr()}
    account_id = fake.ascii_email()
    mu = 10 + random.random() * 170
    var = mu / 10

    # init tstamp
    dt = fake.date_time_this_decade()

    for e in gen:
        if e == 0:
            body = {"dvce_os": fake.android_platform_token()} | base_params
            dt = fake.date_time_between(start_date=dt)
            yield build_event("anonymous_visited", dt, body)
        if e == 1:
            body = {"account_id": account_id} | base_params
            dt = fake.date_time_between(start_date=dt)
            yield build_event("account_created", dt, body)
        if e == 2:
            body = {
                "account_id": account_id,
                "measurement": random.gauss(mu, var),
            } | base_params
            dt = fake.date_time_between(start_date=dt)
            yield build_event("measurement_recorded", dt, body)


if __name__ == "__main__":
    # transition probability matrix, with following states
    # 0: "anonymous_visited"
    # 1: "account_created"
    # 2: "measurement_recorded"
    # 3: "interest_lost"

    P = np.array(
        [
            [0.4, 0.4, 0.0, 0.2],
            [0.0, 0.0, 0.7, 0.3],
            [0.0, 0.0, 0.9, 0.1],
            [0.0, 0.0, 0.0, 1.0],
        ]
    )

    # holds cumulative distributions
    C = P.cumsum(axis=1)

    NUM_SESSIONS = 100_000
    DUPLICATE_PROBABILITY = 0.01

    events = []
    for _ in tqdm(range(NUM_SESSIONS), desc="Generator", unit=" sessions"):
        for event in enhance(event_generator(C)):
            event_copy = event.copy()
            events.append(event)

            # simulate duplicated events
            if random.uniform(0., 1.) < DUPLICATE_PROBABILITY:
                events.append(event_copy)

    # shuffle rows
    events.sort(key=lambda e: e['payload_md5'])

    # write to file
    with open("events.data", "w", encoding='UTF-8') as f:
        for event in tqdm(events, desc="Writer", unit=" events"):
            event['payload'] = json.dumps(event['payload'])
            f.write(f"{json.dumps(event)}\n")
