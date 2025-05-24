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
            Your modern full-stack development starter kit
          </p>
        </div>

        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
              Our Mission
            </h2>
            <p className="text-gray-600 dark:text-gray-300">
              To provide developers with a robust, modern, and scalable foundation for building web applications quickly and efficiently.
            </p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
              Technology Stack
            </h2>
            <p className="text-gray-600 dark:text-gray-300">
              Built with Next.js 14, TypeScript, Tailwind CSS, and Django REST Framework, offering the best of both frontend and backend technologies.
            </p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
              Open Source
            </h2>
            <p className="text-gray-600 dark:text-gray-300">
              Committed to the open-source community, we believe in transparency and collaborative development to create better software.
            </p>
          </div>
        </div>

        <div className="mt-12 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
            Why Choose LaunchKit?
          </h2>
          <div className="space-y-4">
            <p className="text-gray-600 dark:text-gray-300">
              LaunchKit is designed to eliminate the repetitive setup process of modern web applications. 
              It provides a carefully curated stack of technologies that work seamlessly together, 
              allowing developers to focus on building features rather than configuring tools.
            </p>
            <p className="text-gray-600 dark:text-gray-300">
              Whether you're building a startup MVP or enterprise application, LaunchKit provides the 
              solid foundation you need with built-in authentication, responsive design, dark mode support, 
              and many other essential features ready to use out of the box.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
} 