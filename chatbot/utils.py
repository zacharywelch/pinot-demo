"""Utility functions for the analytics chatbot."""
import datetime
import jwt
import requests
import streamlit as st
from langchain_openai.embeddings import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_community.document_loaders import CubeSemanticLoader
from langchain_core.prompts import PromptTemplate

def log(message):
    current_time = datetime.datetime.now()
    milliseconds = current_time.microsecond // 1000
    timestamp = current_time.strftime(
        f"[%Y-%m-%d %H:%M:%S.{milliseconds:03d}] "
    )
    st.text(timestamp + message)

def load_cube_meta(api_url, api_secret):
    token = jwt.encode({}, api_secret, algorithm="HS256")

    loader = CubeSemanticLoader(
        api_url,
        token,
        load_dimension_values=False
    )

    documents = loader.load()
    embeddings = OpenAIEmbeddings()
    vectorstore = FAISS.from_documents(documents, embeddings)
    vectorstore.save_local("vectorstore.pkl")

    return vectorstore

def format_column_context(column_docs):
    lines = []
    for doc in column_docs:
        meta = doc.metadata
        column_type = meta.get("column_member_type", "unknown")
        data_type = meta.get("column_data_type", "unknown")

        lines.append(f"Field: {meta['column_name']}")
        lines.append(f"  Title: {meta['column_title']}")
        lines.append(f"  Description: {meta.get('column_description', 'No description')}")
        lines.append(f"  Type: {column_type} ({data_type})")
        lines.append(f"  Table: {meta['table_name']}")
        lines.append("")

    return "\n".join(lines)

def query_cube(query, api_url, api_secret):
    token = jwt.encode({}, api_secret, algorithm="HS256")

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    response = requests.post(
        f"{api_url.rstrip('/')}/load",
        headers=headers,
        json={"query": query}
    )

    response.raise_for_status()
    return response.json()

# Enhanced prompt template for better query generation
CUBE_PROMPT = PromptTemplate(
    input_variables=["question", "table_name", "columns"],
    template="""You are a Cube.js query expert helping to answer business questions about {table_name}.

Available Columns:
{columns}

Question: {question}

Generate a precise Cube.js query in this JSON format:
{{
    "measures": ["CubeName.measureName"],
    "dimensions": ["CubeName.dimensionName"],
    "segments": ["CubeName.segmentName"],
    "filters": [{{
        "member": "CubeName.fieldName",
        "operator": "equals",
        "values": ["value"]
    }}],
    "timeDimensions": [{{
        "dimension": "CubeName.timeField",
        "dateRange": ["2023-01-01", "2023-12-31"],
        "granularity": "month"
    }}],
    "order": {{
        "CubeName.fieldName": "desc"
    }},
    "limit": 100
}}

IMPORTANT:
- Only use columns from the available list
- Your response must ONLY contain a valid JSON object with NO text before or after
- Measures, dimensions, and segments must be strings in the format "CubeName.fieldName"
- Choose appropriate measures and dimensions based on the question
- Include filters if relevant to the question
- Use meaningful aggregations
- Limit to 100 results by default
- DO NOT wrap your response in a code block or markdown syntax"""
)