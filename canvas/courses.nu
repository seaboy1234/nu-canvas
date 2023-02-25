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
  fetch $"/courses/($course_id)" {include: $include, teacher_limit: $max_teachers}
  | update created_at {|it| $it.created_at | try { into datetime }}
  | update end_at {|it| $it.end_at | try { into datetime }}
  | update start_at {|it| $it.start_at | try { into datetime }}
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
    by_teachers: ($teachers | each { id-of $in })
    by_subaccounts: ($subaccounts | each { id-of $in })
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
  | each { 
    paginated-fetch $"/accounts/(id-of $in)/courses" $params 
    | update created_at {|it| $it.created_at | try { into datetime }}
    | update end_at {|it| $it.created_at | try { into datetime }}
    | update start_at {|it| $it.created_at | try { into datetime }}
  }
}

export def section [
  section_id?
  --include(-i) # Additional fields to include in the query. Allowed values: students, avatar_url, enrollments, total_students, passback_status, permissions
] {
  $in
  | default $section_id
  | each {
    fetch $"/sections/($in)"
  }
  | maybe-flatten
  | into datetime start_at end_at
}

export def "list sections" [
  course?
  --include(-i): list # Additional fields to include in the query. Allowed values: students, avatar_url, enrollments, total_students, passback_status, permissions
] {
  $in
  | default $course
  | each { paginated-fetch $"/courses/(id-of $in)/sections" {include: $include}}
  | maybe-flatten
  | into datetime start_at end_at
}


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
# Top-level options are 
export def create [
  attrs?: table
  --account(-a): any
  --offer(-o)
  --enroll-me(-e)
  --reactivate(-r)
] {
  $in
  | default $attrs
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
        | default "Unnamed Course" name
      )
      offer: $offer
      enroll_me: $enroll_me
      enable_sis_reactivation: $reactivate
    }

    print $"Creating ($it.name)"

    let course = post $"/accounts/(id-of $account)/courses" $options

    if $template != null {
      # TODO: move this logic to a `content-migrations` module
      let template_course = main (id-of $template)

      let migration = {
        migration_type: "course_copy_importer"
        settings: {
          source_course_id: $template_course.id
        }
      }

      print $"Copying ($template_course.name) to ($course.name)"

      let resp = post $"/courses/(id-of $course)/content_migrations" $migration

      if ($resp | get message -i) != null {
        error make {
          msg: $"Failed to create content migration: ($resp.message)"
        }
      }
    }

    $course
  }
}
