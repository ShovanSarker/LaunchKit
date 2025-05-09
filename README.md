# LaunchKit

![LaunchKit](https://via.placeholder.com/800x200?text=LaunchKit)

LaunchKit is a comprehensive, production-ready starter kit for building modern web applications. It includes a Django backend with API capabilities, a modern frontend setup, and a complete Docker-based development and deployment workflow.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- **Django Backend**: Fully configured Django API with REST framework
- **Containerized**: Complete Docker setup for both development and production
- **Authentication**: User authentication with JWT tokens and advanced security features
- **Background Processing**: Celery task queue with Redis and RabbitMQ
- **Database**: PostgreSQL with migrations management
- **Dev Workflow**: Streamlined development environment with helpful scripts
- **Monitoring**: Prometheus and Grafana setup for production monitoring
- **Deployment Ready**: Configuration for easy deployment to production

## Architecture

LaunchKit uses a modern architecture consisting of:

- **Backend**: Django API with Django REST Framework
- **Database**: PostgreSQL for reliable data storage
- **Caching**: Redis for fast caching and session storage
- **Message Broker**: RabbitMQ for reliable message queueing
- **Task Processing**: Celery for background task processing
- **Frontend**: (Optional) Ready to connect with any frontend framework
- **Reverse Proxy**: Nginx for production deployments
- **Monitoring**: Prometheus and Grafana for system monitoring

### Architecture Diagram

```
                                    ┌────────────┐   HTTPS   ┌────────────┐
                      Internet ────▶│   Nginx    │──────────▶│ Frontend   │ 
                                    │(reverse    │           │(Optional)  │
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

In this architecture:

1. **Nginx** serves as the entry point, handling SSL termination and routing requests
2. **Django API** powers the backend, processing requests and returning data
3. **PostgreSQL** provides robust data storage
4. **Redis** offers fast caching and serves as result backend for Celery
5. **RabbitMQ** handles reliable message queueing
6. **Celery Worker** processes background tasks
7. **Prometheus** monitors the entire system

## Prerequisites

Before getting started, ensure you have the following installed:

- [Docker](https://www.docker.com/get-started) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- [Git](https://git-scm.com/downloads)

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/yourusername/launchkit.git
cd launchkit
```

### Initialize the Environment

```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Initialize the environment with configuration settings
./scripts/init.sh
```

Follow the prompts to configure your development environment. You can choose between:
- **Development**: Local development setup
- **Production**: Production-ready configuration

### Start the Development Environment

```bash
# Start only essential services for development
./scripts/run-dev.sh
```

This will start the following services:
- PostgreSQL database
- Redis cache
- RabbitMQ message broker
- Django API server
- Celery worker
- Celery scheduler (beat)

### Set up the Database

```bash
# Generate database migrations
./scripts/make-migrations.sh

# Apply migrations and create admin user
./scripts/run-migrations.sh
```

### Access the Application

- Django API: [http://localhost:8000](http://localhost:8000)
- Django Admin: [http://localhost:8000/admin](http://localhost:8000/admin) (username: `admin`, password: `admin`)
- API Documentation: [http://localhost:8000/api/schema/swagger-ui/](http://localhost:8000/api/schema/swagger-ui/)
- RabbitMQ Management: [http://localhost:15672](http://localhost:15672)

## Development Workflow

### Available Commands

LaunchKit includes several scripts to streamline development:

#### Main Commands

| Command | Description |
|---------|-------------|
| `./scripts/run-dev.sh` | Start development environment |
| `./scripts/run-dev.sh down` | Stop development environment |
| `./scripts/run-dev.sh ps` | List running services |
| `./scripts/run-dev.sh logs [service]` | Show logs for specific or all services |
| `./scripts/deploy.sh` | Deploy all services for staging/production |

#### Database Commands

| Command | Description |
|---------|-------------|
| `./scripts/make-migrations.sh` | Generate database migrations |
| `./scripts/run-migrations.sh` | Apply migrations and create admin user |

#### Utility Commands

| Command | Description |
|---------|-------------|
| `./scripts/fix-settings.sh` | Fix Django settings for CELERY_RESULT_BACKEND |
| `./scripts/fix-profiles.sh` | Fix missing user profiles |

### Development to Production Workflow

1. **Development**: Use `run-dev.sh` for local development with hot-reloading
2. **Testing**: Run tests and ensure code quality
3. **Staging**: Use `deploy.sh` with staging configuration
4. **Production**: Use `deploy.sh` with production configuration

## File Structure

```
launchkit/
├── api/                 # Django backend
│   ├── apps/            # Django applications
│   ├── project/         # Project settings
│   ├── requirements/    # Python requirements
│   ├── templates/       # Django templates
│   └── manage.py        # Django management script
├── app/                 # Frontend application (if included)
├── docker/              # Docker configuration
│   ├── api/             # API container configuration
│   ├── nginx/           # Nginx configuration
│   ├── postgres/        # PostgreSQL configuration
│   └── ...              # Other services
├── scripts/             # Helper scripts
│   ├── init.sh          # Environment initialization
│   ├── run-dev.sh       # Development environment management
│   └── ...              # Other scripts
├── templates/           # Configuration templates
│   └── env/             # Environment templates
├── .env                 # Environment variables (generated)
├── docker-compose.yml   # Docker Compose configuration
└── README.md            # This file
```

## Common Issues and Troubleshooting

### Login Fails Due to Missing User Profiles

If you can't log in to the admin interface, run:

```bash
./scripts/fix-profiles.sh
```

This script creates profiles for existing users that don't have one.

### CELERY_RESULT_BACKEND Error

If you see an error related to `CELERY_RESULT_BACKEND`, run:

```bash
./scripts/fix-settings.sh
```

### Database Connection Issues

Check that the PostgreSQL container is running:

```bash
./scripts/run-dev.sh ps
```

If not, restart the development environment:

```bash
./scripts/run-dev.sh down
./scripts/run-dev.sh
```

### Missing Dockerfiles

Some Dockerfiles may be missing, which is expected. The `run-dev.sh` script uses pre-built images for services that don't have customized Dockerfiles.

## Production Deployment

For production deployment, follow these steps:

```bash
# Initialize with production settings
./scripts/init.sh

# Choose "Live (production)" when prompted

# Deploy all services
./scripts/deploy.sh
```

This will deploy all services including:
- PostgreSQL database
- Redis cache
- RabbitMQ message broker
- Django API
- Nginx web server
- Monitoring tools (Prometheus, Grafana)

## Contributing

We welcome contributions to LaunchKit! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows our coding standards and includes appropriate tests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Django](https://www.djangoproject.com/)
- [Docker](https://www.docker.com/)
- [PostgreSQL](https://www.postgresql.org/)
- [Redis](https://redis.io/)
- [RabbitMQ](https://www.rabbitmq.com/)
- [Celery](https://docs.celeryq.dev/)

---

Created with ❤️ by Your Name 