# Updates `$env` to match the environment resulting from running the given
# command in `bash`.
#
# Example:
#   > replay (ssh-agent)
export def-env replay [
  ...command: string  # The bash command or script to execute
] {
  let new-env = play-internal ($command | str collect ' ')

  # We can't call `load-env` in `if` or `else` and `return` must be the last
  # command we execute so we must make sure to execute everything at the top
  # level of the function.
  let exit-code = if ($new-env | describe) == 'int' { $new-env } else { 0 }
  let new-env = if ($new-env | describe) == 'int' { {} } else { $new-env }

  $new-env | load-env

  return $exit-code
}

# Executes the given command in `bash` and returns a record similar to `$env`
# corresponding to the environment in `bash` at the end of its execution.
export def play [
  ...command: string  # The bash command or script to execute
] {
  let new-env = play-internal ($command | str collect ' ')

  if ($new-env | describe) == 'int' {
    return $new-env
  } else {
    $new-env
  }
}

# Returns a subset of `new-env` where entries already in `$env` are filtered
# out.
export def diff [
  new-env: any,  # An `$env`-like record
] {
  let raw-env = (env | select name raw | transpose -r | first)

  $new-env
  | transpose key value
  | where key not-in $raw-env || value != ($raw-env | get $it.key)
  | transpose -r
  | first
  | reject _ SHLVL
}

# Actual implementation of `play` which returns the exit code of the command
# in case of failure, or the described record otherwise.
def play-internal [$command: string] {
  let pipe-name = (^mktemp --tmpdir --dry-run 'replay-nu-XXXXXXXXXX' | str trim)

  ^bash -c $"
    ($command)

    env > ($pipe-name)
  "

  let exit-code = $env.LAST_EXIT_CODE

  if $exit-code == 0 {
    open --raw $pipe-name | lines | parse '{key}={value}' | transpose -r | first
  } else {
    $exit-code
  }
}

# Returns from the given function with the given exit code. Due to how Nushell
# works, must be called as the last command in a function.
def return [exit-code: int] {
  ^bash -c $"exit ($exit-code)"
}
