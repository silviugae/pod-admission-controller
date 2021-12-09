FROM gcr.io/distroless/base

COPY ./admission-controller .
EXPOSE 443

CMD ["./admission-controller", "--tls-cert", "/etc/certs/tls.crt", "--tls-key", "/etc/certs/tls.key"]
