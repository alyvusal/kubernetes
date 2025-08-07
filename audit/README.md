# Auditing

## Terminology

- **Log backend**: Writes the events into the filesystem. If your security tool is installed in the same machine it can parse the files. You can also manually process the files with a json parser, like jq, and build up some queries.
- **Webhook backend**: Sends the events to an external HTTP API. Then, your security tool doesn’t need access to the filesystem; or, you could have a single security tool instance protecting several kube-apiserver.

Levels:

- `None` - don't log events that match this rule.
- `Metadata` - log events with metadata (requesting user, timestamp, resource, verb, etc.) but not request or response body.
- `Request` - log events with request metadata and body but not response body. This does not apply for non-resource requests.
- `RequestResponse` - log events with request metadata, request body and response body. This does not apply for non-resource requests.

Stages:

- `RequestReceived` - The stage for events generated as soon as the audit handler receives the request, and before it is delegated down the handler chain.
- `ResponseStarted` - Once the response headers are sent, but before the response body is sent. This stage is only generated for long-running requests (e.g. watch).
- `ResponseComplete` - The response body has been completed and no more bytes will be sent.
- `Panic` - Events generated when a panic occurred.

Rules:

- `level`: The audit level defining the verbosity of the event.
- `resources`: The object under audit (e.g., `ConfigMaps`).
- `nonResourcesURL`: A non resource Uniform Resource Locator (URL) path that is not associated with any resources.
- `namespace`: Specific objects within a namespace that are under audit.
- `verb`: Specific operation for audit – `create`, `update`, `delete`.
- `users`: Authenticated user that the rule applies to.
- `userGroups`: Authenticated user group the rule applies to.
- `omitStages`: Skips generating events on given stages.

## Install

Add below settongs to kube-api-server manifest file (usually located at /etc/kubernetes/manifests/kube-apiserver.yaml) (Backup file before editing it):

```bash
--audit-policy-file=/etc/kubernetes/policies/audit-policy.yaml
--audit-webhook-config-file=/etc/kubernetes/policies/audit-webhook-backend-falco.yaml
--audit-log-path=/var/log/kubernetes/kube-apiserver-audit.log  # stdout: "-"
--audit-log-maxbackup=1
--audit-log-maxsize=1
--audit-log-maxage=1
--audit-log-format=json
```

## REFERENCE

- [k8s-docs](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)
- [kind k8s](https://kind.sigs.k8s.io/docs/user/auditing/)
- [Explanation of audit log output](https://support.d2iq.com/hc/en-us/articles/4409472617876-How-to-read-kube-apiserver-audit-logs)

`kube-api-server` arguments related to audit:

```bash
      --audit-log-batch-buffer-size int             The size of the buffer to store events before batching and writing. Only used in batch mode. (default 10000)
      --audit-log-batch-max-size int                The maximum size of a batch. Only used in batch mode. (default 1)
      --audit-log-batch-max-wait duration           The amount of time to wait before force writing the batch that hadn't reached the max size. Only used in batch mode.
      --audit-log-batch-throttle-burst int          Maximum number of requests sent at the same moment if ThrottleQPS was not utilized before. Only used in batch mode.
      --audit-log-batch-throttle-enable             Whether batching throttling is enabled. Only used in batch mode.
      --audit-log-batch-throttle-qps float32        Maximum average number of batches per second. Only used in batch mode.
      --audit-log-compress                          If set, the rotated log files will be compressed using gzip.
      --audit-log-format string                     Format of saved audits. "legacy" indicates 1-line text format for each event. "json" indicates structured json format. Known formats are legacy,json. (default "json")
      --audit-log-maxage int                        The maximum number of days to retain old audit log files based on the timestamp encoded in their filename.
      --audit-log-maxbackup int                     The maximum number of old audit log files to retain. Setting a value of 0 will mean there's no restriction on the number of files.
      --audit-log-maxsize int                       The maximum size in megabytes of the audit log file before it gets rotated.
      --audit-log-mode string                       Strategy for sending audit events. Blocking indicates sending events should block server responses. Batch causes the backend to buffer and write events asynchronously. Known modes are batch,blocking,blocking-strict. (default "blocking")
      --audit-log-path string                       If set, all requests coming to the apiserver will be logged to this file.  '-' means standard out.
      --audit-log-truncate-enabled                  Whether event and batch truncating is enabled.
      --audit-log-truncate-max-batch-size int       Maximum size of the batch sent to the underlying backend. Actual serialized size can be several hundreds of bytes greater. If a batch exceeds this limit, it is split into several batches of smaller size. (default 10485760)
      --audit-log-truncate-max-event-size int       Maximum size of the audit event sent to the underlying backend. If the size of an event is greater than this number, first request and response are removed, and if this doesn't reduce the size enough, event is discarded. (default 102400)
      --audit-log-version string                    API group and version used for serializing audit events written to log. (default "audit.k8s.io/v1")
      --audit-policy-file string                    Path to the file that defines the audit policy configuration.
      --audit-webhook-batch-buffer-size int         The size of the buffer to store events before batching and writing. Only used in batch mode. (default 10000)
      --audit-webhook-batch-max-size int            The maximum size of a batch. Only used in batch mode. (default 400)
      --audit-webhook-batch-max-wait duration       The amount of time to wait before force writing the batch that hadn't reached the max size. Only used in batch mode. (default 30s)
      --audit-webhook-batch-throttle-burst int      Maximum number of requests sent at the same moment if ThrottleQPS was not utilized before. Only used in batch mode. (default 15)
      --audit-webhook-batch-throttle-enable         Whether batching throttling is enabled. Only used in batch mode. (default true)
      --audit-webhook-batch-throttle-qps float32    Maximum average number of batches per second. Only used in batch mode. (default 10)
      --audit-webhook-config-file string            Path to a kubeconfig formatted file that defines the audit webhook configuration.
      --audit-webhook-initial-backoff duration      The amount of time to wait before retrying the first failed request. (default 10s)
      --audit-webhook-mode string                   Strategy for sending audit events. Blocking indicates sending events should block server responses. Batch causes the backend to buffer and write events asynchronously. Known modes are batch,blocking,blocking-strict. (default "batch")
      --audit-webhook-truncate-enabled              Whether event and batch truncating is enabled.
      --audit-webhook-truncate-max-batch-size int   Maximum size of the batch sent to the underlying backend. Actual serialized size can be several hundreds of bytes greater. If a batch exceeds this limit, it is split into several batches of smaller size. (default 10485760)
      --audit-webhook-truncate-max-event-size int   Maximum size of the audit event sent to the underlying backend. If the size of an event is greater than this number, first request and response are removed, and if this doesn't reduce the size enough, event is discarded. (default 102400)
      --audit-webhook-version string                API group and version used for serializing audit events written to webhook. (default "audit.k8s.io/v1")
```
