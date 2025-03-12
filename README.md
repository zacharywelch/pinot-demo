# Real-Time Analytics Pipeline with Kafka, Apache Pinot and Cube

This project sets up a real-time analytics pipeline using Apache Kafka as the message queue, Apache Pinot as the real-time analytics database, and Cube as the analytics API platform. It includes a simple order producer that generates order events with nested JSON structure and publishes them to Kafka, which are then consumed by Pinot for real-time analysis and made available through Cube for visualization and exploration.

## Architecture

![Architecture Diagram](images/diagram.png)

The pipeline consists of:

- **Zookeeper**: For coordination between Kafka and Pinot components
- **Kafka**: Message broker for handling event streams
- **Event Producer**: Ruby application that generates random events with ISO timestamps
- **Apache Pinot**: Real-time analytics database with components:
  - Controller: Manages the Pinot cluster
  - Broker: Handles queries
  - Server: Stores and processes data
- **Cube**: Semantic layer platform that provides:
  - Data modeling layer
  - Analytics API
  - Playground for exploring and visualizing data

## Getting Started

### 1. Clone the repository

```bash
git clone git@github.com:zacharywelch/pinot-demo.git
cd pinot-demo
```

### 2. Make sure scripts are executable

```bash
chmod +x bin/*
```

### 3. Start the services

You can use Rake tasks or directly use the bin scripts:

```bash
# Using Rake
rake start  # Start the services
rake setup  # Set up Pinot schema and table

# Or directly use the bin scripts
./bin/start
./bin/setup
```

### 4. Verify data is being produced

```bash
# View the logs of the event producer
docker logs -f event-producer
# Press Ctrl+C after a few seconds
```

### 5. Verify the setup

Access the Pinot UI at http://localhost:9000 and navigate to the Query Console to run some queries.

Example query:
```sql
SELECT COUNT(*) FROM orders
```
![Data Explorer](images/data-explorer.png)

### 6. Explore with Cube

Access the Cube Playground at http://localhost:4000 to build and visualize queries.
In the Cube Playground, you can build queries using the visual query builder:

1. Select the `Orders` cube
2. Add measures like `Orders.count` or `Orders.totalRevenue`
3. Add dimensions like `Orders.paymentMethod`
4. Run the query and visualize the results

![Cube](images/cube.png)

## Commands Reference

This project includes several rake tasks to simplify management:

```bash
# Show all available commands
rake

# Start the entire analytics stack
rake start

# Stop the analytics stack and remove volumes
rake stop

# Setup Pinot schema and table
rake setup

# Restart the entire stack (combines stop, start, and setup)
rake restart
```

You can also use the bin scripts directly:

```bash
./bin/start    # Start the analytics stack
./bin/stop     # Stop the analytics stack
./bin/setup    # Setup Pinot schema and table
./bin/restart  # Restart the entire stack
```

For checking logs and service status, use the Docker commands:

```bash
# View logs for a service
docker logs -f service_name
Examples: docker logs -f pinot-controller, docker logs -f kafka

# Check status of all services
docker compose ps
```

## Timestamp Handling

The `orders` table uses Pinot's native TIMESTAMP datatype to handle ISO-format timestamps. This allows for powerful time-series analysis using Pinot's time functions:

```sql
-- Count orders by day
SELECT
  DATETRUNC('day', event_at) AS day,
  COUNT(*) AS order_count
FROM orders
GROUP BY day
ORDER BY day DESC
```

## Troubleshooting

If you encounter any issues with the pipeline:

### No events in Pinot or Cube

Check the logs:
```bash
docker logs -f event-producer
docker logs -f pinot-server
docker logs -f cube
```

### Rebuilding after code changes

Always rebuild containers after making code changes:
```bash
rake restart
```

## Project Structure

```
├── bin/                       # Command scripts for operations
│   ├── start                  # Script to start services
│   ├── stop                   # Script to stop services
│   ├── setup                  # Script to set up Pinot
│   └── restart                # Script to restart everything
├── docker-compose.yml         # Main configuration for services
├── Rakefile                   # Task definitions for common operations

├── producer/                  # Event producer application
│   ├── Dockerfile             # Container definition for producer
│   ├── Gemfile                # Ruby dependencies
│   ├── Gemfile.lock           # Locked Ruby dependencies
│   └── producer.rb            # Ruby event generator code
├── pinot-config/              # Pinot configuration files
│   ├── schema.json            # Defines the data structure
│   └── table.json             # Defines how data is stored and queried
└── cube/                      # Cube configuration files
    ├── cube.js                # Main Cube configuration
    └── model/                 # Data models directory
        └── cubes/             # Cube definitions
            └── Orders.js      # Orders cube definition
```

## Schema Definition

The `orders` table schema includes:

### Dimension Fields
- `team_id` (INT): Identifier for the tenant/team
- `order_id` (STRING): Unique identifier for each order
- `payment_method` (STRING): Method of payment used
- `customer_id` (LONG): Unique identifier for the customer
- `customer_email` (STRING): Email address of the customer
- `event_id` (STRING): Unique identifier for the event

### Metric Fields
- `order_total` (DOUBLE): Total monetary value of the order

### DateTime Fields
- `event_at` (TIMESTAMP): Timestamp when the event occurred, stored in ISO format (e.g., "2023-03-15T14:30:45.123Z")

## Customizing

### Changing Event Generation

To modify the event data structure or generation frequency:

1. Edit `producer/producer.rb`
2. Update schema in `pinot-config/schema.json`
3. Update table configuration in `pinot-config/table.json`
4. Update Cube model in `cube/model/cubes/Orders.js`
5. Rebuild and restart:
   ```bash
   rake restart
   ```

## Further Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Apache Pinot Documentation](https://docs.pinot.apache.org/)
- [Apache Pinot Recipes](https://dev.startree.ai/docs/pinot/recipes)
- [Cube Documentation](https://cube.dev/docs)
- [Pinot Connector for Cube](https://cube.dev/docs/product/configuration/data-sources/pinot)
- [Real-Time Analytics with Pinot](https://docs.pinot.apache.org/basics/components/table#real-time-table)
- [Ruby Kafka Documentation](https://github.com/zendesk/ruby-kafka)
