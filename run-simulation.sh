#!/bin/bash
# Interactive Simulation Control for ShopFast Demo
# No Python installation required - runs in Docker!

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="shopfast-simulator"

# Check for Docker permissions
check_docker_permissions() {
    if ! docker ps &>/dev/null; then
        echo "❌ Docker permission denied!"
        echo ""
        echo "Options:"
        echo "  1. Run with sudo: sudo ./run-simulation.sh"
        echo "  2. Add your user to docker group:"
        echo "     sudo usermod -aG docker $USER"
        echo "     newgrp docker  # or logout/login"
        echo ""
        exit 1
    fi
}

# Build the image if it doesn't exist
build_image_if_needed() {
    if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
        echo "🔨 Building simulator Docker image (first time only)..."
        docker build -t $IMAGE_NAME "$SCRIPT_DIR/simulation"
        echo "✅ Image built successfully!"
        echo ""
    fi
}

# Run a simulation scenario
run_simulation() {
    local scenario=$1
    shift
    
    echo ""
    echo "🚀 Running simulation: $scenario"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    docker run --rm \
        --network demo-alerting-stack_monitoring \
        -e API_URL="http://shopfast-api:8080" \
        -e FRONTEND_URL="http://shopfast-frontend:8081" \
        -e PAYMENT_URL="http://shopfast-payment:8082" \
        -e INVENTORY_URL="http://shopfast-inventory:8083" \
        -e DB_HOST="shopfast-postgres" \
        $IMAGE_NAME "$scenario" "$@"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Simulation completed!"
    echo ""
}

# Check if running in non-interactive mode (with arguments)
if [ $# -gt 0 ]; then
    check_docker_permissions
    build_image_if_needed
    run_simulation "$@"
    exit 0
fi

# Interactive mode
clear
check_docker_permissions
build_image_if_needed

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        🚀 ShopFast Simulation Control Center 🚀           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Choose a simulation scenario to trigger Grafana alerts:"
echo ""
echo "💡 TIP: Press 'q' or '10' to exit | Option '1' to view stock levels"
echo ""

PS3="Select scenario (1-10, or 'q' to quit): "
options=(
    "📊 View Current Stock Levels"
    "🟢 Normal Traffic (baseline - no alerts)"
    "⚡ Flash Sale (triggers LOW INVENTORY alert)"
    "💳 Payment Failures (triggers LOG-BASED alert)"
    "🔒 Security Breach (triggers DATABASE alert)"
    "🔥 High CPU Usage (triggers METRICS alert)"
    "📦 Low Inventory (gradual depletion)"
    "🎯 Run ALL Scenarios (complete demo)"
    "🔧 Rebuild Docker Image"
    "❌ Exit"
)

while true; do
    select opt in "${options[@]}"
    do
        case $REPLY in
            q|Q)
                echo ""
                echo "👋 Goodbye!"
                exit 0
                ;;
            1)
                echo ""
                echo "📊 Current Stock Levels"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                docker exec shopfast-postgres psql -U shopfast -d shopfast -c "
                    SELECT 
                        id,
                        name,
                        stock_level,
                        low_stock_threshold,
                        CASE 
                            WHEN stock_level <= 5 THEN '🔴 CRITICAL'
                            WHEN stock_level <= low_stock_threshold THEN '🟡 LOW'
                            ELSE '🟢 OK'
                        END as status
                    FROM products 
                    ORDER BY id;
                " 2>/dev/null || echo "❌ Could not connect to database. Is Docker running?"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                break
                ;;
            2)
                echo ""
                read -p "Duration in seconds [60]: " duration
                duration=${duration:-60}
                run_simulation "normal" --duration "$duration"
                break
                ;;
            3)
                echo ""
                echo "Available Products:"
                echo "  1. Gaming Laptop (Stock: 50)"
                echo "  2. Wireless Mouse (Stock: 150)"
                echo "  3. Mechanical Keyboard (Stock: 75)"
                echo "  4. USB-C Hub (Stock: 200)"
                echo "  5. External SSD 1TB (Stock: 30)"
                echo "  6. Webcam 4K (Stock: 25)"
                echo "  7. Noise-Canceling Headphones (Stock: 40)"
                echo "  8. Monitor 27\" (Stock: 20)"
                echo "  9. Laptop Stand (Stock: 100)"
                echo " 10. Phone Charger (Stock: 300)"
                echo ""
                read -p "Select Product ID [1-10, default: 1]: " product_id
                product_id=${product_id:-1}
                read -p "Duration in seconds [30]: " duration
                duration=${duration:-30}
                run_simulation "flash-sale" --product-id "$product_id" --duration "$duration"
                echo ""
                echo "💡 TIP: Check Grafana → Alerting → Alert rules"
                echo "   Look for 'Low Inventory Warning' alert"
                break
                ;;
            4)
                echo ""
                read -p "Duration in seconds [60]: " duration
                duration=${duration:-60}
                run_simulation "payment-failures" --duration "$duration"
                echo ""
                echo "💡 TIP: Check Grafana → Explore → Loki"
                echo "   Query: {service=\"payment\"} |= \"ERROR\""
                break
                ;;
            5)
                echo ""
                read -p "Number of failed login attempts [10]: " attempts
                attempts=${attempts:-10}
                run_simulation "security"
                echo ""
                echo "💡 TIP: Check Grafana → Alerting → Alert rules"
                echo "   Look for 'Multiple Failed Login Attempts' alert"
                break
                ;;
            6)
                echo ""
                read -p "Duration in seconds [30]: " duration
                duration=${duration:-30}
                run_simulation "high-cpu" --duration "$duration"
                echo ""
                echo "💡 TIP: Check Grafana → Alerting → Alert rules"
                echo "   Look for 'High CPU Usage' alert"
                break
                ;;
            7)
                echo ""
                echo "Available Products:"
                echo "  1. Gaming Laptop (Stock: 50)"
                echo "  2. Wireless Mouse (Stock: 150)"
                echo "  3. Mechanical Keyboard (Stock: 75)"
                echo "  4. USB-C Hub (Stock: 200)"
                echo "  5. External SSD 1TB (Stock: 30)"
                echo "  6. Webcam 4K (Stock: 25)"
                echo "  7. Noise-Canceling Headphones (Stock: 40)"
                echo "  8. Monitor 27\" (Stock: 20)"
                echo "  9. Laptop Stand (Stock: 100)"
                echo " 10. Phone Charger (Stock: 300)"
                echo ""
                read -p "Select Product ID [1-10, default: 6]: " product_id
                product_id=${product_id:-6}
                run_simulation "low-inventory" --product-id "$product_id"
                break
                ;;
            8)
                echo ""
                echo "⏱️  This will run all scenarios in sequence (~5 minutes)"
                read -p "Continue? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    run_simulation "all"
                    echo ""
                    echo "🎉 All scenarios completed! Check Grafana for fired alerts."
                else
                    echo "Cancelled."
                fi
                break
                ;;
            9)
                echo ""
                echo "🔨 Rebuilding Docker image..."
                docker rmi $IMAGE_NAME 2>/dev/null || true
                docker build -t $IMAGE_NAME "$SCRIPT_DIR/simulation"
                echo "✅ Image rebuilt successfully!"
                echo ""
                break
                ;;
            10)
                echo ""
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo "❌ Invalid option. Please select 1-10 or 'q'."
                break
                ;;
        esac
    done
    
    echo ""
    read -p "Press Enter to continue (or 'q' to quit)... " continue_choice
    if [[ $continue_choice =~ ^[Qq]$ ]]; then
        echo ""
        echo "👋 Goodbye!"
        exit 0
    fi
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        🚀 ShopFast Simulation Control Center 🚀           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Choose a simulation scenario to trigger Grafana alerts:"
    echo ""
    echo "💡 TIP: Press 'q' or '10' to exit | Option '1' to view stock levels"
    echo ""
done

