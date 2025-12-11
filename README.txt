================================================================================
FEELINGS AND BODY INVESTIGATION (FBI) APP
================================================================================

PROJECT PURPOSE
================================================================================
Feelings and Body Investigation (FBI) is an educational app designed to help 
children learn about their bodies and emotions through interactive 
character-based experiences. The app was developed as part of CompSci 408 at 
Duke University with Dr. Nancy Zucker, Professor of Psychiatry and Behavioral 
Sciences at Duke, based on her practical handbook "Treating Functional 
Abdominal Pain in Children."

The app features interactive characters that help children:
- Understand and track their physical sensations (heartbeat, temperature, etc.)
- Log their feelings and emotions as they complete body investigations
- Learn about their body's signals through engaging character interactions
- Share their data with parents/guardians for monitoring

The application consists of:
- A Flutter frontend web application for children and parents
- A Node.js backend with GraphQL API
- A PostgreSQL database for data storage

================================================================================
PROJECT STRUCTURE
================================================================================
- backend/          - Node.js backend with GraphQL API
- fbi_app/          - Flutter frontend application
- Icon.png          - Project logo

================================================================================
DEPENDENCIES
================================================================================

BACKEND DEPENDENCIES (Node.js)
-------------------------------
Required packages (see backend/package.json):
- @apollo/server: ^4.9.5        - GraphQL server
- @sendgrid/mail: ^8.1.3        - Email service for password reset
- bcryptjs: ^2.4.3              - Password hashing
- cors: ^2.8.5                  - Cross-origin resource sharing
- dotenv: ^16.3.1               - Environment variable management
- express: ^4.18.2              - Web framework
- graphql: ^16.11.0             - GraphQL implementation
- pg: ^8.11.3                   - PostgreSQL client

Development dependencies:
- jest: ^30.2.0                 - Testing framework
- @jest/globals: ^30.2.0        - Jest globals

System Requirements:
- Node.js (v14 or higher recommended)
- PostgreSQL database
- npm or yarn package manager

FRONTEND DEPENDENCIES (Flutter)
--------------------------------
Required packages (see fbi_app/pubspec.yaml):
- flutter: SDK
- google_fonts: ^6.1.0           - Custom fonts
- fluttermoji: ^1.0.0           - Avatar creation
- avatar_maker: ^0.2.0          - Avatar customization
- get: ^4.6.6                   - State management
- graphql_flutter: ^5.1.2       - GraphQL client
- http: ^1.1.0                  - HTTP requests
- flutter_svg: ^2.0.10+1        - SVG support
- shared_preferences: ^2.2.0     - Local storage
- audioplayers: ^5.2.1          - Audio playback
- path_provider: ^2.1.1         - File system paths
- share_plus: ^7.2.1            - File sharing
- email_validator: ^2.1.17      - Email validation
- showcaseview: ^3.0.0          - Tutorial overlays
- fl_chart: ^0.66.0             - Charts and graphs

System Requirements:
- Flutter SDK (2.19.0 or higher)
- Dart SDK (included with Flutter)
- For web deployment: Flutter web support enabled

================================================================================
DEPLOYMENT OVERVIEW
================================================================================

CURRENT PRODUCTION DEPLOYMENT
-----------------------------
The application is currently deployed using the following services:

1. RAILWAY (Backend & Database)
   - PostgreSQL database hosted on Railway
   - Node.js backend API deployed on Railway
   - GraphQL endpoint: https://tender-wisdom-production-fe18.up.railway.app/graphql
   - Automatic deployments from Git repository

2. NETLIFY (Frontend)
   - Flutter web application deployed on Netlify
   - Frontend URL: https://fbiapp1.netlify.app/
   - Static site hosting with automatic builds

DEPLOYMENT ARCHITECTURE
-----------------------
┌─────────────────┐         ┌──────────────────┐
│   NETLIFY       │         │    RAILWAY       │
│                 │         │                  │
│  Flutter Web    │────────▶│  Node.js Backend │
│  Application    │  HTTP   │  GraphQL API     │
│                 │         │                  │
└─────────────────┘         └────────┬─────────┘
                                      │
                                      ▼
                              ┌──────────────────┐
                              │    RAILWAY       │
                              │                  │
                              │  PostgreSQL DB   │
                              │                  │
                              └──────────────────┘

BACKEND DEPLOYMENT (Railway)
----------------------------
1. Connect your Git repository to Railway
2. Create a new PostgreSQL service in Railway
3. Create a new Node.js service in Railway
4. Link the PostgreSQL service to the Node.js service
5. Set the following environment variables in Railway:

   Required Environment Variables:
   - DATABASE_URL (automatically provided by Railway PostgreSQL service)
   - NODE_ENV=production
   - PORT=3000 (Railway may override this automatically)

   Optional (for password reset emails):
   - SENDGRID_API_KEY=your-sendgrid-api-key
   - EMAIL_FROM=your-verified-email@domain.com

6. Railway will automatically:
   - Detect the Node.js project in the backend/ directory
   - Install dependencies (npm install)
   - Build and deploy the application
   - Restart on code changes

7. Initialize the database in production:
   - Connect to Railway PostgreSQL database
   - Run initialization scripts:
     * npm run init-db
     * npm run populate-characters
     * npm run seed-test-data (optional)
     * npm run upload-audio

FRONTEND DEPLOYMENT (Netlify)
-----------------------------
1. Build the Flutter web application:
   cd fbi_app
   flutter build web

2. Deploy to Netlify:
   Option A - Manual Deployment:
   - Log into Netlify dashboard
   - Drag and drop the fbi_app/build/web folder
   - Or use Netlify CLI: netlify deploy --prod --dir=fbi_app/build/web

   Option B - Continuous Deployment:
   - Connect Git repository to Netlify
   - Set build command: cd fbi_app && flutter build web
   - Set publish directory: fbi_app/build/web
   - Netlify will automatically build and deploy on git push

3. Configure environment (if needed):
   - Update API endpoint in Flutter code to point to Railway backend
   - Ensure CORS is configured on backend to allow Netlify domain

CONFIGURATION NOTES
-------------------
- CORS must be configured on the backend to allow requests from the Netlify 
  frontend domain
- The production database is separate from local development database
- Character data and test data need to be initialized separately in production
- Email functionality (password reset) requires SendGrid API key configuration
- Without email configuration, password reset will fail but other features work

UPDATING PRODUCTION
-------------------
Backend Updates:
- Push changes to the backend/ directory
- Railway automatically detects changes and redeploys

Frontend Updates:
- Build: cd fbi_app && flutter build web
- Deploy the build/web folder to Netlify
- Or use continuous deployment if Git is connected

================================================================================
LOCAL DEVELOPMENT SETUP
================================================================================

BACKEND SETUP
-------------
OPTION 1: Automated Rebuild (Recommended)
Use the rebuild script for complete automated setup:
  ./rebuild-server.sh

This script handles all setup steps automatically. See REBUILD_SERVER_GUIDE.md
for detailed instructions.

OPTION 2: Manual Setup
1. Navigate to backend directory: cd backend
2. Install dependencies: npm install
3. Create .env file with database connection string
4. Start with Docker Compose: docker compose up -d
5. Initialize database: npm run init-db
6. Seed test data: npm run seed-test-data (optional)
7. Populate characters: npm run populate-characters
8. Upload audio: npm run upload-audio

FRONTEND SETUP
--------------
1. Navigate to Flutter app directory: cd fbi_app
2. Install dependencies: flutter pub get
3. Run the app: flutter run

For more detailed setup instructions, see README.md

================================================================================
CONTACT & SUPPORT
================================================================================
This project was developed as part of CompSci 408 at Duke University.

Development Team:
- Cynthia Ma
- Linda Wang
- Sean Rogers
- Kyle McCutchen

For issues or questions, please refer to the project repository or contact
the development team.

================================================================================

