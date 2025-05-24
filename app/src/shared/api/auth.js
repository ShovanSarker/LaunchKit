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