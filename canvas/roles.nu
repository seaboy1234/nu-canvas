export def main [
  role # The id of the role to fetch
  --account(-a): any
] {
  $in
  | default $role
  | each {|role|
    let account = (
      $account
      | default $env.CANVAS_ROOT_ACCOUNT_ID
    )

    fetch $"/accounts/(id-of $account)/roles/(id-of $role)"
  }
}

export def list [
  --account(-a): any # The id of the account to retrieve roles for. Defaults to the root account.
  --state(-s): list # Filter by role state. If this argument is omitted, only 'active' roles are returned. Allowed values: active, inactive 
  --include-inherited(-i) # If this argument is true, all roles inherited from parent accounts will be included.
] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {|account|
    paginated-fetch $"/accounts/(id-of $account)/roles" {
      show_inherited: $include_inherited
      state: $state
    }
    | default null account
  }
}
