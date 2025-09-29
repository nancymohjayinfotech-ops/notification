# MI Skilled API Integration

This document describes how the Course and Categories API have been integrated with authentication in the MI Skilled app.

## Overview

The following API endpoints have been integrated:

1. **Course APIs**
   - Get all courses based on trainer
   - Get all courses in the system
   - Get courses with enrollments

2. **Category APIs**
   - Get all categories

## Integration Details

### Authentication Flow

The integration uses the `AuthService` to handle authentication and token management:

1. User logs in with phone number and OTP
2. The `AuthService` stores access and refresh tokens securely
3. All API requests are made through `AuthService.authenticatedRequest()` which:
   - Automatically adds the Authorization header with the current access token
   - Handles token expiration and refresh
   - Returns responses in a consistent format

### Service Layer

Three service classes have been created to encapsulate API functionality:

1. **AuthService**
   - Handles authentication, token storage, and token refresh
   - Provides the `authenticatedRequest` method for secure API calls

2. **CourseService**
   - Fetches instructor courses
   - Fetches all courses
   - Fetches courses with enrollment data

3. **CategoryService**
   - Fetches categories

### UI Integration

- The CourseListView now uses `CourseService` instead of direct API calls
- The CategoriesView now uses `CategoryService` instead of direct API calls
- Both components use proper error handling and loading states
- Sample data is provided as a fallback if API calls fail

## How to Test

1. Run the app and log in with your instructor credentials
2. Navigate to the Courses page to view the Course List tab
3. Switch to the Categories tab to view the Categories
4. Both tabs should load data from the API using your authentication token
5. You can also run the test script to verify API integration:

```bash
dart test_api_integration.dart
```

## Error Handling

- If token refresh fails, the user is redirected to login
- If API calls fail, components fall back to sample data
- Network errors and server errors are properly handled and displayed to the user

## Next Steps

1. Implement create, edit, and delete functionality for courses
2. Add pagination support for course lists
3. Implement filtering and sorting on the server side
4. Add course enrollment and student management features

## Troubleshooting

If you encounter issues with the API integration:

1. Check that you have a valid token (login again if needed)
2. Verify the API endpoints are accessible and responsive
3. Check for network connectivity issues
4. Look for error messages in the console logs
