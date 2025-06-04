FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install dependencies
COPY requirements/ /app/requirements/

# Install build dependencies and Python requirements
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc python3-dev libpq-dev postgresql-client \
    && pip install --no-cache-dir -r requirements/dev.txt \
    && apt-get purge -y --auto-remove gcc python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy entrypoint script first
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# Copy project files
COPY . /app/

# Expose port
EXPOSE 8000

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Run command
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"] 