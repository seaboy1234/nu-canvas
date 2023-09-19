# Get the accounts that the current user can view or manage.
export def accounts [
  --as-user(-u): any = self
] {
  paginated-fetch $"/manageable_accounts" {as_user_id: (id-of $as_user)}
}

export def course-accounts [
  --as-user(-u): any = self
] {
  paginated-fetch $"/course_accounts" {as_user_id: (id-of $as_user)}
}

# Get the current user's profile.
export def user [
  --as-user(-u): any = self
] {
  users $as_user
}

# Get the current user's courses.
export def courses [
  --as-user(-u): any = self
  --include(-i): any = [] # 
] {
  paginated-fetch $"/users/(id-of $as_user)/courses" {
    include: $include
  }
}

# Perform a query against the Canvas API and return the rate limit information.
export def rate-limit [] {
  check-rate-limit
}
