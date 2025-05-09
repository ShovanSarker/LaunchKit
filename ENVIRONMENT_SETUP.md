# LaunchKit Environment Setup

LaunchKit provides a flexible environment configuration system that allows you to easily set up your project for different environments:

- **Development**: For local development
- **Staging**: For testing in a production-like environment
- **Production**: For live deployment

## Quick Start

To set up your environment, run:

```bash
# Make scripts executable
chmod +x scripts/setup.sh

# Run setup script with desired environment
./scripts/setup.sh -e development
```

## Setup Options

The setup script supports the following options:

```
Usage: ./scripts/setup.sh [OPTIONS]

Options:
  -e, --environment ENV    Set environment (development, staging, production)
  -f, --force              Force overwrite of existing files
  -n, --non-interactive    Run in non-interactive mode
  -h, --help               Show this help message
```

### Examples

```bash
# Set up development environment (interactive mode)
./scripts/setup.sh -e development

# Set up production environment, forcing overwrite of existing files
./scripts/setup.sh -e production --force

# Non-interactive setup for CI/CD pipelines
./scripts/setup.sh -e staging --non-interactive
```

## Environment Configuration

LaunchKit uses environment-specific templates to configure your project:

### Development Environment

- **API**: `templates/env/development/api.env.template`
- **Frontend**: `templates/env/development/app.env.template`

Development configuration includes:
- Debug mode enabled
- Console email backend
- Local database configuration
- Relaxed security settings for easier development
- CORS configured for local development

### Staging Environment

- **API**: `templates/env/staging/api.env.template`
- **Frontend**: `templates/env/staging/app.env.template`

Staging configuration includes:
- Production-like settings with enhanced debugging
- Separate resource names (S3 buckets, etc.)
- Clear "Staging" indicators in UI
- Increased logging verbosity

### Production Environment

- **API**: `templates/env/production/api.env.template`
- **Frontend**: `templates/env/production/app.env.template`

Production configuration includes:
- Debug mode disabled
- Strict security settings
- Production-ready performance optimizations
- Limited API rate limiting

## Customizing Templates

You can customize the environment templates to meet your specific needs:

1. Edit the appropriate template files in `templates/env/[environment]/`
2. Add your custom variables to the template using `%%VARIABLE_NAME%%` syntax
3. Update the `apply_template()` function in `scripts/setup.sh` to handle your new variables

## Environment Variables

When running the setup script, it will:

1. Generate a main `.env` file with Docker Compose variables
2. Create `api/.env` with Django-specific settings
3. Create `app/.env.local` with Next.js-specific settings

The setup script handles generating secure random values for:
- Secret keys
- Database passwords
- Other security-sensitive information

## Additional Configuration

For advanced configuration needs:

- **Infrastructure**: Modify `docker-compose.yml` for your service needs
- **CI/CD**: Use the non-interactive mode for automated deployments
- **Scaling**: Adjust service configurations in Docker Compose files

## Troubleshooting

If you encounter issues during setup:

1. Check that template files exist in the correct locations
2. Verify Docker and Docker Compose are installed
3. Ensure you have sufficient permissions to create files
4. Use the `--force` flag to overwrite existing configuration

For more help, consult the main README.md or open an issue on the repository. 