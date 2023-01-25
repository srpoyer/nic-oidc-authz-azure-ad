#!/bin/zsh
openssl req -x509 -newkey rsa:4096 -nodes -sha256 -days 365 \
    -keyout privkey.pem -out cert.pem -extensions san \
    -config \
    <(echo "[req]";
      echo distinguished_name=req;
      echo "[san]";
      echo subjectAltName=DNS:kibana.example.com
     ) \
    -subj '/CN=kibana.example.com'
