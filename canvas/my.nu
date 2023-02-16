export def accounts [
  --as-user(-u): any
] {
  paginated-fetch $"/manageable_accounts" {as_user_id: (id-of $as_user)}
}

export def course-accounts [
  --as-user(-u): any
] {
  paginated-fetch $"/course_accounts" {as_user_id: (id-of $as_user)}
}

export def user [
  --as-user(-u): any = self
] {
  users get $as_user
}

export def courses [
  --as-user(-u): any = self
] {
  paginated-fetch $"/users/(id-of $as_user)/courses"
}

export def rate-limit [] {
  check-rate-limit
}
