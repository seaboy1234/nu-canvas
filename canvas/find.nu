# Search for users in this Canvas instance. 
# Matches on name, email, SIS ID, and login ID.
export def user [
  search? # The search term to use. Defaults to the pipeline input.
  --field(-f): string # The field from the input to search in. Required if the input is a table.
] {
  $in
  | default $search
  | if $field != null {
    get $field
  } else {
    $in
  }
  | each {|search| 
    $env.CANVAS_ROOT_ACCOUNT_ID
    | users list --search $search
    | users get
    | flatten
    | where {|it| [$it.name, $it.email, $it.sis_user_id, $it.login_id] | any {|it|( $it | str downcase) =~ ($search | str downcase)}}
  }
}

# Search for courses in this Canvas instance.
# Matches on name and SIS ID.
export def course [
  search? # The search term to use. Defaults to the pipeline input.
  --term(-t): any # The term to search in. If not specified, all terms are searched.
  --account(-a): any # The account to search in. If not specified, the root account is searched.
] {
  $in
  | default $search
  | each {|it| 
    $account
    | default $env.CANVAS_ROOT_ACCOUNT_ID
    | courses list --search $it --term $term
    | each {|it| courses $it.id}
    | flatten
    | where {|it| [$it.name, $it.sis_course_id] | any {|it|( $it | str downcase) =~ ($search | str downcase)}}
  }
}
