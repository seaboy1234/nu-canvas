export def main [
  course_id
    # The id of the course to fetch. Accepts SIS ids when prefixed with sis_course_id:
  --include(-i): list
    # Additional information to include in the result. Allowed values: needs_grading_count, syllabus_body,
    # public_description, total_scores, current_grading_period_scores, term, account, course_progress,
    # sections, storage_quota_used_mb, total_students, passback_status, favorites, teachers, observed_users,
    # all_courses, permissions, course_image, banner_image, concluded
  --max-teachers(-t): int
    # The maximum number of teacher enrollments to show. If the course contains more teachers than
    # this, instead of giving the teacher enrollments, the count of teachers will be given under a
    # teacher_count key.
] {
  fetch $"/courses/(id-of $course_id)" {include: $include, teacher_limit: $max_teachers}
  | to-datetime created_at end_at start_at 
}

# Retrieve a paginated list of courses.
#
# See https://canvas.instructure.com/doc/api/accounts.html#method.accounts.courses_api
export def list [
  --account(-a): any # The account to search in. Defaults to the configured root account.
  --enrollment-type(-t): list # If set, only return courses that have at least one user enrolled in in the course with one of the specified enrollment types. Allowed values: `teacher`, `student`, `ta`, `observer`, `designer`
  --published(-p): any # If true, only return courses that are published. If false, return only courses that are unpublished. If ommited, return all courses
  --completed(-c): any # If true, only return courses that are completed. If false, return only courses that are not completed. If ommited, return all courses
  --blueprint(-b): any # If true, only return blueprint courses. If false, return only non-blueprint courses. If ommited, return all courses
  --state(-w): list # Search for courses by workflow state. Valid states: created, claimed, available, deleted, all. By default, all states but deleted are returned.
  --search(-s): string # The search term
  --include(-i): list # Additional fields to include. Allowed values: syllabus_body, term, course_progress, storage_quota_used_mb, total_students, teachers, account_name, concluded
  --with-enrollments: any # If true, include only courses with at least one enrollment. If false, include only courses with no enrollments. If not present, do not filter on course enrollment status.
  --blueprint-associated: any # If true, only return courses that are associated with a blueprint. If false, return only courses that are not associated with a blueprint. If ommited, return all courses
  --teachers: list # If supplied, only include courses taught by the specified users
  --subaccounts: list # If supplied, only search for courses in the specified subaccounts
  --term: int # If supplied, only search in the specified enrollment terms
  --sort: string # The column to sort values by. Allowed values: course_name, sis_course_id, teacher, account_name
  --order: string # The order to sort by. Allowed values: asc, desc
  --search-by: string # The filter to search by. "course" searches for course names, course codes, and SIS IDs. "teacher" searches for teacher names
  --starts-before: datetime # If set, only return courses that start before the value (inclusive) or their enrollment term starts before the value (inclusive) or both the course's start_at and the enrollment term's start_at are set to null.
  --ends-after: datetime # If set, only return courses that end after the value (inclusive) or their enrollment term ends after the value (inclusive) or both the course's end_at and the enrollment term's end_at are set to null.
] {
  let accounts = (
    $in
    | default $account
    | default $env.CANVAS_ROOT_ACCOUNT_ID
  )

  let params = {
    with_enrollments: $with_enrollments
    enrollment_type: $enrollment_type
    published: $published
    completed: $completed
    blueprint: $blueprint
    blueprint_associated: $blueprint_associated
    by_teachers: ($teachers | each {|it| id-of $it })
    by_subaccounts: ($subaccounts | each {|it| id-of $it })
    state: $state
    enrollment_term_id: (id-of $term)
    search_term: $search
    include: $include
    sort: $sort
    order: $order
    search_by: $search_by
    starts_before: $starts_before
    ends_after: $ends_after
  }

  $accounts
  | each {|it|
    paginated-fetch $"/accounts/(id-of $it)/courses" $params 
    | update created_at {|it| $it.created_at | try { into datetime }}
    | update end_at {|it| $it.created_at | try { into datetime }}
    | update start_at {|it| $it.created_at | try { into datetime }}
  }
}

# Retrieve a list of the modules in a course.
# export alias modules = (modules list)

# Retrieve a single course section.
export def section [
  section_id?
  --include(-i) # Additional fields to include in the query. Allowed values: students, avatar_url, enrollments, total_students, passback_status, permissions
] {
  $in
  | default $section_id
  | each {|it|
    fetch $"/sections/($it)"
  }
  | maybe-flatten
  | update created_at {|it| $it.created_at | try { into datetime }}
  | update end_at {|it| $it.created_at | try { into datetime }}
  | update start_at {|it| $it.created_at | try { into datetime }}
}

# List the sections in one or more courses.
export def "list sections" [
  course? # The course to search in. Defaults to the pipeline input.
  --include(-i): list # Additional fields to include in the query. Allowed values: students, avatar_url, enrollments, total_students, passback_status, permissions
] {
  $in
  | default $course
  | each {|it| paginated-fetch $"/courses/(id-of $it)/sections" {include: $include}}
  | update created_at {|it| $it.created_at | try { into datetime }}
  | update end_at {|it| $it.end_at | try { into datetime }}
  | update start_at {|it| $it.start_at | try { into datetime }}
}

# List the users in one or more courses.
export def users [
  course?: any
  --include(-i): list # Additional fields to include in the query. Allowed values: avatar_url, enrollments, email, locale, last_login, pseudonym, time_zone, total_scores, current_grading_period_scores, current_grading_period_totals, final_grading_period_scores, final_grading_period_totals, permissions, observed_users, custom_links, group_ids, avatar_url, enrollments, email, locale, last_login, pseudonym, time_zone, total_scores, current_grading_period_scores, current_grading_period_totals, final_grading_period_scores, final_grading_period_totals, permissions, observed_users, custom_links, group_ids
  --search(-s): string
  --sort: string
  --type: list
  --role: string
  --role-id: int
  --users: list
  --state: list
] {
  $in
  | default $course
  | each {|course|
    paginated-fetch $"/courses/(id-of $course)/users" {
      include: $include
      search_term: $search
      sort: $sort
      enrollment_type: $type
      enrollment_role: $role
      enrollment_role_id: $role_id
      enrollment_state: $state
      user_ids: ($users | each {|it| id-of $it})
    }
  }
}

# Get a single user in a course.
export def user [
  course?: any
  --users(-u): any
  --include(-i): list
] {
  $in
  | default $course
  | each {|course|
    $users
    | each {|user|
      fetch $"/courses/(id-of $course)/users/(id-of $user)" {include: $include}
    }
  }
}

# List the tabs in a course's navigation.
export def tabs [
  course?
] {
  $in
  | default $course
  | each {|it|
    fetch $"/courses/(id-of $it)/tabs"
    | default false hidden
    | insert course_id (id-of $it)
  }
}

# Update the position or visibility of a tab.
export def "tabs update" [
  tab?
  --course(-c)
] {
  $in
  | default $tab
  | each {|it|
    let course = (
      $it
      | default $course course_id
      | get course_id
    )
    let attrs = (
      $it
      | select position hidden -i
    )
    put $"/courses/(id-of $course)/tabs/(id-of $it)" $attrs
  }
}

# Toggle the visibility of a tab.
export def "tabs toggle" [
  predicate: closure
] {
  $in
  | each {|course|
    tabs $course
    | where {|it| (do $predicate $it) == true}
    | each {|it|
      $it
      | update hidden {|it| not $it.hidden}
      | tabs update
    }
  }
}

# Create one or more new courses
# 
# See https://canvas.instructure.com/doc/api/courses.html#method.courses.create
export def create [
  attrs?: table
  --account(-a): any # The account to create this course in
  --name(-n): string # The name of the course
  --short-name(-s): string # The short name of the course
  --sis-id(-i): string # The SIS ID of the course

  --offer(-o) # Whether to make this course public
  --enroll-me(-e) # Whether to enroll the caller (default: false)
  --teacher(-t): any # Enroll a teacher user
  --reactivate(-r): any # Whether to reactivate a previously deleted course with the same SIS id (default: true)
] {
  $in
  | default $attrs
  | default {}
  | each {|it|
    let offer = (
      $it
      | get offer -i
      | default $offer
    )
    
    let enroll_me = (
      $it
      | get enroll_me -i
      | default $enroll_me
    )

    let reactivate = (
      $it
      | get reactivate -i
      | default $reactivate
      | default true
    )

    let account = (
      $it
      | get account -i
      | default $account
      | default (accounts sandbox)
    )

    let template = (
      $it 
      | get template -i
      | do {|it| 
        try { $it | into int } catch {$it}
      } $in
    )

    let options = {
      course: (
        $it
        | maybe-reject offer enroll_me reactivate account template
        | add $name name
        | add $name course_code
        | default "Unnamed Course" name
        | default "Unnamed Course" course_code
      )
      offer: $offer
      enroll_me: $enroll_me
      enable_sis_reactivation: false
    }

    print $"Creating ($options.course.name)"

    $options;

    let course = (post $"/accounts/(id-of $account)/courses" $options)

     if $template != null {
       copy --from $template --to $course
     }
     
     if $teacher != null {
       
       enrollments create -y --course=$course --user=$teacher --role=teacher --state=active --notify
     }

    $course
  }
}

export def edit [
  attrs?
  --course: any
  --account: any
  --name: string
  --short-name: string
  --start-at: datetime
  --end-at: datetime
  --license: string
  --description: string
  --term: any
  --sis-id: string
  --quota: int
  --state: string
  --home: string
  --syllabus-body: string
  --format: string
] {
  $in
  | default $attrs
  | default {}
  | add $course id
  | add $name name
  | add $short_name course_code
  | add (id-of $account) account_id
  | add $start_at start_at
  | add $end_at end_at
  | add $license license
  | add $description public_description
  | add (id-of $term) term_id
  | add $sis_id sis_course_id
  | add $quota storage_quota_mb
  | add $state event
  | add $home default_view
  | add $syllabus_body syllabus_body
  | add $format course_format
  | each {|it| 
    let params = {
      course: (
        $it
        | maybe-reject id
      )
    }

    echo $params;

    put $"/courses/(id-of $it)" $params
  }
}

export def copy [
  --from(-f): any
  --to(-t): any
  --only(-o): list
] {
  let template_course = (main (id-of $from))

  let migration = {
    migration_type: "course_copy_importer"
    settings: {
      source_course_id: $template_course.id
    }
  }

  print $"Copying ($template_course.name) to ($to.name)"

  let resp = (post $"/courses/(id-of $to)/content_migrations" $migration)

  if ($resp | get message -i) != null {
    error make {
      msg: $"Failed to create content migration: ($resp.message)"
    }
  }
}

export def imports [
  --course(-c): any
] {
  $in
  | default $course
  | each {|it|
    fetch $"/courses/(id-of $it)/content_migrations"
  }
}

export def delete [
  --course(-c): any
  --no-prompt(-y)
] {
  $in
  | default $course
  | each {|it|
    main $it
  }
  | confirm "Are you sure you want to delete these courses?" $no_prompt
  | each {|it|
    web delete $"/courses/(id-of $it)" {event: "delete"}
  }
}

export def conclude [
  --course(-c): any
  --no-prompt(-y)
] {
  $in
  | default $course
  | each {|it|
    main $it
  }
  | confirm "Are you sure you want to conclude these courses?" $no_prompt
  | each {|it|
    web delete $"/courses/(id-of $it)" {event: "conclude"}
  }
}
