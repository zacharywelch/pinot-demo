# 📊 Real-Time Analytics

Learn real-time analytics with Kafka, Pinot, and Cube.

## 📂 Directory Structure

```
pinot-demo/
├── bin/                 # Command scripts for operations
├── docker-compose.yml   # Docker configuration for services
├── Rakefile             # Task definitions for common operations
├── producer/            # Event producer application
├── pinot/               # Pinot configuration files
│   ├── schemas/         # Schema definition files
│   └── tables/          # Table configuration files
├── cube/                # Cube.js configuration
│   ├── cube.js          # Main Cube configuration
│   └── model/           # Data models directory
└── chatbot/             # AI Chatbot application
```

## 🚀 Getting Started

### 📋 Prerequisites

- Docker and Docker Compose
- Ruby and Bundler (for running Rake tasks)

### 🔧 Installation

1. Clone the repository:

```bash
git clone git@github.com:zacharywelch/pinot-demo.git
cd pinot-demo
```

2. Start the services:

```bash
rake start  # Start the services
rake setup  # Set up Pinot schema and table
```

3. Check that the producer is generating events:

```bash
docker logs -f event-producer
```

4. Access the services:
- Pinot UI: http://localhost:9000
- Cube Playground: http://localhost:4000
- Analytics Chatbot: http://localhost:8501

## 🛠️ Available Commands

You can run all commands through Rake, which provides a simple interface to the underlying scripts:

```bash
# List all available commands
rake

# Start all services
rake start

# Stop all services
rake stop

# Restart all services
rake restart

# Set up Pinot schemas and tables
rake setup
```

## 🔌 Components

### 📊 Apache Pinot

Real-time OLAP database that powers the analytics backend:

- **Controller**: Manages the Pinot cluster (http://localhost:9000)
- **Broker**: Handles queries
- **Server**: Stores and processes data
- **Tables**:
  - Append-only tables (orders)
  - Upsert tables (customers)

Try a query in the Pinot UI:
```sql
SELECT COUNT(*) FROM orders
```

### 🚀 Event Producer

Ruby application that generates random event data:
- Generates order and customer events with nested JSON
- Publishes events to Kafka topics
- Simulates real-time event streams

### 📈 Cube

Semantic layer that provides a data modeling API:
- Defines cubes, measures, and dimensions
- Provides a query API for analytics
- Includes a playground for building queries (http://localhost:4000)

### 🤖 AI Chatbot

Streamlit application that provides natural language analytics:
- Ask questions in plain English
- Automatically translates to Cube queries
- Visualizes query results
- Uses OpenAI and LangChain for NLP

https://github.com/user-attachments/assets/4311bb10-4487-4ba7-9db3-44998ef851be

To use the chatbot with advanced language capabilities:
1. Set up an OpenAI API key:
   ```bash
   echo "OPENAI_API_KEY=your-api-key-here" > .env
   ```
2. Restart the chatbot service:
   ```bash
   docker compose restart chatbot
   ```

Sample questions to try:
- How many orders do we have?
- What's my total revenue?
- Show me orders by payment method
- What's the trend of orders over time?

## 🧩 Schema Design

The project includes two main tables:

### Orders Table (Append-Only)
Captures each order event with:
- Dimensions: team_id, order_id, payment_method, customer_id, etc.
- Metrics: order_total
- DateTime: event_at (ISO format timestamp)

### Customers Table (Upsert-Enabled)
Maintains current customer state with:
- Dimensions: team_id, customer_id, email, etc.
- DateTime: event_at
- Uses Pinot's upsert feature to update records based on primary key

## 📚 Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Apache Pinot Documentation](https://docs.pinot.apache.org/)
- [Apache Pinot Recipes](https://dev.startree.ai/docs/pinot/recipes)
- [Cube Documentation](https://cube.dev/docs)
- [Pinot Connector for Cube](https://cube.dev/docs/product/configuration/data-sources/pinot)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [LangChain Documentation](https://python.langchain.com/)
