#!/bin/bash

echo "Deploy ElasticSearch Operator"
oc create -f ./install/01-elasticsearch-operator.yaml

sleep 60

oc get clusterserviceversion | grep -i elasticsearch
oc get pod  -n openshift-operators | grep "^elasticsearch"

echo "Deploy Jaeger Operator"
oc create -f ./install/02-jaeger-operator.yaml

sleep 60

oc get clusterserviceversion | grep jaeger
oc get pod  -n openshift-operators | grep "^jaeger"

echo "Deploy Kiali Operator"
oc create -f ./install/03-kiali-operator.yaml

sleep 60

oc get clusterserviceversion | grep kiali
oc get pod  -n openshift-operators | grep "^kiali"

echo "Deploy Red Hat OpenShift Service Mesh Operator "
oc create -f ./install/04-service-mesh-operator.yaml

sleep 120

oc get clusterserviceversion | grep mesh
oc get pod  -n openshift-operators | grep "^istio"
#oc logs -n openshift-operators $(oc -n openshift-operators get pods -l name=istio-operator --output=jsonpath={.items..metadata.name})

echo "Create Service Mesh Control Plane namespace for Bookinfo application"
oc adm new-project bookretail-istio-system --display-name="Service Mesh for Book Retail"

sleep 10

echo "Deploy Service Mesh Control Plane"
oc create -f ./install/05-service-mesh-control-plane.yaml -n bookretail-istio-system

sleep 120

echo "Watch pod status"
#watch oc get pods -n bookretail-istio-system
oc get pods -n bookretail-istio-system
