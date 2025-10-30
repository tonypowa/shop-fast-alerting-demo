from flask import Flask, request, jsonify
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY
import logging
import time
import os
import random

app = Flask(__name__)

# Configure logging
log_file = os.getenv('LOG_FILE', '/app/logs/payment.log')
os.makedirs(os.path.dirname(log_file), exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s [payment] %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
PAYMENT_COUNT = Counter('payments_total', 'Total payments', ['status', 'method'])
PAYMENT_AMOUNT = Counter('payment_amount_total', 'Total payment amount processed')

# Simulate payment failure rate (can be modified for demo)
FAILURE_RATE = 0.02  # 2% failure rate by default

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'payment'}), 200

@app.route('/metrics', methods=['GET'])
def metrics():
    return generate_latest(REGISTRY)

@app.route('/api/payment/process', methods=['POST'])
def process_payment():
    start_time = time.time()
    try:
        data = request.get_json()
        amount = data.get('amount', 0)
        payment_method = data.get('method', 'credit_card')
        order_id = data.get('order_id')
        
        # Simulate payment processing time
        time.sleep(random.uniform(0.1, 0.5))
        
        # Simulate payment failures
        if random.random() < FAILURE_RATE:
            duration = time.time() - start_time
            REQUEST_COUNT.labels(method='POST', endpoint='/api/payment/process', status='400').inc()
            REQUEST_DURATION.labels(method='POST', endpoint='/api/payment/process').observe(duration)
            PAYMENT_COUNT.labels(status='failed', method=payment_method).inc()
            
            error_reasons = [
                'Insufficient funds',
                'Card declined',
                'Payment gateway timeout',
                'Invalid card details'
            ]
            reason = random.choice(error_reasons)
            
            logger.error(f'Payment failed for order {order_id}: {reason} - amount: ${amount}')
            return jsonify({
                'status': 'failed',
                'reason': reason,
                'order_id': order_id
            }), 400
        
        # Successful payment
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='POST', endpoint='/api/payment/process', status='200').inc()
        REQUEST_DURATION.labels(method='POST', endpoint='/api/payment/process').observe(duration)
        PAYMENT_COUNT.labels(status='success', method=payment_method).inc()
        PAYMENT_AMOUNT.inc(amount)
        
        transaction_id = f'TXN-{int(time.time())}-{random.randint(1000, 9999)}'
        logger.info(f'Payment successful: {transaction_id} - order: {order_id}, amount: ${amount}, method: {payment_method}')
        
        return jsonify({
            'status': 'success',
            'transaction_id': transaction_id,
            'amount': amount,
            'order_id': order_id
        }), 200
        
    except Exception as e:
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='POST', endpoint='/api/payment/process', status='500').inc()
        REQUEST_DURATION.labels(method='POST', endpoint='/api/payment/process').observe(duration)
        PAYMENT_COUNT.labels(status='error', method='unknown').inc()
        logger.error(f'Payment processing error: {str(e)}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/payment/refund', methods=['POST'])
def refund_payment():
    start_time = time.time()
    try:
        data = request.get_json()
        transaction_id = data.get('transaction_id')
        amount = data.get('amount', 0)
        
        # Simulate refund processing time
        time.sleep(random.uniform(0.2, 0.6))
        
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='POST', endpoint='/api/payment/refund', status='200').inc()
        REQUEST_DURATION.labels(method='POST', endpoint='/api/payment/refund').observe(duration)
        
        logger.info(f'Refund processed: {transaction_id} - amount: ${amount}')
        
        return jsonify({
            'status': 'refunded',
            'transaction_id': transaction_id,
            'amount': amount
        }), 200
        
    except Exception as e:
        duration = time.time() - start_time
        REQUEST_COUNT.labels(method='POST', endpoint='/api/payment/refund', status='500').inc()
        REQUEST_DURATION.labels(method='POST', endpoint='/api/payment/refund').observe(duration)
        logger.error(f'Refund error: {str(e)}')
        return jsonify({'error': str(e)}), 500

@app.route('/simulate/payment-failures', methods=['POST'])
def simulate_failures():
    """Endpoint to simulate high payment failure rate for demo"""
    global FAILURE_RATE
    data = request.get_json()
    new_rate = data.get('failure_rate', 0.5)
    FAILURE_RATE = new_rate
    logger.warning(f'Payment failure rate changed to {FAILURE_RATE * 100}% for demo purposes')
    return jsonify({'status': 'updated', 'failure_rate': FAILURE_RATE}), 200

if __name__ == '__main__':
    logger.info('Starting Payment service on port 8082')
    app.run(host='0.0.0.0', port=8082)

