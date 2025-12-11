# Quick Start Guide - Rebuilding the Server

This is a quick walkthrough of how to use the automated rebuild script to set up your FBI App backend server.

---

## Prerequisites Check

Before you start, make sure you have:

1. **Docker** installed and running
   - Check: Open Docker Desktop (if on Mac/Windows) or verify Docker is running
   - Verify: Open terminal and type `docker --version`

2. **Node.js** installed (v14 or higher)
   - Verify: Open terminal and type `node --version`

3. **Git** (if cloning the repository)
   - Verify: Open terminal and type `git --version`

---

## Step-by-Step Walkthrough

### Step 1: Navigate to Project Directory

Open your terminal and navigate to the project root:

```bash
cd /path/to/app_fbi
```

Or if you're already in the project directory, you're good to go!

### Step 2: Make Script Executable (First Time Only)

The script should already be executable, but if you get a "permission denied" error:

```bash
chmod +x rebuild-server.sh
```

### Step 3: Run the Rebuild Script

#### Basic Rebuild (Without Test Data)

```bash
./rebuild-server.sh
```

This will:
- Check that you have all required software
- Stop any existing services
- Set up the environment
- Install all dependencies
- Start the database
- Initialize the database schema
- Populate character data
- Upload audio files

**Time:** Approximately 3-5 minutes

#### Rebuild with Test Data

If you want test accounts and sample data:

```bash
./rebuild-server.sh --with-test-data
```

This does everything above PLUS:
- Creates test child accounts (alice_child, bob_child, charlie_child)
- Creates test parent accounts (alice_mom, alice_dad, bob_mom)
- Generates sample feeling logs

---

## What You'll See

The script provides colored output to show progress:

- **Blue:** Headers and important information
- **Yellow:** Current step in progress
- **Green:** Successfully completed steps
- **Red:** Errors (if any)

Example output:
```
========================================
FBI App - Server Rebuild Script
========================================

📋 Checking prerequisites...
✅ Docker found
✅ Docker Compose found
✅ Node.js found: v18.17.0
✅ npm found: 9.6.7

🛑 Stopping existing services...
✅ Services stopped

📝 Setting up environment...
✅ .env file created

📦 Installing Node.js dependencies...
✅ Dependencies installed

🐳 Starting Docker services...
✅ Docker services started

⏳ Waiting for database to be ready...
✅ Database is ready

🗄️  Initializing database schema...
✅ Database schema initialized

👥 Populating character data...
✅ Characters populated

🎵 Uploading audio files...
✅ Audio files uploaded

🎉 Server rebuild completed successfully!
```

---

## After the Script Completes

### Starting the Server

Once the rebuild is complete, you need to start the backend server:

#### Option A: Run Locally (Recommended for Development)

```bash
cd backend
npm start
```

You should see:
```
Server running on http://localhost:3000
```

#### Option B: Run in Docker

```bash
cd backend
docker-compose up
```

This starts all services including the backend in Docker containers.

---

## Verifying Everything Works

### 1. Check the GraphQL API

Open your browser and go to:
```
http://localhost:3000/graphql
```

You should see the GraphQL Playground interface. This confirms the backend is running.

### 2. Test a Query

In the GraphQL Playground, try this query:

```graphql
query {
  characterLibrary {
    id
    name
    description
  }
}
```

Click the "Play" button. You should see a list of characters.

### 3. Check Database (Optional)

Open pgAdmin:
```
http://localhost:8080
```

Login:
- Email: `admin@example.com`
- Password: `admin`

Add a server:
- Host: `database`
- Port: `5432`
- Username: `user`
- Password: `password`
- Database: `appdb`

You should be able to see all the tables and data.

---

## Common Issues and Solutions

### Issue: "Permission denied"

**Solution:**
```bash
chmod +x rebuild-server.sh
```

### Issue: "Docker is not installed"

**Solution:**
1. Install Docker Desktop: https://docs.docker.com/get-docker/
2. Start Docker Desktop
3. Wait for it to fully start (Docker icon in system tray)
4. Try the script again

### Issue: "Port 5432 already in use"

**Solution:**
You likely have PostgreSQL running locally. Either:
1. Stop your local PostgreSQL service
2. Or change the port in `backend/docker-compose.yml` (line 24)

### Issue: "Database failed to start"

**Solution:**
1. Check Docker is running: `docker ps`
2. Check Docker logs: `docker-compose logs database`
3. Try stopping and restarting: `docker-compose down` then run script again

### Issue: "Character images not found"

**Solution:**
- Make sure you're running from the project root
- Verify files exist in `fbi_app/data/characters/`
- The script will continue, but those characters won't be added

---

## Quick Reference

### Rebuild Commands

```bash
# Basic rebuild
./rebuild-server.sh

# Rebuild with test data
./rebuild-server.sh --with-test-data

# Clean rebuild (removes all data first)
cd backend
docker-compose down -v
cd ..
./rebuild-server.sh
```

### Start Server

```bash
cd backend
npm start
```

### Stop Services

```bash
cd backend
docker-compose down
```

### View Logs

```bash
cd backend
docker-compose logs -f
```

---

## Getting Help

If you encounter issues:

1. Check the error message carefully
2. Review `REBUILD_SERVER_GUIDE.md` troubleshooting section
3. Check Docker is running: `docker ps`
4. See `TROUBLESHOOTING_GUIDE.md` for more help
5. Contact support (see `SUPPORT_CONTACTS.md`)

---

**Ready to rebuild?** Just run:
```bash
./rebuild-server.sh
```


