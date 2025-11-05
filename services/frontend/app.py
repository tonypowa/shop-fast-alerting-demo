from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY
import logging
import time
import os
import random

# OpenTelemetry imports
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Initialize Flask app
app = Flask(__name__)

# Configure OpenTelemetry
resource = Resource.create({"service.name": "frontend-service"})
trace.set_tracer_provider(TracerProvider(resource=resource))
tracer = trace.get_tracer(__name__)

# Configure OTLP exporter to send traces to Alloy
otlp_exporter = OTLPSpanExporter(
    endpoint="http://alloy:4317",
    insecure=True
)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

# Auto-instrument Flask
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

# Configure logging
log_file = os.getenv('LOG_FILE', '/app/logs/frontend.log')
os.makedirs(os.path.dirname(log_file), exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s [frontend] %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
PAGE_VIEWS = Counter('page_views_total', 'Total page views', ['page'])

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'frontend'}), 200

@app.route('/metrics', methods=['GET'])
def metrics():
    return generate_latest(REGISTRY)

@app.route('/', methods=['GET'])
def home():
    start_time = time.time()
    # Simulate some processing time
    time.sleep(random.uniform(0.01, 0.05))
    
    duration = time.time() - start_time
    REQUEST_COUNT.labels(method='GET', endpoint='/', status='200').inc()
    REQUEST_DURATION.labels(method='GET', endpoint='/').observe(duration)
    PAGE_VIEWS.labels(page='home').inc()
    logger.info('Home page accessed')
    
    return jsonify({'page': 'home', 'status': 'ok'}), 200

@app.route('/products', methods=['GET'])
def products():
    start_time = time.time()
    # Simulate some processing time
    time.sleep(random.uniform(0.02, 0.1))
    
    duration = time.time() - start_time
    REQUEST_COUNT.labels(method='GET', endpoint='/products', status='200').inc()
    REQUEST_DURATION.labels(method='GET', endpoint='/products').observe(duration)
    PAGE_VIEWS.labels(page='products').inc()
    logger.info('Products page accessed')
    
    return jsonify({'page': 'products', 'status': 'ok'}), 200

@app.route('/checkout', methods=['GET'])
def checkout():
    start_time = time.time()
    # Simulate some processing time
    time.sleep(random.uniform(0.05, 0.15))
    
    # Occasionally simulate errors
    if random.random() < 0.05:  # 5% error rate
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/checkout', status='500').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/checkout').observe(duration)
        logger.error('Checkout page error: Session timeout')
        return jsonify({'error': 'Session timeout'}), 500
    
    duration = time.time() - start_time
    REQUEST_COUNT.labels(method='GET', endpoint='/checkout', status='200').inc()
    REQUEST_DURATION.labels(method='GET', endpoint='/checkout').observe(duration)
    PAGE_VIEWS.labels(page='checkout').inc()
    logger.info('Checkout page accessed')
    
    return jsonify({'page': 'checkout', 'status': 'ok'}), 200

@app.route('/simulate/high-cpu', methods=['POST'])
def simulate_high_cpu():
    """Endpoint to simulate high CPU usage for demo purposes"""
    logger.warning('Starting CPU intensive operation for demo')
    start = time.time()
    # CPU intensive operation
    result = sum([i**2 for i in range(1000000)])
    duration = time.time() - start
    logger.info(f'CPU intensive operation completed in {duration:.2f}s')
    return jsonify({'status': 'completed', 'duration': duration}), 200

if __name__ == '__main__':
    logger.info('Starting Frontend service on port 8081')
    app.run(host='0.0.0.0', port=8081)

