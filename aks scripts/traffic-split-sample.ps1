
## Traffic Split Scenario
# Create a sample application deployment

# This command creates the following on your cluster:
#  * a namespace called test-infra
#  * two services called backend-v1 and backend-v2 in the test-infra namespace
#  * two deployments called backend-v1 and backend-v2 in the test-infra namespace

kubectl apply -f https://trafficcontrollerdocs.blob.core.windows.net/examples/traffic-split-scenario/deployment.yaml

# Create a gateway
@"
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: gateway-01
  namespace: test-infra
  annotations:
    alb.networking.azure.io/alb-namespace: alb-test-infra
    alb.networking.azure.io/alb-name: alb-test
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
"@ | kubectl apply -f -

# Use this command to check gateway status
# kubectl get gateway gateway-01 -n test-infra -o yaml

# Create an HTTPRoute
@"
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: traffic-split-route
  namespace: test-infra
spec:
  parentRefs:
  - name: gateway-01
  rules:
  - backendRefs:
    - name: backend-v1
      port: 8080
      weight: 50
    - name: backend-v2
      port: 8080
      weight: 50
"@ | kubectl apply -f -

# Use this command to check HTTPRoute status
# kubectl get httproute traffic-split-route -n test-infra -o yaml

# Use this command to get the gateway fqdn 
# $fqdn=$(kubectl get gateway gateway-01 -n test-infra -o jsonpath='{.status.addresses[0].value}')

# Use this command to test the traffic split
# while($true) { curl "http://$fqdn"; Start-Sleep -Seconds 1 }