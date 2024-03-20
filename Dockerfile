FROM python:3.8 as base
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apt-get update && apt-get -y install curl

WORKDIR /app
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

COPY src/. .
RUN pip install --no-cache-dir -r requirements.txt
#RUN pip install -r requirements.txt --no-index --find-links libs/

########
# Test
########
FROM base as test

WORKDIR /app
CMD ["pytest","-v","/app"]

########
# App
########
FROM base as app

RUN groupadd -g 999 appuser && \
    useradd -u 999 -d /app -g appuser appuser
RUN chown appuser:appuser /app

USER appuser
WORKDIR /app

EXPOSE 8080
ENTRYPOINT ["python"]
CMD ["app.py"]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:8080/health