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

8. Start the backend server:
   ```bash
   npm start
   ```

The backend will be available at `http://localhost:3000/graphql`

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

#### Platform-specific Setup

**For iOS:**
```bash
cd ios
pod install
cd ..
flutter run
```

**For Android:**
Make sure you have Android Studio and Android SDK installed, then:
```bash
flutter run
```

**For Web:**
```bash
flutter run -d chrome
```

**For Desktop (macOS):**
```bash
flutter run -d macos
```

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

The server provides a GraphQL API at `http://localhost:3000/graphql` with:

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
