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
  --search(-s): string
  --include(-i): list
  --sort: string
  --order: string
] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {|it|
    $it 
    | paginated-fetch $"/accounts/(id-of $it)/users" {search_term: $search, sort: $sort, order: $order, include: $include}
    | to-datetime created_at updated_at last_login
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

# Get a user. If no user is specified, the current user is returned.
export def main [
  user?
  --include(-i): list
    # Array of additional information to include on the user record. “locale”, “avatar_url”, “permissions”, “email”,
    # and “effective_locale” will always be returned. Allowed values: uuid, last_login
] {
  $in
  | default $user
  | default self
  | each {|it|
    fetch $"/users/(id-of $it)/" {include: $include}
    | each {|it| try {into datetime created_at} catch {$it} }
  }
  | maybe-flatten
}

export def logout [
  user?
] {
  $in
  | default $user
  | default self
  | each {|it| ^delete $"/users/(id-of $it)/sessions"}
}

# Get a user's settings.
export def settings [
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

export def comm-channels [
  user?
] {
  $in
  | default $user
  | default self
  | each {|it| fetch $"/users/(id-of $it)/communication_channels" }
}

export def profile [
  user?
] {
  $in
  | default $user
  | default self
  | each {|it| fetch $"/users/(id-of $it)/profile"}
  | maybe-flatten
}

export def courses [
  user?
] {
  $in
  | default $user
  | default self
  | each {|it| fetch $"/users/(id-of $it)/courses"}
  | maybe-flatten
}

# List page views for a user. If no user is specified, the current user's page views are returned.
# If no time range is specified, the last 7 days are returned.
export def pageviews [
  user?
  --from(-f): datetime # The beginning of the time range from which you want page views.
  --to(-t): datetime # The end of the time range from which you want page views.
] {
  $in
  | default $user
  | default self
  | each {|it| 
    let $from = ($from | default ((date now) - 7day) | format date "%Y-%m-%dT%H:%M:%SZ")
    let $to = ($to | default (date now) | format date "%Y-%m-%dT%H:%M:%SZ")

    paginated-fetch $"/users/(id-of $it)/page_views" {start_time: $from, end_time: $to} --spec
  }
}
