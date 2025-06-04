'use client';

export default function Features() {
  const features = [
    {
      title: 'Authentication & Authorization',
      description: 'Complete JWT-based authentication system with token refresh, secure password handling, and role-based access control.',
      details: [
        'JWT token-based authentication',
        'Automatic token refresh mechanism',
        'Secure password hashing',
        'Protected routes and API endpoints',
        'User session management',
      ]
    },
    {
      title: 'User Management',
      description: 'Comprehensive user management system with profiles and account settings.',
      details: [
        'User registration and login',
        'Profile management with avatars',
        'Email verification',
        'Password reset functionality',
        'User preferences storage',
      ]
    },
    {
      title: 'Modern Frontend',
      description: 'Built with Next.js 14 and modern web technologies for optimal performance.',
      details: [
        'React 18 with Server Components',
        'TypeScript for type safety',
        'Tailwind CSS for styling',
        'Responsive design',
        'Dark mode support',
      ]
    },
    {
      title: 'Robust Backend',
      description: 'Django-based backend with REST API and comprehensive features.',
      details: [
        'Django REST Framework',
        'API versioning',
        'Request validation',
        'Response serialization',
        'Database migrations',
      ]
    },
    {
      title: 'Security Features',
      description: 'Enterprise-grade security measures to protect your application.',
      details: [
        'CORS protection',
        'XSS prevention',
        'CSRF protection',
        'Rate limiting',
        'Input sanitization',
      ]
    },
    {
      title: 'Developer Experience',
      description: 'Tools and features to make development smooth and efficient.',
      details: [
        'Hot reloading',
        'Development environment',
        'API documentation',
        'Code formatting',
        'TypeScript integration',
      ]
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
            Features
          </h1>
          <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
            Discover all the powerful features that make LaunchKit the perfect starting point for your next project.
          </p>
        </div>

        <div className="mt-16 grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          {features.map((feature, index) => (
            <div
              key={index}
              className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow"
            >
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
                {feature.title}
              </h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                {feature.description}
              </p>
              <ul className="space-y-2">
                {feature.details.map((detail, detailIndex) => (
                  <li
                    key={detailIndex}
                    className="flex items-start text-gray-600 dark:text-gray-300"
                  >
                    <svg
                      className="h-6 w-6 text-green-500 mr-2 flex-shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                    <span>{detail}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
} 