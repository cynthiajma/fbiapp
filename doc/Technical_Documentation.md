# FBI App - Technical Documentation

**Feelings and Body Investigation (FBI) App**  
**Version:** 1.0  
**Last Updated:** December 2024  
**Team:** CS408 Development Team

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Design](#architecture-design)
3. [Database Schema](#database-schema)
4. [Frontend Structure](#frontend-structure)
5. [Backend Structure](#backend-structure)
6. [Design Decisions & Justifications](#design-decisions--justifications)
7. [Extensibility Guide](#extensibility-guide)
8. [Code Organization](#code-organization)

---

## Overview

The FBI (Feelings and Body Investigation) App is a Flutter-based mobile/web application designed to help children recognize and log their bodily sensations through character-based interactions. Parents can monitor their children's logs through a separate dashboard.

### Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart) |
| Backend | Node.js with Apollo GraphQL |
| Database | PostgreSQL 15 |
| Containerization | Docker & Docker Compose |
| State Management | GetX (Flutter) |
| API Protocol | GraphQL |

---

## Architecture Design

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SYSTEM ARCHITECTURE                                 │
└─────────────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐     ┌──────────┐
    │  Child   │     │  Parent  │
    │   User   │     │   User   │
    └────┬─────┘     └────┬─────┘
         │                │
         └───────┬────────┘
                 │
                 ▼
    ┌────────────────────────┐
    │      FLUTTER UI        │
    │  ┌──────────────────┐  │
    │  │      Pages       │  │
    │  │  (Presentation)  │  │
    │  └────────┬─────────┘  │
    │           │            │
    │  ┌────────▼─────────┐  │
    │  │    Services      │  │
    │  │  (Business Logic)│  │
    │  └────────┬─────────┘  │
    └───────────┼────────────┘
                │
        ┌───────┴───────┐
        │               │
        ▼               ▼
┌───────────────┐  ┌─────────────────────────────────────────┐
│Local Storage  │  │         DOCKER ENVIRONMENT              │
│(SharedPrefs)  │  │  ┌─────────────────────────────────┐    │
│               │  │  │      GraphQL Server             │    │
│ • User State  │  │  │      (Apollo Server)            │    │
│ • Avatar Data │  │  │      Port: 3000                 │    │
│ • Preferences │  │  └──────────────┬──────────────────┘    │
└───────────────┘  │                 │                       │
                   │                 ▼                       │
                   │  ┌─────────────────────────────────┐    │
                   │  │      PostgreSQL Database        │    │
                   │  │      Port: 5432                 │    │
                   │  └─────────────────────────────────┘    │
                   │                                         │
                   │  ┌─────────────────────────────────┐    │
                   │  │      pgAdmin (Dev Tool)         │    │
                   │  │      Port: 8080                 │    │
                   │  └─────────────────────────────────┘    │
                   └─────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| **UI (Pages)** | User interface, user interactions, displaying data |
| **Services** | Business logic, API calls, data transformation |
| **Local Storage** | Caching user state, avatar preferences |
| **GraphQL Server** | API gateway, request validation, resolver logic |
| **Database** | Data persistence, relationships, integrity |

---

## Database Schema

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            DATABASE SCHEMA DIAGRAM                               │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────┐              ┌─────────────────────────────┐
│          PARENTS            │              │          CHILDREN           │
├─────────────────────────────┤              ├─────────────────────────────┤
│ PK  parent_id      SERIAL   │              │ PK  child_id       SERIAL   │
│     parent_username VARCHAR │              │     child_username VARCHAR  │
│     parent_email    VARCHAR │              │     child_age      INT      │
│     hashed_password VARCHAR │              │         (CHECK: 0-200)      │
│     reset_token     VARCHAR │              └──────────────┬──────────────┘
│     reset_token_expiry      │                             │
│                  TIMESTAMPTZ│                             │
└──────────────┬──────────────┘                             │
               │                                            │
               │                                            │
               │    ┌─────────────────────────────┐         │
               │    │    PARENT_CHILD_LINK        │         │
               │    ├─────────────────────────────┤         │
               └───►│ PK,FK parent_id    INT      │◄────────┘
                    │ PK,FK child_id     INT      │
                    │                             │
                    │ ON DELETE CASCADE (both)    │
                    └─────────────────────────────┘
                           (Many-to-Many)


┌─────────────────────────────┐              ┌─────────────────────────────┐
│        CHARACTERS           │              │          LOGGING            │
├─────────────────────────────┤              ├─────────────────────────────┤
│ PK  character_id     SERIAL │◄─────────────│ PK  log_id          SERIAL  │
│     character_name  VARCHAR │              │     logging_time TIMESTAMPTZ│
│     character_photo   BYTEA │              │ FK  child_id          INT   │◄── children
│     character_description   │              │ FK  character_id      INT   │◄── characters
│                      TEXT   │              │     character_name  VARCHAR │
│     audio_file        BYTEA │              │     feeling_level     INT   │
└─────────────────────────────┘              │         (CHECK: 0-10)       │
                                             │     investigation   TEXT[]  │
                                             └─────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════════
                              RELATIONSHIPS
═══════════════════════════════════════════════════════════════════════════════════

  PARENTS ──────< PARENT_CHILD_LINK >────── CHILDREN
                  (Many-to-Many)
                  • A parent can have multiple children
                  • A child can have multiple parents/guardians
                  
  CHILDREN ─────────────────────────────────< LOGGING
                                              (One-to-Many)
                                              • ON DELETE CASCADE
                                              • Child deletion removes all logs
                                              
  CHARACTERS ───────────────────────────────< LOGGING
                                              (One-to-Many)
                                              • ON DELETE RESTRICT
                                              • Cannot delete character with logs
```

### Table Details

#### `parents`
Stores parent/guardian account information with secure password hashing and password reset functionality.

#### `children`
Stores child profiles. Children don't have passwords - they log in with username only for simplicity.

#### `parent_child_link`
Junction table enabling many-to-many relationships between parents and children.

#### `characters`
Stores the FBI characters (Henry Heartbeat, Betty Butterfly, etc.) with their images and audio as binary data (BYTEA).

#### `logging`
Stores feeling logs with:
- Timestamp
- Child who logged
- Character used
- Feeling level (0-10 scale)
- Investigation notes (array of strings)

---

## Frontend Structure

```
fbi_app/lib/
├── main.dart                    # App entry point, GraphQL provider setup
├── features/
│   └── character.dart           # Character model class
├── pages/                       # UI Screens
│   ├── home_page.dart           # Main dashboard for children
│   ├── opening_page.dart        # Splash/intro screen
│   ├── about_page.dart          # About the app
│   ├── child_login_page.dart    # Child authentication
│   ├── child_profile_page.dart  # Child profile & log history
│   ├── child_signup_page.dart   # Child registration
│   ├── parent_login_page.dart   # Parent authentication
│   ├── parent_signup_page.dart  # Parent registration
│   ├── parent_view_child_page.dart  # Parent dashboard
│   ├── parent_child_selector_page.dart  # Multi-child selector
│   ├── login_selection_page.dart    # Choose child/parent login
│   ├── forgot_password_page.dart    # Password recovery
│   ├── reset_password_page.dart     # Password reset form
│   ├── character_library_page.dart  # Browse characters
│   ├── heartbeat_page.dart      # Henry Heartbeat character
│   ├── sweat.dart               # Samantha Sweat character
│   ├── butterfly.dart           # Betty Butterfly character
│   ├── gerda.dart               # Gerda Gotta Go character
│   ├── rock.dart                # Ricky the Rock character
│   ├── games_selection_page.dart    # Games menu
│   └── memory_game_page.dart    # Memory matching game
├── services/                    # Business Logic Layer
│   ├── user_state_service.dart      # User session management
│   ├── child_auth_service.dart      # Child authentication
│   ├── parent_auth_service.dart     # Parent authentication
│   ├── child_data_service.dart      # Child data operations
│   ├── parent_data_service.dart     # Parent data operations
│   ├── character_service.dart       # Character fetching
│   ├── logging_service.dart         # Feeling log submission
│   ├── avatar_storage_service.dart  # Avatar persistence
│   └── tutorial_service.dart        # Onboarding tutorial
└── widgets/                     # Reusable UI Components
    ├── char_row.dart            # Character row in log history
    └── progress_ring.dart       # Circular progress indicator
```

### Service Layer Details

| Service | Purpose |
|---------|---------|
| `user_state_service.dart` | Manages logged-in user state via SharedPreferences |
| `child_auth_service.dart` | Child login/signup GraphQL mutations |
| `parent_auth_service.dart` | Parent login/signup with password hashing |
| `child_data_service.dart` | Fetches child profile, logs, processes data |
| `character_service.dart` | Fetches character library from backend |
| `logging_service.dart` | Submits feeling logs to backend |
| `avatar_storage_service.dart` | Saves/loads Fluttermoji avatar customizations |
| `tutorial_service.dart` | Controls first-time user onboarding flow |

---

## Backend Structure

```
backend/
├── index.js                 # Apollo Server setup, GraphQL schema & resolvers
├── db.js                    # PostgreSQL connection pool
├── email-config.js          # SendGrid email configuration
├── docker-compose.yml       # Container orchestration
├── Dockerfile               # Backend container image
├── package.json             # Dependencies
├── scripts/
│   ├── 01_init.sql          # Database schema initialization
│   ├── init-db.js           # Database setup script
│   ├── seed-test-data.js    # Test data population
│   ├── populate-characters.js   # Character data loading
│   └── upload-audio.js      # Audio file upload script
├── docs/
│   └── graphql-api.md       # API documentation
└── __tests__/               # Jest unit tests
    ├── db.test.js
    ├── email-config.test.js
    └── resolvers/
        ├── mutations.test.js
        ├── queries.test.js
        └── nested.test.js
```

### GraphQL API Overview

**Queries:**
- `childProfile(id)` - Get child by ID
- `childByUsername(username)` - Get child by username
- `parentProfile(id)` - Get parent by ID
- `characterLibrary` - Get all characters
- `childLogs(childId, startTime?, endTime?)` - Get feeling logs

**Mutations:**
- `createChild(username, age)` - Register child
- `createParent(username, email, password)` - Register parent
- `loginParent(username, password)` - Authenticate parent
- `loginChild(username)` - Authenticate child
- `linkParentChild(parentId, childId)` - Create parent-child link
- `logFeeling(childId, characterId, level, investigation)` - Submit log
- `requestPasswordReset(email)` - Send reset email
- `resetPassword(token, newPassword)` - Complete reset

---

## Design Decisions & Justifications

### 1. **GraphQL over REST**

**Decision:** Use GraphQL as the API protocol.

**Justification:**
- Flexible querying - clients request exactly what they need
- Single endpoint simplifies frontend code
- Strong typing with schema definition
- Built-in documentation via introspection
- Efficient for mobile apps with varying data needs

### 2. **Client-Server Separation**

**Decision:** Complete separation of Flutter frontend and Node.js backend.

**Justification:**
- **Independent deployment:** Frontend can be deployed to Netlify, backend to Railway
- **Technology flexibility:** Backend could be rewritten without affecting mobile app
- **Scalability:** Backend can be scaled independently based on load
- **Security:** Business logic and database credentials stay server-side
- **Team parallelization:** Frontend and backend teams can work independently

### 3. **Binary Storage for Media (BYTEA)**

**Decision:** Store character images and audio as binary data in PostgreSQL.

**Justification:**
- **Atomic transactions:** Media and metadata are always consistent
- **Simplified backup:** Single database backup includes all data
- **No file system dependencies:** Works identically in all environments
- **Simplified deployment:** No CDN or file storage service needed
- **Trade-off acknowledged:** Larger database size, but manageable for ~15 characters

### 4. **Service Layer Pattern (Flutter)**

**Decision:** Implement a dedicated services layer between UI and network.

**Justification:**
- **Separation of concerns:** UI components don't contain business logic
- **Testability:** Services can be unit tested independently
- **Reusability:** Multiple pages can share the same service
- **Maintainability:** Changes to API don't require UI changes

### 5. **Dual User Types (Child/Parent)**

**Decision:** Separate authentication flows for children and parents.

**Justification:**
- **Child simplicity:** Children log in with username only (no password)
- **Parent security:** Parents have full account security with password reset
- **Privacy:** Parents can only see their linked children's data
- **UX optimization:** Each user type has tailored interface

### 6. **Character-Based Flow (Investigation vs Library)**

**Decision:** Two distinct modes for character interactions.

**Justification:**
- **Investigation mode:** Quick daily check-in with "how do you feel now?" questions
- **Library mode:** Educational exploration with scenario-based questions
- **Flexibility:** Same character pages support both modes via `fromCharacterLibrary` flag
- **Data differentiation:** Logs indicate which mode was used

### 7. **SharedPreferences for Local State**

**Decision:** Use SharedPreferences for user session persistence.

**Justification:**
- **Simplicity:** No complex state management setup
- **Persistence:** Session survives app restarts
- **Cross-platform:** Works on web, iOS, Android
- **Lightweight:** Perfect for small key-value data

### 8. **Docker Containerization**

**Decision:** Containerize backend services with Docker Compose.

**Justification:**
- **Reproducibility:** "Works on my machine" problem eliminated
- **Easy setup:** Single `docker-compose up` starts everything
- **Environment parity:** Local matches production configuration
- **Database isolation:** Each developer has independent database

---

## Extensibility Guide

### Adding a New Character

1. **Database:**
   ```sql
   INSERT INTO characters (character_name, character_photo, character_description)
   VALUES ('New Character Name', <binary_data>, 'Description...');
   ```

2. **Frontend (create new page):**
   ```dart
   // lib/pages/new_character.dart
   class NewCharacterPage extends StatefulWidget {
     final bool fromCharacterLibrary;
     const NewCharacterPage({Key? key, this.fromCharacterLibrary = false}) : super(key: key);
     // ... implement similar to heartbeat_page.dart
   }
   ```

3. **Add to Character Library:**
   Update `character_library_page.dart` to include navigation to new character.

4. **Add to Investigation Flow:**
   Update the last character's `_nextQuestion()` to navigate to new character.

### Adding a New Service

1. Create `lib/services/new_service.dart`:
   ```dart
   class NewService {
     static const String _query = '''
       query { ... }
     ''';
     
     static Future<Result> fetchData() async {
       // Implementation
     }
   }
   ```

2. Import and use in pages as needed.

### Adding a New GraphQL Query/Mutation

1. **Backend (`index.js`):**
   ```javascript
   // Add to typeDefs
   type Query {
     newQuery(param: String!): ReturnType
   }
   
   // Add to resolvers
   Query: {
     newQuery: async (_, { param }) => {
       // Implementation
     }
   }
   ```

2. **Frontend:**
   Create corresponding service method using `gql()`.

### Adding a New Database Table

1. **Create migration in `scripts/`:**
   ```sql
   CREATE TABLE IF NOT EXISTS new_table (
     id SERIAL PRIMARY KEY,
     -- columns
   );
   ```

2. **Update GraphQL schema** in `index.js`

3. **Create resolvers** for new queries/mutations

---

## Code Organization

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `child_profile_page.dart` |
| Classes | PascalCase | `ChildProfilePage` |
| Variables | camelCase | `childName` |
| Constants | SCREAMING_SNAKE | `MAX_LEVEL` |
| Private members | _prefix | `_loadData()` |

### File Header Comment Template

Each file should include a header comment:

```dart
/// ============================================================================
/// File: filename.dart
/// Project: FBI App (Feelings and Body Investigation)
/// 
/// Description: Brief description of what this file does
/// 
/// Author(s): [Team Member Names]
/// Created: [Date]
/// Last Modified: [Date]
/// ============================================================================
```

### Import Organization

```dart
// 1. Dart SDK imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:graphql_flutter/graphql_flutter.dart';

// 4. Local imports
import '../services/user_state_service.dart';
```

---

## Testing

### Backend Tests

```bash
cd backend
npm test
```

Tests cover:
- Database connection
- GraphQL resolvers (queries, mutations, nested resolvers)
- Email configuration

### Frontend Tests

```bash
cd fbi_app
flutter test
```

Test files located in `fbi_app/test/`:
- `child_login_test.dart`
- `child_profile_test.dart`
- `child_signup_test.dart`
- `parent_login_test.dart`
- `parent_signup_test.dart`
- `forgot_password_test.dart`
- `parent_view_child_test.dart`

---

## Deployment

### Local Development

```bash
# Start backend
cd backend
docker-compose up -d
npm run seed-test-data
npm run populate-characters

# Start frontend
cd fbi_app
flutter run
```

### Production

- **Frontend:** Netlify (https://fbiapp1.netlify.app/)
- **Backend:** Railway (https://tender-wisdom-production-fe18.up.railway.app/graphql)

See `README.md` for detailed deployment instructions.

---

## Additional Resources

- **GraphQL API Docs:** `backend/docs/graphql-api.md`
- **User Documentation:** `doc/User_Documentation.pdf`
- **App Maintenance:** `doc/App_Maintenance.pdf`

---

*This documentation is maintained in the `doc/` folder of the repository.*
