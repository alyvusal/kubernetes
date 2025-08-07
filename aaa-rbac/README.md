# RBAC

[back](../README.md)

- [reference](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [api](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29)

## Verbs

[Reference](https://kubernetes.io/docs/reference/access-authn-authz/authorization/#determine-the-request-verb)

|Verb||HTTPDescription|
|-|-|-|
|`get`|`GET`, `HEAD`|for individual resources|
|`list`|`GET`, `HEAD`|for collections, including full object content|
|`watch`|`GET`, `HEAD`|watching an individual resource or collection of resources|
|`update`|`PUT`||
|`create`|`POST`||
|`delete`|`DELETE`|for individual resources|
|`deletecollection`|`DELETE`|for collections|

:exclamation: **Caution**: The `get`, `list` and `watch` verbs can all return the full details of a resource. In terms of the returned data they are equivalent. For example, list on secrets will still reveal the data attributes of any returned resources.

## Authentication

```bash
# try anonymous login
$ curl -k https://192.168.0.100:43343
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}

# create token for default user and try with that
$ kubectl create token default
eyJhbGciOi ....

# this time instead of 'anonymous' user we will get user name 'default'
$ curl -k https://192.168.0.100:43343 -H "Authorization: Bearer eyJhbGci.."
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:serviceaccount:default:default\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}
```

### local user authentication

Install cluster with [local-file-basic-auth](../../kind/local-file-basic-auth/local-file-basic-auth-cluster.yml)

Token list cannot be changed without restarting the API server. The token file is a CSV file with a minimum of 3 columns: token, user name, user uid, followed by optional group names.

The bearer token scheme was originally created as part of OAuth 2.0 in RFC 6750, but can also be used on its own. So AuthN strategies like static token authentication just place their specific tokens into the `<token>` field via this mechanism.

Fill [local.users](../../kind/local-file-basic-auth/local.users) file in the following format. If you have more than one group the column must be double quoted e.g.

```xls
token,user,uid,"group1,group2,group3"
22a38432-8bcb-cdcf,bob,124,"prod,dev,uat"
```

When using basic authentication from an HTTP client, the API server expects an Authorization header with a value of:

```bash
BASE64ENCODED=$(echo -n 'USER:PASSWORD' | base64)
curl -H "Basic $BASE64ENCODED" -XGET https://...
curl -k -H "Authorization: Bearer <token>" $API_SERVER_URL/api/v1/namespaces/default/pods
```

now apply [rbac for loca users](../../kind/local-file-basic-auth/local-users-rbac.yml) and check again

```bash
curl -k -H "Authorization: Bearer <token>" $API_SERVER_URL/api/v1/namespaces/default/pods
```

**NOTE**
[`--basic-auth-file` vs `--token-auth-file`](https://stackoverflow.com/questions/35942193/kubernetes-simple-authentication)

If you want your users to authenticate using HTTP Basic Auth (user:password), you can add:

`--basic-auth-file=/basic_auth.csv`

to your kube-apiserver command line, where each line of the file should be password, user-name, user-id. E.g.:

```xls
@dm1nP@ss,admin,admin
w3rck3rP@ss,wercker,wercker

```

If you'd rather use access tokens (HTTP Authentication: Bearer), you can specify:

`--token-auth-file=/known-tokens.csv`

where each line should be token,user-name,user-id[,optional groups]. E.g.:

```xls
@dm1nT0k3n,admin,admin,adminGroup,devGroup
w3rck3rT0k3n,wercker,wercker,devGroup
```

```bash
kubectl config set-context kind-kind --user alice
```

### See also [Service Account](../service-account/README.md) section

## Authorization

### [Aggregated ClusterRoles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.example.com/aggregate-to-monitoring: "true"
rules: [] # The control plane automatically fills in the rules
```

The control plane overwrites any values that you manually specify in the rules field of an aggregate ClusterRole. If you want to change or add rules, do so in the ClusterRole objects that are selected by the aggregationRule.

[Reference](https://kubernetes.io/docs/reference/access-authn-authz/authorization)
