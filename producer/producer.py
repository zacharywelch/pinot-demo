import json
import os
import time
import random
from datetime import datetime
from kafka import KafkaProducer

# Get configuration from environment variables
bootstrap_servers = os.environ.get('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
topic_name = os.environ.get('TOPIC_NAME', 'example-topic')
interval_ms = int(os.environ.get('INTERVAL_MS', '1000'))

# Create a Kafka producer instance
producer = KafkaProducer(
    bootstrap_servers=bootstrap_servers,
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

print(f"Producer started. Sending events to topic '{topic_name}' every {interval_ms}ms")

# Event counter
counter = 0

# Generate and send events indefinitely
while True:
    # Create an event with timestamp and random data
    counter += 1

    # Get current timestamp in seconds since epoch (integer for Pinot)
    timestamp_epoch = int(time.time())

    event = {
        'id': counter,
        'timestamp': timestamp_epoch,  # Using integer timestamp in seconds
        'value': random.randint(1, 100),
        'message': f"Hello Kafka! Message #{counter}"
    }

    # Send the event to Kafka
    producer.send(topic_name, event)

    # Print confirmation message
    print(f"Sent event: {event}")

    # Wait for the specified interval
    time.sleep(interval_ms / 1000)
