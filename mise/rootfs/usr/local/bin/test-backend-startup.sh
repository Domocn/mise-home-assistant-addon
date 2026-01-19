#!/bin/bash
# Test backend startup to help diagnose issues

set -e

echo "====== Backend Startup Test ======"
echo "Testing backend startup with verbose output..."
echo ""

# Source environment
if [ -f /etc/mise.env ]; then
    echo "Loading environment from /etc/mise.env..."
    source /etc/mise.env
else
    echo "WARNING: /etc/mise.env not found!"
fi

echo ""
echo "Python version:"
python3 --version

echo ""
echo "Python path:"
which python3

echo ""
echo "Virtual environment:"
which uvicorn

echo ""
echo "Checking database connectivity..."
if command -v pg_isready &> /dev/null; then
    pg_isready -h 127.0.0.1 -p 5432 && echo "PostgreSQL is ready" || echo "PostgreSQL is NOT ready"
else
    echo "pg_isready command not found"
fi

echo ""
echo "Checking Redis connectivity..."
if command -v redis-cli &> /dev/null; then
    redis-cli -h 127.0.0.1 -p 6379 ping && echo "Redis is ready" || echo "Redis is NOT ready"
else
    echo "redis-cli command not found"
fi

echo ""
echo "Attempting to import server module..."
cd /app/backend
python3 -c "import server; print('✓ Server module imported successfully')" || {
    echo "✗ Failed to import server module"
    echo ""
    echo "Detailed error:"
    python3 -c "import server" 2>&1
    exit 1
}

echo ""
echo "Checking database connection..."
python3 -c "
import asyncio
from database.connection import init_db, close_db

async def test():
    try:
        pool = await init_db()
        print('✓ Database connection successful')
        await close_db()
    except Exception as e:
        print(f'✗ Database connection failed: {e}')
        import traceback
        traceback.print_exc()
        raise

asyncio.run(test())
" || {
    echo "Database connection test failed"
    exit 1
}

echo ""
echo "====== All tests passed! ======"
echo "Backend should start successfully"
