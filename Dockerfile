FROM python:3.7-alpine
RUN mkdir -p /grover/test-app
WORKDIR /grover/test-app
ENV FLASK_APP app.py
COPY . .
RUN \
 apk add --no-cache bash postgresql-libs && \
 apk add --no-cache --virtual .build-deps gcc musl-dev postgresql-dev && \
 python3 -m pip install -r requirements.txt --no-cache-dir && \
 apk --purge del .build-deps

ENTRYPOINT ["./entrypoint.sh"]

