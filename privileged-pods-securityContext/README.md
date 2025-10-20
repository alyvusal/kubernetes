# [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

[back](../README.md)

| Field                      | Pod-level                                     | Container-level                     | Notes                                     |
| -------------------------- | --------------------------------------------- | ----------------------------------- | ----------------------------------------- |
| `runAsUser`                | ✅ Sets default user ID for *all* containers   | ✅ Can override per container        | Container setting takes precedence        |
| `runAsGroup`               | ✅ Default group for all containers            | ✅ Can override                      | Useful for volume ownership consistency   |
| `fsGroup`                  | ✅ Affects **mounted volumes’ file ownership** | ❌ Not valid                         | Ensures group-writable shared volumes     |
| `supplementalGroups`       | ✅ Adds extra group IDs for all containers     | ❌ Not valid                         | For NFS/GlusterFS group permissions       |
| `fsGroupChangePolicy`      | ✅ Controls how volume ownership is changed    | ❌                                   | Added for performance optimization        |
| `capabilities`             | ❌                                             | ✅ Add/drop Linux capabilities       | Example: `NET_ADMIN`, `SYS_TIME`          |
| `privileged`               | ❌                                             | ✅ Runs container in privileged mode | Never use unless absolutely needed        |
| `readOnlyRootFilesystem`   | ❌                                             | ✅ Mounts root FS as read-only       | Good security hardening                   |
| `procMount`                | ❌                                             | ✅ Controls `/proc` exposure         | Default: `Default`; can be `Unmasked`     |
| `allowPrivilegeEscalation` | ❌                                             | ✅ Controls `no_new_privs` flag      | Prevents process gaining extra privileges |
| `seccompProfile`           | ❌                                             | ✅ Controls syscall filtering        | Reduces kernel attack surface             |
| `appArmorProfile`          | ❌                                             | ✅ Controls AppArmor enforcement     | Linux MAC profile per container           |
| `seLinuxOptions`           | ✅ Applies to all containers (can override)    | ✅ Override allowed                  | Enforces SELinux label isolation          |
