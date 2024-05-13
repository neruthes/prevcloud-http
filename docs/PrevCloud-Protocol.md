---
author: 'Neruthes'
date: '2024-05-15'
---

# PrevCloud Protocol Documentation

[PDF URL on Cloudflare R2 OSS](https://pub-714f8d634e8f451d9f2fe91a4debfa23.r2.dev/prevcloud-http/7595b30ff6d3f6d1aca6cde2/PrevCloud-Protocol.md.pdf)



## Preamble

This document explains the protocol suite known as PrevCloud.
With this protocol suite, we should be able to run a Git-based file sharing workflow.



## Data Synchronization

A user may have multiple personal workspaces which are Git repositories in their HOME on a shared server.
For example, `/home/alice/.PrevCloud0` (known as WS0) may be used as the remote path of the repository;
git repository remote URL `alice@example.com:/home/alice/.PrevCloud0` will be used.



## HTTP Endpoints

A web server will be responsible for serving a file `dir/file.txt` in WS0.
The HTTP endpoint shall be `/alice/0/{token}/dir/file.txt`.

However, some paths are not allowed to be accessed via HTTP:
- Any path that starts with a dot.


## File Access Token

### Algorithm
A token is necessary for protecting files from unauthorized access.
The server shall calculate the token using the following algorithm.

```sh
#!/bin/bash
sha256sum \
    <(TZ=UTC date +%Y%m%d) \
    <(echo dir/file.txt) \
    /home/alice/.PrevCloud0/.master-salt \
    /etc/fstab \
    | cut -d' ' -f1 | sha256sum  \
    | cut -c1-64 | xxd -r -p \
    | base32 | cut -c1-32
```

### Subdirectories
There are occasions that we want to share an entire directory.
This can be done by calculating the token for a directory path instead of a file path.
The input path for the algorithm can be either a file or a directory.

In a directory index page, the visitor can get the URL of subdirectories and files.

### Relative Paths
Sometimes we need tools like [staticalbum](https://github.com/neruthes/staticalbum) or
[staticplayer](https://github.com/neruthes/staticplayer).
Such tools require reliable relative paths.
Therefore, a token of any directory in the parent chain of a file has the right to access the file.
For example, using the token for `/dir`, a visitor can access file `/dir/file.txt`.

### Root Token
There is no need to predict the tokens of files on the client side.
Instead, a root token for entire WS0 will be used.
The client only has to know what the root token is.
This is done by calculating `sha256sum .master-salt | cut -c1-40`.

### Navigating
When navigating into a subdirectory, or navigating to a file which is a direct child of the current directory,
the visitor has 2 options:

- Use relative path (retaining the current token)
- Use absolute path (getting a dedicated token)

This allows the user to restrict the scope of sharing by getting the token of the specific directory.

### Invalid Access
HTTP 404 shall be returned if the workspace root directory does not exist or the web server process has no access to it.

HTTP 403 shall be returned if any other problem occurs, e.g. incorrect token, invalid file path.
