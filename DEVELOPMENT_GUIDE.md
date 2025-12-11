# FBI App - Development Guide

This guide provides information for future development work on the FBI App. It covers setting up a development environment, understanding the codebase, and making changes.

---

## Table of Contents

1. [Setting Up Development Environment](#setting-up-development-environment)
2. [Code Structure Overview](#code-structure-overview)
3. [Making Simple Changes](#making-simple-changes)
4. [Testing Procedures](#testing-procedures)
5. [Code Review Process](#code-review-process)
6. [Development Best Practices](#development-best-practices)

---

## Setting Up Development Environment

### Prerequisites

Before you can develop, you need:

1. **Node.js** (v14 or higher)
   - Download: https://nodejs.org/
   - Verify: Run `node --version` in terminal

2. **Flutter SDK** (2.19.0 or higher)
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: Run `flutter --version` in terminal

3. **PostgreSQL** (or use Docker)
   - Download: https://www.postgresql.org/download/
   - Or use Docker (recommended)

4. **Git**
   - Download: https://git-scm.com/downloads
   - Verify: Run `git --version` in terminal

5. **Code Editor**
   - Recommended: Visual Studio Code
   - Or: Android Studio, IntelliJ IDEA

### Initial Setup

#### 1. Clone the Repository

```bash
# Clone the repository
git clone [REPOSITORY_URL]
cd app_fbi
```

#### 2. Set Up Backend

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create .env file
# Copy the example below and fill in your values
cat > .env << EOF
DB_CONNECTION_STRING=postgresql://user:password@localhost:5432/appdb
NODE_ENV=development
EOF

# Start database with Docker
docker compose up -d

# Initialize database
npm run init-db

# Populate character data
npm run populate-characters

# Seed test data (optional)
npm run seed-test-data

# Upload audio files
npm run upload-audio

# Start backend server
npm start
```

The backend will run on: http://localhost:3000

#### 3. Set Up Frontend

```bash
# Navigate to frontend directory
cd ../fbi_app

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run -d chrome
```

The frontend will open in your browser.

### Development URLs

- **Frontend (local):** http://localhost:PORT (Flutter assigns port)
- **Backend API (local):** http://localhost:3000/graphql
- **GraphQL Playground:** http://localhost:3000/graphql

---

## Code Structure Overview

### Repository Structure

```
app_fbi/
├── backend/                 # Node.js backend
│   ├── __tests__/          # Test files
│   ├── scripts/            # Database scripts
│   ├── docs/               # API documentation
│   ├── index.js            # Main server file
│   ├── db.js               # Database connection
│   ├── email-config.js     # Email configuration
│   └── package.json        # Dependencies
│
├── fbi_app/                # Flutter frontend
│   ├── lib/
│   │   ├── main.dart       # App entry point
│   │   ├── pages/          # UI pages
│   │   ├── services/       # Business logic
│   │   └── widgets/        # Reusable components
│   ├── test/               # Test files
│   └── pubspec.yaml        # Dependencies
│
└── doc/                    # Documentation
```

### Backend Structure

#### Key Files

- **`backend/index.js`**: Main server file, GraphQL schema and resolvers
- **`backend/db.js`**: Database connection configuration
- **`backend/email-config.js`**: Email service configuration
- **`backend/scripts/01_init.sql`**: Database schema
- **`backend/scripts/init-db.js`**: Database initialization script

#### GraphQL API

The backend uses GraphQL for the API. Key concepts:

- **Queries**: Read data (e.g., get child profile, get characters)
- **Mutations**: Write data (e.g., create parent, log feeling)
- **Types**: Data structures (Child, Parent, Character, Log)

See `backend/docs/graphql-api.md` for full API documentation.

### Frontend Structure

#### Key Files

- **`fbi_app/lib/main.dart`**: App entry point, sets up GraphQL client
- **`fbi_app/lib/pages/`**: All UI pages
  - `home_page.dart`: Main home screen
  - `child_login_page.dart`: Child authentication
  - `parent_login_page.dart`: Parent authentication
  - `character_library_page.dart`: Character selection
  - Character pages: `heartbeat_page.dart`, `butterfly.dart`, etc.
- **`fbi_app/lib/services/`**: Business logic
  - `character_service.dart`: Character data fetching
  - `logging_service.dart`: Feeling log submission
  - `user_state_service.dart`: User session management

#### State Management

The app uses:
- **GetX** for state management
- **GraphQL Flutter** for API communication
- **SharedPreferences** for local storage

---

## Making Simple Changes

### Changing Text or Labels

**Example: Change a button label**

1. Find the file (usually in `fbi_app/lib/pages/`)
2. Search for the text you want to change
3. Edit the text
4. Save and test

**File:** `fbi_app/lib/pages/home_page.dart`
```dart
// Find this line:
label: Text('Character Library'),

// Change to:
label: Text('My Characters'),
```

### Changing Colors

**Example: Change app theme color**

**File:** `fbi_app/lib/main.dart`
```dart
// Find this line:
theme: ThemeData(primarySwatch: Colors.red),

// Change to:
theme: ThemeData(primarySwatch: Colors.blue),
```

### Adding a New Character

1. **Add character image:**
   - Place image in `fbi_app/data/characters/`
   - Format: PNG file, descriptive name

2. **Populate database:**
   ```bash
   cd backend
   # Edit scripts/populate-characters.js to add new character
   npm run populate-characters
   ```

3. **Add character page (if needed):**
   - Create new file in `fbi_app/lib/pages/`
   - Follow pattern from existing character pages
   - Add navigation in `character_library_page.dart`

### Updating API Endpoint

If you need to change the backend URL:

**File:** `fbi_app/lib/main.dart` (line 25)
```dart
link: HttpLink('https://your-new-backend-url.com/graphql'),
```

**File:** `fbi_app/lib/services/character_service.dart` (line 4)
```dart
static const String _graphqlEndpoint = 'https://your-new-backend-url.com/graphql';
```

---

## Testing Procedures

### Running Tests

#### Backend Tests

```bash
cd backend

# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# View coverage report
# Open backend/coverage/lcov-report/index.html in browser
```

#### Frontend Tests

```bash
cd fbi_app

# Run all tests
flutter test

# Run specific test file
flutter test test/child_login_test.dart

# Run tests with coverage
flutter test --coverage
```

### Manual Testing Checklist

Before deploying, test:

- [ ] Application loads correctly
- [ ] Child can log in
- [ ] Parent can log in
- [ ] Character library displays
- [ ] Can interact with characters
- [ ] Feeling logging works
- [ ] Parent can view child data
- [ ] Data export works
- [ ] Password reset works (if configured)
- [ ] No console errors
- [ ] No errors in Railway logs

### Testing on Different Browsers

Test the web app on:
- Chrome
- Firefox
- Safari
- Edge

---

## Code Review Process

### Before Submitting Changes

1. **Test your changes:**
   - Run all tests
   - Test manually
   - Check for errors

2. **Check code quality:**
   - Follow existing code style
   - Add comments for complex logic
   - Remove debug code

3. **Update documentation:**
   - Update relevant docs if needed
   - Add comments in code

### Submitting Changes

1. **Create a branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Edit files
   - Test changes
   - Commit changes

3. **Commit changes:**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

4. **Push to repository:**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create pull request:**
   - Go to repository on GitLab/GitHub
   - Create pull request
   - Describe your changes
   - Request review

### Code Review Checklist

Reviewers should check:

- [ ] Code follows project style
- [ ] Tests pass
- [ ] No obvious bugs
- [ ] Documentation updated
- [ ] No security issues
- [ ] Performance considerations
- [ ] Error handling is appropriate

---


### Git Workflow

1. **Create feature branches:**
   - Don't work directly on main branch
   - Use descriptive branch names

2. **Commit often:**
   - Small, logical commits
   - Clear commit messages

3. **Keep main branch stable:**
   - Only merge tested code
   - Use pull requests for review

### Error Handling

Always handle errors:

**Backend:**
```javascript
try {
  // Your code
} catch (error) {
  console.error('Error:', error);
  throw new Error('User-friendly error message');
}
```

**Frontend:**
```dart
try {
  // Your code
} catch (e) {
  print('Error: $e');
  // Show user-friendly error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Something went wrong')),
  );
}
```

### Security Considerations

1. **Never commit secrets:**
   - Don't commit `.env` files
   - Don't commit API keys
   - Use environment variables

2. **Validate user input:**
   - Check all user inputs
   - Sanitize data
   - Use parameterized queries

3. **Handle authentication:**
   - Verify user permissions
   - Don't expose sensitive data
   - Use secure password hashing (already implemented)

---

## Common Development Tasks

### Adding a New Feature

1. **Plan the feature:**
   - Define requirements
   - Design data structure
   - Plan UI/UX

2. **Update database (if needed):**
   - Create migration script
   - Update schema
   - Test migration

3. **Update backend:**
   - Add GraphQL types
   - Add resolvers
   - Add tests

4. **Update frontend:**
   - Create UI components
   - Add service methods
   - Connect to API

5. **Test thoroughly:**
   - Unit tests
   - Integration tests
   - Manual testing

6. **Deploy:**
   - Follow deployment guide
   - Test in production
   - Monitor for issues

### Debugging

#### Backend Debugging

1. **Check logs:**
   ```bash
   # View Railway logs
   # Or run locally and check console
   npm start
   ```

2. **Use console.log:**
   ```javascript
   console.log('Debug:', variable);
   ```

3. **Use debugger:**
   ```javascript
   debugger; // Pauses execution
   ```

#### Frontend Debugging

1. **Use browser DevTools:**
   - Press F12
   - Check Console tab
   - Check Network tab

2. **Use print statements:**
   ```dart
   print('Debug: $variable');
   ```

3. **Use Flutter DevTools:**
   - Run: `flutter run`
   - Open DevTools
   - Inspect widgets

---

## Resources

### Documentation

- **Flutter:** https://flutter.dev/docs
- **GraphQL:** https://graphql.org/learn/
- **Node.js:** https://nodejs.org/docs
- **PostgreSQL:** https://www.postgresql.org/docs/

### Project Documentation

- **API Documentation:** `backend/docs/graphql-api.md`
- **Maintenance Guide:** `MAINTENANCE_GUIDE.md`
- **Deployment Guide:** `DEPLOYMENT_GUIDE.md`
- **Troubleshooting:** `TROUBLESHOOTING_GUIDE.md`

### Tools

- **GraphQL Playground:** http://localhost:3000/graphql (local)
- **Railway Dashboard:** https://railway.app/
- **Netlify Dashboard:** https://app.netlify.com/

---

## Getting Help

If you need help with development:

1. **Check documentation** first
2. **Review existing code** for examples
3. **Check error messages** carefully
4. **Contact support** (see `SUPPORT_CONTACTS.md`)

---

## Quick Reference

### Common Commands

```bash
# Backend
cd backend
npm install          # Install dependencies
npm start            # Start server
npm test             # Run tests
npm run init-db      # Initialize database

# Frontend
cd fbi_app
flutter pub get      # Install dependencies
flutter run          # Run app
flutter test         # Run tests
flutter build web    # Build for web
```

### Key File Locations

- **Backend API:** `backend/index.js`
- **Database Schema:** `backend/scripts/01_init.sql`
- **Frontend Entry:** `fbi_app/lib/main.dart`
- **Character Service:** `fbi_app/lib/services/character_service.dart`
- **GraphQL Endpoint:** Configured in `fbi_app/lib/main.dart`

---

**Document Version:** 1.0  
**Last Updated:** December 2025

