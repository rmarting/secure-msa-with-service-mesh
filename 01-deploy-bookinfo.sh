#!/bin/bash

echo "Create bookinfo project"
oc new-project bookinfo

echo "Deploy Bookinfo objects"
oc apply -f https://raw.githubusercontent.com/istio/istio/1.4.0/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo

echo "Expose Product Page route"
oc expose service productpage -n bookinfo

echo -en "\nProduct Page: http://$(oc get route productpage --template '{{ .spec.host }}' -n bookinfo)\n"
