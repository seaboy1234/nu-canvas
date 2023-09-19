def enrollments-impl [
  thing
  params
] {

  let resource = (
    match $thing {
      {course_code: _} => "courses"
      {course_id: _} => "sections"
      {sortable_name: _} => "users"
      {} => ""
      _ => "courses" 
    }
  )

  if $resource == "" {
    let span = (metadata $thing).span;
    error make {
      msg: $"cannot get this thing's enrollments: ($thing)",
      label: {
          text: "must be a course id or a course, section, or user record",
          start: $span.start,
          end: $span.end
      }
    }
  }

  paginated-fetch $"/($resource)/(id-of $thing)/enrollments" $params --spec
  | each {|it|
    $it
    | to-datetime last_activity_at created_at updated_at
  }
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
  | each {|it|
    enrollments-impl $it {
      role: $role
      state: $state
      include: $include
      user_id: (id-of $user)
      grading_period_id: (id-of $grading_period)
      enrollment_term_id: (id-of $enrollment_term)
      sis_account_id: $sis_account_ids
      sis_course_id: $sis_course_ids
      sis_section_id: $sis_section_ids
      sis_user_id: $sis_user_ids
    }
  }
}

export def conclude [
  enrollment? # An enrollment record or id. Can be passed by pipe.
  --no-confirm(-y) # Don't show the confirmation prompt
  --course(-c): any # The course to conclude the enrollment in. If course_id is specified on the enrollment, this is ignored.
  --task: string # The task to conclude the enrollment with. Accepted values: conclude, delete, inactivate. Defaults to inactivate.
] {
  $in
  | default $enrollment
  | default $task task
  | default "inactivate" task
  | confirm "Conclude these enrollments?" $no_confirm
  | each {|it|
    let path = (
      match $it {
        {course_id: _} => $"/courses/($it.course_id)/enrollments/($it.id)"
        {course: _} => $"/courses/(id-of $it.course)/enrollments/($it.id)"
        {sis_course_id: _} => $"/courses/sis_course_id:($it.sis_course_id)/enrollments/($it.id)"
        _ => (error make {
          msg: "cannot conclude this enrollment",
          label: {
            text: "must be a course id or a course record",
            start: (metadata $it).span.start,
            end: (metadata $it).span.end
          }
        })
      }
    )
    let params = {task: $it.task}

    delete $path $params
  }
}

# Create one or more enrollments. 
# Accepts a "course" or "section" column.
# 
# See https://canvas.instructure.com/doc/api/enrollments.html
export def create [
  enrollment? # A table or record with enrollment fields. Defaults to pipe input
  --course(-c): any # The course to create the enrollment in
  --section: any # The section to create the enrollment in
  --user(-u): any # The user to enroll
  --sis-user: string # The SIS ID of the user to enroll
  --role(-r): string # The role to enroll the user with
  --state(-s): string # The state of the enrollment
  --notify(-n) # Whether to notify the user of this enrollment. Defaults to false.
  --no-confirm(-y) # Don't show the confirmation prompt
] {
  $in
  | default $enrollment
  | default {}
  | default $course course
  | default $section section
  | default (id-of $user) user_id
  | default $"sis_user_id:($sis_user)" user_id
  | default $role role
  | default "StudentEnrollment" role
  | default $state enrollment_state
  | default "invited" enrollment_state
  | default $notify notify
  | update role {|it| $it.role | simple-role-to-enrollment-type}
  | confirm "Create these enrollments?" $no_confirm
  | each {|it|
    let path = (
      if (($it | columns | any {|it| $it == "sis_course_id"}) and $it.sis_course_id != null)  {
        $"/courses/($it.sis_course_id)/enrollments"
      } else if (($it | columns | any {|it| $it == "course"}) and $it.course != null)  {
        $"/courses/(id-of $it.course)/enrollments"
      } else if (($it | columns | any {|it| $it == "section"}) and $it.section != null) {
        $"/sections(id-of $it.section)/enrollments"
      } else {
        let span = (metadata $it).span
        error make {
          msg: "Cannot determine course or section for enrollment",
          label: {
            text: "This record doesn't have a course or section"
            start: $span.start
            end: $span.end
          }
        }
      }
    )
    
    let enrollment = (
      $it
      | maybe-reject course section
      | default 'invited' enrollment_state
      | wrap enrollment
    )
    
    post $path $enrollment
  }
}

def simple-role-to-enrollment-type [] {
  let input = $in
  let role = ($input | str downcase)

  match $role {
    "student" => "StudentEnrollment"
    "teacher" => "TeacherEnrollment"
    "designer" => "DesignerEnrollment"
    "ta" => "TaEnrollment"
    "observer" => "ObserverEnrollment"
    _ => $input
  }
}
