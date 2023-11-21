FROM golang:alpine AS builder

RUN mkdir /var/www
WORKDIR /var/www

COPY . .

RUN go build -o go-hello

FROM alpine:latest

RUN mkdir /var/www
WORKDIR /var/www

COPY --from=builder /var/www/go-hello .

ENTRYPOINT ["/var/www/go-hello"]
