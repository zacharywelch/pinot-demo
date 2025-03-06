#!/bin/bash
# Simple Pinot setup script
# This script helps set up Apache Pinot by creating the schema and table

# Stop script if any command fails
set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print a message with color
print_message() {
  # $1 is the color, $2 is the message
  echo -e "${1}${2}${NC}"
}

# Wait for Kafka to be fully ready
print_message "$YELLOW" "Waiting for Kafka to be fully ready..."
sleep 20

# Create Kafka topic first
print_message "$YELLOW" "Creating Kafka topic..."
# For Bitnami Kafka image, the command is in a different location
/opt/bitnami/kafka/bin/kafka-topics.sh --create --if-not-exists \
  --topic example-topic \
  --bootstrap-server kafka:9092 \
  --partitions 1 \
  --replication-factor 1
print_message "$GREEN" "Kafka topic created!"

# Step 1: Wait for Pinot to start
print_message "$YELLOW" "Waiting for Pinot to start..."

# Install curl if not available
if ! command -v curl &> /dev/null; then
  print_message "$YELLOW" "Installing curl..."
  apt-get update && apt-get install -y curl
fi

# Try up to 60 times, waiting 5 seconds between attempts
attempt=1
max_attempts=60

while ! curl -s http://pinot-controller:9000/health > /dev/null; do
  if [ $attempt -ge $max_attempts ]; then
    print_message "$RED" "Pinot failed to start after $max_attempts attempts."
    print_message "$YELLOW" "Check logs with: docker logs pinot-controller"
    exit 1
  fi

  echo "Attempt $attempt/$max_attempts: Still waiting..."
  sleep 5
  ((attempt++))
done

print_message "$GREEN" "Pinot is running!"
# Extra time for Pinot to fully initialize
print_message "$YELLOW" "Giving Pinot a moment to fully initialize..."
sleep 10

# Step 2: Add the schema
print_message "$YELLOW" "Adding the schema..."

# Send schema file to Pinot
schema_response=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d @pinot-config/schema.json \
  http://pinot-controller:9000/schemas)

# Get the response body and status code
schema_body=$(echo "$schema_response" | head -n 1)
schema_status=$(echo "$schema_response" | tail -n 1)

# Check if the request was successful
if [ "$schema_status" -ne 200 ]; then
  print_message "$RED" "Failed to add schema. Status code: $schema_status"
  print_message "$RED" "Response: $schema_body"
  exit 1
fi

print_message "$GREEN" "Schema added successfully!"

# Step 3: Add the table
print_message "$YELLOW" "Adding the table..."

# Check if table already exists and delete it if needed
if curl -s http://pinot-controller:9000/tables/orders | grep -q "orders"; then
  print_message "$YELLOW" "Table 'orders' already exists. Deleting it first..."
  curl -s -X DELETE http://pinot-controller:9000/tables/orders
  sleep 5  # Wait for deletion to complete
fi

# Send table file to Pinot
table_response=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d @pinot-config/table.json \
  http://pinot-controller:9000/tables)

# Get the response body and status code
table_body=$(echo "$table_response" | head -n 1)
table_status=$(echo "$table_response" | tail -n 1)

# Check if the request was successful
if [ "$table_status" -ne 200 ]; then
  print_message "$RED" "Failed to add table. Status code: $table_status"
  print_message "$RED" "Response: $table_body"
  exit 1
fi

print_message "$GREEN" "Table added successfully!"

# Step 4: Make sure the table was actually created
print_message "$YELLOW" "Verifying the table was created..."

# Try 5 times since table creation can take time
for i in {1..5}; do
  if curl -s http://pinot-controller:9000/tables/orders | grep -q "orders"; then
    print_message "$GREEN" "Table 'orders' verified!"
    break
  fi

  if [ $i -eq 5 ]; then
    print_message "$RED" "Could not verify table 'orders' was created."
    exit 1
  fi

  echo "Attempt $i: Table not ready yet, waiting..."
  sleep 5
done

# Step 5: Test producing a proper JSON message to Kafka
print_message "$YELLOW" "Testing Kafka connectivity by sending a message..."
/opt/bitnami/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka:9092 \
  --topic example-topic <<< '{"test":"message","timestamp":"'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"}'
print_message "$GREEN" "Test message sent to Kafka!"

# All done!
print_message "$GREEN" "========================================="
print_message "$GREEN" "Pinot setup completed successfully!"
print_message "$GREEN" "========================================="
echo -e "You can access Pinot at: ${YELLOW}http://localhost:9000${NC}"
echo -e "Run queries at: ${YELLOW}http://localhost:9000/query${NC}"
echo -e "Visualize with Cube at: ${YELLOW}http://localhost:4000${NC}"
