#!/bin/bash

echo -en "\nCreate Policy object for bookinfo deployments\n"

for deployment in $(oc get deployment --no-headers=true -n bookinfo | awk '{print $1}'); do 
  echo -en "\nCreate Policy for $deployment\n"
  echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: $deployment-mtls-policy
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: $deployment" | oc apply -n bookinfo -f -
done

# Create Destination Rules

echo -en "\nCreate Destination Rules for bookinfo services\n"

for svc in $(oc get svc --no-headers=true -n bookinfo | awk '{print $1}'); do 
  echo -en "\nCreate DestinationRule for $svc\n"
  echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: $svc-mtls-destinationrule
spec:
  host: $svc.bookinfo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL" | oc apply -n bookinfo -f -
done

# Create VirtualServices for Product Page

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage-virtualservice
spec:
  hosts:
  - productpage-bookretail-istio-system.<OCP_APPS_BASE_URL>
  gateways:
  - bookretail-wildcard-gateway.bookretail-istio-system.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 9080
        host: productpage.bookinfo.svc.cluster.local
" | oc create -n bookinfo -f -

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: \"true\"
  labels:
    app: productpage
  name: productpage-gateway
spec:
  host: productpage-bookretail-istio-system.<OCP_APPS_BASE_URL>
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" | oc create -n bookretail-istio-system -f -

echo "Deleting insecure route"

oc delete route productpage -n bookinfo

#ISTIO_INGRESSGATEWAY_POD=$(oc get pod -l app=istio-ingressgateway -o jsonpath={.items[0].metadata.name} -n $SM_CP_NS)
#$ istioctl -n bookretail-istio-system -i bookretail-istio-system authn tls-check ${ISTIO_INGRESSGATEWAY_POD} $ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local
