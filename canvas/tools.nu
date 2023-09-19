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
