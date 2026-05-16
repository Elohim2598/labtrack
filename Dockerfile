FROM perl:5.38-slim

RUN apt-get update && apt-get install -y \
    libpq-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm App::cpanminus

WORKDIR /app

COPY backend/cpanfile .
RUN cpanm --installdeps .

COPY backend/ .

EXPOSE 3000

CMD ["perl", "script/labtrack", "daemon", "-l", "http://*:3000"]
