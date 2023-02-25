export def list [
  assignment?
  --course(-c): any
  --section(-s): any
  --include(-i): list # Allowed values: submission_history, submission_comments, rubric_assessment, assignment, visibility, course, user, group, read_status
] {
  $in
  | default $assignment
  | each {|it|
    let course = (
      $it
      | get course_id -i
      | default $course
    )
    
    let path = if $course != null {
      $"/courses/(id-of $course)/assignments/(id-of $it)/submissions"
      } else if $section != null {
      $"/sections/(id-of $section)/assignments/(id-of $it)/submissions"
    }

    paginated-fetch $path { include: $include }
    | default (id-of $it) assignment_id
    | default (id-of $course) course_id
    | default (id-of $section) section_id
  }
  | flatten
}
