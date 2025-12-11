#!/bin/bash

# FBI App - Server Rebuild Script
# This script completely rebuilds the backend server from scratch
# Usage: ./rebuild-server.sh [--with-test-data]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="backend"
INCLUDE_TEST_DATA=false

# Parse arguments
if [[ "$1" == "--with-test-data" ]]; then
    INCLUDE_TEST_DATA=true
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}FBI App - Server Rebuild Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Error: backend/ directory not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

cd "$BACKEND_DIR"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✅ Docker found${NC}"

# Check for Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    echo "Please install Docker Compose"
    exit 1
fi
echo -e "${GREEN}✅ Docker Compose found${NC}"

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo "Please install Node.js: https://nodejs.org/"
    exit 1
fi
echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"

# Check for npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ npm found: $(npm --version)${NC}"

echo ""

# Step 1: Stop existing services
echo -e "${YELLOW}🛑 Stopping existing services...${NC}"
docker-compose down -v 2>/dev/null || docker compose down -v 2>/dev/null || true
echo -e "${GREEN}✅ Services stopped${NC}"
echo ""

# Step 2: Create .env file if it doesn't exist
echo -e "${YELLOW}📝 Setting up environment...${NC}"
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo "Creating .env file from .env.example..."
        cp .env.example .env
    else
        echo "Creating .env file..."
        cat > .env << EOF
DB_CONNECTION_STRING=postgresql://user:password@database:5432/appdb
NODE_ENV=development
EOF
    fi
    echo -e "${GREEN}✅ .env file created${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi
echo ""

# Step 3: Install dependencies
echo -e "${YELLOW}📦 Installing Node.js dependencies...${NC}"
npm install
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 4: Build and start Docker services
echo -e "${YELLOW}🐳 Starting Docker services...${NC}"
if command -v docker-compose &> /dev/null; then
    docker-compose up -d --build
else
    docker compose up -d --build
fi
echo -e "${GREEN}✅ Docker services started${NC}"
echo ""

# Step 5: Wait for database to be ready
echo -e "${YELLOW}⏳ Waiting for database to be ready...${NC}"
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if docker-compose exec -T database pg_isready -U user > /dev/null 2>&1 || \
       docker compose exec -T database pg_isready -U user > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Database is ready${NC}"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo "  Attempt $ATTEMPT/$MAX_ATTEMPTS..."
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}❌ Database failed to start within timeout${NC}"
    exit 1
fi

# Give database a bit more time to fully initialize
sleep 3
echo ""

# Step 6: Update .env for localhost connection (for npm scripts)
echo -e "${YELLOW}🔧 Configuring database connection...${NC}"
# Save original .env
cp .env .env.docker 2>/dev/null || true
# Update .env to use localhost for npm scripts running outside Docker
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' 's/@database:5432/@localhost:5432/g' .env
else
    # Linux
    sed -i 's/@database:5432/@localhost:5432/g' .env
fi
echo -e "${GREEN}✅ Database connection configured for localhost${NC}"
echo ""

# Step 7: Initialize database schema
echo -e "${YELLOW}🗄️  Initializing database schema...${NC}"
npm run init-db
echo -e "${GREEN}✅ Database schema initialized${NC}"
echo ""

# Step 8: Populate characters
echo -e "${YELLOW}👥 Populating character data...${NC}"
npm run populate-characters
echo -e "${GREEN}✅ Characters populated${NC}"
echo ""

# Step 9: Upload audio files
echo -e "${YELLOW}🎵 Uploading audio files...${NC}"
npm run upload-audio
echo -e "${GREEN}✅ Audio files uploaded${NC}"
echo ""

# Step 10: Seed test data (optional)
if [ "$INCLUDE_TEST_DATA" = true ]; then
    echo -e "${YELLOW}🧪 Seeding test data...${NC}"
    npm run seed-test-data
    echo -e "${GREEN}✅ Test data seeded${NC}"
    echo ""
fi

# Step 11: Restore .env for Docker (optional - keep localhost for local development)
# The .env.docker backup is kept for reference
# For Docker services, they use the connection string from docker-compose.yml
echo -e "${YELLOW}ℹ️  Note: .env uses localhost for local npm scripts${NC}"
echo -e "${YELLOW}   Docker services use connection from docker-compose.yml${NC}"

# Step 12: Verify services are running
echo -e "${YELLOW}🔍 Verifying services...${NC}"

# Determine which docker-compose command to use
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    DOCKER_COMPOSE_CMD="docker compose"
fi

# Check database
if $DOCKER_COMPOSE_CMD ps database 2>/dev/null | grep -q "Up"; then
    echo -e "${GREEN}✅ Database service is running${NC}"
else
    echo -e "${RED}❌ Database service is not running${NC}"
fi

# Check backend (if started)
if $DOCKER_COMPOSE_CMD ps backend 2>/dev/null | grep -q "Up"; then
    echo -e "${GREEN}✅ Backend service is running${NC}"
else
    echo -e "${YELLOW}⚠️  Backend service is not running (this is normal if you want to run it manually)${NC}"
fi

echo ""

# Final summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 Server rebuild completed successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo "1. Start the backend server:"
echo "   cd backend"
echo "   npm start"
echo ""
echo "2. Or use Docker Compose to run everything:"
echo "   cd backend"
if command -v docker-compose &> /dev/null; then
    echo "   docker-compose up"
else
    echo "   docker compose up"
fi
echo ""
echo "3. Access the GraphQL API:"
echo "   http://localhost:3000/graphql"
echo ""
echo "4. Access pgAdmin (database management):"
echo "   http://localhost:8081"
echo "   Email: admin@example.com"
echo "   Password: admin"
echo ""
if [ "$INCLUDE_TEST_DATA" = true ]; then
    echo -e "${YELLOW}📝 Test Accounts Created:${NC}"
    echo "   Child: alice_child (no password)"
    echo "   Parent: alice_mom / password123"
    echo ""
fi
echo -e "${BLUE}========================================${NC}"

