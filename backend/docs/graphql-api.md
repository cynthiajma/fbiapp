# FBI App GraphQL API Documentation

## Overview
GraphQL API for the FBI (Feeling Body Intelligence) app, providing endpoints for parent-child relationships, feeling logging, and character management.

**Base URL**: `http://localhost:4000`  
**GraphQL Playground**: `http://localhost:4000`

## Setup
1. Start database: `docker-compose up database -d`
2. Start server: `npm start`
3. Access GraphQL Playground: `http://localhost:4000`

---


## API Endpoints Summary

| Operation | Type | Description |
|-----------|------|-------------|
| `childProfile` | Query | Get child by ID. Response includes their parents info|
| `parentProfile` | Query | Get parent by ID. Response includes their childrens info|
| `characterLibrary` | Query | Get all available characters |
| `childLogs` | Query | Get child's feeling logs (with time filter) |
| `createChild` | Mutation | Create new child profile |
| `createParent` | Mutation | Create parent link and optionally link to child's profile |
| `loginParent` | Mutation | Authenticate parent login |
| `logFeeling` | Mutation | Log child's feeling about a character |

---


## Schema Types

### Child
```graphql
type Child {
  id: ID!
  username: String!
  name: String
  age: Int
  parents: [Parent!]
}
```

### Parent
```graphql
type Parent {
  id: ID!
  username: String!
  children: [Child!]
}
```

### Character
```graphql
type Character {
  id: ID!
  name: String!
  photo: String
  description: String
}
```

### Log
```graphql
type Log {
  id: ID!
  childId: ID!
  characterId: ID!
  characterName: String
  level: Int!
  timestamp: String!
}
```

---

## Queries

### 1. Get Child Profile
```graphql
query GetChildProfile($id: ID!) {
  childProfile(id: $id) {
    id
    username
    name
    age
    parents {
      id
      username
    }
  }
}
```

**Variables:**
```json
{
  "id": "1"
}
```

**Response:**
```json
{
  "data": {
    "childProfile": {
      "id": "1",
      "username": "alice",
      "name": "Alice",
      "age": 8,
      "parents": [
        {"id": "1", "username": "mom"},
        {"id": "2", "username": "dad"}
      ]
    }
  }
}
```

### 2. Get Parent Profile
```graphql
query GetParentProfile($id: ID!) {
  parentProfile(id: $id) {
    id
    username
    children {
      id
      username
      name
      age
    }
  }
}
```

### 3. Get Character Library
```graphql
query GetCharacterLibrary {
  characterLibrary {
    id
    name
    photo
    description
  }
}
```

### 4. Get Child Logs (with time filtering)
```graphql
query GetChildLogs($childId: ID!, $startTime: String, $endTime: String) {
  childLogs(childId: $childId, startTime: $startTime, endTime: $endTime) {
    id
    childId
    characterId
    characterName
    level
    timestamp
  }
}
```

**Variables:**
```json
{
  "childId": "1",
  "startTime": "2025-01-01",
  "endTime": "2025-12-31"
}
```

---

## Mutations

### 1. Create Child
```graphql
mutation CreateChild($username: String!, $name: String, $age: Int) {
  createChild(username: $username, name: $name, age: $age) {
    id
    username
    name
    age
  }
}
```

**Variables:**
```json
{
  "username": "alice",
  "name": "Alice",
  "age": 8
}
```

### 2. Create Parent (with auto-linking)
```graphql
mutation CreateParent($username: String!, $password: String!, $childId: ID) {
  createParent(username: $username, password: $password, childId: $childId) {
    id
    username
  }
}
```

**Variables:**
```json
{
  "username": "mom",
  "password": "password123",
  "childId": "1"
}
```

### 3. Parent Login
```graphql
mutation LoginParent($username: String!, $password: String!) {
  loginParent(username: $username, password: $password) {
    id
    username
  }
}
```

**Variables:**
```json
{
  "username": "mom",
  "password": "password123"
}
```

### 4. Log Feeling
```graphql
mutation LogFeeling($childId: ID!, $characterId: ID!, $level: Int!) {
  logFeeling(childId: $childId, characterId: $characterId, level: $level) {
    id
    childId
    characterId
    characterName
    level
    timestamp
  }
}
```

**Variables:**
```json
{
  "childId": "1",
  "characterId": "1",
  "level": 7
}
```

---


## Database Schema

### Tables
- `parents` - Parent user accounts
- `children` - Child profiles  
- `parent_child_link` - Many-to-many parent-child relationships
- `characters` - Available characters for the app
- `logging` - Feeling logs for children

### Key Relationships
- One parent can have multiple children
- One child can have multiple parent accounts linked to their profile
- Each log belongs to one child and one character. Each child can have multiple logs of the same character (with different time stamps)
- Characters are shared across all children

---

## Development Notes

### Auto-Linking Workflow
- Child creates profile first
- Parent creates account with `childId` parameter
- Multiple parents can link to same child
- No manual linking required

### Time Filtering
- `startTime` and `endTime` are optional
- Format: ISO date strings (`"2025-01-01"`)
- If not provided, returns all logs
- Logs are ordered by timestamp (newest first)

### Security Notes
- Passwords are not hashed (TODO: implement proper hashing)
- No authentication middleware (TODO: add JWT tokens)
- Basic error handling implemented

---

## Testing Examples

### Test Data Setup
```graphql
# 1. Create a child
mutation {
  createChild(username: "testchild", name: "Test Child", age: 8) {
    id
    username
  }
}

# 2. Create parent and link
mutation {
  createParent(username: "testparent", password: "testpass", childId: "1") {
    id
    username
  }
}

# 3. Log a feeling
mutation {
  logFeeling(childId: "1", characterId: "1", level: 5) {
    id
    level
    timestamp
  }
}

# 4. View the results
query {
  childLogs(childId: "1") {
    id
    characterName
    level
    timestamp
  }
}
```

### Character Library Test
```graphql
query {
  characterLibrary {
    id
    name
    photo
    description
  }
}
```

---

## Frontend Integration

### React with Apollo Client
```javascript
import { useQuery, useMutation } from '@apollo/client';

// Get child profile
const { data } = useQuery(GET_CHILD_PROFILE, {
  variables: { id: childId }
});

// Log feeling
const [logFeeling] = useMutation(LOG_FEELING);
```

### Flutter/Dart
```dart
// GraphQL query
const String getChildProfile = '''
  query GetChildProfile(\$id: ID!) {
    childProfile(id: \$id) {
      id
      username
      name
      age
    }
  }
''';
```


*Last updated: October 2025*
