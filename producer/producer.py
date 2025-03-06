import json
import os
import time
import random
import uuid
from datetime import datetime
from kafka import KafkaProducer

# Get configuration from environment variables
bootstrap_servers = os.environ.get('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
topic_name = os.environ.get('TOPIC_NAME', 'example-topic')
interval_ms = int(os.environ.get('INTERVAL_MS', '1000'))

# Get security settings
security_protocol = os.environ.get('KAFKA_SECURITY_PROTOCOL', 'PLAINTEXT')
sasl_mechanism = os.environ.get('KAFKA_SASL_MECHANISM', 'PLAIN')
sasl_username = os.environ.get('KAFKA_SASL_USERNAME', '')
sasl_password = os.environ.get('KAFKA_SASL_PASSWORD', '')

# Configure Kafka producer
kafka_config = {
    'bootstrap_servers': bootstrap_servers,
    'value_serializer': lambda v: json.dumps(v).encode('utf-8'),
    'api_version': (2, 5, 0)  # Add explicit API version to avoid auto-detection
}

# Add security settings if using SASL authentication
if security_protocol.startswith('SASL_'):
    print(f"Configuring SASL authentication with mechanism {sasl_mechanism}")
    kafka_config.update({
        'security_protocol': security_protocol,
        'sasl_mechanism': sasl_mechanism,
        'sasl_plain_username': sasl_username,
        'sasl_plain_password': sasl_password,
    })

print(f"Connecting to Kafka with protocol: {security_protocol}")

# Create a Kafka producer instance
producer = KafkaProducer(**kafka_config)

print(f"Producer started. Sending events to topic '{topic_name}' every {interval_ms}ms")

# Sample data for random selection
tenant_ids = [100, 200, 300]
user_ids = [1001, 1002, 1003, 1004, 1005]
event_types = ["order.created", "order.updated", "order.shipped", "order.canceled"]
payment_methods = ["credit_card", "paypal", "bank_transfer"]

# Generate and send events indefinitely
counter = 0
while True:
  # Create an event with a timestamp and structured data
  counter += 1

  # Generate ISO format datetime
  event_timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%fZ')

  # Generate a unique event ID
  event_id = str(uuid.uuid4())

  # Select random values for the event
  tenant_id = random.choice(tenant_ids)
  user_id = random.choice(user_ids)

  # For demonstration, we'll set event_type to order.created 70% of the time
  # and other types 30% of the time
  event_type = "order.created" if random.random() < 0.7 else random.choice(event_types[1:])

  # Generate order total (a random value between $10 and $200)
  order_total = round(random.uniform(10, 200), 2)

  # Create the domain-driven event structure with tenant_id at the root
  event = {
    "id": event_id,
    "tenant_id": tenant_id,
    "event_type": event_type,
    "created_at": event_timestamp,
    "object": {
      "id": f"ORD-{counter}",
      "total": order_total,
      "payment_method": random.choice(payment_methods),
      "customer": {
        "id": user_id,
        "email": f"user{user_id}@example.com"
      }
    }
  }

  # Send the event to Kafka
  producer.send(topic_name, event)

  # Print confirmation message
  print(f"Sent event: {json.dumps(event, indent=2)}")

  # Wait for the specified interval
  time.sleep(interval_ms / 1000)
