import Link from 'next/link';
import Image from 'next/image';

export default function Home() {
  return (
    <div className="container mx-auto px-6 py-12">
      {/* Hero Section */}
      <div className="flex flex-col items-center justify-center py-12 md:py-24">
        <h1 className="text-4xl md:text-6xl font-bold text-center mb-6">
          Welcome to <span className="text-blue-600">LaunchKit</span>
        </h1>
        <p className="text-xl text-gray-600 dark:text-gray-300 text-center max-w-3xl mb-8">
          A production-ready full-stack boilerplate for building modern web applications with Django, REST API, Next.js, and Docker.
        </p>
        <div className="flex flex-col sm:flex-row gap-4">
          <Link
            href="/docs"
            className="px-8 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
          >
            Documentation
          </Link>
          <Link
            href="/auth/register"
            className="px-8 py-3 bg-gray-200 text-gray-800 dark:bg-gray-700 dark:text-white rounded-md hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors"
          >
            Get Started
          </Link>
        </div>
      </div>

      {/* Features Section */}
      <div className="py-12">
        <h2 className="text-3xl font-bold text-center mb-12">Key Features</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="p-6 border rounded-lg shadow-sm">
            <h3 className="text-xl font-semibold mb-3">Django REST API</h3>
            <p className="text-gray-600 dark:text-gray-300">
              Robust backend with Django 5.0 and Django REST Framework with authentication, permissions, and more.
            </p>
          </div>
          <div className="p-6 border rounded-lg shadow-sm">
            <h3 className="text-xl font-semibold mb-3">Next.js Frontend</h3>
            <p className="text-gray-600 dark:text-gray-300">
              Modern frontend with Next.js 14, TypeScript, and Tailwind CSS for a responsive user experience.
            </p>
          </div>
          <div className="p-6 border rounded-lg shadow-sm">
            <h3 className="text-xl font-semibold mb-3">Docker Deployment</h3>
            <p className="text-gray-600 dark:text-gray-300">
              Containerized setup with Docker Compose for easy development and production deployment.
            </p>
          </div>
          <div className="p-6 border rounded-lg shadow-sm">
            <h3 className="text-xl font-semibold mb-3">Authentication</h3>
            <p className="text-gray-600 dark:text-gray-300">
              Complete authentication system with JWT tokens, session management, and security features.
            </p>
          </div>
          <div className="p-6 border rounded-lg shadow-sm">
            <h3 className="text-xl font-semibold mb-3">Monitoring</h3>
            <p className="text-gray-600 dark:text-gray-300">
              Built-in monitoring with Prometheus, Grafana, and Loki for comprehensive insights.
            </p>
          </div>
          <div className="p-6 border rounded-lg shadow-sm">
            <h3 className="text-xl font-semibold mb-3">Background Tasks</h3>
            <p className="text-gray-600 dark:text-gray-300">
              Asynchronous task processing with Celery, RabbitMQ, and Redis for scalable operations.
            </p>
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="py-12 bg-gray-50 dark:bg-gray-800 rounded-lg my-12 p-8">
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-4">Ready to Launch Your Project?</h2>
          <p className="text-xl text-gray-600 dark:text-gray-300 mb-8 max-w-2xl mx-auto">
            Get started with LaunchKit today and accelerate your development process.
          </p>
          <Link
            href="/auth/register"
            className="px-8 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
          >
            Create an Account
          </Link>
        </div>
      </div>
    </div>
  );
} 