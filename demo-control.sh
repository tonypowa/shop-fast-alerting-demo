#!/bin/bash
# Demo Control Script - Easy inventory management during presentation

# Check for Docker permissions
if ! docker ps &>/dev/null; then
    echo "❌ Docker permission denied!"
    echo ""
    echo "Options:"
    echo "  1. Run with sudo: sudo ./demo-control.sh"
    echo "  2. Add your user to docker group:"
    echo "     sudo usermod -aG docker $USER"
    echo "     newgrp docker  # or logout/login"
    echo ""
    exit 1
fi

DB_EXEC="docker exec shopfast-postgres psql -U shopfast -d shopfast -c"

clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         📊 ShopFast Database Control Panel 📊            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Current Stock Levels (Sorted by Stock):"
$DB_EXEC "
    SELECT 
        id,
        CASE 
            WHEN LENGTH(name) > 28 THEN SUBSTRING(name, 1, 25) || '...'
            ELSE name
        END as name,
        stock_level,
        low_stock_threshold,
        CASE 
            WHEN stock_level <= 5 THEN '🔴 CRITICAL'
            WHEN stock_level <= low_stock_threshold THEN '🟡 LOW'
            ELSE '🟢 OK'
        END as status
    FROM products 
    ORDER BY stock_level ASC;
" 2>/dev/null
echo ""
echo "💡 TIP: Press 'q' or '8' to exit at any time"
echo ""

PS3="Choose action (1-8, or 'q' to quit): "
options=(
    "Reset Product to Default Stock"
    "Set Product to High Stock"
    "Set Product Near Threshold"
    "Trigger Alert on Product"
    "View All Products"
    "Reset All Products to Defaults"
    "Clear All Orders"
    "Exit"
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
                echo "Available Products:"
                echo "  1. Gaming Laptop       6. Webcam 4K"
                echo "  2. Wireless Mouse      7. Headphones"
                echo "  3. Keyboard            8. Monitor 27\""
                echo "  4. USB-C Hub           9. Laptop Stand"
                echo "  5. External SSD       10. Phone Charger"
                echo ""
                read -p "Select Product ID(s) [e.g., 1 or 1,3,5 or 1-4]: " product_input
                
                # Parse input (supports: "1", "1,3,5", "1-4")
                IFS=',' read -ra PRODUCTS <<< "$product_input"
                for prod in "${PRODUCTS[@]}"; do
                    if [[ $prod =~ ^([0-9]+)-([0-9]+)$ ]]; then
                        # Range format: 1-4
                        start=${BASH_REMATCH[1]}
                        end=${BASH_REMATCH[2]}
                        for ((i=start; i<=end; i++)); do
                            if [[ $i -ge 1 && $i -le 10 ]]; then
                                case $i in
                                    1) default=50 ;;
                                    2) default=150 ;;
                                    3) default=75 ;;
                                    4) default=200 ;;
                                    5) default=30 ;;
                                    6) default=25 ;;
                                    7) default=40 ;;
                                    8) default=20 ;;
                                    9) default=100 ;;
                                    10) default=300 ;;
                                esac
                                $DB_EXEC "UPDATE products SET stock_level = $default WHERE id = $i;" 2>/dev/null
                                product_name=$($DB_EXEC "SELECT name FROM products WHERE id = $i;" 2>/dev/null | sed -n 3p | xargs)
                                echo "✓ $product_name reset to $default units"
                            fi
                        done
                    elif [[ $prod =~ ^[0-9]+$ ]]; then
                        # Single number
                        product_id=$prod
                        if [[ $product_id -ge 1 && $product_id -le 10 ]]; then
                            case $product_id in
                                1) default=50 ;;
                                2) default=150 ;;
                                3) default=75 ;;
                                4) default=200 ;;
                                5) default=30 ;;
                                6) default=25 ;;
                                7) default=40 ;;
                                8) default=20 ;;
                                9) default=100 ;;
                                10) default=300 ;;
                            esac
                            $DB_EXEC "UPDATE products SET stock_level = $default WHERE id = $product_id;" 2>/dev/null
                            product_name=$($DB_EXEC "SELECT name FROM products WHERE id = $product_id;" 2>/dev/null | sed -n 3p | xargs)
                            echo "✓ $product_name reset to $default units"
                        fi
                    fi
                done
                break
                ;;
            2)
                echo ""
                echo "Available Products:"
                echo "  1. Gaming Laptop       6. Webcam 4K"
                echo "  2. Wireless Mouse      7. Headphones"
                echo "  3. Keyboard            8. Monitor 27\""
                echo "  4. USB-C Hub           9. Laptop Stand"
                echo "  5. External SSD       10. Phone Charger"
                echo ""
                read -p "Select Product ID(s) [e.g., 1 or 1,3,5 or 1-4]: " product_input
                
                IFS=',' read -ra PRODUCTS <<< "$product_input"
                for prod in "${PRODUCTS[@]}"; do
                    if [[ $prod =~ ^([0-9]+)-([0-9]+)$ ]]; then
                        start=${BASH_REMATCH[1]}
                        end=${BASH_REMATCH[2]}
                        for ((i=start; i<=end; i++)); do
                            if [[ $i -ge 1 && $i -le 10 ]]; then
                                case $i in
                                    1) high=100 ;;
                                    2) high=300 ;;
                                    3) high=150 ;;
                                    4) high=400 ;;
                                    5) high=60 ;;
                                    6) high=50 ;;
                                    7) high=80 ;;
                                    8) high=40 ;;
                                    9) high=200 ;;
                                    10) high=600 ;;
                                esac
                                $DB_EXEC "UPDATE products SET stock_level = $high WHERE id = $i;" 2>/dev/null
                                product_name=$($DB_EXEC "SELECT name FROM products WHERE id = $i;" 2>/dev/null | sed -n 3p | xargs)
                                echo "✓ $product_name set to $high units (high stock)"
                            fi
                        done
                    elif [[ $prod =~ ^[0-9]+$ ]]; then
                        product_id=$prod
                        if [[ $product_id -ge 1 && $product_id -le 10 ]]; then
                            case $product_id in
                                1) high=100 ;;
                                2) high=300 ;;
                                3) high=150 ;;
                                4) high=400 ;;
                                5) high=60 ;;
                                6) high=50 ;;
                                7) high=80 ;;
                                8) high=40 ;;
                                9) high=200 ;;
                                10) high=600 ;;
                            esac
                            $DB_EXEC "UPDATE products SET stock_level = $high WHERE id = $product_id;" 2>/dev/null
                            product_name=$($DB_EXEC "SELECT name FROM products WHERE id = $product_id;" 2>/dev/null | sed -n 3p | xargs)
                            echo "✓ $product_name set to $high units (high stock)"
                        fi
                    fi
                done
                break
                ;;
            3)
                echo ""
                echo "Available Products:"
                echo "  1. Gaming Laptop       6. Webcam 4K"
                echo "  2. Wireless Mouse      7. Headphones"
                echo "  3. Keyboard            8. Monitor 27\""
                echo "  4. USB-C Hub           9. Laptop Stand"
                echo "  5. External SSD       10. Phone Charger"
                echo ""
                read -p "Select Product ID(s) [e.g., 1 or 1,3,5 or 1-4]: " product_input
                
                IFS=',' read -ra PRODUCTS <<< "$product_input"
                for prod in "${PRODUCTS[@]}"; do
                    if [[ $prod =~ ^([0-9]+)-([0-9]+)$ ]]; then
                        start=${BASH_REMATCH[1]}
                        end=${BASH_REMATCH[2]}
                        for ((i=start; i<=end; i++)); do
                            if [[ $i -ge 1 && $i -le 10 ]]; then
                                threshold=$($DB_EXEC "SELECT low_stock_threshold FROM products WHERE id = $i;" 2>/dev/null | sed -n 3p | xargs)
                                near_threshold=$((threshold + 5))
                                $DB_EXEC "UPDATE products SET stock_level = $near_threshold WHERE id = $i;" 2>/dev/null
                                product_name=$($DB_EXEC "SELECT name FROM products WHERE id = $i;" 2>/dev/null | sed -n 3p | xargs)
                                echo "✓ $product_name set to $near_threshold units (near threshold of $threshold)"
                            fi
                        done
                    elif [[ $prod =~ ^[0-9]+$ ]]; then
                        product_id=$prod
                        if [[ $product_id -ge 1 && $product_id -le 10 ]]; then
                            threshold=$($DB_EXEC "SELECT low_stock_threshold FROM products WHERE id = $product_id;" 2>/dev/null | sed -n 3p | xargs)
                            near_threshold=$((threshold + 5))
                            $DB_EXEC "UPDATE products SET stock_level = $near_threshold WHERE id = $product_id;" 2>/dev/null
                            product_name=$($DB_EXEC "SELECT name FROM products WHERE id = $product_id;" 2>/dev/null | sed -n 3p | xargs)
                            echo "✓ $product_name set to $near_threshold units (near threshold of $threshold)"
                        fi
                    fi
                done
                break
                ;;
            4)
                echo ""
                echo "Available Products:"
                echo "  1. Gaming Laptop       6. Webcam 4K"
                echo "  2. Wireless Mouse      7. Headphones"
                echo "  3. Keyboard            8. Monitor 27\""
                echo "  4. USB-C Hub           9. Laptop Stand"
                echo "  5. External SSD       10. Phone Charger"
                echo ""
                read -p "Select Product ID(s) [e.g., 1 or 1,3,5 or 1-4]: " product_input
                
                IFS=',' read -ra PRODUCTS <<< "$product_input"
                for prod in "${PRODUCTS[@]}"; do
                    if [[ $prod =~ ^([0-9]+)-([0-9]+)$ ]]; then
                        start=${BASH_REMATCH[1]}
                        end=${BASH_REMATCH[2]}
                        for ((i=start; i<=end; i++)); do
                            if [[ $i -ge 1 && $i -le 10 ]]; then
                                threshold=$($DB_EXEC "SELECT low_stock_threshold FROM products WHERE id = $i;" 2>/dev/null | sed -n 3p | xargs)
                                alert_level=$((threshold - 2))
                                if [[ $alert_level -lt 3 ]]; then
                                    alert_level=3
                                fi
                                $DB_EXEC "UPDATE products SET stock_level = $alert_level WHERE id = $i;" 2>/dev/null
                                product_name=$($DB_EXEC "SELECT name FROM products WHERE id = $i;" 2>/dev/null | sed -n 3p | xargs)
                                echo "✓ $product_name set to $alert_level units (ALERT FIRING! Threshold: $threshold)"
                            fi
                        done
                    elif [[ $prod =~ ^[0-9]+$ ]]; then
                        product_id=$prod
                        if [[ $product_id -ge 1 && $product_id -le 10 ]]; then
                            threshold=$($DB_EXEC "SELECT low_stock_threshold FROM products WHERE id = $product_id;" 2>/dev/null | sed -n 3p | xargs)
                            alert_level=$((threshold - 2))
                            if [[ $alert_level -lt 3 ]]; then
                                alert_level=3
                            fi
                            $DB_EXEC "UPDATE products SET stock_level = $alert_level WHERE id = $product_id;" 2>/dev/null
                            product_name=$($DB_EXEC "SELECT name FROM products WHERE id = $product_id;" 2>/dev/null | sed -n 3p | xargs)
                            echo "✓ $product_name set to $alert_level units (ALERT FIRING! Threshold: $threshold)"
                        fi
                    fi
                done
                break
                ;;
            5)
                echo ""
                $DB_EXEC "SELECT id, name, stock_level, low_stock_threshold FROM products ORDER BY id;" 2>/dev/null
                break
                ;;
            6)
                $DB_EXEC "UPDATE products SET stock_level = CASE id WHEN 1 THEN 50 WHEN 2 THEN 150 WHEN 3 THEN 75 WHEN 4 THEN 200 WHEN 5 THEN 30 WHEN 6 THEN 25 WHEN 7 THEN 40 WHEN 8 THEN 20 WHEN 9 THEN 100 WHEN 10 THEN 300 END;" 2>/dev/null
                echo "✓ All products reset to defaults"
                break
                ;;
            7)
                $DB_EXEC "DELETE FROM orders;" 2>/dev/null
                echo "✓ All orders cleared"
                break
                ;;
            8)
                echo ""
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo "❌ Invalid option. Please select 1-8 or 'q'."
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
    echo "║         📊 ShopFast Database Control Panel 📊            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Current Stock Levels (Sorted by Stock):"
    $DB_EXEC "
        SELECT 
            id,
            CASE 
                WHEN LENGTH(name) > 28 THEN SUBSTRING(name, 1, 25) || '...'
                ELSE name
            END as name,
            stock_level,
            low_stock_threshold,
            CASE 
                WHEN stock_level <= 5 THEN '🔴 CRITICAL'
                WHEN stock_level <= low_stock_threshold THEN '🟡 LOW'
                ELSE '🟢 OK'
            END as status
        FROM products 
        ORDER BY stock_level ASC;
    " 2>/dev/null
    echo ""
    echo "💡 TIP: Press 'q' or '8' to exit at any time"
    echo ""
done

