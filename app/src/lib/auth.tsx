'use client';

import React, { createContext, useState, useContext, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { authAPI, userAPI } from './api';

// Define types
type User = {
  id: string;
  username: string;
  email: string;
  first_name: string;
  last_name: string;
  profile: {
    id: string;
    bio: string;
    avatar: string | null;
    phone_number: string;
  };
};

type AuthContextType = {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  register: (userData: any) => Promise<void>;
  updateProfile: (profileData: any) => Promise<void>;
};

// Create the auth context with default values
const AuthContext = createContext<AuthContextType>({
  user: null,
  isLoading: false,
  isAuthenticated: false,
  login: async () => {},
  logout: () => {},
  register: async () => {},
  updateProfile: async () => {},
});

// Auth provider component
export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();

  // Check if user is authenticated on mount
  useEffect(() => {
    const checkAuth = async () => {
      try {
        const token = localStorage.getItem('accessToken');
        if (!token) {
          setIsLoading(false);
          return;
        }

        const response = await userAPI.getProfile();
        setUser(response.data);
      } catch (error) {
        console.error('Authentication check failed:', error);
        // Clear tokens if auth check fails
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        setUser(null);
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, []);

  // Login function
  const login = async (username: string, password: string) => {
    try {
      // First, ensure we're logged out
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      setUser(null);

      // Perform login
      const authResponse = await authAPI.login(username, password);
      
      // Verify tokens were set
      const token = localStorage.getItem('accessToken');
      if (!token) {
        throw new Error('Login failed: No token received');
      }

      // Fetch user profile
      const userResponse = await userAPI.getProfile();
      setUser(userResponse.data);
      
      // Only navigate on success
      router.replace('/');
    } catch (error) {
      console.error('Login failed:', error);
      // Ensure we're fully logged out on error
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      setUser(null);
      throw error; // Re-throw the error to be handled by the login page
    }
  };

  // Logout function
  const logout = () => {
    // Clear all auth state
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    setUser(null);
    
    // Navigate to login
    router.replace('/auth/login');
  };

  // Register function
  const register = async (userData: any) => {
    setIsLoading(true);
    try {
      await authAPI.register(userData);
      router.push('/auth/login');
    } catch (error) {
      console.error('Registration failed:', error);
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  // Update profile function
  const updateProfile = async (profileData: any) => {
    setIsLoading(true);
    try {
      const response = await userAPI.updateProfile(profileData);
      setUser((prevUser) => {
        if (!prevUser) return null;
        return {
          ...prevUser,
          profile: {
            ...prevUser.profile,
            ...response.data,
          },
        };
      });
    } catch (error) {
      console.error('Profile update failed:', error);
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const value = {
    user,
    isLoading,
    isAuthenticated: !!user,
    login,
    logout,
    register,
    updateProfile,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// Custom hook to use auth context
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

// Auth guard component for protected routes
export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/auth/login');
    }
  }, [isAuthenticated, isLoading, router]);

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return isAuthenticated ? <>{children}</> : null;
} 