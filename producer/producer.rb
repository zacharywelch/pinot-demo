require 'json'
require 'kafka'
require 'securerandom'
require 'time'

# Get configuration from environment variables
bootstrap_servers = ENV.fetch('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
topic_name = ENV.fetch('TOPIC_NAME', 'example-topic')
interval_ms = ENV.fetch('INTERVAL_MS', '1000').to_i

# Create a Kafka producer instance
kafka = Kafka.new(
  seed_brokers: [bootstrap_servers],
  client_id: "event-producer"
)

producer = kafka.producer

puts "Producer started. Sending events to topic '#{topic_name}' every #{interval_ms}ms"

# Sample data for random selection
tenant_ids = [100, 200, 300]
user_ids = [1001, 1002, 1003, 1004, 1005]
event_types = ["order.created", "order.updated", "order.shipped", "order.canceled"]
payment_methods = ["credit_card", "paypal", "bank_transfer"]

# Generate and send events indefinitely
counter = 0
begin
  loop do
    # Create an event with a timestamp and structured data
    counter += 1

    # Generate ISO format datetime
    event_timestamp = Time.now.utc.iso8601(6)

    # Generate a unique event ID
    event_id = SecureRandom.uuid

    # Select random values for the event
    tenant_id = tenant_ids.sample
    user_id = user_ids.sample

    # For demonstration, we'll set event_type to order.created 70% of the time
    # and other types 30% of the time
    event_type = rand < 0.7 ? "order.created" : event_types[1..].sample

    # Generate order total (a random value between $10 and $200)
    order_total = (rand * 190 + 10).round(2)

    # Create the domain-driven event structure with tenant_id at the root
    event = {
      "id" => event_id,
      "tenant_id" => tenant_id,
      "event_type" => event_type,
      "created_at" => event_timestamp,
      "object" => {
        "id" => "ORD-#{counter}",
        "total" => order_total,
        "payment_method" => payment_methods.sample,
        "customer" => {
          "id" => user_id,
          "email" => "user#{user_id}@example.com"
        }
      }
    }

    # Send the event to Kafka
    producer.produce(JSON.generate(event), topic: topic_name)
    producer.deliver_messages

    # Print confirmation message
    puts "Sent event: #{JSON.pretty_generate(event)}"

    # Wait for the specified interval
    sleep(interval_ms / 1000.0)
  end
rescue Interrupt
  puts "Shutting down producer..."
ensure
  # Make sure to properly shut down the producer
  producer.shutdown
end
