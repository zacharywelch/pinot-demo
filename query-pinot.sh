#!/bin/bash
# Pinot query script
# Runs sample queries to demonstrate Pinot's capabilities

# Immediately exit if any command fails
set -e

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}jq is not installed. Results will be shown in raw JSON format.${NC}"
  JQ_AVAILABLE=false
else
  JQ_AVAILABLE=true
fi

# Function to run a query and display results
run_query() {
  local name="$1"
  local sql="$2"

  echo -e "\n${BLUE}Query: ${name}${NC}"
  echo -e "${YELLOW}SQL: ${sql}${NC}"

  response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"sql\":\"${sql}\"}" \
    http://localhost:9000/query/sql)

  if $JQ_AVAILABLE; then
    echo -e "${GREEN}Results:${NC}"
    echo "$response" | jq '.resultTable'
  else
    echo -e "${GREEN}Results (raw):${NC}"
    echo "$response"
  fi
}

echo -e "${YELLOW}Checking if Pinot is ready...${NC}"
if ! curl -s http://localhost:9000/health > /dev/null; then
  echo -e "${RED}Pinot is not available. Make sure the services are running.${NC}"
  exit 1
fi

echo -e "${GREEN}Pinot is ready! Running sample queries...${NC}"

# Run a count query to make sure data is being ingested
count_response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"sql":"SELECT COUNT(*) FROM events"}' \
  http://localhost:9000/query/sql)

if [[ "$count_response" == *"numDocsScanned\":0"* ]]; then
  echo -e "${YELLOW}Warning: No data found in the table yet. Make sure your producer is running.${NC}"
  echo -e "${YELLOW}Continuing with queries, but they may not return meaningful results.${NC}"
fi

# Run sample queries
run_query "Count all events" "SELECT COUNT(*) FROM events"
run_query "Get average value" "SELECT AVG(value) FROM events"
run_query "Get latest 10 events" "SELECT * FROM events ORDER BY timestamp DESC LIMIT 10"
run_query "Get value distribution" "SELECT MIN(value) AS min_value, MAX(value) AS max_value, AVG(value) AS avg_value FROM events"
run_query "Group by value ranges" "SELECT CASE WHEN value <= 25 THEN '0-25' WHEN value <= 50 THEN '26-50' WHEN value <= 75 THEN '51-75' ELSE '76-100' END AS range, COUNT(*) AS count FROM events GROUP BY range ORDER BY range"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}All queries completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "You can run more queries using the Pinot Query Console at: ${YELLOW}http://localhost:9000/query${NC}"
