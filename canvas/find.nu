export def user [
  search?
] {
  $in
  | default $search
  | each {|it| 
    $env.CANVAS_ROOT_ACCOUNT_ID
    | users list --search $it
    | users get
    | flatten
    | where {|it| [$it.name, $it.email, $it.sis_user_id, $it.login_id] | any {|it|( $it | str downcase) =~ ($search | str downcase)}}
  }
}
