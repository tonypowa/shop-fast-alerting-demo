#!/usr/bin/env python3
"""
ShopFast Demo Traffic Simulator

This script simulates realistic e-commerce traffic and various scenarios
to trigger Grafana alerts for demonstration purposes.
"""

import requests
import random
import time
import argparse
import logging
import os
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
import psycopg2

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

# Service URLs - support both Docker and localhost
API_URL = os.environ.get("API_URL", "http://localhost:8080")
FRONTEND_URL = os.environ.get("FRONTEND_URL", "http://localhost:8081")
PAYMENT_URL = os.environ.get("PAYMENT_URL", "http://localhost:8082")
INVENTORY_URL = os.environ.get("INVENTORY_URL", "http://localhost:8083")

# Database connection - support both Docker and localhost
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'port': int(os.environ.get('DB_PORT', '5432')),
    'user': os.environ.get('DB_USER', 'shopfast'),
    'password': os.environ.get('DB_PASSWORD', 'shopfast123'),
    'database': os.environ.get('DB_NAME', 'shopfast')
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

def get_products():
    """Get list of products from API"""
    try:
        response = requests.get(f"{API_URL}/api/products", timeout=5)
        if response.status_code == 200:
            return response.json()
        return []
    except Exception as e:
        logger.error(f"Error fetching products: {e}")
        return []

def simulate_normal_browsing():
    """Simulate normal user browsing behavior"""
    try:
        # Visit home page
        requests.get(f"{FRONTEND_URL}/", timeout=5)
        time.sleep(random.uniform(0.5, 2))
        
        # Browse products
        requests.get(f"{FRONTEND_URL}/products", timeout=5)
        time.sleep(random.uniform(1, 3))
        
        # Maybe go to checkout
        if random.random() < 0.3:  # 30% conversion rate
            requests.get(f"{FRONTEND_URL}/checkout", timeout=5)
    except Exception as e:
        logger.debug(f"Browsing error: {e}")

def simulate_purchase(product_id, quantity=1):
    """Simulate a product purchase"""
    try:
        # Create order
        response = requests.post(
            f"{API_URL}/api/orders",
            json={'product_id': product_id, 'quantity': quantity},
            timeout=5
        )
        
        if response.status_code == 201:
            order = response.json()
            logger.info(f"Order created: {order['order_id']} - Product {product_id}, Quantity {quantity}")
            
            # Process payment
            payment_response = requests.post(
                f"{PAYMENT_URL}/api/payment/process",
                json={
                    'order_id': order['order_id'],
                    'amount': order['total_amount'],
                    'method': random.choice(['credit_card', 'debit_card', 'paypal'])
                },
                timeout=5
            )
            
            if payment_response.status_code == 200:
                logger.info(f"Payment successful for order {order['order_id']}")
            else:
                logger.warning(f"Payment failed for order {order['order_id']}")
                
            return True
        else:
            logger.warning(f"Order failed: {response.json().get('error', 'Unknown error')}")
            return False
    except Exception as e:
        logger.error(f"Purchase error: {e}")
        return False

def simulate_failed_logins(email, attempts=5):
    """Simulate failed login attempts (for security alerts)"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        for i in range(attempts):
            cur.execute(
                "INSERT INTO login_attempts (email, ip_address, success) VALUES (%s, %s, %s)",
                (email, f"192.168.1.{random.randint(1, 255)}", False)
            )
            time.sleep(random.uniform(0.5, 2))
        
        conn.commit()
        cur.close()
        conn.close()
        logger.info(f"Simulated {attempts} failed login attempts for {email}")
    except Exception as e:
        logger.error(f"Failed login simulation error: {e}")

def scenario_normal_traffic(duration_seconds=60, requests_per_second=2):
    """Scenario 1: Normal e-commerce traffic"""
    logger.info(f"Starting NORMAL TRAFFIC scenario for {duration_seconds} seconds")
    
    products = get_products()
    if not products:
        logger.error("No products available")
        return
    
    start_time = time.time()
    request_count = 0
    
    while time.time() - start_time < duration_seconds:
        # Simulate browsing
        simulate_normal_browsing()
        
        # Occasionally make purchases
        if random.random() < 0.2:  # 20% purchase rate
            product = random.choice(products)
            simulate_purchase(product['id'], quantity=random.randint(1, 3))
        
        request_count += 1
        time.sleep(1.0 / requests_per_second)
    
    logger.info(f"Normal traffic scenario completed: {request_count} iterations")

def scenario_flash_sale(product_id=1, duration_seconds=30, requests_per_second=10):
    """Scenario 2: Flash sale - High traffic, rapid inventory depletion"""
    logger.info(f"Starting FLASH SALE scenario for product {product_id}")
    
    start_time = time.time()
    purchase_count = 0
    
    def make_purchase():
        nonlocal purchase_count
        if simulate_purchase(product_id, quantity=random.randint(1, 2)):
            purchase_count += 1
    
    with ThreadPoolExecutor(max_workers=5) as executor:
        while time.time() - start_time < duration_seconds:
            executor.submit(make_purchase)
            time.sleep(1.0 / requests_per_second)
    
    logger.info(f"Flash sale scenario completed: {purchase_count} purchases")

def scenario_payment_failures(duration_seconds=60):
    """Scenario 3: Payment service failures"""
    logger.info("Starting PAYMENT FAILURES scenario")
    
    # Increase failure rate
    try:
        requests.post(
            f"{PAYMENT_URL}/simulate/payment-failures",
            json={'failure_rate': 0.8},  # 80% failure rate
            timeout=5
        )
    except:
        pass
    
    products = get_products()
    if not products:
        return
    
    start_time = time.time()
    while time.time() - start_time < duration_seconds:
        product = random.choice(products)
        simulate_purchase(product['id'])
        time.sleep(random.uniform(1, 3))
    
    # Reset failure rate
    try:
        requests.post(
            f"{PAYMENT_URL}/simulate/payment-failures",
            json={'failure_rate': 0.02},
            timeout=5
        )
    except:
        pass
    
    logger.info("Payment failures scenario completed")

def scenario_high_cpu(duration_seconds=30):
    """Scenario 4: High CPU usage"""
    logger.info("Starting HIGH CPU scenario")
    
    start_time = time.time()
    while time.time() - start_time < duration_seconds:
        try:
            requests.post(f"{FRONTEND_URL}/simulate/high-cpu", timeout=10)
        except Exception as e:
            logger.debug(f"CPU simulation error: {e}")
        time.sleep(2)
    
    logger.info("High CPU scenario completed")

def scenario_security_breach(email="admin@shopfast.com", attempts=10):
    """Scenario 5: Security - Multiple failed login attempts"""
    logger.info("Starting SECURITY BREACH scenario")
    simulate_failed_logins(email, attempts)
    logger.info("Security breach scenario completed")

def scenario_gradual_depletion(product_id=6, target_stock=3, rate=2):
    """Scenario 6: Gradual inventory depletion to trigger low stock alerts"""
    logger.info(f"Starting GRADUAL DEPLETION scenario for product {product_id}")
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Get current stock
        cur.execute("SELECT stock_level FROM products WHERE id = %s", (product_id,))
        current_stock = cur.fetchone()[0]
        
        logger.info(f"Current stock: {current_stock}, target: {target_stock}")
        
        while current_stock > target_stock:
            quantity = min(rate, current_stock - target_stock)
            simulate_purchase(product_id, quantity)
            time.sleep(5)
            
            cur.execute("SELECT stock_level FROM products WHERE id = %s", (product_id,))
            current_stock = cur.fetchone()[0]
            logger.info(f"Stock level now: {current_stock}")
        
        cur.close()
        conn.close()
        logger.info("Gradual depletion scenario completed")
    except Exception as e:
        logger.error(f"Gradual depletion error: {e}")

def main():
    parser = argparse.ArgumentParser(description="ShopFast Traffic Simulator")
    parser.add_argument(
        'scenario',
        choices=['normal', 'flash-sale', 'payment-failures', 'high-cpu', 'security', 'low-inventory', 'all'],
        help='Scenario to simulate'
    )
    parser.add_argument('--duration', type=int, default=60, help='Duration in seconds')
    parser.add_argument('--product-id', type=int, default=1, help='Product ID for targeted scenarios')
    
    args = parser.parse_args()
    
    logger.info(f"Starting simulation: {args.scenario}")
    
    try:
        if args.scenario == 'normal':
            scenario_normal_traffic(duration_seconds=args.duration)
        elif args.scenario == 'flash-sale':
            scenario_flash_sale(product_id=args.product_id, duration_seconds=args.duration)
        elif args.scenario == 'payment-failures':
            scenario_payment_failures(duration_seconds=args.duration)
        elif args.scenario == 'high-cpu':
            scenario_high_cpu(duration_seconds=args.duration)
        elif args.scenario == 'security':
            scenario_security_breach()
        elif args.scenario == 'low-inventory':
            scenario_gradual_depletion(product_id=args.product_id)
        elif args.scenario == 'all':
            logger.info("Running all scenarios in sequence")
            scenario_normal_traffic(duration_seconds=30)
            time.sleep(10)
            scenario_gradual_depletion(product_id=6, target_stock=2)
            time.sleep(10)
            scenario_flash_sale(product_id=1, duration_seconds=30)
            time.sleep(10)
            scenario_payment_failures(duration_seconds=30)
            time.sleep(10)
            scenario_security_breach()
            time.sleep(10)
            scenario_high_cpu(duration_seconds=20)
    except KeyboardInterrupt:
        logger.info("Simulation interrupted by user")
    except Exception as e:
        logger.error(f"Simulation error: {e}")
    
    logger.info("Simulation completed")

if __name__ == '__main__':
    main()

