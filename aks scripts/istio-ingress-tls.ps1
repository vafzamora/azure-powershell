$hostName='demo.azure.com'

# Deploy httpbin sample app
@"
# Copyright Istio Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

##################################################################################################
# httpbin service
##################################################################################################
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      serviceAccountName: httpbin
      containers:
      - image: docker.io/kong/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
"@ | kubectl apply -f -

# Create Istio Gateway 
@"
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: ingress-tls-csi # must be the same as secret
      # serverCertificate: /etc/istio/ingressgateway-certs/aks-ingress-cert.crt
      # privateKey: /etc/istio/ingressgateway-certs/aks-ingress-cert.key
    hosts:
    - $hostName
"@ | kubectl apply -f -

# Create Istio VirtualService
@"
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - $hostName
  gateways:
  - mygateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
"@ | kubectl apply -f -

# Test the connection to the httpbin service using the ingress gateway and SSL

$INGRESS_NAME='istio-ingressgateway'
$INGRESS_NS='istio-ingress' 

kubectl get svc "$INGRESS_NAME" -n "$INGRESS_NS"

$INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$SECURE_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
$TCP_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')

Write-Output "${INGRESS_HOST}:$INGRESS_PORT"
Write-Output "${INGRESS_HOST}:$SECURE_INGRESS_PORT"
Write-Output "${INGRESS_HOST}:$TCP_INGRESS_PORT"

curl -v -HHost:$hostName --resolve "${hostName}:${SECURE_INGRESS_PORT}:${INGRESS_HOST}" `
  --cacert aks-ingress-tls.crt "https://${hostName}:$SECURE_INGRESS_PORT/status/418"