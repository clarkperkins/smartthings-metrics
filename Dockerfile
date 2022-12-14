FROM python:3.11-slim AS build

WORKDIR /app

#COPY docker/install_build.sh /app/
#RUN sh install_build.sh

# Install poetry
RUN python -m pip install poetry virtualenv

ENV VIRTUAL_ENV /app/venv

# Create & activate virtualenv
RUN virtualenv $VIRTUAL_ENV
ENV PATH $VIRTUAL_ENV/bin:$PATH

COPY pyproject.toml poetry.lock logging.yaml /app/
RUN poetry install --sync --without=dev --no-root

COPY shm shm
RUN poetry install --sync --without=dev

FROM python:3.11-slim AS shm

ENV PYTHONUNBUFFERED 1
ENV PIP_NO_CACHE_DIR off

# Passing the -d /app will set that as the home dir & chown it
RUN useradd -r -U -m -d /app shm

WORKDIR /app

#COPY --chown=shm:shm docker/install_runtime.sh /app/
#RUN sh install_runtime.sh

COPY --chown=shm:shm --from=build /app /app

ENV VIRTUAL_ENV /app/venv
ENV PATH $VIRTUAL_ENV/bin:$PATH

USER shm

CMD ["gunicorn", "shm.wsgi:app", "-b", "0.0.0.0:9000"]
