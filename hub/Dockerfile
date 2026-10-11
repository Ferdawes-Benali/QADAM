FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 QADAM_DATA_DIR=/data QADAM_SHARED_DIR=/app/shared
WORKDIR /app
COPY hub/requirements.txt /app/hub/requirements.txt
RUN pip install --no-cache-dir -r /app/hub/requirements.txt
COPY shared /app/shared
COPY hub /app/hub
WORKDIR /app/hub
RUN useradd --create-home qadam && mkdir -p /data && chown qadam /data
USER qadam
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s CMD python -c "import urllib.request;urllib.request.urlopen('http://127.0.0.1:8000/api/health')"
CMD ["python", "-m", "qadam_hub", "--host", "0.0.0.0", "--port", "8000"]
