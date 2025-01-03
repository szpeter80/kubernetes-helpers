#!/bin/bash

openssl req -new \
    -newkey rsa:4096 -nodes -keyout snakeoil.key \
    -out snakeoil.csr \
    -subj "/C=US/ST=Krakosia/L=City/O=ACME corp/CN=*.snakeoil.example.com" \
    -addext "subjectAltName=DNS:snakeoil.example.com,DNS:*.snakeoil.example.com,IP:192.168.1.1"

# Blindly copying extensions from the CRT is a bad practice for a real CA, but will do for a dummy one
openssl x509 -req -days 3650 -in snakeoil.csr -signkey snakeoil.key -out snakeoil.crt -copy_extensions copyall