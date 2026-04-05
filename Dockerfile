FROM python:3.10-slim

WORKDIR /app

# system deps
RUN apt-get update && apt-get install -y \
    curl \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# install deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# copy project
COPY . .

# environment
ENV PYTHONUNBUFFERED=1

HEALTHCHECK CMD curl --fail http://localhost:8000/api/v1/health || exit 1

EXPOSE 8000

CMD ["uvicorn","app.main:app","--host","0.0.0.0","--port","8000"]
