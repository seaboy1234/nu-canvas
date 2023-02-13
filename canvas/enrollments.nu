def enrollments-impl [
  thing
  params
] {
  mut resource = ""

  if ($thing | describe | str contains "record") {
    if ($thing | columns | any {|it| $it == "course_code"}) {
      $resource = "courses"
    }
    if ($thing | columns | any {|it| $it == "course_id"}) {
      $resource = "sections"
    }
    if ($thing | columns | any {|it| $it == "sortable_name"}) {
      $resource = "users"
    }
  } else {
    $resource = "courses"
  }

  if $resource == "" {
    let span = (metadata $thing).span;
    error make {
      msg: "cannot get this thing's enrollments",
      label: {
          text: "must be a course id or a course, section, or user record",
          start: $span.start,
          end: $span.end
      }
    }
  }

  fetch $"/($resource)/(id-of $thing)/enrollments" $params
}

# Fetch the enrollments for a course, course section, or user.
export def list [
  thing? # A course id or a course, section, or user. Can be passed by pipe.
  --role: list # Filter to these roles. Accepts role types or a role id.
  --state: list # Filter to these enrollment states. Accepted values: active, invited, creation_pending, deleted, rejected, completed, inactive, current_and_invited, current_and_future, current_and_concluded.
  --include: list # Additional information to include on the enrollment or user records. Accepted values: avatar_url, group_ids, locked, observed_users, can_be_removed, uuid, current_points.
  --user: any # Filter by user for course or section queries. Accepts user record or user id.
  --grading-period: any # Return grades for the given grading period. If not specified, returns grades for the whole course.
  --enrollment-term: any # Return enrollments only for the specified term. Applies only when `thing` is a user. Accepts a term record, id, or sis_term_id.
  --sis-account-ids: list # Returns only enrollments for the specified SIS account ID(s). Does not look into sub_accounts. May pass in array or string.
  --sis-course-ids: list # Returns only enrollments matching the specified SIS course ID(s). May pass in array or string.
  --sis-section-ids: list # Returns only section enrollments matching the specified SIS section ID(s). May pass in array or string.
  --sis-user-ids: list # Returns only enrollments for the specified SIS user ID(s). May pass in array or string.
] {
  $in
  | default $thing
  | each{|it|
    enrollments-impl $it {
      role: $role
      state: $state
      include: $include
      user_id: (id-of $user)
      grading_period:_id (id-of $grading_period)
      enrollment_term_id: (id-of $enrollment_term)
      sis_account_id: $sis_account_ids
      sis_course_id: $sis_course_ids
      sis_section_id: $sis_section_ids
      sis_user_id: $sis_user_ids
    }
  }
}
