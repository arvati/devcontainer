# devcontainer

https://github.com/microsoft/vscode-dev-containers

https://github.com/devcontainers


https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/common.md

```
./common-debian.sh [Install zsh flag] [Non-root user] [User UID] [User GID] [Upgrade packages flag] [Install Oh My Zsh! flag] [Non-free packages flag]
```

|Argument| Feature option |Default|Description|
|--------|----------------|-------|-----------|
|Install zsh flag| `installZsh` | `true`| A `true`/`false` flag that indicates whether zsh should be installed. |
|Non-root user| `username` |`automatic`| Specifies a user in the container other than root that should be created or modified. A value of `automatic` will cause the script to check for a user called `vscode`, then `node`, `codespace`, and finally a user with a UID of `1000` before falling back to `root`. A value of `none` will skip this step. |
|User UID| `uid` |`automatic`| A specific UID (e.g. `1000`) for the user that will be created modified. A value of `automatic` will pick a free one if the user is created. |
|User GID| `gid` | `automatic`| A specific GID (e.g. `1000`) for the user's group that will be created modified. A value of `automatic` will pick a free one if the group is created. |
| Upgrade packages flag | `upgradePackages` | `true` | A `true`/`false` flag that indicates whether packages should be upgraded to the latest for the distro. |
| Install Oh My Zsh! flag | `installOhMyZsh` | `true` | A `true`/`false` flag that indicates whether Oh My Zsh! should be installed. |
| Non-free packages flag | `nonFreePackages` | `false` | A `true`/`false` flag that non-free channel packages like `manpages-posix` should be installed. |

> **Note:** Previous versions of this script also installed Oh My Bash! but this has been dropped in favor of a simplified, default PS1 since it conflicted with common user configuration. A stub has been added so those that may have referenced it in places like their dotfiles are informed of the change and how to add it back if needed.

