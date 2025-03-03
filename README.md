# Real-Time Analytics Pipeline with Kafka and Apache Pinot

This project sets up a real-time analytics pipeline using Apache Kafka as the message queue and Apache Pinot as the real-time analytics database. It includes a simple event producer that generates random data events and publishes them to Kafka, which are then consumed by Pinot for real-time analysis.

## Architecture

![Architecture Diagram](images/diagram.png)

The pipeline consists of:

- **Zookeeper**: For coordination between Kafka and Pinot components
- **Kafka**: Message broker for handling event streams
- **Event Producer**: Python application that generates random events
- **Apache Pinot**: Real-time analytics database with components:
  - Controller: Manages the Pinot cluster
  - Broker: Handles queries
  - Server: Stores and processes data

## Getting Started

### 1. Clone the repository

```bash
git clone git@github.com:zacharywelch/pinot-demo.git
cd pinot-demo
```

### 2. Start the services

```bash
# Build and start all services
docker-compose up -d --build

# Wait for services to start
echo "Waiting for services to start..."
sleep 60
```

### 3. Set up Pinot

```bash
# Run the setup script to create schema and table
./setup-pinot.sh
```

### 4. Verify data is being produced
```bash
docker logs -f event-producer
# Press Ctrl+C after a few seconds
```

### 5. Verify the setup

Access the Pinot UI at http://localhost:9000 and navigate to the Query Console to run some queries.

Example query:
```sql
SELECT COUNT(*) FROM events
```

![Data Explorer](images/data-explorer.png)


## Troubleshooting

If you encounter any issues with the pipeline:

### No events in Pinot

Check the producer logs:
```bash
docker logs event-producer
```

Check the Pinot server logs:
```bash
docker logs pinot-server
```

### Rebuilding after code changes

Always rebuild containers after making code changes:
```bash
docker-compose down -v
docker-compose up -d --build
```

## Project Structure

```
├── docker-compose.yml          # Main configuration for services
├── setup-pinot.sh              # Script to set up Pinot schema and table
├── producer/                   # Event producer application
│   ├── Dockerfile              # Container definition for producer
│   ├── requirements.txt        # Python dependencies
│   └── producer.py             # Python event generator code
└── pinot-config/               # Pinot configuration files
    ├── schema.json             # Defines the data structure
    └── table.json              # Defines how data is stored and queried
```

## Schema Definition

The `events` table schema includes:

- `id` (INT): Unique identifier for each event
- `timestamp` (INT): Unix epoch timestamp in seconds
- `value` (INT): Random value between 1-100
- `message` (STRING): Text message for the event

## Customizing

### Changing Event Generation

To modify the event data structure or generation frequency:

1. Edit `producer/producer.py`
2. Update schema in `pinot-config/schema.json`
3. Update table configuration in `pinot-config/table.json`
4. Rebuild and restart:
   ```bash
   docker-compose down -v
   docker-compose up -d --build
   ./setup-pinot.sh
   ```

## Further Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Apache Pinot Documentation](https://docs.pinot.apache.org/)
- [Real-Time Analytics with Pinot](https://docs.pinot.apache.org/basics/components/table#real-time-table)
