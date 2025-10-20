# Service Accounts

[back](../README.md)

- [concepts](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [tasks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Understanding the Service Account Token Changes in Kubernetes (1.20.15 :vs: 1.21.14 :vs: 1.24.12)](https://www.linkedin.com/pulse/service-account-token-changes-kubernetes-version-124-shafeeque-aslam/)
- [Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)

||User Account|Service Account|
|-|-|-|
|entity|human|non-human|
|namespaced|:x:|:white_check_mark:|
|Kubernetes API Object|:x:|:white_check_mark:|

## Service Account Token

Kubernetes supports two types of tokens from version 1.22 onwards.

- Long-Lived Token - never expires
- Time Bound Token - default 1h

| **#** | **Pod automountServiceAccountToken** | **ServiceAccount automountServiceAccountToken** | **Projected Volume Used** | **Token Auto-Mounted?**  | **Manual Projected Token?**   | **Notes**                                                    |
| :---: | :----------------------------------- | :---------------------------------------------- | :------------------------ | :----------------------- | :---------------------------- | :----------------------------------------------------------- |
|   1   | *(unset)*                            | *(unset)*                                       | ❌                         | ✅ Yes (default behavior) | ❌                             | Default: token auto-mounted under `/var/run/secrets/...`     |
|   2   | *(unset)*                            | `true`                                          | ❌                         | ✅ Yes                    | ❌                             | Same as default — SA allows auto-mount                       |
|   3   | *(unset)*                            | `false`                                         | ❌                         | ❌ No                     | ❌                             | SA disables auto-mount globally (used for security)          |
|   4   | `true`                               | `true`                                          | ❌                         | ✅ Yes                    | ❌                             | Explicitly allows token mount                                |
|   5   | `true`                               | `false`                                         | ❌                         | ✅ Yes (Pod overrides SA) | ❌                             | Pod explicitly re-enables it                                 |
|   6   | `false`                              | `true`                                          | ❌                         | ❌ No                     | ❌                             | Pod explicitly disables — takes precedence                   |
|   7   | `false`                              | `false`                                         | ❌                         | ❌ No                     | ❌                             | Both disable → no token                                      |
|   8   | `false`                              | *(any)*                                         | ✅                         | ❌ No auto token          | ✅ Manual projected works      | **Recommended secure approach** — explicit short-lived token |
|   9   | `true`                               | *(any)*                                         | ✅                         | ✅ Auto token             | ✅ Manual projected also works | Two tokens — not recommended (ambiguous source)              |

## Scenarios

Sample [manifest](sa.yml)

### Automount (default)

Automount always mounts to: `/var/run/secrets/kubernetes.io/serviceaccount/token`, automatically rotates token and default duration is `~1h`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
```

This will automatically create create below mount

```yaml
...
spec:
  containers:
  - image: nginx:alpine
    ...
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-4l224
      readOnly: true
    ...
  volumes:
  - name: kube-api-access-4l224  # dynamic projected volume created an mounted
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607  # ~1h
          path: token
```

token location in pod

```bash
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

check token if refreshed

```bash
kubectl exec sa-pod -- date
kubectl exec sa-pod -- ls -l /var/run/secrets/kubernetes.io/serviceaccount/token
```

### Disable Automount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
automountServiceAccountToken: false
```

This will automatically create create below mount

```yaml
...
spec:
  containers:
  - image: nginx:alpine
    ...
    # no projected volume created an mounted
```

token location in pod

```bash
$ cat /var/run/secrets/kubernetes.io/serviceaccount/token
cat: can't open '/var/run/secrets/kubernetes.io/serviceaccount/token': No such file or directory
```

### Override Automount setting of SA in Pod level

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
automountServiceAccountToken: false
```

Override automount option of SA

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sa-pod
spec:
  serviceAccountName: my-sa
  automountServiceAccountToken: true  # override false option of SA
  containers:
  - name: my-container
    image: nginx:alpine
```

This will automatically create create below mount

```yaml
...
spec:
  containers:
  - image: nginx:alpine
    ...
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-4l224
      readOnly: true
    ...
  volumes:
  - name: kube-api-access-4l224  # dynamic projected volume created an mounted
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607  # ~1h
          path: token
```

token location in pod

```bash
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

### [Projected volume](https://kubernetes.io/docs/concepts/storage/projected-volumes)

If automount is `true` and also projected volume used, then token will be mount in both place: `/var/run/secrets/kubernetes.io/serviceaccount/token` and `/projected-dir/token`

Add token to pod via projected volume and customize duration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sa-pod
spec:
  serviceAccountName: my-sa
  automountServiceAccountToken: true
  containers:
  - name: my-container
    image: nginx:alpine
    volumeMounts:
    - mountPath: /var/run/secrets/tokens
      name: my-proj-vol
  volumes:
  - name: my-proj-vol
    projected:
      sources:
      - serviceAccountToken:
          path: my-proj-vol
          expirationSeconds: 600 #specify the desired epiration time in seconds
```

after apply result will look like

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sa-pod
spec:
  serviceAccountName: my-sa
  automountServiceAccountToken: true
  containers:
  - name: my-container
    image: nginx:alpine
    volumeMounts:
    - mountPath: /my-proj-vol
      name: my-proj-vol
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-7f64g
      readOnly: true
  volumes:
  - name: my-proj-vol
    projected:
      sources:
      - serviceAccountToken:
          path: sa-token
          expirationSeconds: 600 #specify the desired epiration time in seconds
  - name: kube-api-access-7f64g
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
```

token location in pod (both automount and projected token will be mount)

```bash
cat /my-proj-vol/sa-token
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

check token if refreshed

```bash
kubectl exec sa-pod -- date
kubectl exec sa-pod -- ls -l /my-proj-vol/sa-token
kubectl exec sa-pod -- ls -l /var/run/secrets/kubernetes.io/serviceaccount/token
```

## [Manually create an API token for a ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#manually-create-an-api-token-for-a-serviceaccount)

Service accounts in Kubernetes are non-human accounts that provide a unique identity for system components and application pods. They are namespaced objects within the Kubernetes API server. Every Kubernetes namespace has a default service account named default which has no special roles or privileges assigned to it. In Kubernetes versions prior to `1.24`, a token was automatically generated when a service account was created and mounted in the pod’s file system. However, starting from Kubernetes `1.24`, **tokens are no longer generated automatically** and must be obtained using the TokenRequest API or by creating a Secret API object for the token controller to populate with a service account token.

```bash
kubectl create token my-sa --duration 600s
```

Decode token, see [`jws_decode`](#jwt-json-decoder) script for local usage

```bash
TOKEN=$(kubectl create token my-sa)

# jwt_decode $TOKEN with https://www.jwt.io/

  HEADER: ALGORITHM & TOKEN TYPE
  {
    "alg": "RS256",
    "kid": "sBbb4eXsVB4Nhpy8Zfn_pFAZouL-hzB3bUZ3tU5Uzf8"
  }
  PAYLOAD: DATA
  {
    "aud": [
      "https://kubernetes.default.svc.cluster.local",
      "k3s"
    ],
    "exp": 1760942697,
    "iat": 1760939097,
    "iss": "https://kubernetes.default.svc.cluster.local",
    "jti": "87caa655-6470-47f0-9ca3-40479fe85edc",
    "kubernetes.io": {
      "namespace": "default",
      "serviceaccount": {
        "name": "my-sa",
        "uid": "69dc3b47-4455-4365-87c7-e5bed10cee93"
      }
    },
    "nbf": 1760939097,
    "sub": "system:serviceaccount:default:my-sa"
  }
```

Using kubectl `v1.31` or later, it is possible to create a service account token that is directly bound to a Node:

```bash
kubectl create token my-sa --bound-object-kind Node --bound-object-name node-001 --bound-object-uid 123...456
```

## [Manually create a long-lived API token for a ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#manually-create-a-long-lived-api-token-for-a-serviceaccount)

**Note**:
> Versions of Kubernetes before v1.22 automatically created long term credentials for accessing the Kubernetes API. This older mechanism was based on creating token Secrets that could then be mounted into running Pods. In more recent versions, including Kubernetes v1.34, API credentials are obtained directly by using the TokenRequest API, and are mounted into Pods using a projected volume. The tokens obtained using this method have bounded lifetimes, and are automatically invalidated when the Pod they are mounted into is deleted.
>
> You can still manually create a service account token Secret; for example, if you need a token that never expires. However, using the TokenRequest subresource to obtain a token to access the API is recommended instead.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-sa-long-lived-token
  annotations:
    kubernetes.io/service-account.name: my-sa  # special annotation,
type: kubernetes.io/service-account-token
```

Creating secret not recommended, instead creaet token: `kubectl create token`

Kubernetes sees:

- The type: `kubernetes.io/service-account-token`
- The annotation `kubernetes.io/service-account.name`

Then the controller manager automatically:

- Generates a JWT token for the specified ServiceAccount.
- Adds it into the Secret’s data.token field (base64-encoded).
- Populates metadata like data.ca.crt, data.namespace.
- Keeps it synced — but does not auto-rotate.

The output is similar to this:

```yaml
Name:         my-sa-long-lived-token
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: my-sa
              kubernetes.io/service-account.uid: 69dc3b47-4455-4365-87c7-e5bed10cee93

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     566 bytes
namespace:  7 bytes
token:          ...
```

When you delete a ServiceAccount that has an associated Secret, the Kubernetes control plane automatically deletes `my-sa-long-lived-token` secret

## [Add image pull secret to service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#add-image-pull-secret-to-service-account)

create pull secret

```bash
kubectl create secret docker-registry myregistrykey --docker-server=dockerhub.com \
        --docker-username=DUMMY_USERNAME --docker-password=DUMMY_DOCKER_PASSWORD \
        --docker-email=DUMMY_DOCKER_EMAIL

kubectl patch serviceaccount my-sa -p '{"imagePullSecrets": [{"name": "myregistrykey"}]}'
```

or with yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-docker-secret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6eyJkb2NrZXJodWIuY29tIjp7InVzZXJuYW1lIjoiRFVNTVlfVVNFUk5BTUUiLCJwYXNzd29yZCI6IkRVTU1ZX0RPQ0tFUl9QQVNTV09SRCIsImVtYWlsIjoiRFVNTVlfRE9DS0VSX0VNQUlMIiwiYXV0aCI6IlJGVk5UVmxmVlZORlVrNUJUVVU2UkZWTlRWbGZSRTlEUzBWU1gxQkJVMU5YVDFKRSJ9fX0=
```

SA will contain `imagePullSecrets` key to sue thi secret

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
  # annotations:
  #   kubernetes.io/enforce-mountable-secrets: true  # DEPRECATED
imagePullSecrets:
  - name: myregistrykey
```

## Allow SA to use other secrets

Secrets is a list of the secrets in the same namespace that pods running using this ServiceAccount are allowed to use. Pods are only limited to this list if this service account has a `kubernetes.io/enforce-mountable-secrets` annotation set to `true`. The `kubernetes.io/enforce-mountable-secrets` annotation is deprecated since v1.32. Prefer separate namespaces to isolate access to mounted secrets. This field should not be used to find auto-generated service account token secrets for use outside of pods. Instead, tokens can be requested directly using the TokenRequest API, or service account token secrets can be manually created. [More info](https://kubernetes.io/docs/concepts/configuration/secret).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
data:
  .app.json: e30=
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
secrets:  # Secrets is a list of the secrets in the same namespace that pods running using this ServiceAccount are allowed to use
- name: my-app-secret
```

**Note** In k8s <1.24, when SA created, token for it automatically created in secret and SA referenced that secret. Now it is DEPRECATED and [API token](#manually-create-an-api-token-for-a-serviceaccount) used instead of it

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
secrets:
- name: my-sa-token-22v2k
```

## Token Expiration

Kubernetes is designed to expire the token in one hour, but there are many legacy applications running with the non-expiring token. To allow gradual adoption of the time-bound token, Kubernetes has allowed cluster admins to specify `--service-account-extend-token-expiration=true` to Kube API Server. When specified, it will allow tokens to have longer expiration (365 days) temporarily and record the usage of legacy tokens.

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

## [JWT JSON decoder](https://jwt.io/)

could be used to read token content or via cli

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
