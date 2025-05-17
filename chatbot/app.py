"""
Analytics Chatbot powered by Cube and LangChain.
This app provides a natural language interface for analytics data.
"""
import os
import json
import random
from pathlib import Path

import streamlit as st
import pandas as pd
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_openai.embeddings import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS

from utils import (
    load_cube_meta,
    format_column_context,
    query_cube,
    CUBE_PROMPT
)

# Load environment variables
load_dotenv()

# App configuration
st.set_page_config(
    page_title="Analytics Chatbot",
    page_icon="🤖",
    layout="wide"
)

st.title("Analytics Chatbot 🤖")

# Sample questions to help users get started
SAMPLE_QUESTIONS = [
    "How many orders do we have?",
    "What's my total revenue?",
    "Show me orders by payment method",
    "How many new customers were there this month?",
    "What's the trend of orders over time?"
]

# Fun messages to make the bot feel more playful
ROBOT_MESSAGES = [
    "Umm... Found Stuff?",
    "Whoa, Did I Do That?",
    "Huh? Numbers Appeared!",
    "Oops, Data Happened!"
]

# Sidebar for configuration and sample questions
with st.sidebar:
    st.header("Sample Questions")
    selected_question = st.selectbox(
        "Try a sample question:",
        options=[""] + SAMPLE_QUESTIONS,
        index=0,
        key="sample_selector"
    )

    st.header("Configuration")

    # Model selection
    model_name = st.selectbox(
        "Select model:",
        ["gpt-4", "gpt-3.5-turbo"],
        index=1
    )

    temperature = st.slider(
        "Temperature:",
        min_value=0.0,
        max_value=1.0,
        value=0.1,
        step=0.1,
        help="Higher values make output more random, lower more deterministic"
    )

    max_results = st.number_input(
        "Max results to return:",
        min_value=10,
        max_value=1000,
        value=100,
        step=10
    )

    # Get API credentials from environment
    cube_api_url = os.environ.get("CUBE_API_URL", "http://localhost:4000/cubejs-api/v1")
    cube_api_secret = os.environ.get("CUBE_API_SECRET", "simple-secret")

    # Button to reload metadata
    if st.button("Reload Metadata"):
        with st.spinner("Loading context from Cube API..."):
            load_cube_meta(cube_api_url, cube_api_secret)
            st.success("Metadata reloaded successfully!")

# Initialize vectorstore if needed
vectorstore_path = Path("vectorstore.pkl")
if not vectorstore_path.exists():
    with st.spinner('Loading context from Cube API...'):
        load_cube_meta(cube_api_url, cube_api_secret)
        st.success("Metadata loaded successfully!")

# Initialize language model
@st.cache_resource
def get_llm(model_name, temperature):
    return ChatOpenAI(
        temperature=temperature,
        model_name=model_name,
        verbose=True
    )

llm = get_llm(model_name, temperature)

# Handle question input - use selected sample question if available
if selected_question and not st.session_state.get("user_modified"):
    question = st.text_input(
        "Your question:",
        value=selected_question,
        key="question_input"
    )
else:
    question = st.text_input(
        "Your question:",
        key="question_input",
        on_change=lambda: st.session_state.update({"user_modified": True})
    )

# Process the question when submit button is clicked
if st.button("Submit", type="primary", use_container_width=True):
    if not question:
        st.warning("Please enter a question")
    else:
        # Show thinking process
        with st.status("Processing your question...", expanded=True) as status:
            try:
                # Validate input
                if not question:
                  raise ValueError("Please enter a question.")

                st.write("✅ Valid question format")

                # Load vectorstore for semantic search
                st.write("🔍 Finding relevant data...")
                vectorstore = FAISS.load_local(
                    "vectorstore.pkl",
                    OpenAIEmbeddings(),
                    allow_dangerous_deserialization=True
                )

                # Find most relevant data model
                docs = vectorstore.similarity_search(question, k=5)
                table_name = docs[0].metadata["table_name"]
                st.write(f"📊 Selected data model: {table_name}")

                # Get relevant columns for this table
                column_docs = vectorstore.similarity_search(
                    f"All columns in {table_name}",
                    filter={"table_name": table_name},
                    k=15
                )

                # Format column information for the prompt
                columns_formatted = format_column_context(column_docs)

                # Generate the Cube query
                st.write("🧠 Generating analytics query...")
                prompt = CUBE_PROMPT.format(
                    question=question,
                    table_name=table_name,
                    columns=columns_formatted
                )

                # Generate query with LLM
                llm_answer = llm.predict(prompt)
                cube_query = json.loads(llm_answer)

                # Add result limit if not present
                if "limit" not in cube_query and not any(k.startswith("limit") for k in cube_query):
                    cube_query["limit"] = max_results

                st.write("✅ Query generated successfully")
                st.json(cube_query)

                # Execute the query against Cube
                st.write("🔄 Executing query against Cube...")
                result = query_cube(cube_query, cube_api_url, cube_api_secret)
                status.update(label="✅ Analysis complete!", state="complete", expanded=False)

            except Exception as e:
                status.update(label=f"❌ Error: {str(e)}", state="error")
                st.error(f"Error processing query: {str(e)}")
                st.stop()

        # Display results
        if "data" in result and result["data"]:
            st.info(f"🤖 {random.choice(ROBOT_MESSAGES)}")
            df = pd.DataFrame(result["data"])
            st.dataframe(
                df,
                use_container_width=True,
                height=min(35 * len(df) + 38, 500)
            )
        else:
            st.warning("🤖 No data returned from the query.")

# Footer
st.markdown("---")
st.markdown("Analytics Chatbot powered by Cube and LangChain")