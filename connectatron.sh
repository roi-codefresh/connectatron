#!/bin/bash

set -o pipefail
set -e

accountId="id$1"
currentContext=$(kubectl config current-context)

if [ "$accountId" == "id" ]; then
    echo "missing accountId"
    exit 1
fi
accountId=$1

echo "using context: $currentContext"
echo "using account id: $accountId"

namespace=$(kubectl get release | grep $accountId | grep vcluster | awk '{print $1}' | sed s/-vcluster//)
echo "namespace: $namespace"

secretName="vc-$namespace"
config=$(kubectl get secret -n$namespace -o jsonpath="{.data.config}" $secretName | base64 -d)
echo "got kubeconfig"
echo "rewriting host to 'https://$namespace.$namespace.svc' -> 'http://localhost:7443'"
config=$(echo "$config" | sed s/$namespace\.$namespace\.svc/localhost:7443/)
echo "$config" > /tmp/kubeconfig

echo "merging to original kubeconfig"
cp ~/.kube/config ~/.kube/config.bak
KUBECONFIG=/tmp/kubeconfig:~/.kube/config kubectl config view --flatten > /tmp/config
mv /tmp/config ~/.kube/config

echo "switching current context"
kubectl config use-context Default

echo "---"
echo "---"
echo "run:"
echo "kubectl port-forward --context $currentContext -n $namespace svc/$namespace 7443:443 &"