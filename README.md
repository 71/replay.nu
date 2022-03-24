replay.nu
=========

Run a command in `bash` from [`nu`](https://github.com/nushell/nushell#readme)
and keep its environment. Inspired by [`replay.fish`](
https://github.com/jorgebucaran/replay.fish).

```nu
> use ./replay.nu [replay]
> 'SSH_AGENT_PID' in $env
false
> replay (ssh-agent)
Agent pid 19159
> 'SSH_AGENT_PID' in $env
true
```

## Caveats
- `replay` cannot receive data from `stdin` or be piped to another command.
