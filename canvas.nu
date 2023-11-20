
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

# Some of the functions' names clash, so provide an escape hatch if a module needs to disambiguate
use canvas/web.nu 

# Main endpoints
export use canvas/accounts.nu
export use canvas/assignments.nu
export use canvas/enrollments.nu
export use canvas/courses.nu
export use canvas/gradebook.nu
export use canvas/discussions.nu
export use canvas/modules.nu
export use canvas/pages.nu
export use canvas/quizzes.nu
export use canvas/roles.nu
export use canvas/submissions.nu
export use canvas/terms.nu
export use canvas/tools.nu
export use canvas/users.nu
export use canvas/notifications.nu
export use canvas/groups.nu

# Helpful utilities
export use canvas/sis.nu
export use canvas/find.nu
export use canvas/my.nu

# Print information about this tool
export def main [] {
  let canvas_url = $env.CANVAS_URL
  let root_account = (accounts $env.CANVAS_ROOT_ACCOUNT_ID)
  let current_user = (my user)

  print $"---=== (ansi yb)Canvas Admin Toolbox(ansi reset) ===---"
  print "Version: 0.1.0"
  print "A nushell tool for interacting with Canvas LMS"
  print ""

  print "Instance information:"
  print $"    Canvas URL: (ansi green)($canvas_url)(ansi reset)"
  print $"    Root account: (ansi green)($root_account.name)(ansi reset)"

  print ""

  print "User information:"
  print $"    Current user: (ansi green)($current_user.name)(ansi reset)"
  print $"    Current user ID: (ansi green)($current_user.id)(ansi reset)"
  print $"    Current user email: (ansi green)($current_user.email)(ansi reset)"
  
  print ""
  print "Run 'help canvas' for more information"
}
