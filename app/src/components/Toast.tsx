import React from 'react';
import { useNotification } from '@/contexts/NotificationContext';
import { XMarkIcon } from '@heroicons/react/24/outline';

const Toast = () => {
    const { notifications, removeNotification } = useNotification();

    const getBackgroundColor = (type: string) => {
        switch (type) {
            case 'success':
                return 'bg-green-500';
            case 'error':
                return 'bg-red-500';
            case 'warning':
                return 'bg-yellow-500';
            case 'info':
                return 'bg-blue-500';
            default:
                return 'bg-gray-500';
        }
    };

    return (
        <div className="fixed top-4 right-4 z-50 space-y-4">
            {notifications.map((notification) => (
                <div
                    key={notification.id}
                    className={`${getBackgroundColor(notification.type)} text-white p-4 rounded-lg shadow-lg 
                    transform transition-all duration-300 hover:scale-105 flex items-center justify-between
                    min-w-[300px] max-w-md`}
                >
                    <p className="flex-1 pr-4">{notification.message}</p>
                    <button
                        onClick={() => removeNotification(notification.id)}
                        className="text-white hover:text-gray-200 transition-colors"
                    >
                        <XMarkIcon className="h-5 w-5" />
                    </button>
                </div>
            ))}
        </div>
    );
};

export default Toast; 