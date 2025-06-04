# API Handling & Security Guide

## Table of Contents
1. [Backend (Django) Configuration](#1-backend-django-configuration)
2. [Frontend (Next.js) Configuration](#2-frontend-nextjs-configuration)
3. [API Organization](#3-api-organization)
4. [Security Best Practices](#4-security-best-practices)
5. [Making API Calls](#5-making-api-calls)
6. [Error Handling](#6-error-handling)
7. [File Storage](#7-file-storage)

## 1. Backend (Django) Configuration

### CSRF Protection
```python
# api/project/settings/base.py
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
# api/project/settings/base.py
CORS_ORIGIN_ALLOW_ALL = True  # In development
CORS_ALLOW_HEADERS = [
    *default_headers,
    'x-project-key',
    'Access-Control-Allow-Origin'
]

# api/project/settings/production.py
CORS_ALLOWED_ORIGIN_REGEXES = [
    r'^https://\w+\.yourdomain\.com$',
]
```

### Authentication
```python
# api/project/settings/base.py
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ),
}
```

## 2. Frontend (Next.js) Configuration

### API Client Setup

1. **Base Axios Instance** (`app/src/shared/api/axios.js`):
```javascript
import axios from 'axios';
import humps from 'humps';
import { UserSession } from '../auth/UserSession';
import settings from '../config/settings';

const instance = axios.create({
    baseURL: settings.apiBaseURL,
    timeout: 30000,
    headers: {
        'Content-Type': 'application/json',
    }
});

// Request interceptor
instance.interceptors.request.use((request) => {
    // Add auth token if available
    const authToken = UserSession.getToken();
    if (authToken) {
        request.headers.Authorization = `Bearer ${authToken}`;
    }
    
    // Transform request data to snake_case
    if (request.data) {
        request.data = humps.decamelizeKeys(request.data);
    }
    
    return request;
});

// Response interceptor
instance.interceptors.response.use(
    (response) => {
        // Transform response data to camelCase
        if (response.data) {
            response.data = humps.camelizeKeys(response.data);
        }
        return response;
    },
    async (error) => {
        if (error.response) {
            // Handle authentication errors
            if (error.response.status === 401) {
                // Try to refresh token if available
                const refreshToken = localStorage.getItem('refreshToken');
                if (refreshToken) {
                    try {
                        const response = await axios.post(`${settings.apiBaseURL}/api/v1/accounts/token/refresh/`, {
                            refresh: refreshToken
                        });
                        if (response.data.access) {
                            UserSession.setToken(response.data.access);
                            // Retry the original request
                            const config = error.config;
                            config.headers.Authorization = `Bearer ${response.data.access}`;
                            return axios(config);
                        }
                    } catch (refreshError) {
                        UserSession.clearSession();
                        window.location.href = '/login';
                        return Promise.reject(error);
                    }
                } else {
                    UserSession.clearSession();
                    window.location.href = '/login';
                    return Promise.reject(error);
                }
            }
            
            // Transform error response data to camelCase
            if (error.response.data) {
                error.response.data = humps.camelizeKeys(error.response.data);
            }
        }
        return Promise.reject(error);
    }
);

export default instance;
```

### Authentication Flow

1. **Auth API** (`app/src/shared/api/auth.js`):
```javascript
import axios from './axios';
import { UserSession } from '../auth/UserSession';
import settings from '../config/settings';

export class AuthAPI {
    static async login(email, password) {
        try {
            const response = await axios.post('/api/v1/accounts/login/', {
                email,
                password
            });
            
            if (response.data.access) {
                UserSession.setToken(response.data.access);
                // Store refresh token if needed
                if (response.data.refresh) {
                    localStorage.setItem('refreshToken', response.data.refresh);
                }
                // Get user profile
                await this.getCurrentUser();
            }
            
            return response.data;
        } catch (error) {
            if (error.response) {
                throw new Error(error.response.data.detail || 'Login failed');
            }
            throw new Error('Network error occurred');
        }
    }

    static async logout() {
        try {
            await axios.post('/api/v1/accounts/logout/');
        } finally {
            UserSession.clearSession();
        }
    }

    static async getCurrentUser() {
        try {
            const response = await axios.get('/api/v1/accounts/profile/');
            UserSession.setUser(response.data);
            return response.data;
        } catch (error) {
            if (error.response && error.response.status === 401) {
                UserSession.clearSession();
            }
            throw error;
        }
    }
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
api/
├── apps/
│   ├── api/
│   │   └── v1/
│   │       ├── views/
│   │       └── serializers/
│   └── [feature]/
│       ├── views.py
│       └── serializers.py
app/
├── src/
│   ├── shared/
│   │   ├── api/
│   │   │   ├── axios.js
│   │   │   └── auth.js
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
- Secure token storage in localStorage

### 3. CORS
- Strict origin checking in production
- Allowed origins are configured per environment
- Custom headers are explicitly allowed
- Preflight requests are handled correctly

## 5. Making API Calls

### Frontend Example
```javascript
// 1. Import the API client
import { AuthAPI } from '@/shared/api/auth';

// 2. Use the API method
try {
    await AuthAPI.login(email, password);
    // Handle success
} catch (error) {
    // Handle error
}
```

### Backend Example
```python
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

class UserProfileView(generics.RetrieveAPIView):
    """
    API endpoint for retrieving user profile.
    """
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user
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
       const response = await AuthAPI.login(email, password);
       // Handle success
   } catch (error) {
       if (error.response) {
           // Handle API error
           console.error('Login error:', error.response.data);
       } else if (error.request) {
           // Handle network error
           console.error('Network error:', error.request);
       } else {
           // Handle other errors
           console.error('Error:', error.message);
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

## 7. File Storage

### Development Storage
In development, files are stored locally:
```python
# api/project/settings/development.py
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "mediafiles"
```

### Production Storage
In production, files are stored in AWS S3. You need to create two buckets:

1. **Static Files Bucket**:
   - Name: `your-project-name-static`
   - Purpose: Stores static files (CSS, JS, images)
   - Configuration:
   ```python
   # api/project/settings/production.py
   STATICFILES_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"
   AWS_STORAGE_BUCKET_NAME = "your-project-name-static"
   ```

2. **Media Files Bucket**:
   - Name: `your-project-name-media`
   - Purpose: Stores user-uploaded files
   - Configuration:
   ```python
   # api/project/settings/production.py
   DEFAULT_FILE_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"
   AWS_STORAGE_BUCKET_NAME = "your-project-name-media"
   ```

### Required Environment Variables
```bash
# AWS Configuration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_STORAGE_BUCKET_NAME=your-project-name-media  # For media files
AWS_S3_REGION_NAME=your-region  # e.g., us-east-1
AWS_S3_CUSTOM_DOMAIN=your-custom-domain  # Optional
```

### Bucket Setup Steps
1. Create two S3 buckets with the naming convention above
2. Configure bucket permissions:
   - Block all public access
   - Enable versioning (recommended)
   - Set up CORS if needed
3. Create an IAM user with S3 access
4. Add the AWS credentials to your environment variables
5. Test file uploads in development and production

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