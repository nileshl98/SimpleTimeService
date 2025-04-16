FROM python:3.9-slim

RUN useradd -m appuser

WORKDIR /home/appuser

COPY main.py .

RUN pip install flask

RUN chown -R appuser:appuser /home/appuser

USER appuser

EXPOSE 8080

CMD ["python", "main.py"]
