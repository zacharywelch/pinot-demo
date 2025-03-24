require 'json'
require 'kafka'
require 'securerandom'
require 'time'

# Get configuration from environment variables
bootstrap_servers = ENV.fetch('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
orders_topic = ENV.fetch('ORDERS_TOPIC', 'orders-topic')
customers_topic = ENV.fetch('CUSTOMERS_TOPIC', 'customers-topic')
interval_ms = ENV.fetch('INTERVAL_MS', '1000').to_i

# Create a Kafka producer instance
kafka = Kafka.new(
  seed_brokers: [bootstrap_servers],
  client_id: "event-producer"
)

producer = kafka.producer

puts "Producer started. Sending events to orders topic '#{orders_topic}' and customers topic '#{customers_topic}' every #{interval_ms}ms"

# Sample data for random selection
tenant_ids = [100, 200, 300]
customer_ids = [1001, 1002, 1003, 1004, 1005]
payment_methods = ["credit_card", "paypal", "bank_transfer"]

# Store generated customer IDs and emails
customers = {
  1001 => "customer1001@example.com",
  1002 => "customer1002@example.com",
  1003 => "customer1003@example.com",
  1004 => "customer1004@example.com",
  1005 => "customer1005@example.com"
}

# Generate and send events indefinitely
counter = 0
begin
  loop do
    counter += 1
    event_timestamp = Time.now.utc.iso8601(6)
    event_id = SecureRandom.uuid
    tenant_id = tenant_ids.sample

    # Determine what kind of event to generate
    event_type = rand < 0.7 ? "order" : "customer"

    if event_type == "order"
      # Create an order event
      customer_id = customer_ids.sample
      order_id = "ORD-#{counter}"
      order_total = (rand * 190 + 10).round(2)

      event = {
        "id" => event_id,
        "tenant_id" => tenant_id,
        "event_type" => "order.created",
        "created_at" => event_timestamp,
        "object" => {
          "id" => order_id,
          "total" => order_total,
          "payment_method" => payment_methods.sample,
          "customer" => {
            "id" => customer_id,
            "email" => customers[customer_id]
          }
        }
      }

      # Send the order event to Kafka
      producer.produce(JSON.generate(event), topic: orders_topic)
      puts "Sent ORDER event: #{JSON.pretty_generate(event)}"
    else
      # Create a customer event - occasionally update an email
      customer_id = customer_ids.sample

      # 30% chance to update an existing customer's email
      if rand < 0.3
        new_email = "updated#{customer_id}@example.com"
        customers[customer_id] = new_email
        puts "Updating email for customer #{customer_id} to #{new_email}"
      end

      # Create the customer event
      event = {
        "id" => event_id,
        "tenant_id" => tenant_id,
        "event_type" => "customer.updated",
        "created_at" => event_timestamp,
        "object" => {
          "id" => customer_id,
          "email" => customers[customer_id]
        }
      }

      # Send the customer event to Kafka
      producer.produce(JSON.generate(event), topic: customers_topic)
      puts "Sent CUSTOMER event: #{JSON.pretty_generate(event)}"
    end

    producer.deliver_messages

    # Wait for the specified interval
    sleep(interval_ms / 1000.0)
  end
rescue Interrupt
  puts "Shutting down producer..."
ensure
  # Make sure to properly shut down the producer
  producer.shutdown
end
