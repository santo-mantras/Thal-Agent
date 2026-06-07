import os
from google_adk.agent import Agent
from google_adk.workflow import Workflow, Graph

# Make sure Gemini API Key is available in the environment
os.environ.setdefault("GEMINI_API_KEY", os.getenv("GEMINI_API_KEY", ""))

# ---------------------------------------------------------
# 1. Intake & OCR Agent
# ---------------------------------------------------------
intake_agent = Agent(
    name="IntakeAgent",
    instructions=(
        "You are a medical data extraction expert. You receive unstructured text "
        "or OCR data from a patient's CBC or Ferritin report. Your job is to extract "
        "the Hemoglobin (Hb), Serum Ferritin, Age, and Weight into structured JSON format. "
        "If data is missing, mark it as null."
    ),
    model="gemini-1.5-pro",
)

# ---------------------------------------------------------
# 2. Medical Logic Agent (The Brain)
# ---------------------------------------------------------
medical_logic_agent = Agent(
    name="MedicalLogicAgent",
    instructions=(
        "You are a Clinical Decision Support System specializing in Thalassemia. "
        "You receive structured patient data. You must analyze the Hemoglobin and "
        "Ferritin levels against Thalassemia International Federation (TIF) guidelines. "
        "If Ferritin is > 2500, calculate appropriate iron chelation therapy doses based on weight. "
        "CRITICAL: Always append a disclaimer that this is a suggestion and requires a doctor's final approval."
    ),
    model="gemini-1.5-pro",
)

# ---------------------------------------------------------
# 3. Communication Agent (Persona Router)
# ---------------------------------------------------------
communication_agent = Agent(
    name="CommunicationAgent",
    instructions=(
        "You translate the output of the MedicalLogicAgent based on the target Persona. "
        "If Persona is 'Doctor', use clinical terms and cite guidelines. "
        "If Persona is 'Patient', use extremely empathetic, simple language, avoiding heavy jargon, "
        "and explain what the numbers mean for their body."
    ),
    model="gemini-1.5-flash",
)

# ---------------------------------------------------------
# 4. RAG Agent (Medical Literature Q&A)
# ---------------------------------------------------------
rag_agent = Agent(
    name="RAGAgent",
    instructions=(
        "You are an expert Thalassemia Medical AI. You will be provided with a user's question "
        "and a set of trusted medical literature excerpts retrieved from a vector database. "
        "You MUST answer the question using ONLY the provided excerpts. "
        "If the answer cannot be found in the excerpts, say 'I cannot answer this based on the available medical literature.' "
        "Always cite the source of your information if possible."
    ),
    model="gemini-1.5-pro",
)

# ---------------------------------------------------------
# Workflow Graph
# ---------------------------------------------------------
thalassemia_workflow = Workflow(name="Thalassemia_Analysis_Flow")

# A basic sequential routing graph for demonstration
graph = Graph()
graph.add_node("intake", intake_agent)
graph.add_node("logic", medical_logic_agent)
graph.add_node("communication", communication_agent)

graph.add_edge("intake", "logic")
graph.add_edge("logic", "communication")

thalassemia_workflow.set_graph(graph)

def run_thalassemia_analysis(raw_report_text: str, persona: str):
    """
    Entry point for the FastAPI backend to trigger the ADK workflow.
    """
    print(f"Starting workflow for persona: {persona}")
    # In a real implementation, you pass the initial context to the workflow engine
    # result = thalassemia_workflow.run(input_data={"report": raw_report_text, "persona": persona})
    # return result
    
    return {"status": "success", "message": "Workflow created successfully."}
