export def list [
  --include(-i): list
] {
  paginated-fetch $"/accounts" {include: $include}
}

export def subaccounts [account?, --recursive(-r)] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each { paginated-fetch $"/accounts/(id-of $in)/sub_accounts" {recursive: $recursive} }
  | maybe-flatten
}

export def main [account?] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each { fetch $"/accounts/(id-of $in)" }
  | maybe-flatten
}

export def sandbox [] {
  fetch $"/manually_created_courses_account"
}

export def help-links [account?] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {fetch $"/accounts/(id-of $in)/help_links"}
  | maybe-flatten
}
