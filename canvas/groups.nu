export def main [
  --group: any
  --include: list # Additional objects to include in the output. Allowed values: permissions, tabs.
] {
  $in
  | default $group
  | each {|it|
    paginated-fetch $"/groups/(id-of $it)" {
      include: $include
    }
  }
}

export def list [
  context?: any # List groups in this context. If context is not specified, use the pipeline input. If neither are specified, list groups in the root account.
  --scope: string # Only list groups that are in this context. Allowed values: course, account. If not specified, list groups in the context specified by the context parameter.
] {
  $in
  | default $context
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {|it|
    let local_scope = (
      if (($scope | default "") =~ "course|account") {
        $scope
      } else {
        match $it {
          {id: _} => "account"
          {course_id: _} => "course"
          {account_id: _} => "account"
          _ => "account"
        }
      }
    )

    let it = (
      match $it {
        {id: _} => $it.id
        {course_id: _} => $it.course_id
        {account_id: _} => $it.account_id
        _ => $it
      }
    )

    paginated-fetch $"/($local_scope)s/($it)/groups"
  }
}

export def enroll [
  --group: any
  --user: any
] {
  $in
  | default $group
  | each {|it|
    post $"/groups/(id-of $it --prefix group)/memberships" {
      user_id: (id-of ($it | get user_id -i | default $user)),
      workflow_state: "accepted",
    }
  }
}

export def unenroll [
  --group: any
  --user: any
] {
  $in
  | default $group
  | each {|it|
    delete $"/groups/(id-of $it)/memberships/(id-of ($it | get user_id -i | default $user))"
  }
}

export def members [
  --group: any
  --states: list # Only list memberships with the given workflow_states. By default it will return all memberships.
] {
  $in
  | default $group
  | each {|it|
    paginated-fetch $"/groups/(id-of $it)/memberships" {
      filter_states: $states
    }
  }
}
