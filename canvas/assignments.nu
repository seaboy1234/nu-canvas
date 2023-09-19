# Fetch assignments for a course.
export def list [
  course? #
  --include(-i): list # List of fields to include in the response. Allowed values: submission, assignment_visibility, all_dates, overrides, observed_users, can_edit, score_statistics
  --search(-s): string # The partial title of the assignments to match and return.
  --bucket(-b): string # If included, only return certain assignments depending on deu date and submission status. Allowed values: past, overdue, undated, ungraded, unsubmitted, upcoming, future
  --sort: string # Determines the sort order of returned results. Allowed values: due_at, name, position. Defaults to position.
] {
  $in
  | default $course
  | each {|it|
    paginated-fetch $"/courses/(id-of $it)/assignments" {
      include: $include
      search_term: $search
      bucket: $bucket
      sort_by: $sort
    }
    | each {|it| 
      $it 
      | default (id-of $course) course_id
      | try {into datetime created_at} catch {$it}  # These fields can be null, but `into datetime` throws on null
      | try {into datetime updated_at} catch {$it} 
      | try {into datetime due_at} catch {$it} 
      | try {into datetime lock_at} catch {$it} 
      | try {into datetime unlock_at} catch {$it} 
    }
  }
}

export def main [
  assignment: int
  --course: any
] {
  $in
  | default $course
  | each {|it|
    fetch $"/courses/(id-of $it)/assignments/($assignment)"
    | each {|it| 
      $it 
      | default (id-of $course) course_id
      | try {into datetime created_at} catch {$it}  # These fields can be null, but `into datetime` throws on null
      | try {into datetime updated_at} catch {$it} 
      | try {into datetime due_at} catch {$it} 
      | try {into datetime lock_at} catch {$it} 
      | try {into datetime unlock_at} catch {$it} 
    }
  }
}
