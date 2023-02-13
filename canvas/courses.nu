export def get [
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
  | cast created_at datetime
  | cast end_at datetime
  | cast start_at datetime
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
    | cast created_at datetime
    | cast updated_at datetime
    | cast due_at datetime
    | cast lock_at datetime
    | cast unlock_at datetime
  }
}
