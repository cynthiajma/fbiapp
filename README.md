# CompSci 408 App Feelings and Body Investigation

This is the repository where you will keep everything related to this CompSci 408 project.

## Project Structure

- `backend/` - Node.js backend with GraphQL API
- `fbi_app/` - Flutter frontend application

## Setup Instructions

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create environment file:
   Create a `.env` file with:
   ```
   DB_CONNECTION_STRING=postgresql://user:password@database:5432/appdb
   ```

4. Start with Docker Compose:
   ```bash
   docker compose up -d
   ```

   This will:
   - Start PostgreSQL database
   - Automatically run SQL initialization scripts
   - Start the GraphQL server on port **3000** (not 4000)
   - Start pgAdmin on port 8080

5. Initialize the database:
   ```bash
   npm run init-db
   ```

6. Seed test data:
   ```bash
   npm run seed-test-data
   ```

7. Populate character data:
   ```bash
   npm run populate-characters
   ```

8. Populate character audio data: 
   ```bash
   npm run upload-audio
   ```

### Frontend Setup (Flutter)

1. Navigate to the Flutter app directory:
   ```bash
   cd fbi_app
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the Flutter app:
   ```bash
   flutter run
   ```

## Production Deployment

The app is currently deployed and accessible at:

- **Frontend (Web App)**: [https://fbiapp1.netlify.app/](https://fbiapp1.netlify.app/)
- **Backend API**: [https://tender-wisdom-production-fe18.up.railway.app/graphql](https://tender-wisdom-production-fe18.up.railway.app/graphql)
- **Railway Project**: [View on Railway](https://railway.com/project/2f2f6d4d-4a44-4914-a44f-ebf090b9e668?environmentId=c600e312-0dbf-42e9-8e09-d658dba534f3)

### Production Environment Configuration

The backend service on Railway requires the following environment variables:

**Required:**
- `DATABASE_URL` - Automatically provided by Railway's PostgreSQL service
- `NODE_ENV=production` - Sets the application to production mode
- `PORT=3000` - Server port (Railway may override this automatically)

**Email Configuration (for password reset):**
To enable password reset emails, add these environment variables in Railway:

**Recommended: SendGrid Web API (Required for Railway Hobby)**
1. Sign up for a free account at [SendGrid](https://sendgrid.com) (100 emails/day free)
2. Go to Settings → API Keys → Create API Key
3. Give it a name (e.g., "FBI App Production") and select "Full Access" or "Mail Send" permissions
4. Copy the API key (you'll only see it once!)
5. Verify a sender email address in Settings → Sender Authentication

Add these variables in Railway:
```
SENDGRID_API_KEY=SG.your-sendgrid-api-key-here
EMAIL_FROM=your-verified-email@yourdomain.com
```

**Note:** The app uses SendGrid's Web API (HTTPS) instead of SMTP, which is required for Railway Hobby plan. This is more reliable and doesn't require SMTP ports.

**Note:** Without email configuration, password reset requests will fail. The app will still work for login and other features.

### Accessing Production

1. **Web App**: Simply visit [https://fbiapp1.netlify.app/](https://fbiapp1.netlify.app/) in your browser
2. **GraphQL API**: Access the GraphQL playground at [https://tender-wisdom-production-fe18.up.railway.app/graphql](https://tender-wisdom-production-fe18.up.railway.app/graphql)

### Deployment Architecture

- **Frontend**: Deployed on Netlify as a Flutter web app
- **Backend**: Deployed on Railway with Node.js and PostgreSQL
- **Database**: PostgreSQL hosted on Railway (automatically linked to backend service)

### Updating Production

1. **Backend Updates**: Push changes to the `backend/` directory. Railway automatically rebuilds and redeploys.
2. **Frontend Updates**: 
   - Build the Flutter web app: `cd fbi_app && flutter build web`
   - Deploy the `build/web` folder to Netlify (or connect GitLab for automatic deployments)

### Production Notes

- The production database is separate from the local development database
- Character data and test data need to be initialized separately in production
- CORS is configured to allow requests from the Netlify frontend domain

## Development

- Backend API documentation: See `backend/docs/graphql-api.md`
- Frontend: Flutter app with character-based UI for children's health tracking

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

The server provides a GraphQL API at:

- **Development**: `http://localhost:3000/graphql`
- **Production**: `https://tender-wisdom-production-fe18.up.railway.app/graphql`

Available operations:

### Queries
- `childProfile(id: ID!)` - Get child information
- `parentProfile(id: ID!)` - Get parent information  
- `characterLibrary` - Get all available characters
- `childLogs(childId: ID!, startTime: String, endTime: String)` - Get child's feeling logs

### Mutations
- `createChild(username: String!, name: String, age: Int)` - Create new child
- `createParent(username: String!, password: String!, childId: ID)` - Create new parent
- `loginParent(username: String!, password: String!)` - Authenticate parent
- `linkParentChild(parentId: ID!, childId: ID!)` - Link parent to child
- `logFeeling(childId: ID!, characterId: ID!, level: Int!, investigation: [String!])` - Log a feeling

### New Queries
- `childByUsername(username: String!)` - Get child by username for login verification

### Authentication Flow
1. Parent logs in with `loginParent` mutation
2. System automatically links parent to current child with `linkParentChild`
3. Parent can then access child data through `childLogs` query

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

## Test Data

The backend comes with pre-seeded test data:

### Test Children
- **Alice** (ID: 1) - Username: `alice_child`, Age: 8
- **Bob** (ID: 2) - Username: `bob_child`, Age: 7  
- **Charlie** (ID: 3) - Username: `charlie_child`, Age: 9

### Test Parents
- **Alice's Mom** (ID: 1) - Username: `alice_mom`, Password: `password123` → Linked to Alice (ID: 1)
- **Alice's Dad** (ID: 2) - Username: `alice_dad`, Password: `password123` → Linked to Alice (ID: 1)
- **Bob's Mom** (ID: 3) - Username: `bob_mom`, Password: `password123` → Linked to Bob (ID: 2)

### Test Characters
- Henry the Heartbeat (heart rate feelings)
- Samantha Sweat (temperature sensations)
- Gerda Gotta Go (bathroom needs)
- Patricia the Poop Pain (digestive feelings)
- And 7 more characters...

### Sample Logs
Alice has 3 feeling logs for Henry the Heartbeat with levels 9, 2, and 10.

## API Examples

### Parent Login
```graphql
mutation {
  loginParent(username: "alice_mom", password: "password123") {
    id
    username
  }
}
```

### Get Child Logs
```graphql
query {
  childLogs(childId: "1") {
    id
    characterName
    level
    timestamp
    investigation
  }
}
```

### Link Parent to Child
```graphql
mutation {
  linkParentChild(parentId: "1", childId: "1")
}
```

### Verify Child by Username
```graphql
query {
  childByUsername(username: "alice_child") {
    id
    username
    name
    age
  }
}
```

## Database Management

Access pgAdmin at `http://localhost:8080`:
- Email: admin@example.com
- Password: admin
- Server: database:5432
- Username: user
- Password: password
