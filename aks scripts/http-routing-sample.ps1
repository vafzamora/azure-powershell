# This command creates the following on your cluster:
#   - a namespace called test-infra
#   - two services called backend-v1 and backend-v2 in the test-infra namespace
#   - two deployments called backend-v1 and backend-v2 in the test-infra namespace

kubectl apply -f https://trafficcontrollerdocs.blob.core.windows.net/examples/traffic-split-scenario/deployment.yaml

# Create a gateway
@"
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: gateway-http
  namespace: test-infra
  annotations:
    alb.networking.azure.io/alb-namespace: alb-test-infra
    alb.networking.azure.io/alb-name: alb-test
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http-listener
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same  
"@ | kubectl apply -f - 

# Use this command to check gateway status
# kubectl get gateway gateway-http -n test-infra -o yaml

# Create an HTTPRoute
@"
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: http-route
  namespace: test-infra
spec:
  parentRefs:
  - name: gateway-http
    namespace: test-infra
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /bar
    backendRefs:
    - name: backend-v2
      port: 8080
  - matches:
    - headers:
      - type: Exact
        name: magic
        value: foo
      queryParams:
      - type: Exact
        name: great
        value: example
      path:
        type: PathPrefix
        value: /some/thing
      method: GET
    backendRefs:
    - name: backend-v2
      port: 8080
  - backendRefs:
    - name: backend-v1
      port: 8080
"@ | kubectl apply -f -

# Use this command to check HTTPRoute status
# kubectl get httproute http-route -n test-infra -o yaml

# Use this command to get the gateway fqdn
# $fqdn=$(kubectl get gateway gateway-http -n test-infra -o jsonpath='{.status.addresses[0].value}')

# Use this command to test the path based routing
# curl -H "Host: $fqdn" http://$fqdn/bar

# Use this command to test the header based routing
# curl -H "Host: $fqdn" -H "magic: foo" http://$fqdn/some/thing?great=example

# Use this command to test the default routing
# curl -H "Host: $fqdn" http://$fqdn/


