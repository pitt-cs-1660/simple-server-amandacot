# ----------------------------
# Stage 1: build (deps with uv)
# ----------------------------
    FROM python:3.12 AS build

    # Install uv (fast Python package manager)
    RUN pip install --no-cache-dir uv
    
    # Use a fixed venv path and prefer it on PATH
    ENV VIRTUAL_ENV=/opt/venv
    ENV PATH="$VIRTUAL_ENV/bin:$PATH"
    
    WORKDIR /app
    
    # Copy dependency manifests first for better caching
    COPY pyproject.toml ./
    COPY uv.lock ./
    
    # Create venv and install ONLY deps into it
    RUN uv venv "$VIRTUAL_ENV" \
     && . "$VIRTUAL_ENV/bin/activate" \
     && uv sync --no-install-project --active
    
    # ----------------------------
    # Stage 2: final (runtime)
    # ----------------------------
    FROM python:3.12-slim AS final
    
    # Non-root user
    ARG APP_USER=appuser
    ARG APP_UID=10001
    RUN useradd --create-home --uid ${APP_UID} ${APP_USER}
    
    # Bring the ready venv from the build stage
    COPY --from=build /opt/venv /opt/venv
    
    # Use that venv by default
    ENV VIRTUAL_ENV=/opt/venv
    ENV PATH="/opt/venv/bin:$PATH"
    ENV PYTHONUNBUFFERED=1
    
    # make sure python can import from /app
    ENV PYTHONPATH=/app
    
    # App dir, permissions, then copy code + tests
    WORKDIR /app
    RUN mkdir -p /app && chown -R ${APP_USER}:${APP_USER} /app
    
    # Copy your app package and tests
    COPY --chown=${APP_USER}:${APP_USER} cc_simple_server ./cc_simple_server
    COPY --chown=${APP_USER}:${APP_USER} tests ./tests
    
    EXPOSE 8000
    
    USER ${APP_USER}
    
    # Default: run the API server
    CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]
