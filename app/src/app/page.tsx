'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth';

export default function Home() {
  const router = useRouter();
  const { user } = useAuth();

  // Redirect to login if not authenticated
  useEffect(() => {
    if (user === null) { // Only redirect if we're sure user is not authenticated
      router.replace('/auth/login');
    }
  }, [user, router]);

  // Show loading state while checking authentication
  if (user === undefined) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-center">
          <div className="mb-4 text-gray-600 dark:text-gray-300">Loading...</div>
        </div>
      </div>
    );
  }

  // If not authenticated, don't render anything while redirecting
  if (!user) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Dashboard Content */}
      <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="border-4 border-dashed border-gray-200 dark:border-gray-700 rounded-lg h-96 p-4">
            <h2 className="text-2xl font-bold mb-4 text-gray-900 dark:text-white">
              Welcome to Your Dashboard
            </h2>
            <p className="text-gray-600 dark:text-gray-300">
              This is your protected dashboard page. You're successfully logged in!
            </p>
          </div>
        </div>
      </div>
    </div>
  );
} 