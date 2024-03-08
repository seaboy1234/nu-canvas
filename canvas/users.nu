# Edit a user's information.
export def edit [
  user? # The user or user id to update.
  --name(-n): string # The full name of the user.
  --short-name(-s): string # The abbreviated name of the user.
  --sortable-name(-S): string # The name of the user that is should be used for sorting groups of users, such as in the gradebook.
  --time-zone(-t): string # The time zone for the user. Allowed time zones are {http://www.iana.org/time-zones IANA time zones} or friendlier {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  --email(-e): string # The email address of the user.
  --locale(-l): string # The user's preferred language, from the list of languages Canvas supports in user settings. This is in RFC-5646 format.
  --title(-T): string # The user's title.
  --bio(-b): string # A short bio for the user.
  --pronouns(-p): string # The pronouns of the user.
] {
  $in
  | default $user
  | each {|user|
    let user_params = (
      $user
      | select -i name short_name sortable_name time_zone email locale title bio pronouns
      | transpose key value
      | where value != null
      | wrap user
    )

    let params = {
      name: $name, 
      short_name: $short_name, 
      sortable_name: $sortable_name, 
      time_zone: $time_zone, 
      email: $email, 
      locale: $locale, 
      title: $title, 
      bio: $bio, 
      pronouns: $pronouns
    }

    let params = (
      $user
      | merge $params
    )

    put $"/users/(id-of $user)" {user: $params}
  }
  | maybe-flatten
}

# List users in an account.
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

# List a user's missing submissions in one or more courses, or in all courses.
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
  | to-datetime due_at lock_at unlock_at created_at updated_at peer_reviews_assign_at 
  | to-datetime overrides.due_at overrides.lock_at overrides.unlock_at overrides.all_day_date
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

# Terminate a user's session. If no user is specified, the current user's session is terminated.
# WARNING: This will revoke your configured access token if you are terminating your own session.
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

# Update a user's settings.
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

# Get a user's communication channels.
export def comm-channels [
  user?
] {
  $in
  | default $user
  | default self
  | each {|it| fetch $"/users/(id-of $it)/communication_channels" }
}

export def "comm-channels delete" [
  user? # The user to delete the communication channel from.
  --channel(-c): any # The communication channel to delete. Use the id of the communication channel.
] {
  $in
  | default $user
  | default self
  | each {|it| web delete $"/users/(id-of $it)/communication_channels/(id-of $channel)"}
}

# Get a user's profile.
export def profile [
  user?
] {
  $in
  | default $user
  | default self
  | each {|it| fetch $"/users/(id-of $it)/profile"}
  | maybe-flatten
}

# List a user's courses.
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
