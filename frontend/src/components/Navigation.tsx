import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  ChartBarIcon, 
  CloudArrowUpIcon, 
  HomeIcon 
} from '@heroicons/react/24/outline';

const Navigation: React.FC = () => {
  const location = useLocation();

  const navItems = [
    {
      name: 'Dashboard',
      href: '/',
      icon: ChartBarIcon,
      current: location.pathname === '/'
    },
    {
      name: 'Upload CSV',
      href: '/upload',
      icon: CloudArrowUpIcon,
      current: location.pathname === '/upload'
    }
  ];

  return (
    <nav className="bg-white shadow-sm border-b border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            {/* Logo */}
            <div className="flex-shrink-0 flex items-center">
              <HomeIcon className="h-6 w-6 text-blue-600" />
              <span className="ml-2 text-xl font-bold text-gray-900">
                Ranking Deputados
              </span>
            </div>

            {/* Navigation links */}
            <div className="hidden sm:ml-8 sm:flex sm:space-x-8">
              {navItems.map((item) => {
                const Icon = item.icon;
                return (
                  <Link
                    key={item.name}
                    to={item.href}
                    className={`${
                      item.current
                        ? 'border-blue-500 text-gray-900'
                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                    } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors`}
                  >
                    <Icon className="h-5 w-5 mr-2" />
                    {item.name}
                  </Link>
                );
              })}
            </div>
          </div>

          {/* Mobile menu button */}
          <div className="sm:hidden flex items-center">
            <div className="flex space-x-4">
              {navItems.map((item) => {
                const Icon = item.icon;
                return (
                  <Link
                    key={item.name}
                    to={item.href}
                    className={`${
                      item.current
                        ? 'text-blue-600'
                        : 'text-gray-400 hover:text-gray-500'
                    } p-2 rounded-md transition-colors`}
                  >
                    <Icon className="h-6 w-6" />
                    <span className="sr-only">{item.name}</span>
                  </Link>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </nav>
  );
};

export default Navigation; 