# Get a quiz from a course
export def main [
  --course(-c): any # The course to get the quiz from
  --quiz(-q): any # The quiz to get. Defaults to the front quiz
] {
  $in
  | each {|it|
    let course = (
        match $it {
          {course: $course} => $course
          {course_id: $course_id} => $course_id
          _ => $course
        }
      )

    fetch $"/courses/(id-of $course)/quizzes/(id-of $it)"
  }
}

# Get all quizzes from a course
export def list [
  --course(-c): any
  --search(-s): string # Search for quizzes with a matching title
] {
  $in
  | default $course
  | each {|it|
    paginated-fetch $"/courses/(id-of $it)/quizzes" {search_term: $search}
  }
}

export def questions [
  --course(-c): any
  --quiz(-q): any
] {
  $in
  | default $quiz
  | each {|it|
    let course = (
        match $it {
          {course: $course} => $course
          {course_id: $course_id} => $course_id
          _ => $course
        }
      )

    paginated-fetch $"/courses/(id-of $course)/quizzes/(id-of $it)/questions"
  }
}
