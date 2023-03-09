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

export def lti-tools [
  account?
  --search(-s): string
  --selectable: any
  --include-parents: any
  --placement: string
] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {|account|
    let params = {
      search_term: $search
      selectable: $selectable
      include_parents: $include_parents
      placement: $placement
    }

    paginated-fetch $"/accounts/(id-of $account)/external_tools" $params
    #| default account_id $account.id
  }
}

export def lti-tool [
  id?
  --account(-a): any
] {
  $in
  | default $id
  | each {|tool|
    let account = (
      $tool
      | get -i account_id
      | default $account
      | default $env.CANVAS_ROOT_ACCOUNT_ID
    )

    fetch $"/accounts/(id-of $account)/external_tools/(id-of $tool)"
  }
}
