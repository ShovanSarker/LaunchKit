# LaunchKit

```
 _                            _     _   ___ _   
| |                          | |   | | / (_) |  
| |     __ _ _   _ _ __   ___| |__ | |/ / _| |_ 
| |    / _` | | | | '_ \ / __| '_ \|    \| | __|
| |___| (_| | |_| | | | | (__| | | | |\  \ | |_ 
\_____/\__,_|\__,_|_| |_|\___|_| |_\_| \_/_|\__| 
```

Full‑stack Django + DRF + Celery + RabbitMQ + Redis + Next.js boilerplate. Everything ships in a single repository, one‑command deploy with Docker Compose.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Django](https://img.shields.io/badge/Django-4.2-green.svg)](https://www.djangoproject.com/)
[![Next.js](https://img.shields.io/badge/Next.js-14.1.0-black.svg)](https://nextjs.org/)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0+-blue.svg)](https://www.typescriptlang.org/)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](CODE_OF_CONDUCT.md)

## Quick Links

- [Development Guide](docs/DEVELOPMENT.md) - Setup and development workflow
- [Production Guide](docs/PRODUCTION.md) - Deployment and production setup
- [API Handling Guide](API_HANDLING_GUIDE.md) - API development guidelines
- [Celery Setup Guide](celery-setup.md) - Background task configuration
- [Contributing Guide](CONTRIBUTING.md) - How to contribute to LaunchKit
- [Code of Conduct](CODE_OF_CONDUCT.md) - Community guidelines
- [Changelog](CHANGELOG.md) - Project version history

## Getting Started

### Option 1: Fork and Clone (Recommended)

1. **Fork the Repository**
   - Click the "Fork" button in the top-right corner of this repository
   - This creates your own copy of LaunchKit in your GitHub account

2. **Clone Your Fork**
   ```bash
   # Replace YOUR_USERNAME with your GitHub username
   git clone https://github.com/YOUR_USERNAME/LaunchKit.git
   cd LaunchKit
   ```

3. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/ShovanSarker/LaunchKit.git
   ```

4. **Keep Your Fork Updated**
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

### Option 2: Use as Template

1. **Create New Repository**
   - Click "Use this template" button on GitHub
   - Choose a name for your new repository
   - Select public or private visibility

2. **Clone Your New Repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   cd YOUR_REPO_NAME
   ```

### Initial Setup

1. **Setup Development Environment**
   ```bash
   # Run the setup script
   ./scripts/setup_development.sh
   ```
   This script will:
   - Create necessary environment files
   - Generate the `run_dev.sh` script in the scripts directory
   - Set up initial configurations
   - Make scripts executable

2. **Start Development Environment**
   ```bash
   # Start all services
   ./scripts/run_dev.sh
   ```

3. **Access the Application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/api/schema/swagger-ui/
   - Admin Interface: http://localhost:8000/admin

### Customization

1. **Update Project Name**
   - Edit `api/project/settings.py`
   - Update `app/package.json`
   - Modify Docker configurations

2. **Configure Environment**
   - Update `.env` file with your settings
   - Configure database settings
   - Set up authentication keys

3. **Add Your Features**
   - Create new Django apps in `api/apps/`
   - Add new Next.js pages in `app/pages/`
   - Update API endpoints in `api/apps/`

### Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Write code
   - Add tests
   - Update documentation

3. **Commit Changes**
   ```bash
   git add .
   git commit -m "Add your feature"
   ```

4. **Push Changes**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**
   - Go to your fork on GitHub
   - Click "New Pull Request"
   - Select your feature branch
   - Fill in the PR template

## Features

- **Django Backend**: Fully configured Django API with REST framework
- **Containerized**: Complete Docker setup for both development and production
- **Authentication**: User authentication with JWT tokens and advanced security features
- **Background Processing**: Celery task queue with Redis and RabbitMQ
- **Database**: PostgreSQL with migrations management
- **Dev Workflow**: Streamlined development environment with helpful scripts
- **Monitoring**: Prometheus and Grafana setup for production monitoring
- **Deployment Ready**: Configuration for easy deployment to production
- **Next.js 14.1.0 frontend with TypeScript and Tailwind CSS**
- **Auto-deployment system**

## Architecture

LaunchKit uses a modern architecture consisting of:

- **Backend**: Django API with Django REST Framework
- **Database**: PostgreSQL for reliable data storage
- **Caching**: Redis for fast caching and session storage
- **Message Broker**: RabbitMQ for reliable message queueing
- **Task Processing**: Celery for background task processing
- **Frontend**: Next.js with TypeScript and Tailwind CSS
- **Reverse Proxy**: Nginx for production deployments
- **Monitoring**: Prometheus and Grafana for system monitoring

### Architecture Diagram

```
                                    ┌────────────┐   HTTPS   ┌────────────┐
                      Internet ────▶│   Nginx    │──────────▶│ Frontend   │ 
                                    │(reverse    │           │(Next.js)   │
                                    │ proxy)     │           └────────────┘
                                    └────────────┘    
                                          │
                                          │ /api
                                          ▼                             
┌────────────┐           ┌────────────┐   │      ┌────────────┐ AMQP  ┌────────────┐
│ Prometheus │◀──────────│ Django API │◀──┘      │ RabbitMQ   │◀─────▶│ Celery     │
│ Monitoring │           └────────────┘          │ Message    │       │ Worker     │
└────────────┘                  │                │ Broker     │       └────────────┘
      ▲                         │                │            │
      │                         │                └────────────┘             │
      │                         ▼                                           │
      │                 ┌────────────┐          ┌────────────┐              │
      └─────────────────│ PostgreSQL │◀─────────│ Redis      │◀─────────────┘
                        │ Database   │          │ Cache      │
                        └────────────┘          └────────────┘
```

## Prerequisites

Before getting started, ensure you have the following installed:

- [Docker](https://www.docker.com/get-started) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- [Git](https://git-scm.com/downloads)

## File Structure

```
launchkit/
├── api/                      # Django backend
│   ├── apps/                 # Django applications
│   ├── project/              # Project settings
│   ├── requirements/         # Python requirements
│   ├── templates/            # Django templates
│   └── manage.py             # Django management script
├── app/                      # Next.js frontend
├── docker/                   # Docker configuration
│   ├── api/                  # API container configuration
│   ├── nginx/                # Nginx configuration
│   ├── postgres/             # PostgreSQL configuration
│   └── ...                   # Other services
├── scripts/                  # Helper scripts
│   ├── setup_development.sh  # Development environment setup
│   ├── run_dev.sh            # Development environment management
│   └── ...                   # Other scripts
├── templates/                # Configuration templates
│   └── env/                  # Environment templates
├── docs/                     # Documentation
│   ├── DEVELOPMENT.md        # Development guide
│   └── PRODUCTION.md         # Production guide
├── .github/                  # GitHub configuration
│   ├── ISSUE_TEMPLATE/       # Issue templates
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md
├── CHANGELOG.md              # Project changelog
├── CODE_OF_CONDUCT.md        # Community guidelines
├── CONTRIBUTING.md           # Contribution guidelines
├── LICENSE                   # MIT License
├── .env                      # Environment variables (generated)
├── docker-compose.yml        # Docker Compose configuration
└── README.md                 # This file
```

## Documentation

- [Development Guide](docs/DEVELOPMENT.md) - Detailed instructions for setting up and running the development environment
- [Production Guide](docs/PRODUCTION.md) - Comprehensive guide for deploying to production
- [API Handling Guide](API_HANDLING_GUIDE.md) - Guidelines for API development
- [Celery Setup Guide](celery-setup.md) - Configuration for background tasks
- [Contributing Guide](CONTRIBUTING.md) - How to contribute to the project
- [Code of Conduct](CODE_OF_CONDUCT.md) - Community guidelines
- [Changelog](CHANGELOG.md) - Project version history

## Acknowledgments

- [Django](https://www.djangoproject.com/)
- [Docker](https://www.docker.com/)
- [PostgreSQL](https://www.postgresql.org/)
- [Redis](https://redis.io/)
- [RabbitMQ](https://www.rabbitmq.com/)
- [Celery](https://docs.celeryq.dev/)
- [Nginx](https://nginx.org/)
- [Prometheus](https://prometheus.io/)
- [Next.js](https://nextjs.org/)
- [Tailwind CSS](https://tailwindcss.com/)

---

Created with ❤️ by Shovan 