# Use Python 3.9 slim image as base
FROM python:3.9-slim

# Set working directory in container
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV FLASK_APP=run.py
ENV FLASK_ENV=production

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run as non-root user for better security
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Expose port for the app
EXPOSE 5000

# Command to run the application with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "run:app"]