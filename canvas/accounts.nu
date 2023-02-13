export def list [
  --include(-i): list
] {
  paginated-fetch $"/accounts" {include: $include}
}

def subaccounts-impl [account, --recursive(-r) = false] {

}

export def subaccounts [account?, --recursive(-r)] {
  $in
  | default $account
  | default 1
  | each { paginated-fetch $"/accounts/(id-of $in)/sub_accounts" {recursive: $recursive} }
  | maybe-flatten
}

export def get [account?] {
  $in
  | default $account
  | each { fetch $"/accounts/(id-of $in)" }
  | maybe-flatten
}

export def "get help-links" [account?] {
  $in
  | default $account
  | each {fetch $"/accounts/(id-of $in)/help_links"}
  | maybe-flatten
}

# Retrieve a paginated list of courses in this account.
#
# See https://canvas.instructure.com/doc/api/accounts.html#method.accounts.courses_api
export def courses [
  account? # The account to search in. Must be an id, sis_account_id, or an account object that has an id. Can be supplied by pipe.
  --enrollment-type(-t): list # If set, only return courses that have at least one user enrolled in in the course with one of the specified enrollment types. Allowed values: `teacher`, `student`, `ta`, `observer`, `designer`
  --published(-p): any # If true, only return courses that are published. If false, return only courses that are unpublished. If ommited, return all courses
  --completed(-c): any # If true, only return courses that are completed. If false, return only courses that are not completed. If ommited, return all courses
  --blueprint(-b): any # If true, only return blueprint courses. If false, return only non-blueprint courses. If ommited, return all courses
  --state(-w): list # Search for courses by workflow state. Valid states: created, claimed, available, deleted, all. By default, all states but deleted are returned.
  --search(-s): string # The search term
  --include(-i): list # Additional fields to include. Allowed values: syllabus_body, term, course_progress, storage_quota_used_mb, total_students, teachers, account_name, concluded
  --with-enrollments: any # If true, include only courses with at least one enrollment. If false, include only courses with no enrollments. If not present, do not filter on course enrollment status.
  --blueprint-associated: any # If true, only return courses that are associated with a blueprint. If false, return only courses that are not associated with a blueprint. If ommited, return all courses
  --teachers: list # If supplied, only include courses taught by the specified users
  --subaccounts: list # If supplied, only search for courses in the specified subaccounts
  --term: int # If supplied, only search in the specified enrollment terms
  --sort: string # The column to sort values by. Allowed values: course_name, sis_course_id, teacher, account_name
  --order: string # The order to sort by. Allowed values: asc, desc
  --search-by: string # The filter to search by. "course" searches for course names, course codes, and SIS IDs. "teacher" searches for teacher names
  --starts-before: datetime # If set, only return courses that start before the value (inclusive) or their enrollment term starts before the value (inclusive) or both the course's start_at and the enrollment term's start_at are set to null.
  --ends-after: datetime # If set, only return courses that end after the value (inclusive) or their enrollment term ends after the value (inclusive) or both the course's end_at and the enrollment term's end_at are set to null.
] {
  let accounts = (
    $in
    | default $account
    | default 2
  )

  let params = {
    with_enrollments: $with_enrollments
    enrollment_type: $enrollment_type
    published: $published
    completed: $completed
    blueprint: $blueprint
    blueprint_associated: $blueprint_associated
    by_teachers: ($teachers | each { id-of $in })
    by_subaccounts: ($subaccounts | each { id-of $in })
    state: $state
    enrollment_term_id: (id-of $term)
    search_term: $search
    include: $include
    sort: $sort
    order: $order
    search_by: $search_by
    starts_before: $starts_before
    ends_after: $ends_after
  }

  $accounts
  | each {
    paginated-fetch $"/accounts/(id-of $in)/courses" $params
    | cast created_at datetime
    | cast end_at datetime
    | cast start_at datetime
  }
  | maybe-flatten
}
