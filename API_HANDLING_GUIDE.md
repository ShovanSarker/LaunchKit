# API Handling & Security Guide

## Table of Contents
1. [Backend (Django) Configuration](#1-backend-django-configuration)
2. [Frontend (React) Configuration](#2-frontend-react-configuration)
3. [API Organization](#3-api-organization)
4. [Security Best Practices](#4-security-best-practices)
5. [Making API Calls](#5-making-api-calls)
6. [Error Handling](#6-error-handling)

## 1. Backend (Django) Configuration

### CSRF Protection
```python
# settings/base.py
MIDDLEWARE = [
    'django.middleware.csrf.CsrfViewMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    # ...
]
```

- CSRF protection is enabled by default
- CSRF tokens are required for POST, PUT, PATCH, and DELETE requests
- Exempt APIs can be marked with `@csrf_exempt` decorator

### CORS Configuration
```python
# settings/base.py
CORS_ORIGIN_ALLOW_ALL = True  # In development
CORS_ALLOW_HEADERS = [
    *default_headers,
    'x-project-key',
    'Access-Control-Allow-Origin'
]

# settings/live.py
CORS_ALLOWED_ORIGIN_REGEXES = [
    r'^https://\w+\.staging\.approvd\.io$',
    r'^https://\w+\.production\.approvd\.io$',
]
```

### Authentication
```python
# settings/base.py
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ),
}
```

## 2. Frontend (React) Configuration

### API Client Setup

1. **Base Axios Instance** (`src/shared/api/axios.js`):
```javascript
const instance = axios.create()
instance.defaults.headers.post['Content-Type'] = 'application/json'
instance.defaults.headers.patch['Content-Type'] = 'application/json'
instance.defaults.headers.delete['Content-Type'] = 'application/json'
```

2. **Request Interceptors**:
```javascript
instance.interceptors.request.use((request) => {
    // Auth Token
    const authToken = UserSession.getToken()
    if (authToken) {
        request.headers.Authorization = `Token ${authToken}`
    }
    
    // Project Key Header
    const projectMatch = window.location.pathname.split('/')
    if (projectMatch) {
        const projectKey = projectMatch[2]
        if (projectMatch[1] !== 'organization') {
            request.headers['X-PROJECT-KEY'] = projectKey
        }
    }
    
    // Data Transformation
    if (request.data) {
        request.data = JSON.stringify(humps.decamelizeKeys(request.data))
    }
    return request
})
```

### Authentication Flow

1. **Token Storage** (`src/shared/auth/UserSession.js`):
```javascript
class UserSession {
    setToken(token) {
        if (token) {
            window.localStorage.setItem('token', token)
            Cookies.set('Authorization', token)
        } else {
            window.localStorage.removeItem('token')
            Cookies.expire('Authorization')
        }
    }
}
```

2. **Login Process** (`src/shared/auth/api.js`):
```javascript
static login(email, password, acceptTerms) {
    return axios.post(`${settings.apiBaseURL}/login`, {
        email,
        password,
        acceptTerms,
    })
}
```

## 3. API Organization

### Backend Structure
- API endpoints are versioned (v1)
- Each app has its own views and serializers
- Permissions are handled through Django REST Framework permissions classes
- Views are organized by feature/domain
- Common functionality is shared through mixins and base classes

### Frontend Structure
- API calls are organized by feature/domain
- Each domain has its own API class
- Common API configuration is centralized in axios instances
- Reusable hooks handle common API patterns

### File Structure
```
backend/
├── apps/
│   ├── api/
│   │   └── v1/
│   │       ├── views/
│   │       └── serializers/
│   └── [feature]/
│       ├── views.py
│       └── serializers.py
frontend/
├── src/
│   ├── shared/
│   │   ├── api/
│   │   │   ├── axios.js
│   │   │   └── fileAxios.js
│   │   └── [feature]/
│   │       └── api.js
```

## 4. Security Best Practices

### 1. HTTPS
- Production enforces HTTPS
- Secure headers are configured
- HSTS is enabled in production
- All API calls use HTTPS in production

### 2. Authentication
- Token-based authentication
- Session authentication as backup
- Token expiration (30 days by default)
- Secure token storage in localStorage and cookies

### 3. CORS
- Strict origin checking in production
- Allowed origins are configured per environment
- Custom headers are explicitly allowed
- Preflight requests are handled correctly

### 4. Project Isolation
- Project-specific requests require X-PROJECT-KEY header
- Header is automatically added based on URL
- Server validates project access
- Cross-project access is prevented

## 5. Making API Calls

### Frontend Example
```javascript
// 1. Import the API client
import axios from '../api/axios'

// 2. Create an API method
static getProjectDetails(projectKey) {
    return axios.get(`${settings.apiBaseURL}/projects/${projectKey}`)
}

// 3. Handle the response
try {
    const response = await ProjectsApi.getProjectDetails(projectKey)
    // Handle success
} catch (error) {
    // Handle error
}
```

### Backend Example
```python
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

class ProjectViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    # ... rest of the viewset
```

## 6. Error Handling

### Frontend Error Handling
1. **Global Error Handling**:
   - Axios interceptors catch and process errors
   - Authentication errors redirect to login
   - Network errors show appropriate UI feedback
   - Error boundaries catch rendering errors

2. **Local Error Handling**:
   ```javascript
   try {
       const response = await api.call()
       // Handle success
   } catch (error) {
       if (error.response) {
           // Handle API error
       } else if (error.request) {
           // Handle network error
       } else {
           // Handle other errors
       }
   }
   ```

### Backend Error Handling
1. **DRF Exception Handling**:
   - Custom exception handler for consistent responses
   - Proper HTTP status codes
   - Detailed error messages in development
   - Sanitized error messages in production

2. **Custom Exceptions**:
   ```python
   class CustomAPIException(APIException):
       status_code = 400
       default_detail = 'Custom error message'
   ```

## Best Practices

1. **API Versioning**
   - Use versioned endpoints (e.g., `/api/v1/`)
   - Maintain backward compatibility
   - Document breaking changes

2. **Rate Limiting**
   - Implement rate limiting for API endpoints
   - Use appropriate throttling classes
   - Configure per-user and per-IP limits

3. **Logging**
   - Log API requests and responses
   - Track error rates and performance
   - Monitor authentication failures

4. **Testing**
   - Write tests for API endpoints
   - Test error scenarios
   - Validate response formats

## Common Issues and Solutions

1. **CORS Issues**
   - Check allowed origins configuration
   - Verify CORS headers
   - Test preflight requests

2. **Authentication Problems**
   - Verify token format
   - Check token expiration
   - Validate request headers

3. **Performance Issues**
   - Use pagination for large datasets
   - Implement caching
   - Optimize database queries

## Additional Resources

1. **Documentation**
   - API Documentation: `/api/docs/`
   - Swagger UI: `/api/swagger/`
   - Internal Wiki

2. **Tools**
   - Postman Collections
   - Environment Configurations
   - Testing Scripts 