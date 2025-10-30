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
echo "Current Gaming Laptop Stock:"
$DB_EXEC "SELECT id, name, stock_level, low_stock_threshold FROM products WHERE id = 1;" 2>/dev/null
echo ""
echo "💡 TIP: Press 'q' or '8' to exit at any time"
echo ""

PS3="Choose action (1-8, or 'q' to quit): "
options=(
    "Reset to Default (50 units)"
    "Set to High Stock (100 units)"
    "Set Near Threshold (15 units)"
    "Trigger Alert Now (8 units)"
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
                $DB_EXEC "UPDATE products SET stock_level = 50 WHERE id = 1;" 2>/dev/null
                echo "✓ Gaming Laptop reset to 50 units"
                break
                ;;
            2)
                $DB_EXEC "UPDATE products SET stock_level = 100 WHERE id = 1;" 2>/dev/null
                echo "✓ Gaming Laptop set to 100 units"
                break
                ;;
            3)
                $DB_EXEC "UPDATE products SET stock_level = 15 WHERE id = 1;" 2>/dev/null
                echo "✓ Gaming Laptop set to 15 units (close to alert!)"
                break
                ;;
            4)
                $DB_EXEC "UPDATE products SET stock_level = 8 WHERE id = 1;" 2>/dev/null
                echo "✓ Gaming Laptop set to 8 units (ALERT FIRING!)"
                break
                ;;
            5)
                echo ""
                $DB_EXEC "SELECT id, name, stock_level, low_stock_threshold FROM products ORDER BY stock_level;" 2>/dev/null
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
    echo "Current Gaming Laptop Stock:"
    $DB_EXEC "SELECT id, name, stock_level, low_stock_threshold FROM products WHERE id = 1;" 2>/dev/null
    echo ""
    echo "💡 TIP: Press 'q' or '8' to exit at any time"
    echo ""
done

