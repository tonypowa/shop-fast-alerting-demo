#!/bin/bash
# Demo Control Script - Easy inventory management during presentation

DB_EXEC="docker exec shopfast-postgres psql -U shopfast -d shopfast -c"

echo "=== ShopFast Demo Control ==="
echo ""
echo "Current Gaming Laptop Stock:"
$DB_EXEC "SELECT id, name, stock_level, low_stock_threshold FROM products WHERE id = 1;"
echo ""

PS3="Choose action: "
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

select opt in "${options[@]}"
do
    case $opt in
        "Reset to Default (50 units)")
            $DB_EXEC "UPDATE products SET stock_level = 50 WHERE id = 1;"
            echo "✓ Gaming Laptop reset to 50 units"
            ;;
        "Set to High Stock (100 units)")
            $DB_EXEC "UPDATE products SET stock_level = 100 WHERE id = 1;"
            echo "✓ Gaming Laptop set to 100 units"
            ;;
        "Set Near Threshold (15 units)")
            $DB_EXEC "UPDATE products SET stock_level = 15 WHERE id = 1;"
            echo "✓ Gaming Laptop set to 15 units (close to alert!)"
            ;;
        "Trigger Alert Now (8 units)")
            $DB_EXEC "UPDATE products SET stock_level = 8 WHERE id = 1;"
            echo "✓ Gaming Laptop set to 8 units (ALERT FIRING!)"
            ;;
        "View All Products")
            $DB_EXEC "SELECT id, name, stock_level, low_stock_threshold FROM products ORDER BY stock_level;"
            ;;
        "Reset All Products to Defaults")
            $DB_EXEC "UPDATE products SET stock_level = CASE id WHEN 1 THEN 50 WHEN 2 THEN 150 WHEN 3 THEN 75 WHEN 4 THEN 200 WHEN 5 THEN 30 WHEN 6 THEN 25 WHEN 7 THEN 40 WHEN 8 THEN 20 WHEN 9 THEN 100 WHEN 10 THEN 300 END;"
            echo "✓ All products reset to defaults"
            ;;
        "Clear All Orders")
            $DB_EXEC "DELETE FROM orders;"
            echo "✓ All orders cleared"
            ;;
        "Exit")
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
    
    echo ""
    echo "Current Gaming Laptop Stock:"
    $DB_EXEC "SELECT id, name, stock_level, low_stock_threshold FROM products WHERE id = 1;"
    echo ""
done

