#!/bin/bash

set -o pipefail
set -e

accountId="id$1"
currentContext=$(kubectl config current-context)

if [ "$accountId" == "id" ]; then
    echo "missing accountId"
    exit 1
fi

if [ "$accountId" == "idstop" ]; then
    lsof -i :7443 | awk '{if (NR==2) print $2}' | xargs kill
    exit 0
fi
accountId=$1

echo "using context: $currentContext"
echo "using account id: $accountId"

namespace=$(kubectl get release | grep $accountId | grep vcluster | awk '{print $1}' | sed s/-vcluster//)
echo "namespace: $namespace"

secretName="vc-$namespace"
config=$(kubectl get secret -n$namespace -o jsonpath="{.data.config}" $secretName | base64 -d)
echo "rewriting host to 'https://$namespace.$namespace.svc' -> 'http://localhost:7443'"
config=$(echo "$config" | sed s/$namespace\.$namespace\.svc/localhost:7443/)

echo "getting runtime parameters..."
runtimeSecretName=$(kubectl get secret -n$namespace | grep codefresh-token | awk '{print $1}')
runtimeToken=$(kubectl get secret -n$namespace $runtimeSecretName -o jsonpath="{.data.token}" | base64 -d)
runtimeIv=$(kubectl get secret -n$namespace $runtimeSecretName -o jsonpath="{.data.encryptionIV}" | base64 -d)

argocdTokenSecretName=$(kubectl get secret -n$namespace | grep argocd-token | awk '{print $1}')
argocdToken=$(kubectl get secret -n$namespace $argocdTokenSecretName -o jsonpath="{.data.token}" | base64 -d)

echo "$config" > /tmp/kubeconfig

echo "merging to original kubeconfig"
cp ~/.kube/config ~/.kube/config.bak
KUBECONFIG=/tmp/kubeconfig:~/.kube/config kubectl config view --flatten > /tmp/config
mv /tmp/config ~/.kube/config

echo "switching current context"
kubectl config use-context Default

echo "---"
echo "app-proxy config should be:"
echo "{"
echo "  \"NAMESPACE\": \"codefresh-default\","
echo "  \"RUNTIME_TOKEN\": \"$runtimeToken\","
echo "  \"RUNTIME_STORE_IV\": \"$runtimeIv\","
echo "  \"ARGO_CD_PASSWORD\": \"$argocdToken\""
echo "}"
echo "---"
echo "run:"
echo "kubectl port-forward --context $currentContext -n $namespace svc/$namespace 7443:443 &"