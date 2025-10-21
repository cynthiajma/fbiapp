# FBI App Backend

## Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Create environment file:**
   Create a `.env` file with:
   ```
   DB_CONNECTION_STRING=postgresql://user:password@database:5432/appdb
   ```

3. **Start with Docker Compose:**
   ```bash
   docker-compose up -d
   ```

   This will:
   - Start PostgreSQL database
   - Automatically run SQL initialization scripts
   - Start the GraphQL server on port 4000
   - Start pgAdmin on port 8080

4. **Manual database initialization (if needed):**
   ```bash
   npm run init-db
   ```

## Database Schema

The database includes the following tables:
- `parents` - Parent user accounts
- `children` - Child profiles
- `parent_child_link` - Many-to-many relationship between parents and children
- `characters` - Available characters for the app
- `logging` - Feeling logs for children

## GraphQL API

The server provides a GraphQL API at `http://localhost:4000` with:
- Queries: `childProfile`, `characterLibrary`
- Mutations: `logFeeling`, `updateProfile`

## Database Management

Access pgAdmin at `http://localhost:8080`:
- Email: admin@example.com
- Password: admin
- Server: database:5432
- Username: user
- Password: password
