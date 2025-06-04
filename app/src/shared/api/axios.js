import axios from 'axios';
import humps from 'humps';
import { UserSession } from '../auth/UserSession';
import settings from '../config/settings';

// Create axios instance
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