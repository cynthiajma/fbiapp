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
   docker compose up -d
   ```

   This will:
   - Start PostgreSQL database
   - Automatically run SQL initialization scripts
   - Start the GraphQL server on port 4000
   - Start pgAdmin on port 8080

4. **Database initialization:**
   ```bash
   # Initialize database tables
   npm run init-db
   
   # Populate characters with binary images
   npm run populate-characters
   ```

5. **Start the server:**
   ```bash
   npm start
   ```

## Database Schema

The database includes the following tables:
- `parents` - Parent user accounts
- `children` - Child profiles
- `parent_child_link` - Many-to-many relationship between parents and children
- `characters` - Available characters for the app (with binary image storage)
- `logging` - Feeling logs for children

### Character Images
Character photos are stored as binary data (BYTEA) in the database and returned as base64 strings through the GraphQL API. This provides:
- No file system dependencies
- Atomic transactions
- Simplified deployment
- Backup included with database

## GraphQL API

The server provides a GraphQL API at `http://localhost:4000` with:
- Queries: `childProfile`, `parentProfile`, `characterLibrary`, `childLogs`
- Mutations: `createChild`, `createParent`, `loginParent`, `logFeeling`

### Character Library Response
Character photos are returned as base64 strings:
```json
{
  "characterLibrary": [
    {
      "id": "1",
      "name": "Henry the Heartbeat",
      "photo": "iVBORw0KGgoAAAANSUhEUgAA...",
      "description": "I am a very powerful machine..."
    }
  ]
}
```

Frontend usage:
```javascript
<img src={`data:image/png;base64,${character.photo}`} />
```

## Database Management

Access pgAdmin at `http://localhost:8080`:
- Email: admin@example.com
- Password: admin
- Server: database:5432
- Username: user
- Password: password
