# Service Accounts

[back](../README.md)

- [concepts](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [tasks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Understanding the Service Account Token Changes in Kubernetes (1.20.15 :vs: 1.21.14 :vs: 1.24.12)](https://www.linkedin.com/pulse/service-account-token-changes-kubernetes-version-124-shafeeque-aslam/)
- [Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)

Service accounts in Kubernetes are non-human accounts that provide a unique identity for system components and application pods. They are namespaced objects within the Kubernetes API server. Every Kubernetes namespace has a default service account named default which has no special roles or privileges assigned to it. In Kubernetes versions prior to `1.24`, a token was automatically generated when a service account was created and mounted in the pod’s file system. However, starting from Kubernetes `1.24`, **tokens are no longer generated automatically** and must be obtained using the TokenRequest API or by creating a Secret API object for the token controller to populate with a service account token.

||User Account|Service Account|
|-|-|-|
|entity|human|non-human|
|namespaced|:x:|:white_check_mark:|
|Kubernetes API Object|:x:|:white_check_mark:|

Create a new service account in the current namespace.

```bash
kubectl create serviceaccount <service_account_name>
```

List all the service accounts in the current namespace.

```bash
kubectl get serviceaccounts
```

Retrieve detailed information about a specific service account.

```bash
kubectl describe serviceaccount <service_account_name>
```

Create a new token associated with the specified service account.

```bash
kubectl create token <service_account_name>
```

## Service Account Token

Kubernetes supports two types of tokens from version 1.22 onwards.

- Long-Lived Token - never expires
- Time Bound Token - default 1h

## Token Expiration

Kubernetes is designed to expire the token in one hour, but there are many legacy applications running with the non-expiring token. To allow gradual adoption of the time-bound token, Kubernetes has allowed cluster admins to specify `--service-account-extend-token-expiration=true` to Kube API Server. When specified, it will allow tokens to have longer expiration (365 days) temporarily and record the usage of legacy tokens.

Click [here](https://github.com/kubernetes/enhancements/blob/master/keps/sig-auth/1205-bound-service-account-tokens/README.md#serviceaccount-admission-controller-migration) to learn more about the token expiry.

Even if the token-expiration flag is set to true , Kubernetes allows us to create a token or mount a token that expires in one hour or whatever time we want. We can use the below definitions to achieve it.

```bash
# Export the internal Kubernetes API server hostname
APISERVER=https://192.168.0.100:39271

# Export the path to ServiceAccount mount directory
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# Read the ServiceAccount bearer token, this token expires after 1h
TOKEN_WITH_DEFAULT_TIMEOUT=$(kubectl exec sa-pod -- cat ${SERVICEACCOUNT}/token)

# Custom temporary token which wll expire after custom timeout
TOKEN_WITH_CUSTOM_TIMEOUT=$(kubectl exec sa-pod -- cat /var/run/secrets/tokens/my-proj-vol)

# Reference the internal Kubernetes certificate authority (CA)
CACERT=$(mktemp).crt
kubectl exec sa-pod -- cat ${SERVICEACCOUNT}/ca.crt > $CACERT

# Make a call to the Kubernetes API with TOKEN_WITH_DEFAULT_TIMEOUT or TOKEN_WITH_CUSTOM_TIMEOUT
curl --cacert ${CACERT} -H "Authorization: Bearer ${TOKEN_WITH_DEFAULT_TIMEOUT}" -X GET ${APISERVER}/api/v1/namespaces/default/pods

curl --cacert ${CACERT} -H "Authorization: Bearer ${TOKEN_WITH_CUSTOM_TIMEOUT}" -X GET ${APISERVER}/api/v1/namespaces/default/pods
```

check token if refreshed

```bash
kubectl exec sa-pod -- date
kubectl exec sa-pod -- ls -l /var/run/secrets/tokens/..data/my-proj-vol
```

**NOTE** [JWT JSON decoder](https://jwt.io/) could be used to read token content or via cli

Sample shell script for `jwt_decode`

```bash
function _url_base64_decode() {
  local len=$((${#1} % 4))
  local result="$1"

  if [ $len -eq 2 ]; then result="$1"'=='
  elif [ $len -eq 3 ]; then result="$1"'='
  fi

  echo "$result" | tr '_-' '/+' | openssl enc -d -base64
}

function jwt_decode() {
  echo
  red "HEADER: ALGORITHM & TOKEN TYPE"
  _url_base64_decode $(echo -n $1 | cut -d "." -f 1) | jq .

  red "PAYLOAD: DATA"
  _url_base64_decode $(echo -n $1 | cut -d "." -f 2) | jq .
  echo
}
```

```bash
jwt_decode $TOKEN_WITH_CUSTOM_TIMEOUT
```
