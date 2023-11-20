export def history [
  --course(-c): any # course to get history for
  --assignment(-a): any # The ID of the assignment for which you want to see submissions. If absent, versions of submissions from any assignment in the course are included.
  --student(-s): any # The ID of the student for which you want to see submissions. If absent, versions of submissions from any student in the course are included.
  --ascending: bool # Return submissions in ascending order by version number. Defaults to false, which returns submissions in descending order by version number.
] {
  $in
  | default [{}]
  | each {|it|
    let params = (
      {}
      | add $assignment assignment
      | add $student user
      | add $ascending ascending
    )

    let course = (
      match $it {
        {course: $course} => $course
        _ => $course
      }
    )

    paginated-fetch $"/courses/(id-of $course)/gradebook_history/feed" $params
  }
  | flatten --all
}
