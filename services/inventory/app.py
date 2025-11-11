from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, Gauge, generate_latest, REGISTRY
import psycopg2
import logging
import time
import os

# OpenTelemetry imports
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.psycopg2 import Psycopg2Instrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Initialize Flask app
app = Flask(__name__)

# Configure OpenTelemetry
resource = Resource.create({"service.name": "inventory-service"})
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

# Auto-instrument Flask and database
FlaskInstrumentor().instrument_app(app)
Psycopg2Instrumentor().instrument()
RequestsInstrumentor().instrument()

# Configure logging
log_file = os.getenv('LOG_FILE', '/app/logs/inventory.log')
os.makedirs(os.path.dirname(log_file), exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s [inventory] %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
INVENTORY_LEVEL = Gauge('inventory_stock_level', 'Current stock level', ['product_id', 'product_name'])
LOW_STOCK_COUNT = Gauge('inventory_low_stock_products', 'Number of products with low stock')

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'postgres'),
        port=os.getenv('DB_PORT', '5432'),
        user=os.getenv('DB_USER', 'shopfast'),
        password=os.getenv('DB_PASSWORD', 'shopfast123'),
        database=os.getenv('DB_NAME', 'shopfast')
    )

def update_inventory_metrics():
    """Update Prometheus metrics with current inventory levels"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Get all products and their stock levels
        cur.execute('SELECT id, name, stock_level FROM products')
        products = cur.fetchall()
        
        for product_id, name, stock_level in products:
            INVENTORY_LEVEL.labels(product_id=str(product_id), product_name=name).set(stock_level)
        
        # Count low stock products
        cur.execute('SELECT COUNT(*) FROM products WHERE stock_level <= low_stock_threshold')
        low_stock_count = cur.fetchone()[0]
        LOW_STOCK_COUNT.set(low_stock_count)
        
        cur.close()
        conn.close()
    except Exception as e:
        logger.error(f'Error updating inventory metrics: {str(e)}')

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'inventory'}), 200

@app.route('/metrics', methods=['GET'])
def metrics():
    # Update metrics before serving them
    update_inventory_metrics()
    return generate_latest(REGISTRY), 200, {'Content-Type': 'text/plain; charset=utf-8'}

@app.route('/api/inventory/status', methods=['GET'])
def inventory_status():
    start_time = time.time()
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Get inventory summary
        cur.execute('''
            SELECT 
                COUNT(*) as total_products,
                SUM(stock_level) as total_units,
                COUNT(*) FILTER (WHERE stock_level <= low_stock_threshold) as low_stock_count,
                COUNT(*) FILTER (WHERE stock_level = 0) as out_of_stock_count
            FROM products
        ''')
        stats = cur.fetchone()
        
        cur.close()
        conn.close()
        
        result = {
            'total_products': stats[0],
            'total_units': stats[1],
            'low_stock_count': stats[2],
            'out_of_stock_count': stats[3]
        }
        
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/inventory/status', status='200').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/inventory/status').observe(duration)
        logger.info(f'Inventory status: {result}')
        
        return jsonify(result), 200
    except Exception as e:
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/inventory/status', status='500').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/inventory/status').observe(duration)
        logger.error(f'Error getting inventory status: {str(e)}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/inventory/alerts', methods=['GET'])
def inventory_alerts():
    start_time = time.time()
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Get products that need attention
        cur.execute('''
            SELECT id, name, stock_level, low_stock_threshold,
                   CASE 
                       WHEN stock_level = 0 THEN 'OUT_OF_STOCK'
                       WHEN stock_level <= 5 THEN 'CRITICAL'
                       WHEN stock_level <= low_stock_threshold THEN 'LOW'
                   END as alert_level
            FROM products
            WHERE stock_level <= low_stock_threshold
            ORDER BY stock_level ASC
        ''')
        alerts = cur.fetchall()
        
        cur.close()
        conn.close()
        
        result = [
            {
                'product_id': a[0],
                'product_name': a[1],
                'stock_level': a[2],
                'threshold': a[3],
                'alert_level': a[4]
            }
            for a in alerts
        ]
        
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/inventory/alerts', status='200').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/inventory/alerts').observe(duration)
        
        if result:
            logger.warning(f'Inventory alerts: {len(result)} products need attention')
        else:
            logger.info('No inventory alerts')
        
        return jsonify(result), 200
    except Exception as e:
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/inventory/alerts', status='500').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/inventory/alerts').observe(duration)
        logger.error(f'Error getting inventory alerts: {str(e)}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/inventory/simulate-cpu', methods=['POST'])
def simulate_high_cpu():
    """Endpoint to simulate high CPU usage for demo purposes"""
    logger.warning('Starting CPU intensive operation for demo')
    start = time.time()
    # Very CPU intensive operation - multiple operations to max out CPU
    result = 0
    for _ in range(5):
        result += sum([i**2 * i**0.5 for i in range(5000000)])
        result += sum([i**3 for i in range(3000000)])
    duration = time.time() - start
    logger.info(f'CPU intensive operation completed in {duration:.2f}s, result={result}')
    return jsonify({'status': 'completed', 'duration': duration}), 200

if __name__ == '__main__':
    logger.info('Starting Inventory service on port 8083')
    # Update metrics on startup
    update_inventory_metrics()
    app.run(host='0.0.0.0', port=8083)

