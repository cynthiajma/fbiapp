# CompSci 408 App

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

3. Start the database with Docker:
   ```bash
   docker-compose up -d
   ```

4. Initialize the database:
   ```bash
   npm run init-db
   ```

5. Start the backend server:
   ```bash
   npm start
   ```

The backend will be available at `http://localhost:4000`

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
