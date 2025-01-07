#!/bin/bash

openssl req -new \
    -newkey rsa:4096 -nodes -keyout ./certs/snakeoil.key \
    -out ./certs/snakeoil.csr \
    -subj "/C=US/ST=Krakosia/L=City/O=ACME corp/CN=*.snakeoil.example.com" \
    -addext "subjectAltName=DNS:snakeoil.example.com,DNS:*.snakeoil.example.com,IP:192.168.1.1"

# Blindly copying extensions from the CRT is a bad practice for a real CA, but will do for a dummy one
openssl x509 -req -days 3650 -in ./certs/snakeoil.csr -signkey ./certs/snakeoil.key -out ./certs/snakeoil.crt -copy_extensions copyall

cat ./certs/snakeoil.crt >> ./certs/snakeoil.pem
cat ./certs/snakeoil.key >> ./certs/snakeoil.pem

rm -f ./certs/snakeoil.csr
rm -f ./certs/snakeoil.crt
rm -f ./certs/snakeoil.key