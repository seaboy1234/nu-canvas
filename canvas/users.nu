export def edit [
  user?
  --override-sis(-o)
] {
  $in
  | default $user
  | each {|user|
    let params = (
      $user
      | select -i name short_name sortable_name time_zone email locale title bio pronouns event avatar
      | transpose key value
      | where value != null
      | wrap user
      | merge {override_sis_stickiness: $override_sis}
    )

    put $"/users/(id-of $user)" $params
  }
  | maybe-flatten
}

export def list [
  account?
] {
  $in
  | default $account
  | default 2
  | each {
    paginated-fetch $"/accounts/(id-of $in)/users"
    | update created_at {|it| $it.created_at | try { into datetime }}
  }
}

export def missing-submissions [
  user?
  --include(-i): list # Additional fields to include. Allowed values: planner_overrides, course
  --filter: list # Filter by assignment attributes. Allowed values: submittable, current_grading_period
  --courses: list # Optionally restricts the list of past-due assignments to only those associated with the specified course IDs.
] {
  $in
  | default $user
  | default self
  | each {|user| fetch $"/users/(id-of $user)/missing_submissions"}
  | maybe-flatten
}

export def get [
  user?
  --include(-i): list
    # Array of additional information to include on the user record. “locale”, “avatar_url”, “permissions”, “email”,
    # and “effective_locale” will always be returned. Allowed values: uuid, last_login
] {
  $in
  | default $user
  | default self
  | each {
    fetch $"/users/(id-of $in)/"
    | update created_at {|it| $it.created_at | try { into datetime }}
  }
  | maybe-flatten
}

export def logout [
  user?
] {
  $in
  | default $user
  | default self
  | each { ^delete $"/users/(id-of $in)/sessions"}
}

export def get-settings [
  user?
] {
  $in
  | default $user
  | default self
  | each {|user| fetch $"/users/(id-of $user)/settings"}
  | maybe-flatten
}

export def "settings update" [
  settings?
  --user(-u): any = self
] {
  let settings = (
    $in
    | default $settings
    | select -i manual_mark_as_read release_notes_badge_disabled collapse_global_nav collapse_course_nav hide_dashcard_color_overlays comment_library_suggestions_enabled elementary_dashboard_disabled
  )
  put $"/users/(id-of $user)/settings" $settings
}

export def profile [
  user?
] {
  $in
  | default $user
  | default self
  | each {fetch $"/users/(id-of $in)/profile"}
  | maybe-flatten
}

export def courses [
  user?
] {
  $in
  | default $user
  | default self
  | each { fetch $"/users/(id-of $in)/courses"}
  | maybe-flatten
}

export def pageviews [
  user?
  --from(-f): datetime
  --to(-t): datetime
] {
  $in
  | default $user
  | default self
  | each {fetch $"/users/(id-of $in)/page_views" {start_time: $from, end_time: $to}}
}
