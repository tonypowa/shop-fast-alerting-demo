@echo off
REM Quick start script for ShopFast demo (Windows)

echo.
echo 🚀 Starting ShopFast Demo Environment...
echo.

REM Start Docker Compose
echo 📦 Starting Docker containers...
docker-compose up -d

echo.
echo ⏳ Waiting for services to initialize (30 seconds)...
timeout /t 30 /nobreak > nul

echo.
echo ✅ Services should be ready!
echo.
echo Access the following services:
echo   🎨 Grafana:    http://localhost:3000 (admin/admin)
echo   📊 Prometheus: http://localhost:9090
echo   📝 Loki:       http://localhost:3100
echo   🔌 API:        http://localhost:8080/health
echo.
echo To run simulations:
echo   cd simulation
echo   pip install -r requirements.txt
echo   python simulator.py --help
echo.
echo To view logs:
echo   docker-compose logs -f
echo.
echo To stop:
echo   docker-compose down
echo.
pause

