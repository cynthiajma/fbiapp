# FBI App - Comprehensive Test Plan

## Document Information
- **Project**: Feelings and Body Investigation (FBI) App
- **Version**: 1.0
- **Last Updated**: November 6, 2025
- **Test Coverage Goal**: 80%+

## Table of Contents
1. [Overview](#overview)
2. [Testing Strategy](#testing-strategy)
3. [Test Type Distribution](#test-type-distribution)
4. [Test Scenarios by Feature](#test-scenarios-by-feature)
5. [Test Data Requirements](#test-data-requirements)
6. [Testing Recommendations](#testing-recommendations)
7. [Traceability Matrix](#traceability-matrix)

---

## Overview

This test plan covers all major features of the FBI (Feelings and Body Investigation) app, a health tracking application for children with a detective theme. The app allows children to log their feelings using body-based characters and enables parents to monitor their child's emotional and physical states.

**Key Stakeholders:**
- Children (primary users, ages 5-12)
- Parents (monitoring and oversight)

---

## Testing Strategy

### Test Pyramid Approach
Our testing follows the standard test pyramid with emphasis on fast, reliable unit tests at the base and comprehensive integration coverage in the middle layer.

### Test Objectives
1. Ensure all user workflows function correctly
2. Validate data integrity across frontend and backend
3. Verify security and authentication mechanisms
4. Confirm proper error handling and user feedback
5. Test edge cases and boundary conditions

---

## Test Type Distribution

### Recommended Coverage
- **Unit Tests: 40%** - Service layer, data models, utilities, widget logic
- **Integration Tests: 35%** - API interactions, database operations, GraphQL queries
- **End-to-End UI Tests: 25%** - Complete user workflows across multiple screens

### Testing Frameworks
- **Unit Tests**: flutter_test, mockito
- **Integration Tests**: flutter_test with http mocking
- **E2E Tests**: integration_test package
- **Code Coverage**: flutter test --coverage

---

## Test Scenarios by Feature

---

## Feature 1: Child Authentication

### Test ID: CHILD-AUTH-001

**Feature**: Child Login

**Purpose**: Verify that a child can successfully log in with a valid username

**Test Type**: Integration

**Preconditions**:
- Database is initialized with test data
- Child with username "alice_child" exists in database
- Backend server is running on port 3000
- App is launched to child login screen

**Steps** (Gherkin):
```gherkin
Given I am on the child login page
When I enter "alice_child" in the username field
And I tap the "Login" button
Then I should be navigated to the home page
And the detective name should display "Alice"
And my session should be persisted
```

**Post-conditions**:
- User is authenticated and redirected to HomePage
- UserStateService contains child_id and child_name
- SharedPreferences stores login state

---

### Test ID: CHILD-AUTH-002

**Feature**: Child Login - Invalid Username

**Purpose**: Verify appropriate error handling when child enters non-existent username

**Test Type**: Integration

**Preconditions**:
- Database is initialized
- Backend server is running
- App is launched to child login screen

**Steps** (Gherkin):
```gherkin
Given I am on the child login page
When I enter "nonexistent_detective" in the username field
And I tap the "Login" button
Then I should see an error message "Detective name not found. Please try again or contact support."
And I should remain on the login page
And no session data should be stored
```

**Post-conditions**:
- User remains on login page
- Error message is displayed
- No authentication state is saved

---

### Test ID: CHILD-AUTH-003

**Feature**: Child Signup

**Purpose**: Verify successful child account creation with valid data

**Test Type**: Integration

**Preconditions**:
- Database is initialized
- Backend server is running
- App is on child signup page
- Username "new_detective" does not exist in database

**Steps** (Gherkin):
```gherkin
Given I am on the child signup page
When I enter "new_detective" in the username field
And I enter "Detective Nova" in the name field
And I enter "8" in the age field
And I tap the "Sign Up" button
Then a new child record should be created in the database
And I should be navigated to the home page
And the detective name should display "Detective Nova"
```

**Post-conditions**:
- New child record exists in database with provided data
- User is authenticated and redirected to HomePage
- Session state is persisted

---

### Test ID: CHILD-AUTH-004

**Feature**: Child Signup - Validation

**Purpose**: Verify that empty username is rejected during signup

**Test Type**: Unit

**Preconditions**:
- App is on child signup page

**Steps** (Gherkin):
```gherkin
Given I am on the child signup page
When I leave the username field empty
And I tap the "Sign Up" button
Then I should see an error message "Please enter a detective username"
And the signup should not proceed
And no API call should be made
```

**Post-conditions**:
- No database records created
- User remains on signup page
- Error message displayed

---

## Feature 2: Parent Authentication

### Test ID: PARENT-AUTH-001

**Feature**: Parent Login

**Purpose**: Verify successful parent login with valid credentials

**Test Type**: Integration

**Preconditions**:
- Database contains parent account: username "alice_mom", password "password123"
- Backend server is running
- App is on parent login page

**Steps** (Gherkin):
```gherkin
Given I am on the parent login page
When I enter "alice_mom" in the username field
And I enter "password123" in the password field
And I tap the "Login" button
Then the credentials should be verified via GraphQL loginParent mutation
And I should be navigated to the parent profile page
And the parent session should be stored
```

**Post-conditions**:
- Parent is authenticated
- Parent profile page displays with child's data
- Session persisted in SharedPreferences

---

### Test ID: PARENT-AUTH-002

**Feature**: Parent Login - Invalid Credentials

**Purpose**: Verify error handling for incorrect password

**Test Type**: Integration

**Preconditions**:
- Database contains parent account: username "alice_mom"
- Backend server is running
- App is on parent login page

**Steps** (Gherkin):
```gherkin
Given I am on the parent login page
When I enter "alice_mom" in the username field
And I enter "wrongpassword" in the password field
And I tap the "Login" button
Then I should see an error message "Incorrect password. Please try again."
And I should remain on the login page
And no session data should be stored
```

**Post-conditions**:
- User remains on login page
- Authentication fails
- No session state saved

---

### Test ID: PARENT-AUTH-003

**Feature**: Parent Signup with Child Linking

**Purpose**: Verify parent can create account and link to existing child

**Test Type**: Integration

**Preconditions**:
- Database contains child with username "alice_child" (ID: 1)
- Backend server is running
- Username "new_parent" does not exist
- App is on parent signup page

**Steps** (Gherkin):
```gherkin
Given I am on the parent signup page
When I enter "new_parent" in the username field
And I enter "SecurePass123" in the password field
And I enter "alice_child" in the child username field
And I tap the "Sign Up" button
Then a new parent record should be created with hashed password
And the parent should be linked to child ID 1 in parent_child_link table
And I should be navigated to the parent profile page
```

**Post-conditions**:
- New parent record created in database
- Password is hashed using bcrypt
- Parent-child link established
- User authenticated and redirected

---

### Test ID: PARENT-AUTH-004

**Feature**: Parent Signup - Invalid Child Username

**Purpose**: Verify error handling when linking to non-existent child

**Test Type**: Integration

**Preconditions**:
- Backend server is running
- Child username "fake_child" does not exist
- App is on parent signup page

**Steps** (Gherkin):
```gherkin
Given I am on the parent signup page
When I enter "parent_user" in the username field
And I enter "password123" in the password field
And I enter "fake_child" in the child username field
And I tap the "Sign Up" button
Then I should see an error message containing "Child username not found"
And no parent record should be created
And I should remain on the signup page
```

**Post-conditions**:
- No parent record created
- No database entries added
- Error message displayed to user

---

## Feature 3: Character Library

### Test ID: CHAR-LIB-001

**Feature**: Load Character Library

**Purpose**: Verify characters load and display correctly from backend

**Test Type**: Integration

**Preconditions**:
- Database contains 11 characters (populated via populate-characters script)
- Backend server is running
- User is authenticated as child
- App is on home page

**Steps** (Gherkin):
```gherkin
Given I am logged in as a child
When I tap the "Start Case" button on the home page
Then the character library page should load
And I should see a list of characters including "Henry the Heartbeat"
And each character should display a name and image
And the images should be decoded from base64 data
```

**Post-conditions**:
- Character library page is displayed
- All 11 characters are rendered
- Images are properly decoded and shown

---

### Test ID: CHAR-LIB-002

**Feature**: Character Library - Empty State

**Purpose**: Verify proper handling when no characters exist in database

**Test Type**: Integration

**Preconditions**:
- Database is initialized but characters table is empty
- Backend server is running
- User is authenticated as child

**Steps** (Gherkin):
```gherkin
Given the characters table is empty
When I navigate to the character library page
Then I should see a message "No characters available"
And a retry button should be displayed
```

**Post-conditions**:
- Empty state message is shown
- No character cards are rendered
- User can retry loading

---

### Test ID: CHAR-LIB-003

**Feature**: Navigate to Character Detail

**Purpose**: Verify navigation from character library to heartbeat page

**Test Type**: E2E

**Preconditions**:
- User is authenticated as child
- Character library is loaded with characters
- App displays character library page

**Steps** (Gherkin):
```gherkin
Given I am on the character library page
And I see "Henry the Heartbeat" character card
When I tap on the "Henry the Heartbeat" card
Then I should be navigated to the heartbeat page
And the page title should display "HOW FAST IS YOUR HENRY HEARTBEAT GOING?"
And audio controls should be visible in the app bar
```

**Post-conditions**:
- User is on heartbeat page
- Character-specific content is displayed
- Audio feature is available

---

## Feature 4: Heartbeat Tracking & Logging

### Test ID: HEARTBEAT-001

**Feature**: Adjust Heartbeat Speed

**Purpose**: Verify slider interaction updates heartbeat animation speed

**Test Type**: Unit

**Preconditions**:
- App is on heartbeat page
- Heartbeat animation is initialized

**Steps** (Gherkin):
```gherkin
Given I am on the heartbeat page
And the slider value is 0.5 (default)
When I drag the slider to value 1.0 (fast)
Then the heartbeat animation duration should update to 500 milliseconds
And the animation should speed up noticeably
```

**Post-conditions**:
- Slider value updated to 1.0
- Animation controller duration changed
- Heart icon animates faster

---

### Test ID: HEARTBEAT-002

**Feature**: Log Feeling Successfully

**Purpose**: Verify feeling can be logged to database with correct data

**Test Type**: Integration

**Preconditions**:
- User is authenticated as child with ID 1
- Backend server is running
- App is on heartbeat page with slider at 0.6

**Steps** (Gherkin):
```gherkin
Given I am on the heartbeat page
And my child ID is 1
And the slider is set to 0.6
When I tap the "Save" button
Then a GraphQL mutation should be sent to logFeeling endpoint
And the feeling_level should be 6 (slider value * 10)
And character_id should be 1 (Henry the Heartbeat)
And a success message "Feeling logged successfully!" should be displayed
And a new record should exist in the logging table
```

**Post-conditions**:
- New log entry in database with correct values
- Green snackbar confirmation displayed
- Button returns to enabled state

---

### Test ID: HEARTBEAT-003

**Feature**: Log Feeling - Missing Child ID

**Purpose**: Verify error handling when child ID is not available

**Test Type**: Unit

**Preconditions**:
- User session does not contain child_id
- App is on heartbeat page

**Steps** (Gherkin):
```gherkin
Given I am on the heartbeat page
And no child ID is stored in UserStateService
When I tap the "Save" button
Then I should see an error message "No child ID found. Please log in first."
And no API call should be made
And no database record should be created
```

**Post-conditions**:
- Error message displayed in red snackbar
- No network request sent
- User remains on page

---

### Test ID: HEARTBEAT-004

**Feature**: Heartbeat Slider Range

**Purpose**: Verify slider operates within expected bounds (0.0 to 1.0)

**Test Type**: Unit

**Preconditions**:
- App is on heartbeat page

**Steps** (Gherkin):
```gherkin
Given I am on the heartbeat page
When I attempt to set slider value below 0.0
Then the slider should clamp to 0.0
And when I attempt to set slider value above 1.0
Then the slider should clamp to 1.0
And the slider should have 5 divisions (6 discrete values)
```

**Post-conditions**:
- Slider value constrained between 0.0 and 1.0
- Only discrete values selectable

---

## Feature 5: Character Audio Playback

### Test ID: AUDIO-001

**Feature**: Play Character Audio

**Purpose**: Verify audio plays successfully when button is pressed

**Test Type**: Integration

**Preconditions**:
- Henry the Heartbeat has audio_file in database
- Audio data is available as base64
- User is on heartbeat page
- Audio is not currently playing

**Steps** (Gherkin):
```gherkin
Given I am on the heartbeat page
And character audio is loaded
And the speaker icon is displayed
When I tap the speaker icon
Then the audio should begin playing
And the icon should change to a pause icon
And a green snackbar should display "Audio playing..."
And the snackbar should persist until audio completes
```

**Post-conditions**:
- Audio is playing
- Play/pause button shows pause icon
- Snackbar visible at bottom of screen

---

### Test ID: AUDIO-002

**Feature**: Pause and Resume Audio

**Purpose**: Verify audio can be paused and resumed correctly

**Test Type**: Integration

**Preconditions**:
- User is on heartbeat page
- Audio is currently playing

**Steps** (Gherkin):
```gherkin
Given audio is playing
And the pause icon is displayed
When I tap the pause icon
Then the audio should pause
And the icon should change to a play arrow
And an orange snackbar should display "Audio paused"
And when I tap the play arrow icon
Then the audio should resume playing
And the icon should change back to pause
```

**Post-conditions**:
- Audio playback state toggles correctly
- Icons update appropriately
- User receives feedback via snackbars

---

### Test ID: AUDIO-003

**Feature**: Replay Audio from Beginning

**Purpose**: Verify replay button resets audio to start without auto-playing

**Test Type**: E2E

**Preconditions**:
- User is on heartbeat page
- Audio has been played or is currently playing

**Steps** (Gherkin):
```gherkin
Given audio is playing or has been played
When I tap the replay button (circular arrow icon)
Then the audio should stop
And the play button should change to speaker icon
And a blue snackbar should display "Audio reset to beginning"
And the audio should NOT automatically start playing
And when I tap the speaker icon
Then the audio should play from the beginning
```

**Post-conditions**:
- Audio position reset to 0:00
- Play button shows initial speaker icon
- Audio ready to play from start

---

## Feature 6: Parent Profile & Dashboard

### Test ID: PARENT-PROF-001

**Feature**: View Child's Logged Data

**Purpose**: Verify parent can see child's feeling logs with character information

**Test Type**: Integration

**Preconditions**:
- Parent is logged in (alice_mom)
- Parent is linked to child (alice_child, ID: 1)
- Child has 5 logged feelings in database
- Backend server is running

**Steps** (Gherkin):
```gherkin
Given I am logged in as a parent
And my child has logged feelings
When the parent profile page loads
Then I should see my child's name "Alice"
And I should see a list of logged feelings
And each log entry should display:
  | Field | Value |
  | Character Name | Henry the Heartbeat |
  | Feeling Level | 0-10 scale |
  | Timestamp | Date and time |
And the logs should be sorted by most recent first
```

**Post-conditions**:
- Parent profile page displays child data
- All logs are visible
- Data matches database records

---

### Test ID: PARENT-PROF-002

**Feature**: Parent Profile - No Logs Available

**Purpose**: Verify appropriate message when child has no logged data

**Test Type**: Integration

**Preconditions**:
- Parent is logged in
- Child account exists but has 0 log entries
- Backend server is running

**Steps** (Gherkin):
```gherkin
Given I am logged in as a parent
And my child has no logged feelings
When the parent profile page loads
Then I should see a message "No feelings logged yet"
And I should see an encouraging message to have child use the app
```

**Post-conditions**:
- Empty state message displayed
- No error occurs
- Page renders correctly

---

### Test ID: PARENT-PROF-003

**Feature**: Character Usage Statistics

**Purpose**: Verify parent can see which characters child uses most

**Test Type**: Integration

**Preconditions**:
- Parent is logged in
- Child has multiple log entries with different characters
- Backend server is running

**Steps** (Gherkin):
```gherkin
Given I am logged in as a parent
And my child has logged feelings with multiple characters
When the parent profile page loads
Then I should see character usage statistics
And characters should be grouped by frequency
And each character should show:
  | Field | Value |
  | Character Name | e.g., Henry the Heartbeat |
  | Times Used | Count of logs |
  | Character Image | Base64 decoded image |
```

**Post-conditions**:
- Statistics calculated correctly
- Characters displayed with images
- Data aggregated properly

---

## Feature 7: Child Profile

### Test ID: CHILD-PROF-001

**Feature**: View Own Profile

**Purpose**: Verify child can view their profile information

**Test Type**: E2E

**Preconditions**:
- Child is logged in (alice_child)
- Backend server is running

**Steps** (Gherkin):
```gherkin
Given I am logged in as a child
And I am on the home page
When I tap the profile/settings button
Then I should see my profile page
And my detective name should be displayed
And my age should be displayed
And my username should be shown
```

**Post-conditions**:
- Profile page renders
- Correct child data displayed
- User can navigate back to home

---

### Test ID: CHILD-PROF-002

**Feature**: Child Profile - Avatar Display

**Purpose**: Verify child's Fluttermoji avatar displays correctly

**Test Type**: Unit

**Preconditions**:
- Child is logged in
- Child has saved Fluttermoji configuration

**Steps** (Gherkin):
```gherkin
Given I am on the child profile page
And my Fluttermoji configuration is saved
When the page loads
Then my custom avatar should be displayed
And the avatar should match my saved configuration
```

**Post-conditions**:
- Avatar rendered with correct attributes
- Fluttermoji controller initialized
- Visual matches stored data

---

## Feature 8: Home Navigation

### Test ID: NAV-001

**Feature**: Navigate Between Pages

**Purpose**: Verify navigation flow works correctly throughout app

**Test Type**: E2E

**Preconditions**:
- Child is logged in
- App is on home page

**Steps** (Gherkin):
```gherkin
Given I am on the home page
When I tap "Start Case"
Then I should navigate to the character library
And when I tap the back button
Then I should return to the home page
And when I tap a character card
Then I should navigate to the heartbeat page
And when I tap the back button
Then I should return to the character library
```

**Post-conditions**:
- Navigation stack maintained correctly
- Back navigation works as expected
- No navigation errors occur

---

### Test ID: NAV-002

**Feature**: Session Persistence

**Purpose**: Verify user session persists across app restarts

**Test Type**: Integration

**Preconditions**:
- Child is logged in
- Session data stored in SharedPreferences

**Steps** (Gherkin):
```gherkin
Given I am logged in as a child
And I close the app completely
When I reopen the app
Then I should still be logged in
And I should land on the home page
And my detective name should still be displayed
And I should not be redirected to login page
```

**Post-conditions**:
- Session restored from SharedPreferences
- User remains authenticated
- No re-login required

---

## Test Data Requirements

### Database Test Data
The following test data should be seeded before running integration and E2E tests:

#### Children
```sql
INSERT INTO children (child_username, child_name, child_age) VALUES
  ('alice_child', 'Alice', 8),
  ('bob_child', 'Bob', 7),
  ('charlie_child', 'Charlie', 9);
```

#### Parents
```sql
INSERT INTO parents (parent_username, hashed_password) VALUES
  ('alice_mom', '$2b$10$hashed_password_here'),
  ('alice_dad', '$2b$10$hashed_password_here'),
  ('bob_mom', '$2b$10$hashed_password_here');
```

#### Parent-Child Links
```sql
INSERT INTO parent_child_link (parent_id, child_id) VALUES
  (1, 1), -- alice_mom -> alice_child
  (2, 1), -- alice_dad -> alice_child
  (3, 2); -- bob_mom -> bob_child
```

#### Characters
- Run `npm run populate-characters` to load 11 characters
- Optionally run `npm run upload-audio` to add audio files

#### Sample Logs
```sql
INSERT INTO logging (child_id, character_id, character_name, feeling_level) VALUES
  (1, 1, 'Henry the Heartbeat', 5),
  (1, 1, 'Henry the Heartbeat', 7),
  (1, 2, 'Samantha Sweat', 3);
```

### Mock Data for Unit Tests
- Use `mockito` to mock service responses
- Mock GraphQL client responses
- Mock SharedPreferences for state persistence tests

---

## Testing Recommendations

### Test Execution Order
1. **Unit Tests First** - Fast feedback on individual components
2. **Integration Tests** - Verify API and database interactions
3. **E2E Tests Last** - Complete workflow validation

### CI/CD Integration
```yaml
# Example GitLab CI configuration
test:
  stage: test
  script:
    - flutter test --coverage
    - genhtml coverage/lcov.info -o coverage/html
    - flutter test integration_test/
  coverage: '/lines\.*: \d+\.\d+%/'
  artifacts:
    paths:
      - coverage/
```

### Code Coverage Targets
- **Overall Target**: 80%+ lines covered
- **Critical Paths**: 95%+ (authentication, data logging)
- **UI Widgets**: 70%+ (focus on logic over rendering)
- **Services**: 90%+ (business logic must be well-tested)

### Testing Frameworks & Tools

#### Flutter Testing
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

#### Test Organization
```
test/
├── unit/
│   ├── services/
│   │   ├── child_auth_service_test.dart
│   │   ├── parent_auth_service_test.dart
│   │   ├── logging_service_test.dart
│   │   └── user_state_service_test.dart
│   └── widgets/
│       ├── char_row_test.dart
│       └── progress_ring_test.dart
├── integration/
│   ├── child_login_test.dart
│   ├── parent_login_test.dart
│   └── heartbeat_logging_test.dart
└── e2e/
    ├── complete_user_journey_test.dart
    └── navigation_flow_test.dart

integration_test/
└── app_test.dart
```

### Best Practices
1. **Isolate Tests** - Each test should be independent
2. **Clean Up** - Reset database state between tests
3. **Use Descriptive Names** - Test names should explain what they validate
4. **Mock External Dependencies** - Use mocks for network calls in unit tests
5. **Test Edge Cases** - Empty strings, null values, boundary conditions
6. **Parallel Execution** - Run unit tests in parallel for speed
7. **Fail Fast** - Stop on first failure during development
8. **Generate Reports** - Use coverage tools and save artifacts

### Running Tests
```bash
# Run all unit tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run specific test file
flutter test test/unit/services/child_auth_service_test.dart

# Run tests in watch mode (during development)
flutter test --watch
```

---

## Traceability Matrix

This matrix maps test scenarios to features and test types for coverage tracking.

| Feature | Test ID | Test Type | Priority | Status |
|---------|---------|-----------|----------|--------|
| **Child Authentication** |
| Child Login | CHILD-AUTH-001 | Integration | High | Pending |
| Child Login - Invalid | CHILD-AUTH-002 | Integration | High | Pending |
| Child Signup | CHILD-AUTH-003 | Integration | High | Pending |
| Child Signup - Validation | CHILD-AUTH-004 | Unit | Medium | Pending |
| **Parent Authentication** |
| Parent Login | PARENT-AUTH-001 | Integration | High | Pending |
| Parent Login - Invalid | PARENT-AUTH-002 | Integration | High | Pending |
| Parent Signup + Link | PARENT-AUTH-003 | Integration | High | Pending |
| Parent Signup - Invalid Child | PARENT-AUTH-004 | Integration | Medium | Pending |
| **Character Library** |
| Load Characters | CHAR-LIB-001 | Integration | High | Pending |
| Empty State | CHAR-LIB-002 | Integration | Low | Pending |
| Navigate to Detail | CHAR-LIB-003 | E2E | High | Pending |
| **Heartbeat Tracking** |
| Adjust Speed | HEARTBEAT-001 | Unit | Medium | Pending |
| Log Feeling | HEARTBEAT-002 | Integration | High | Pending |
| Missing Child ID | HEARTBEAT-003 | Unit | High | Pending |
| Slider Range | HEARTBEAT-004 | Unit | Low | Pending |
| **Audio Playback** |
| Play Audio | AUDIO-001 | Integration | Medium | Pending |
| Pause/Resume | AUDIO-002 | Integration | Medium | Pending |
| Replay | AUDIO-003 | E2E | Low | Pending |
| **Parent Profile** |
| View Logs | PARENT-PROF-001 | Integration | High | Pending |
| No Logs | PARENT-PROF-002 | Integration | Medium | Pending |
| Statistics | PARENT-PROF-003 | Integration | Medium | Pending |
| **Child Profile** |
| View Profile | CHILD-PROF-001 | E2E | Medium | Pending |
| Avatar Display | CHILD-PROF-002 | Unit | Low | Pending |
| **Navigation** |
| Page Navigation | NAV-001 | E2E | High | Pending |
| Session Persistence | NAV-002 | Integration | High | Pending |

**Summary:**
- Total Test Scenarios: 25
- Unit Tests: 5 (20%)
- Integration Tests: 14 (56%)
- E2E Tests: 6 (24%)
- High Priority: 13
- Medium Priority: 9
- Low Priority: 3

---

## Appendix

### Glossary
- **Gherkin**: Behavior-driven development syntax using Given/When/Then
- **E2E**: End-to-end testing through complete user workflows
- **Mock**: Simulated object/service for isolated testing
- **Code Coverage**: Percentage of code executed during tests
- **CI/CD**: Continuous Integration/Continuous Deployment

### References
- Flutter Testing Documentation: https://docs.flutter.dev/testing
- Gherkin Syntax: https://cucumber.io/docs/gherkin/
- GraphQL Testing: https://graphql.org/graphql-js/testing/

### Document History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-06 | FBI Team | Initial test plan creation |

---

**End of Test Plan Document**

