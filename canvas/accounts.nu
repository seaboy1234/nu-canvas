# List accounts in this Canvas instance
export def list [
  --include(-i): list
] {
  paginated-fetch $"/accounts" {include: $include}
}

# List an account's sub-accounts
export def subaccounts [account?, --recursive(-r)] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {|x| paginated-fetch $"/accounts/(id-of $x)/sub_accounts" {recursive: $recursive} }
}

# Get information about an account or accounts. If no account is specified, the root account is used.
export def main [
  account? # The account to get information about. If not specified, the root account is used.
] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {|x| fetch $"/accounts/(id-of $x)" }
  | maybe-flatten
}

# Get the manually created courses account for this Canvas instance
export def sandbox [] {
  fetch $"/manually_created_courses_account"
}

# List the help links for an account
export def help-links [account?] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {|x| fetch $"/accounts/(id-of $x)/help_links"}
  | maybe-flatten
}

# List the available LTI tools for an account.
export def lti-tools [
  account?
  --search(-s): string # The search term to filter the results by.
  --selectable: any # If true, only return tools that can be selected in the account navigation. If false, only return tools that cannot be selected in the account navigation. If not present, return all tools.
  --include-parents: any # If true, include tools from parent accounts. If false, only return tools from the specified account. If not present, return tools from the specified account and its parents.
  --placement: string # The placement to filter the results by. If not present, return all tools.
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

# Get information about an LTI tool
export def lti-tool [
  id?
  --account(-a): any # The account to get the tool from. If not specified, the root account is used.
] {
  $in
  | default $id
  | each {|tool|
    let account = (
      match $tool {
        {account_id: $id} => $id
        {id: $id} => $id
        _ => ($account | default $env.CANVAS_ROOT_ACCOUNT_ID)
      }
    )

    fetch $"/accounts/(id-of $account)/external_tools/(id-of $tool)"
  }
}

export def admins [
  --users: list # Scope the results to those with user IDs equal to any of the IDs specified here.
  --account: any # The account to get the admins from. If not specified, the root account is used.
] {
  let params = {
    user_ids: $users
  }

  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {|account|
    paginated-fetch $"/accounts/(id-of $account)/admins" $params
  }
}
