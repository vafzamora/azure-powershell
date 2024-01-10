# Install Istio using Helm
kubectl create namespace istio-system
helm install istio-base istio/base -n istio-system --set defaultRevision=default

helm install istiod istio/istiod -n istio-system --wait

helm ls -n istio-system


# Install Istio ingress gateway
$ingressNamespace='istio-ingress'
kubectl create ingressNamespace $ingressNamespace

@"
volumes: 
- name: ingressgateway-certs
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: azure-tls
volumeMounts:
- name: ingressgateway-certs
  mountPath: /etc/istio/ingressgateway-certs
  readOnly: true
"@ | helm install istio-ingressgateway istio/gateway -n $ingressNamespace -f -