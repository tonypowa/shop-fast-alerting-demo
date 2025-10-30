@echo off
REM Demo Control Script for Windows - Easy inventory management during presentation

echo === ShopFast Demo Control ===
echo.

:menu
echo Current Gaming Laptop Stock:
docker exec shopfast-postgres psql -U shopfast -d shopfast -c "SELECT id, name, stock_level, low_stock_threshold FROM products WHERE id = 1;"
echo.

echo Choose an action:
echo 1. Reset to Default (50 units)
echo 2. Set to High Stock (100 units)
echo 3. Set Near Threshold (15 units) 
echo 4. Trigger Alert Now (8 units)
echo 5. View All Products
echo 6. Reset All Products to Defaults
echo 7. Clear All Orders
echo 8. Exit
echo.

set /p choice="Enter choice (1-8): "

if "%choice%"=="1" (
    docker exec shopfast-postgres psql -U shopfast -d shopfast -c "UPDATE products SET stock_level = 50 WHERE id = 1;"
    echo [32mGaming Laptop reset to 50 units[0m
    goto menu
)

if "%choice%"=="2" (
    docker exec shopfast-postgres psql -U shopfast -d shopfast -c "UPDATE products SET stock_level = 100 WHERE id = 1;"
    echo [32mGaming Laptop set to 100 units[0m
    goto menu
)

if "%choice%"=="3" (
    docker exec shopfast-postgres psql -U shopfast -d shopfast -c "UPDATE products SET stock_level = 15 WHERE id = 1;"
    echo [33mGaming Laptop set to 15 units (close to alert!)[0m
    goto menu
)

if "%choice%"=="4" (
    docker exec shopfast-postgres psql -U shopfast -d shopfast -c "UPDATE products SET stock_level = 8 WHERE id = 1;"
    echo [31mGaming Laptop set to 8 units (ALERT FIRING!)[0m
    goto menu
)

if "%choice%"=="5" (
    docker exec shopfast-postgres psql -U shopfast -d shopfast -c "SELECT id, name, stock_level, low_stock_threshold FROM products ORDER BY stock_level;"
    pause
    goto menu
)

if "%choice%"=="6" (
    docker exec shopfast-postgres psql -U shopfast -d shopfast -c "UPDATE products SET stock_level = CASE id WHEN 1 THEN 50 WHEN 2 THEN 150 WHEN 3 THEN 75 WHEN 4 THEN 200 WHEN 5 THEN 30 WHEN 6 THEN 25 WHEN 7 THEN 40 WHEN 8 THEN 20 WHEN 9 THEN 100 WHEN 10 THEN 300 END;"
    echo [32mAll products reset to defaults[0m
    goto menu
)

if "%choice%"=="7" (
    docker exec shopfast-postgres psql -U shopfast -d shopfast -c "DELETE FROM orders;"
    echo [32mAll orders cleared[0m
    goto menu
)

if "%choice%"=="8" (
    echo Goodbye!
    exit /b
)

echo Invalid choice!
goto menu

