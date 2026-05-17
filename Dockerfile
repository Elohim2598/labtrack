FROM perl:5.38-slim AS base

RUN apt-get update && apt-get install -y \
    libpq-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm App::cpanminus

FROM base AS deps
WORKDIR /app
COPY backend/cpanfile .
RUN cpanm --installdeps .

FROM deps AS app
COPY backend/ .

EXPOSE 3000
CMD perl script/labtrack daemon -l http://*:${PORT:-3000}