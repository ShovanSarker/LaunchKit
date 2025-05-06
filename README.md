# LaunchKit

A production-ready full-stack boilerplate integrating Django, DRF, Next.js, PostgreSQL, Redis, RabbitMQ, Celery, and Docker.

## Architecture

```
           ┌────────────┐   HTTPS  ┌────────────┐
Internet → │   nginx    │─────────▶│ Next.js    │ (port 3000)
           │ reverse    │          │   app      │
           │  proxy     │          └────────────┘
           │ (TLS +     │  /api
           │ limit_req) │          ┌────────────┐  AMQP   ┌────────────┐
           └────────────┘─────────▶│  Django    │────────▶│  Celery    │
                    ▲ /static      │   API      │◀────────│  Worker    │
                    │ /media       └────────────┘  Redis  └────────────┘
                    │                                ▲
                    │          ┌────────────┐        │
                    └──────────│ PostgreSQL │◀───────┘
                               └────────────┘
```

## Quick Start

### Development Environment

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/launchkit.git
   cd launchkit
   ```

2. Run the initialization script:
   ```bash
   ./scripts/init.sh
   ```
   This will prompt you for configuration options and generate the necessary environment files.

3. Deploy the application:
   ```bash
   ./scripts/deploy.sh
   ```
   This will start all the required services in the correct order.

4. Create a superuser:
   ```bash
   docker compose exec api python manage.py createsuperuser
   ```

5. Access the services:
   - Django API: http://localhost:8000
   - Django Admin: http://localhost:8000/admin
   - RabbitMQ Management: http://localhost:15672

### Production Environment

1. On your server, clone this repository:
   ```bash
   git clone https://github.com/your-username/launchkit.git
   cd launchkit
   ```

2. Run initialization script and choose "Live" environment:
   ```bash
   ./scripts/init.sh
   ```
   Select option 2 for "Live" and then choose whether it's "Production" or "Staging".

3. Deploy the application:
   ```bash
   ./scripts/deploy.sh
   ```

4. Your application will be available at:
   - Frontend: https://www.yourdomain.com
   - API: https://api.yourdomain.com
   - Monitoring: https://monitor.yourdomain.com

## Available Scripts

- `./scripts/init.sh`: Initializes the environment by creating configuration files
  - Options: `--force` (overwrites existing files), `--non-interactive` (uses environment variables)

- `./scripts/deploy.sh`: Deploys all services in the correct order
  - Options: `--skip-pull` (skips pulling latest images, useful for local development)

- `./scripts/run-dev.sh`: Quickly starts only the essential development services
  - Explicitly starts only: PostgreSQL, Redis, RabbitMQ, API, Celery Worker, and Scheduler
  - Skips: Nginx, Prometheus, Grafana, Loki, and the Next.js app
  - Perfect for local Django development without unnecessary services
  - Additional commands:
    - `./scripts/run-dev.sh down` - stops all services
    - `./scripts/run-dev.sh logs [service_name]` - views logs

- `./scripts/backup.sh`: Creates database and media backups
  - Database dumps are stored locally
  - Media files are backed up to S3 if configured

## Technologies

- **Backend**: Python 3.12, Django 5.0, Django REST Framework 3.15
- **Database**: PostgreSQL 15
- **Cache & Queue**: Redis 7, RabbitMQ 3, Celery 5
- **Frontend**: Next.js 14 (App Router, TypeScript), Tailwind CSS, shadcn/ui
- **DevOps**: Docker, Nginx, Let's Encrypt
- **Monitoring**: Prometheus, Grafana, Loki, Sentry

## Environments

### Development
- All services run locally with ports exposed
- API runs with Django development server
- Hot-reloading enabled for both API and frontend
- Minimal monitoring services

### Live (Production/Staging)
- Full suite of services including monitoring
- Automatic SSL certificate management via Let's Encrypt
- Proper reverse proxy with rate limiting
- Scheduled backups via systemd timer (3am daily)
- Multi-domain setup with subdomains for API and monitoring

## Common Issues & Troubleshooting

### Database Connection Issues
- Ensure PostgreSQL is running: `docker compose ps postgres`
- Check credentials in `.env` file
- Verify that database migrations are applied: `docker compose exec api python manage.py migrate`

### RabbitMQ Issues
- Check RabbitMQ management interface at http://localhost:15672
- Verify that credentials match between RabbitMQ and Celery broker URL

### Frontend Build Failures
- Check Node.js version compatibility (requires v18+)
- Ensure all dependencies are installed: `cd app && npm install`
- Verify environment variables in `app/.env`

### Docker Issues
- Restart the Docker daemon: `sudo systemctl restart docker`
- Rebuild containers: `docker compose build --no-cache`
- Check logs: `docker compose logs -f [service_name]`

## License

MIT License - see the [LICENSE](LICENSE) file for details. 