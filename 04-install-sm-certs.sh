#!/bin/bash

echo -en "\nCreate a self-signed certificate and private key\n"

openssl req -x509 -config cert.cfg -extensions req_ext -nodes -days 730 -newkey rsa:2048 -sha256 -keyout tls.key -out tls.crt

echo -en "\nCreate a secret named istio-ingressgateway-certs in the service mesh control plane namespace with the certificates\n"

oc create secret tls istio-ingressgateway-certs --cert tls.crt --key tls.key -n bookretail-istio-system

echo -en "\nRestart the Istio ingress gateway\n"

oc patch deployment istio-ingressgateway \
    -p '{"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt": "'`date +%FT%T%z`'"}}}}}' \
    -n bookretail-istio-system

echo -en "\nCreate a file called wildcard-gateway.yml with the definition of the wildcard gateway\n"

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookretail-wildcard-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      privateKey: /etc/istio/ingressgateway-certs/tls.key
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
    hosts:
    - \"*.<OCP_APPS_BASE_URL>\"
" | oc create -n bookretail-istio-system -f -
