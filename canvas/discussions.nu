# Get a discussion from a course
export def main [
  --course(-c): any # The course to get the discussion from
  --discussion(-p): any # The discussion to get. Defaults to the front discussion
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

    fetch $"/courses/(id-of $course)/discussion_topics/(id-of $it)"
  }
}

# Get all discussions from a course
export def list [
  --course(-c): any
  --search(-s): string # Search for discussions with a matching title
  --include(-i): string # Additional information to include in the response. Allowed values: `all_dates`, `sections`, `sections_user_count`, `overrides`
  --order(-o): string # The order to return discussions in. Allowed values: `position`, `recent_activity`, `title`
  --scope(-f): string # The scope of discussions to return. Allowed values: `locked`, `unlocked`, `pinned`, `unpinned`
  --only-announcements(-a) # Only return announcements. If false, only return non-announcements. If null, return both announcements and non-announcements.
  --only-unread(-u) # Only return unread discussions. If false, return both read and unread discussions.
] {
  $in
  | default $course
  | each {|it|
    let params = {
      search_term: $search,
      include: $include,
      order_by: $order,
      scope: $scope,
      filter_by: (if $only_unread { "unread" } else { null })
    }

    let params = if $only_announcements {
      $params | insert only_announcements true
    } else {
      $params
    }

    paginated-fetch $"/courses/(id-of $it)/discussion_topics" $params
  }
}
