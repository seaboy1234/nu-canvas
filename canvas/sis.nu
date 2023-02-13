export def course [
    sis_id: string
] {
    courses get $"sis_course_id:($sis_id)"
}

export def user [
    sis_id: string
] {
    users get $"sis_user_id:($sis_id)"
}

# export def term [
#     sis_id: string
# ] {
#     terms get $"sis_term_id:($sis_id)"
# }

export def section [
    sis_id: string
] {
    courses get section $"sis_section_id:($sis_id)"
}

# Returns the list of SIS imports for an account.
# 
# See https://canvas.instructure.com/doc/api/sis_imports.html#method.sis_imports_api.index
export def "imports list" [
    account?
    --created-after(-a): datetime # If set, only shows imports created after the specified date.
    --created-before(-b): datetime # If set, only shows imports created before the specified date.
    --state: list # Scope to specified workflow states. Allowed values: initializing, created, importing, cleanup_batch, imported, imported_with_messages, aborted, failed, failed_with_messages, restoring, partially_restored, restored
] {
  $in
  | default $account
  | default $env.CANVAS_ROOT_ACCOUNT_ID
  | each {
    paginated-fetch $"/accounts/($in)/sis_imports" {
      created_before: $created_before
      created_after: $created_after
      workflow_state: $state
    }
  }
}
