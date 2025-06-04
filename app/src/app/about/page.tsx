'use client';

export default function About() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
            About LaunchKit
          </h1>
          <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
            A comprehensive, production-ready starter kit for building modern web applications
          </p>
        </div>

        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
              Our Mission
            </h2>
            <p className="text-gray-600 dark:text-gray-300">
              To provide developers with a robust, modern, and scalable foundation for building web applications quickly and efficiently, eliminating the repetitive setup process.
            </p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
              Technology Stack
            </h2>
            <p className="text-gray-600 dark:text-gray-300">
              Built with Next.js 14.1.0, TypeScript, Tailwind CSS, Django REST Framework, PostgreSQL, Redis, RabbitMQ, and Celery, offering a complete full-stack solution.
            </p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
              Open Source
            </h2>
            <p className="text-gray-600 dark:text-gray-300">
              Committed to the open-source community under the MIT License, we believe in transparency and collaborative development to create better software.
            </p>
          </div>
        </div>

        <div className="mt-12 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
            Key Features
          </h2>
          <div className="grid gap-6 md:grid-cols-2">
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Backend</h3>
              <ul className="space-y-2 text-gray-600 dark:text-gray-300">
                <li>• Django REST Framework API</li>
                <li>• JWT Authentication</li>
                <li>• PostgreSQL Database</li>
                <li>• Redis Caching</li>
                <li>• Celery Task Queue</li>
                <li>• RabbitMQ Message Broker</li>
              </ul>
            </div>
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Frontend</h3>
              <ul className="space-y-2 text-gray-600 dark:text-gray-300">
                <li>• Next.js 14.1.0 with App Router</li>
                <li>• TypeScript Support</li>
                <li>• Tailwind CSS Styling</li>
                <li>• Dark Mode Support</li>
                <li>• Responsive Design</li>
                <li>• Modern UI Components</li>
              </ul>
            </div>
          </div>
        </div>

        <div className="mt-12 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
            Development & Deployment
          </h2>
          <div className="space-y-4">
            <p className="text-gray-600 dark:text-gray-300">
              LaunchKit includes a complete Docker-based development and deployment workflow, making it easy to get started and scale your application. The project comes with:
            </p>
            <ul className="list-disc list-inside space-y-2 text-gray-600 dark:text-gray-300">
              <li>Docker Compose configuration for all services</li>
              <li>Development environment with hot-reloading</li>
              <li>Production-ready deployment setup</li>
              <li>Monitoring with Prometheus and Grafana</li>
              <li>Automated testing and CI/CD support</li>
              <li>Comprehensive documentation</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
} 