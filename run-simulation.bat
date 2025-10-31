@echo off
REM Interactive Simulation Control for ShopFast Demo (Windows)
REM No Python installation required - runs in Docker!

setlocal enabledelayedexpansion

set IMAGE_NAME=shopfast-simulator
set NETWORK_NAME=shop-fast-alerting-demo_monitoring

REM Check if Docker is running
docker ps >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not running or you don't have permission!
    echo.
    echo Please ensure:
    echo   1. Docker Desktop is running
    echo   2. You have permission to use Docker
    echo.
    pause
    exit /b 1
)

REM If arguments provided, run directly (non-interactive mode)
if not "%~1"=="" (
    call :build_image_if_needed
    call :run_simulation %*
    exit /b 0
)

REM Interactive mode
cls
call :build_image_if_needed

:menu
cls
echo ╔════════════════════════════════════════════════════════════╗
echo ║        🚀 ShopFast Simulation Control Center 🚀           ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo Choose a simulation scenario to trigger Grafana alerts:
echo.
echo 💡 TIP: Press 'q' or '9' to exit ^| Option '0' to view stock levels
echo.
echo  0. 📊 View Current Stock Levels
echo  1. 🟢 Normal Traffic (baseline - no alerts)
echo  2. ⚡ Flash Sale (triggers LOW INVENTORY alert)
echo  3. 💳 Payment Failures (triggers LOG-BASED alert)
echo  4. 🔒 Security Breach (triggers DATABASE alert)
echo  5. 🔥 High CPU Usage (triggers METRICS alert)
echo  6. 📦 Low Inventory (gradual depletion)
echo  7. 🎯 Run ALL Scenarios (complete demo)
echo  8. 🔧 Rebuild Docker Image  
echo  9. ❌ Exit
echo.
set /p choice="Select scenario (0-9, or 'q' to quit): "

if /i "%choice%"=="q" goto exit
if "%choice%"=="0" goto view_stock
if "%choice%"=="1" goto normal_traffic
if "%choice%"=="2" goto flash_sale
if "%choice%"=="3" goto payment_failures
if "%choice%"=="4" goto security_breach
if "%choice%"=="5" goto high_cpu
if "%choice%"=="6" goto low_inventory
if "%choice%"=="7" goto run_all
if "%choice%"=="8" goto rebuild_image
if "%choice%"=="9" goto exit
echo Invalid option. Please select 0-9 or 'q'.
pause
goto menu

:view_stock
echo.
echo 📊 Current Stock Levels
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
docker exec shopfast-postgres psql -U shopfast -d shopfast -c "SELECT id, name, stock_level, low_stock_threshold, CASE WHEN stock_level <= 5 THEN '🔴 CRITICAL' WHEN stock_level <= low_stock_threshold THEN '🟡 LOW' ELSE '🟢 OK' END as status FROM products ORDER BY id;" 2>nul || echo ❌ Could not connect to database. Is Docker running?
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
goto post_simulation

:normal_traffic
echo.
set /p duration="Duration in seconds [60]: "
if "%duration%"=="" set duration=60
call :run_simulation normal --duration %duration%
goto post_simulation

:flash_sale
echo.
echo Available Products:
echo   1. Gaming Laptop (Stock: 50)
echo   2. Wireless Mouse (Stock: 150)
echo   3. Mechanical Keyboard (Stock: 75)
echo   4. USB-C Hub (Stock: 200)
echo   5. External SSD 1TB (Stock: 30)
echo   6. Webcam 4K (Stock: 25)
echo   7. Noise-Canceling Headphones (Stock: 40)
echo   8. Monitor 27" (Stock: 20)
echo   9. Laptop Stand (Stock: 100)
echo  10. Phone Charger (Stock: 300)
echo.
set /p product_id="Select Product ID [1-10, default: 1]: "
if "%product_id%"=="" set product_id=1
set /p duration="Duration in seconds [30]: "
if "%duration%"=="" set duration=30
call :run_simulation flash-sale --product-id %product_id% --duration %duration%
echo.
echo 💡 TIP: Check Grafana → Alerting → Alert rules
echo    Look for 'Low Inventory Warning' alert
goto post_simulation

:payment_failures
echo.
set /p duration="Duration in seconds [60]: "
if "%duration%"=="" set duration=60
call :run_simulation payment-failures --duration %duration%
echo.
echo 💡 TIP: Check Grafana → Explore → Loki
echo    Query: {service="payment"} |= "ERROR"
goto post_simulation

:security_breach
echo.
call :run_simulation security
echo.
echo 💡 TIP: Check Grafana → Alerting → Alert rules
echo    Look for 'Multiple Failed Login Attempts' alert
goto post_simulation

:high_cpu
echo.
set /p duration="Duration in seconds [30]: "
if "%duration%"=="" set duration=30
call :run_simulation high-cpu --duration %duration%
echo.
echo 💡 TIP: Check Grafana → Alerting → Alert rules
echo    Look for 'High CPU Usage' alert
goto post_simulation

:low_inventory
echo.
echo Available Products:
echo   1. Gaming Laptop (Stock: 50)
echo   2. Wireless Mouse (Stock: 150)
echo   3. Mechanical Keyboard (Stock: 75)
echo   4. USB-C Hub (Stock: 200)
echo   5. External SSD 1TB (Stock: 30)
echo   6. Webcam 4K (Stock: 25)
echo   7. Noise-Canceling Headphones (Stock: 40)
echo   8. Monitor 27" (Stock: 20)
echo   9. Laptop Stand (Stock: 100)
echo  10. Phone Charger (Stock: 300)
echo.
set /p product_id="Select Product ID [1-10, default: 6]: "
if "%product_id%"=="" set product_id=6
call :run_simulation low-inventory --product-id %product_id%
goto post_simulation

:run_all
echo.
echo ⏱️  This will run all scenarios in sequence (~5 minutes)
set /p confirm="Continue? (y/N): "
if /i not "%confirm%"=="y" (
    echo Cancelled.
    goto post_simulation
)
call :run_simulation all
echo.
echo 🎉 All scenarios completed! Check Grafana for fired alerts.
goto post_simulation

:rebuild_image
echo.
echo 🔨 Rebuilding Docker image...
docker rmi %IMAGE_NAME% 2>nul
docker build -t %IMAGE_NAME% simulation
echo ✅ Image rebuilt successfully!
echo.
pause
goto menu

:post_simulation
echo.
set /p continue_choice="Press Enter to continue (or 'q' to quit)... "
if /i "%continue_choice%"=="q" (
    echo.
    echo 👋 Goodbye!
    exit /b 0
)
goto menu

:exit
echo.
echo 👋 Goodbye!
exit /b 0

REM Functions

:build_image_if_needed
docker images %IMAGE_NAME% 2>nul | findstr /C:"%IMAGE_NAME%" >nul
if errorlevel 1 (
    echo 🔨 Building simulator Docker image (first time only)...
    docker build -t %IMAGE_NAME% simulation
    if errorlevel 1 (
        echo ❌ Failed to build Docker image!
        pause
        exit /b 1
    )
    echo ✅ Image built successfully!
    echo.
)
exit /b 0

:run_simulation
echo.
echo 🚀 Running simulation: %*
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

docker run --rm ^
    --network %NETWORK_NAME% ^
    -e API_URL="http://shopfast-api:8080" ^
    -e FRONTEND_URL="http://shopfast-frontend:8081" ^
    -e PAYMENT_URL="http://shopfast-payment:8082" ^
    -e INVENTORY_URL="http://shopfast-inventory:8083" ^
    -e DB_HOST="shopfast-postgres" ^
    %IMAGE_NAME% %*

echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ✅ Simulation completed!
echo.
exit /b 0

