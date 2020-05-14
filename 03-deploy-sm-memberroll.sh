#!/bin/bash

echo "Deploy Service Mesh Member Roll for bookinfo namespace"
oc create -f ./install/06-service-mesh-member-roll.yaml -n bookretail-istio-system --save-config

sleep 10

echo "Checking Service Mesh labels in bookinfo namespace"
echo -en "\n\n$(oc get project bookinfo -o template --template='{{.metadata.labels}}')\n\n"
# map[kiali.io/member-of:bookretail-istio-system maistra.io/member-of:bookretail-istio-system]

# Add a service mesh data plane auto-injection annotation to your bookinfo deployments.

echo -en "Adding sidecar.istio.io/inject annotation in deployments\n"

for deployment in $(oc get deployment --no-headers=true -n bookinfo | awk '{print $1}'); do 
  echo -en "\nPatching $deployment\n"

  oc patch deployment $deployment --type='json' \
    -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata/annotations\", \"value\": {\"sidecar.istio.io/inject\": \"true\"}}]" \
    -n bookinfo

  # Make sure that all of your bookinfo deployments now include the Envoy sidecar proxy.
  echo -en "Checking $deployment pods\n\n"
  echo -en "counter    replicas    readyReplicas\n"
  replicas=1
  readyReplicas=0 
  counter=1
  while (( $replicas != $readyReplicas && $counter != 20 ))
  do
    sleep 1 
    oc get deployment $deployment -o json -n bookinfo > /tmp/$deployment.json
    replicas=$(cat /tmp/$deployment.json | jq .status.replicas)
    readyReplicas=$(cat /tmp/$deployment.json | jq .status.readyReplicas)
    echo -en "$counter          $replicas           $readyReplicas\n"
    let counter=counter+1
  done
done

echo -en "\nPatching Product Page application to be exposed by Service Mesh\n"

oc patch deployment productpage-v1 --type='json' \
	-p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"maistra.io/expose-route\":\"true\",\"app\":\"productpage\",\"version\":\"v1\"}}}]" \
	-n bookinfo

echo -en "\nChecking number of containers in pods\n"

for pod in $(oc get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}')
do
    oc get pod $pod -n bookinfo -o jsonpath='{.metadata.name}{"    :\t\t"}{.spec.containers[*].name}{"\n"}'
done
