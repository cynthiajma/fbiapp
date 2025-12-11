# FBI App - Deployment Guide

This guide explains how to update and deploy changes to your FBI App. Follow these steps carefully to ensure your application updates successfully.

---

## Table of Contents

1. [Understanding Deployment](#understanding-deployment)
2. [Updating the Frontend (Netlify)](#updating-the-frontend-netlify)
3. [Updating the Backend (Railway)](#updating-the-backend-railway)
4. [Environment Variables](#environment-variables)
5. [Database Updates](#database-updates)
6. [Rolling Back Changes](#rolling-back-changes)
7. [Testing After Deployment](#testing-after-deployment)

---

## Understanding Deployment

### What is Deployment?

Deployment is the process of making your updated code live on the internet so users can access the new version.

### Your Deployment Setup

- **Frontend (Web App):** Deployed on Netlify
- **Backend (API):** Deployed on Railway
- **Database:** Hosted on Railway (PostgreSQL)

### How Updates Work

1. **Code Changes:** Developers make changes to the code
2. **Push to Repository:** Changes are saved to Git repository
3. **Automatic Deployment:** Railway and Netlify automatically detect changes and deploy
4. **Verification:** You test to make sure everything works

---

## Updating the Frontend (Netlify)

### Automatic Deployment (Recommended)

If your Git repository is connected to Netlify, updates happen automatically:

1. **Changes are pushed to the repository**
2. **Netlify detects the changes**
3. **Netlify automatically builds and deploys**
4. **You receive a notification when deployment completes**

**To check automatic deployment:**
1. Log into Netlify: https://app.netlify.com/
2. Select your site (fbiapp1)
3. Go to "Deploys" tab
4. You'll see the deployment status and history

### Manual Deployment

If automatic deployment isn't set up, you can deploy manually:

#### Option 1: Using Netlify Dashboard

1. **Log into Netlify:** https://app.netlify.com/
2. **Select your site**
3. **Go to "Deploys" tab**
4. **Click "Trigger deploy"** → **"Deploy site"**
5. **Wait for deployment to complete** (usually 2-5 minutes)

#### Option 2: Using Netlify CLI (Advanced)

If you have the code locally and Netlify CLI installed:

```bash
# Navigate to your project
cd /path/to/app_fbi

# Build the Flutter web app
cd fbi_app
flutter build web

# Deploy to Netlify
cd ..
netlify deploy --prod --dir=fbi_app/build/web
```

**Note:** This requires Netlify CLI to be installed and configured. See `DEVELOPMENT_GUIDE.md` for setup instructions.

### Frontend Build Configuration

Netlify is configured with:
- **Build command:** `cd fbi_app && flutter build web`
- **Publish directory:** `fbi_app/build/web`

These settings are in your Netlify site settings under "Build & deploy".

---

## Updating the Backend (Railway)

### Automatic Deployment

Railway automatically deploys when you push changes to your Git repository:

1. **Changes are pushed to the repository**
2. **Railway detects changes in the `backend/` directory**
3. **Railway automatically:**
   - Installs dependencies (`npm install`)
   - Builds the application
   - Deploys the new version
   - Restarts the service

**To check automatic deployment:**
1. Log into Railway: https://railway.app/
2. Select your project
3. Click on the backend service
4. Go to "Deployments" tab
5. You'll see deployment history and status

### Manual Deployment

If you need to trigger a manual deployment:

1. **Log into Railway:** https://railway.app/
2. **Select your project**
3. **Click on the backend service**
4. **Go to "Settings" tab**
5. **Click "Redeploy"** or **"Deploy"**
6. **Wait for deployment to complete** (usually 2-5 minutes)

### Backend Deployment Process

When Railway deploys your backend:

1. **Pulls latest code** from Git repository
2. **Installs dependencies** (`npm install`)
3. **Starts the application** (`node index.js`)
4. **Health check** verifies the service is running
5. **Traffic is routed** to the new deployment

**Note:** During deployment, there may be a brief period (30-60 seconds) where the service is unavailable.

---

## Environment Variables

### What Are Environment Variables?

Environment variables are configuration settings that tell your application how to behave. They're stored securely and not in your code.

### Managing Environment Variables in Railway

1. **Log into Railway:** https://railway.app/
2. **Select your project**
3. **Click on the service** (backend or database)
4. **Go to "Variables" tab**
5. **You can:**
   - View existing variables
   - Add new variables
   - Edit existing variables
   - Delete variables

### Important Environment Variables

#### Backend Service Variables

**Required:**
- `DATABASE_URL` - Automatically provided by Railway (don't change)
- `NODE_ENV=production` - Tells the app it's in production mode

**Optional (for email):**
- `SENDGRID_API_KEY` - API key for SendGrid email service
- `EMAIL_FROM` - Email address for sending emails

#### How to Update Environment Variables

1. **Go to Railway dashboard**
2. **Select your backend service**
3. **Click "Variables" tab**
4. **Click "New Variable"** to add, or click existing variable to edit
5. **Enter the variable name and value**
6. **Click "Add" or "Update"**
7. **Railway will automatically restart the service** with new variables

**Important:** After changing environment variables, the service will restart. This causes a brief downtime (30-60 seconds).

---

## Database Updates

### When Database Updates Are Needed

Database updates are needed when:
- Adding new features that require new data tables
- Changing how data is stored
- Adding new character data
- Updating existing data structures

### Running Database Scripts

Database updates are done through initialization scripts:

1. **Connect to Railway database** (via Railway dashboard or database client)
2. **Run SQL scripts** from `backend/scripts/` directory
3. **Verify changes** were applied correctly

### Common Database Tasks

#### Populating Character Data

If you need to add or update characters:

1. **Ensure character images are in:** `fbi_app/data/characters/`
2. **Run the populate script:**
   ```bash
   cd backend
   npm run populate-characters
   ```

#### Seeding Test Data

To add test data (for development/testing):

```bash
cd backend
npm run seed-test-data
```

**Warning:** Only run this in development. Don't run in production unless you want test data.

#### Uploading Audio Files

To add character audio:

1. **Place audio files in:** `fbi_app/data/audio/`
2. **Run the upload script:**
   ```bash
   cd backend
   npm run upload-audio
   ```

### Database Backups

**Before making database changes:**
1. Verify backups are enabled in Railway
2. Note the current backup status
3. Consider creating a manual backup if making significant changes

**How to restore from backup:**
- Contact Railway support or see Railway documentation
- Or contact development team for assistance

---

## Rolling Back Changes

### What is Rolling Back?

Rolling back means going back to a previous version of your application when something goes wrong.

### Rolling Back Frontend (Netlify)

1. **Log into Netlify:** https://app.netlify.com/
2. **Select your site**
3. **Go to "Deploys" tab**
4. **Find the deployment you want to go back to**
5. **Click the "..." menu** (three dots) next to that deployment
6. **Select "Publish deploy"**
7. **Confirm the rollback**

**Note:** Netlify keeps deployment history, so you can roll back to any previous deployment.

### Rolling Back Backend (Railway)

1. **Log into Railway:** https://railway.app/
2. **Select your project**
3. **Click on the backend service**
4. **Go to "Deployments" tab**
5. **Find the deployment you want to go back to**
6. **Click "Redeploy"** on that deployment

**Note:** Railway keeps deployment history, allowing you to redeploy previous versions.


## Testing After Deployment

### Always Test After Deployment

After any deployment, you should test to make sure everything works.

### Testing Checklist

#### Basic Functionality
- [ ] Application loads in browser
- [ ] Login page appears
- [ ] Can log in as a test user
- [ ] Home page displays correctly
- [ ] Navigation works

#### Key Features
- [ ] Character library loads
- [ ] Can interact with characters
- [ ] Feeling logging works
- [ ] Parent can view child data
- [ ] Data export works (if applicable)

#### Backend API
- [ ] API endpoint is accessible
- [ ] GraphQL playground loads (if enabled)
- [ ] No errors in Railway logs
- [ ] Database connections work


## Quick Reference

### Deployment URLs
- **Frontend:** https://fbiapp1.netlify.app/
- **Backend API:** https://tender-wisdom-production-fe18.up.railway.app/graphql
- **Railway Dashboard:** https://railway.app/
- **Netlify Dashboard:** https://app.netlify.com/

### Key Commands (if working locally)
```bash
# Build frontend
cd fbi_app
flutter build web

# Deploy to Netlify (if CLI installed)
netlify deploy --prod --dir=fbi_app/build/web
```

### Important Files
- **This Guide:** `DEPLOYMENT_GUIDE.md`
- **Development:** `DEVELOPMENT_GUIDE.md`

---

**Document Version:** 1.0  
**Last Updated:** December 2025

