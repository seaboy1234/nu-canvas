# List external tools in a course, account, or group.
export def list [
  thing?
  --scope: string # The scope of the external tool. One of "accounts", "courses", or "groups". Defaults to "accounts".
] {
  $in
  | default $thing
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {|it|
    let scope = (
      $scope
      | default accounts
    )

    paginated-fetch $"/($scope)/(id-of $it)/external_tools"
  }
}

export def delete [
  thing?
  --tool: any # The tool to be deleted.
  --scope: string # The scope of the external tool. One of "accounts", "courses", or "groups". Defaults to "accounts".
] {
  $in
  | default $thing
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | confirm "Delete external tool?"
  | each {|it|
    let scope = (
      match $thing {
        {id: _} => ($scope | default accounts)
        {course_id: _} => "courses"
        {account_id: _} => "accounts"
        {group_id: _} => "groups"
        else => $scope
      }
    )

    web delete $"/($scope)/(id-of $it)/external_tools/(id-of $tool)"
  }
}
