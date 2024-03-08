# Get a page from a course
export def main [
  --course(-c): any # The course to get the page from
  --page(-p): any # The page to get. Defaults to the front page
] {
  $in
  | default "front_page"
  | each {|it|
    let course = (
        match $it {
          {course: $course} => $course
          {course_id: $course_id} => $course_id
          _ => $course
        }
      )

    if $it == "front_page" {
      fetch $"/courses/(id-of $course)/front_page"
      | default "teachers" editing_roles
    } else {
      fetch $"/courses/(id-of $course)/pages/(id-of $it)"
      | default "teachers" editing_roles
    }
  }
}

# Get all pages from a course
export def list [
  --course(-c): any
] {
  $in
  | default $course
  | each {|it|
    paginated-fetch $"/courses/(id-of $it)/pages"
    | default "teachers" editing_roles
  }
}

# Create a page in a course
# See https://canvas.instructure.com/doc/api/pages.html#method.wiki_pages_api.create
export def create [
  --course(-c): any # The course to create the page in
  --title(-t): string # The title of the page
  --body(-b): string # The body of the page
] {
  $in
  | default $course
  | each {|it|
    let params = (
      {
        wiki_page: {
          title: $title,
          body: $body
        }
      }
    )
    
    post $"/courses/(id-of $it)/pages" $params
  }
}
