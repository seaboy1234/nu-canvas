
export-env {
  if not "CANVAS_URL" in $env {
    error make {msg: "CANVAS_URL not set"}
    exit 1
  }
  if not "CANVAS_TOKEN" in $env {
    error make {msg: "CANVAS_TOKEN not set"}
    exit 1
  }
  if not "CANVAS_ROOT_ACCOUNT_ID" in $env {
    let-env CANVAS_ROOT_ACCOUNT_ID = 1
  }
  if not "CANVAS_DEBUG" in $env {
    let-env CANVAS_DEBUG = false
  }
}

use canvas/util.nu *
use canvas/web.nu *

# Main endpoints
export use canvas/accounts.nu
export use canvas/courses.nu
export use canvas/enrollments.nu
export use canvas/submissions.nu
export use canvas/terms.nu
export use canvas/tools.nu
export use canvas/users.nu

# Helpful utilities
export use canvas/sis.nu
export use canvas/find.nu
export use canvas/my.nu
