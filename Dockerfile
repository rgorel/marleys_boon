FROM ruby:2.6.5-slim

RUN apt-get update && apt-get install -y build-essential

WORKDIR /app
COPY . .
