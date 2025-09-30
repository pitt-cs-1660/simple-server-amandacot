FROM python:3.12 AS build
RUN pip install --no-cache-dir uv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
WORKDIR /app
COPY pyproject.toml ./
RUN uv venv "$VIRTUAL_ENV" \
 && . "$VIRTUAL_ENV/bin/activate" \
 && uv sync --no-install-project --active

FROM python:3.12-slim AS final
ARG APP_USER=appuser
ARG APP_UID=10001
RUN useradd --create-home --uid ${APP_UID} ${APP_USER}
COPY --from=build /opt/venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
WORKDIR /app
RUN mkdir -p /app && chown -R ${APP_USER}:${APP_USER} /app
COPY --chown=${APP_USER}:${APP_USER} cc_simple_server ./cc_simple_server
COPY --chown=${APP_USER}:${APP_USER} tests ./tests
EXPOSE 8000
USER ${APP_USER}
CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]
