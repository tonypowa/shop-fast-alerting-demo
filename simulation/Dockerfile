FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy simulator script
COPY simulator.py .

# Make script executable
RUN chmod +x simulator.py

# Set the entrypoint to the simulator
ENTRYPOINT ["python", "simulator.py"]

# Default command shows help
CMD ["--help"]

