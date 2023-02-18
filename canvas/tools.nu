export def list [
  thing?
  --scope: string # courses, accounts, or groups
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
