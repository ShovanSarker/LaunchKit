'use client';

import axios from 'axios';

// Check if we're in a browser environment
const isBrowser = typeof window !== 'undefined';

// Create axios instance with default config
const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true, // Important for cookies/auth
});

// Request interceptor for adding auth token
api.interceptors.request.use(
  (config) => {
    // Get token from localStorage if it exists and we're in a browser
    if (isBrowser) {
      const token = localStorage.getItem('accessToken');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for handling token refresh
api.interceptors.response.use(
  (response) => {
    return response;
  },
  async (error) => {
    const originalRequest = error.config;
    
    // If error is 401 and we haven't already tried to refresh
    if (isBrowser && error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        // Try to refresh the token
        const refreshToken = localStorage.getItem('refreshToken');
        if (!refreshToken) {
          throw new Error('No refresh token available');
        }
        
        const response = await axios.post(
          `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'}/api/auth/token/refresh/`,
          { refresh: refreshToken },
          { withCredentials: true }
        );
        
        // Save the new tokens
        const { access } = response.data;
        localStorage.setItem('accessToken', access);
        
        // Update the original request with the new token
        originalRequest.headers.Authorization = `Bearer ${access}`;
        
        // Retry the original request
        return api(originalRequest);
      } catch (refreshError) {
        // If refresh fails, clear tokens but don't redirect
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);

// Auth API functions
export const authAPI = {
  login: async (username: string, password: string) => {
    try {
      const response = await api.post('/api/auth/login/', { username, password });
      if (isBrowser && response.data) {
        const { access, refresh } = response.data;
        localStorage.setItem('accessToken', access);
        localStorage.setItem('refreshToken', refresh);
      }
      return response.data;
    } catch (error) {
      // Don't transform the error, just pass it through
      throw error;
    }
  },
  
  logout: () => {
    if (isBrowser) {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
    }
  },
  
  register: async (userData: any) => {
    return await api.post('/api/auth/register/', userData);
  },
  
  resetPasswordEmail: async (email: string) => {
    return await api.post('/api/auth/reset-password-email/', { email });
  },
  
  resetPassword: async (data: { token: string; uidb64: string; password: string; password2: string }) => {
    return await api.post('/api/auth/reset-password/', data);
  },
  
  changePassword: async (data: { old_password: string; new_password: string; new_password2: string }) => {
    return await api.post('/api/auth/change-password/', data);
  },
};

// User API functions
export const userAPI = {
  getProfile: async () => {
    try {
      return await api.get('/api/auth/profile/');
    } catch (error) {
      // Don't transform the error, just pass it through
      throw error;
    }
  },
  
  updateProfile: async (profileData: any) => {
    return await api.patch('/api/auth/profile/update/', profileData);
  },
};

export default api; 