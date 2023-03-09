export def main [
  --module(-m): any
  --course(-c): any
  --include(-i): list # Additional fields to include. Allowed values: items, content_details
  --student(-s): string # Returns module completion information for the student with this id.
] {
  $in
  | default $module
  | default []
  | each {|mod|
    let course_id = (
      $mod
      | default course_id (id-of $course)
      | get course_id
    )

    if $course_id == null {
      error make {
        msg: $"Cannot find course id for module:\n($mod | table)"
      }
    }

    fetch $"/courses/($course_id)/modules/(id-of $mod)"
    | default $course_id course_id
    | default $mod.id module_id
  }
}

export def list [
  --course(-c): any
  --include(-i): list # Additional fields to include. Allowed values: items, content_details
  --search(-f): string # The partial name of the modules (and module items, if 'items' is specified with include[]) to match and return.
  --student(-s): any # Returns module completion information for the student with this id.
] {
  $in
  | default $course
  | default []
  | each {|course|
    paginated-fetch $"/courses/(id-of $course)/modules" {include: $include, search_term: $search, student_id: (id-of $student)}
    | default (id-of $course) course_id
  }
}
