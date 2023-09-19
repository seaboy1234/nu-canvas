
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
    $env.CANVAS_ROOT_ACCOUNT_ID = 1
  }
  if not "CANVAS_MAX_RETRIES" in $env {
    $env.CANVAS_MAX_RETRIES = 3
  }
  if not "CANVAS_DEBUG" in $env {
    $env.CANVAS_DEBUG = true
  }
}

use canvas/util.nu *
use canvas/web.nu *

# Main endpoints
export use canvas/accounts.nu
export use canvas/assignments.nu
export use canvas/courses.nu
export use canvas/enrollments.nu
export use canvas/modules.nu
export use canvas/submissions.nu
export use canvas/terms.nu
export use canvas/tools.nu
export use canvas/users.nu

# Helpful utilities
export use canvas/sis.nu
export use canvas/find.nu
export use canvas/my.nu
