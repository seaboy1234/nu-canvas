export def history [
  --course(-c): any # course to get history for
  --assignment(-a): any # The ID of the assignment for which you want to see submissions. If absent, versions of submissions from any assignment in the course are included.
  --student(-s): any # The ID of the student for which you want to see submissions. If absent, versions of submissions from any student in the course are included.
  --ascending # Return submissions in ascending order by version number. Defaults to false, which returns submissions in descending order by version number.
] {
  $in
  | default [{}]
  | each {|it|
    let params = (
      {}
      | add $assignment assignment_id
      | add $student user_id
      | add $ascending ascending
    )

    let course = (
      match $it {
        {course: $course} => $course
        _ => $course
      }
    )

    paginated-fetch $"/courses/(id-of $course)/gradebook_history/feed" $params --spec
  }
  | flatten --all
}
