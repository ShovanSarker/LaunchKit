# Development Guide

This guide will help you set up and run the LaunchKit development environment.

## Prerequisites

Before getting started, ensure you have the following installed:

- [Docker](https://www.docker.com/get-started) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- [Git](https://git-scm.com/downloads)

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/ShovanSarker/LaunchKit.git
cd LaunchKit
```

### Setup Development Environment

```bash
# Run the setup script
./scripts/setup_development.sh
```

This script will:
1. Create necessary environment files
2. Generate the `run_dev.sh` script in the scripts directory
3. Set up initial configurations
4. Make scripts executable

### Start the Development Environment

```bash
# Start all services using the generated script
./scripts/run_dev.sh
```

This will start the following services:
- PostgreSQL database
- Redis cache
- RabbitMQ message broker
- Django API server
- Celery worker
- Celery scheduler (beat)

### Access the Application

- Django API: [http://localhost:8000](http://localhost:8000)
- Django Admin: [http://localhost:8000/admin](http://localhost:8000/admin)
- API Documentation: [http://localhost:8000/api/schema/swagger-ui/](http://localhost:8000/api/schema/swagger-ui/)
- RabbitMQ Management: [http://localhost:15672](http://localhost:15672)

## Development Workflow

### Available Commands

#### Main Commands

| Command | Description |
|---------|-------------|
| `./scripts/run_dev.sh` | Start development environment |
| `./scripts/run_dev.sh down` | Stop development environment |
| `./scripts/run_dev.sh ps` | List running services |
| `./scripts/run_dev.sh logs [service]` | Show logs for specific or all services |

#### Database Commands

| Command | Description |
|---------|-------------|
| `./scripts/run_dev.sh migrate` | Apply database migrations |
| `./scripts/run_dev.sh makemigrations` | Create new migrations |
| `./scripts/run_dev.sh createsuperuser` | Create admin user |

#### Celery Commands

| Command | Description |
|---------|-------------|
| `./scripts/run_dev.sh celery` | Start Celery worker |
| `./scripts/run_dev.sh beat` | Start Celery beat |

### Development to Production Workflow

1. **Development**: Use `./scripts/run_dev.sh` for local development
2. **Testing**: Run tests and ensure code quality
3. **Staging**: Deploy to staging environment
4. **Production**: Deploy to production environment

## Common Issues and Troubleshooting

### Setup Issues

If you encounter issues during setup:

```bash
# Check if setup script exists
ls -l scripts/setup_development.sh

# Make sure it's executable
chmod +x scripts/setup_development.sh

# Run setup again
./scripts/setup_development.sh
```

### Database Connection Issues

If you can't connect to the database:

```bash
# Check if PostgreSQL is running
./scripts/run_dev.sh ps

# Check PostgreSQL logs
./scripts/run_dev.sh logs db

# Restart the database
./scripts/run_dev.sh restart db
```

### Redis Connection Issues

If Redis connection fails:

```bash
# Check Redis status
./scripts/run_dev.sh ps redis

# Check Redis logs
./scripts/run_dev.sh logs redis

# Restart Redis
./scripts/run_dev.sh restart redis
```

### RabbitMQ Issues

If RabbitMQ is not working:

```bash
# Check RabbitMQ status
./scripts/run_dev.sh ps rabbitmq

# Check RabbitMQ logs
./scripts/run_dev.sh logs rabbitmq

# Restart RabbitMQ
./scripts/run_dev.sh restart rabbitmq
```

### Celery Issues

If Celery tasks are not processing:

```bash
# Check Celery worker status
./scripts/run_dev.sh ps celery

# Check Celery logs
./scripts/run_dev.sh logs celery

# Restart Celery
./scripts/run_dev.sh restart celery
```

## Environment Variables

The setup script will create a `.env` file with the following variables:

```env
# Django settings
DEBUG=True
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1

# Database settings
POSTGRES_DB=launchkit
POSTGRES_USER=launchkit
POSTGRES_PASSWORD=your-password-here

# Redis settings
REDIS_URL=redis://redis:6379/0

# RabbitMQ settings
RABBITMQ_DEFAULT_USER=launchkit
RABBITMQ_DEFAULT_PASS=your-password-here
```

## Development Best Practices

1. **Code Style**
   - Follow PEP 8 for Python code
   - Use ESLint and Prettier for JavaScript/TypeScript
   - Write meaningful commit messages

2. **Testing**
   - Write unit tests for new features
   - Run tests before committing
   - Maintain test coverage

3. **Documentation**
   - Document new features
   - Update API documentation
   - Keep README up to date

4. **Version Control**
   - Use feature branches
   - Keep commits atomic
   - Review code before merging

5. **Security**
   - Never commit sensitive data
   - Use environment variables
   - Follow security best practices

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Need Help?

- Check the [troubleshooting guide](#common-issues-and-troubleshooting)
- Open an issue on GitHub
- Contact the maintainers 