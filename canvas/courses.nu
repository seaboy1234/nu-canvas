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
  --include(-i) # Additional fields to include in the query. Allowed values: students, avatar_url, enrollments, total_students, passback_status, permissions
] {
  $in
  | default $course
  | each { paginated-fetch $"/courses/(id-of $in)/sections" {include: $include}}
  | maybe-flatten
  | into datetime start_at end_at
}

# Fetch assignments for a course.
export def assignments [
  course? #
  --include(-i): list
  --search(-s): string
  --bucket(-b): string
  --sort: string
] {
  $in
  | default $course
  | each {|it|
    fetch $"/courses/(id-of $it)/assignments" {
      include: $include
      search_term: $search
      bucket: $bucket
      sort_by: $sort
    }
    | into datetime created_at updated_at due_at lock_at unlock_at
  }
}

export def tabs [
  course?
] {
  $in
  | default $course
  | each {|it| 
    fetch $"/courses/(id-of $course)/tabs"
    | default false hidden
    | insert course_id (id-of $course)
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
      let migration = {
        migration_type: course_copy
        settings: {
          source_course_id: (id-of $template)
        }
      }

      let template_course = main (id-of $template)

      print $"Copying ($template_course.name) to ($course.name)"

      post $"/courses/(id-of $course)/content_migrations" $migration
    }

    $course
  }
}
