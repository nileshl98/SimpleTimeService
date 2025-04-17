FROM python:3.9-slim

# Create non-root user
RUN useradd -m appuser

WORKDIR /home/appuser/app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=appuser:appuser . .
USER appuser

EXPOSE 80
CMD ["python", "main.py"]
