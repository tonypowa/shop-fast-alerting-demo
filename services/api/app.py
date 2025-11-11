from flask import Flask, request, jsonify
from flask_cors import CORS
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY
import psycopg2
import logging
import time
import os
from datetime import datetime

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

# Enable CORS for frontend access
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Configure OpenTelemetry
resource = Resource.create({"service.name": "api-service"})
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
log_file = os.getenv('LOG_FILE', '/app/logs/api.log')
os.makedirs(os.path.dirname(log_file), exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s [api] %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
ORDER_COUNT = Counter('orders_total', 'Total orders created', ['status'])

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'postgres'),
        port=os.getenv('DB_PORT', '5432'),
        user=os.getenv('DB_USER', 'shopfast'),
        password=os.getenv('DB_PASSWORD', 'shopfast123'),
        database=os.getenv('DB_NAME', 'shopfast')
    )

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'api'}), 200

@app.route('/metrics', methods=['GET'])
def metrics():
    return generate_latest(REGISTRY), 200, {'Content-Type': 'text/plain; charset=utf-8'}

@app.route('/api/products', methods=['GET'])
def get_products():
    start_time = time.time()
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, name, description, price, stock_level, low_stock_threshold FROM products')
        products = cur.fetchall()
        cur.close()
        conn.close()
        
        result = [
            {
                'id': p[0],
                'name': p[1],
                'description': p[2],
                'price': float(p[3]),
                'stock_level': p[4],
                'low_stock_threshold': p[5]
            }
            for p in products
        ]
        
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/products', status='200').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/products').observe(duration)
        logger.info(f'Retrieved {len(result)} products')
        
        return jsonify(result), 200
    except Exception as e:
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/products', status='500').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/products').observe(duration)
        logger.error(f'Error retrieving products: {str(e)}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    start_time = time.time()
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, name, description, price, stock_level FROM products WHERE id = %s', (product_id,))
        product = cur.fetchone()
        cur.close()
        conn.close()
        
        if not product:
            REQUEST_COUNT.labels(method='GET', endpoint='/api/products/:id', status='404').inc()
            logger.warning(f'Product {product_id} not found')
            return jsonify({'error': 'Product not found'}), 404
        
        result = {
            'id': product[0],
            'name': product[1],
            'description': product[2],
            'price': float(product[3]),
            'stock_level': product[4]
        }
        
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/products/:id', status='200').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/products/:id').observe(duration)
        logger.info(f'Retrieved product {product_id}')
        
        return jsonify(result), 200
    except Exception as e:
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/products/:id', status='500').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/products/:id').observe(duration)
        logger.error(f'Error retrieving product {product_id}: {str(e)}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/orders', methods=['POST'])
def create_order():
    start_time = time.time()
    try:
        data = request.get_json()
        product_id = data.get('product_id')
        quantity = data.get('quantity', 1)
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Check stock
        cur.execute('SELECT price, stock_level FROM products WHERE id = %s', (product_id,))
        product = cur.fetchone()
        
        if not product:
            REQUEST_COUNT.labels(method='POST', endpoint='/api/orders', status='404').inc()
            logger.warning(f'Order failed: Product {product_id} not found')
            return jsonify({'error': 'Product not found'}), 404
        
        price, stock_level = product
        
        if stock_level < quantity:
            REQUEST_COUNT.labels(method='POST', endpoint='/api/orders', status='400').inc()
            ORDER_COUNT.labels(status='failed_insufficient_stock').inc()
            logger.warning(f'Order failed: Insufficient stock for product {product_id}')
            return jsonify({'error': 'Insufficient stock'}), 400
        
        # Create order
        total_amount = float(price) * quantity
        cur.execute(
            'INSERT INTO orders (product_id, quantity, total_amount, order_status) VALUES (%s, %s, %s, %s) RETURNING id',
            (product_id, quantity, total_amount, 'completed')
        )
        order_id = cur.fetchone()[0]
        
        # Update stock
        cur.execute('UPDATE products SET stock_level = stock_level - %s, last_updated = CURRENT_TIMESTAMP WHERE id = %s',
                   (quantity, product_id))
        
        conn.commit()
        cur.close()
        conn.close()
        
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='POST', endpoint='/api/orders', status='201').inc()
        REQUEST_DURATION.labels(method='POST', endpoint='/api/orders').observe(duration)
        ORDER_COUNT.labels(status='success').inc()
        logger.info(f'Order {order_id} created successfully for product {product_id}, quantity {quantity}')
        
        return jsonify({
            'order_id': order_id,
            'product_id': product_id,
            'quantity': quantity,
            'total_amount': total_amount,
            'status': 'completed'
        }), 201
        
    except Exception as e:
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='POST', endpoint='/api/orders', status='500').inc()
        REQUEST_DURATION.labels(method='POST', endpoint='/api/orders').observe(duration)
        ORDER_COUNT.labels(status='failed_error').inc()
        logger.error(f'Error creating order: {str(e)}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/inventory/low', methods=['GET'])
def get_low_inventory():
    start_time = time.time()
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT * FROM low_stock_products')
        products = cur.fetchall()
        cur.close()
        conn.close()
        
        result = [
            {
                'id': p[0],
                'name': p[1],
                'stock_level': p[2],
                'threshold': p[3],
                'units_below': p[4]
            }
            for p in products
        ]
        
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/inventory/low', status='200').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/inventory/low').observe(duration)
        logger.info(f'Retrieved {len(result)} low stock products')
        
        return jsonify(result), 200
    except Exception as e:
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='GET', endpoint='/api/inventory/low', status='500').inc()
        REQUEST_DURATION.labels(method='GET', endpoint='/api/inventory/low').observe(duration)
        logger.error(f'Error retrieving low inventory: {str(e)}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/simulate-cpu', methods=['POST'])
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
    logger.info('Starting API service on port 8080')
    app.run(host='0.0.0.0', port=8080)

