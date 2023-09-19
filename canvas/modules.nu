# Get a module in a course.
export def main [
  --module(-m): any
  --course(-c): any
  --include(-i): list # Additional fields to include. Allowed values: items, content_details
  --student(-s): string # Returns module completion information for the student with this id.
] {
  $in
  | default $module
  | default []
  | each {|mod|
    let course_id = (
      $mod
      | default course_id (id-of $course)
      | get course_id
    )

    if $course_id == null {
      error make {
        msg: $"Cannot find course id for module:\n($mod | table)"
      }
    }

    fetch $"/courses/($course_id)/modules/(id-of $mod)"
    | default $course_id course_id
    | default $mod.id module_id
  }
}

# List modules in a course.
export def list [
  --course(-c): any
  --include(-i): list # Additional fields to include. Allowed values: items, content_details
  --search(-f): string # The partial name of the modules (and module items, if 'items' is specified with include[]) to match and return.
  --student(-s): any # Returns module completion information for the student with this id.
] {
  $in
  | default $course
  | default []
  | each {|course|
    paginated-fetch $"/courses/(id-of $course)/modules" {include: $include, search_term: $search, student_id: (id-of $student)}
    | default (id-of $course) course_id
  }
}

# Create and return a new module in a course.
# Accepts courses in the pipeline.
export def create [
  module,
  --course(-c): any
  --name(-n): string # The name of the module.
  --position(-p): int # The position of this module in the course (1-based).
  --unlock-at(-u): string # The date and time the module will be unlocked. Must be in ISO8601 format.
  --require-sequence(-r): bool # Whether or not the module must be completed sequentially.
  --publish-final-grade(-g): bool # Whether to publish the final grade for the course when the module is completed.
  --prerequisite-modules(-q): list # The ids of the modules that must be completed before this one is unlocked.
] {
  $in
  | default $course
  | default []
  | each {|course|
    let course_id = (id-of $course)
    let prerequisite_module_ids = ($prerequisite_modules | each {|it| id-of $it})

    let module = (
    $module
      | default $name name
      | default $position position
      | default $unlock_at unlock_at
      | default $require_sequence require_sequential_progress
      | default $publish_final_grade publish_final_grade
      | default $prerequisite_module_ids prerequisite_module_ids
    )

    post $"/courses/($course_id)/modules" $module
  }
}

# Update and return a module in a course.
# Accepts courses in the pipeline.
export def update [
  module?,
  --course(-c): any
  --name(-n): string
  --position(-p): int # The position of this module in the course (1-based).
  --unlock-at(-u): string # The date and time the module will be unlocked. Must be in ISO8601 format.
  --require-sequence(-r): bool # Whether or not the module must be completed sequentially.
  --publish-final-grade(-g): bool # Whether to publish the final grade for the course when the module is completed.
  --prerequisite-modules(-p): list # The ids of the modules that must be completed before this one is unlocked.
] {
  $in
  | default $course
  | default []
  | each {|course|
    let course_id = (
      id-of $course
      | default $module.course_id
    )

    let prerequisite_module_ids = ($prerequisite_modules | each {|it| id-of $it})

    let module = (
    $module
      | default $name name
      | default $position position
      | default $unlock_at unlock_at
      | default $require_sequence require_sequential_progress
      | default $publish_final_grade publish_final_grade
      | default $prerequisite_module_ids prerequisite_module_ids
    )

    put $"/courses/($course_id)/modules/(id-of $module)" $module
  }
}

# Delete a module in a course.
export def delete [
  module,
  --course(-c): any
] {
  $in
  | default $course
  | default []
  | each {|course|
    let course_id = (
      id-of $course
      | default $module.course_id
    )

    if $course_id == null {
      error make {
        msg: $"Cannot find course id for module:\n($module | table)"
      }
    }

    web delete $"/courses/($course_id)/modules/(id-of $module)"
  }
}

# List module items in a module.
export def list-items [
  --module(-m): any
  --course(-c): any
  --include(-i): list # Additional fields to include. Allowed values: content_details
  --search(-f): string # The partial name of the module items to match and return.
  --student(-s): any # Returns module completion information for the student with this id.
] {
  $in
  | default $module
  | default []
  | each {|mod|
    let course_id = (
      $mod
      | default {}
      | default course_id (id-of $course)
      | get course_id
    )

    if $course_id == null {
      error make {
        msg: $"Cannot find course id for module:\n($mod | table)"
      }
    }

    let params = {
      include: $include,
      search_term: $search,
      student_id: (id-of $student)
    }

    paginated-fetch $"/courses/($course_id)/modules/(id-of $mod)/items" $params
    | default (id-of $mod) module_id
  }
}

# Get information about a module item.
export def get-item [
  --module(-m): any
  --course(-c): any
  --item(-i): any
  --include(-i): list # Additional fields to include. Allowed values: content_details
  --student(-s): any # Returns module completion information for the student with this id.
] {
  $in
  | default $module
  | default []
  | each {|mod|
    let course_id = (
      $mod
      | default {}
      | default course_id (id-of $course)
      | get course_id
    )

    if $course_id == null {
      error make {
        msg: $"Cannot find course id for module:\n($mod | table)"
      }
    }

    let params = {
      include: $include,
      student_id: (id-of $student)
    }

    fetch $"/courses/($course_id)/modules/(id-of $mod)/items/(id-of $item)" $params
    | default (id-of $mod) module_id
  }
}

# Create and return a new module item in a module.
# Accepts modules in the pipeline.
export def create-item [
  item,
  --module(-m): any
  --course(-c): any
  --title(-t): string # The title of the module item.
  --type(-y): string # The type of the module item. Allowed values: File, Page, Discussion, Assignment, Quiz, SubHeader, ExternalUrl, ExternalTool
  --content-id(-i): any # The id of the content to link to.
  --position(-p): int # The position of this item in the module (1-based).
  --indent(-d): int # The number of indentations for this item.
  --page-url(-u): string # The external URL to display for the module item.
  --new-tab(-n): bool # Whether the external tool opens in a new tab.
  --completion-requirement(-c): string # The type of requirement to mark the item as done. Allowed values: must_view, must_submit, must_contribute, min_score
  --completion-min-score(-s): int # The minimum score to pass.
] {
  $in
  | default $module
  | default []
  | each {|mod|
    let course_id = (
      $mod
      | default {}
      | default course_id (id-of $course)
      | get course_id
    )

    if $course_id == null {
      error make {
        msg: $"Cannot find course id for module:\n($mod | table)"
      }
    }

    let item = (
    $item
      | default $title title
      | default $type type
      | default $content_id content_id
      | default $position position
      | default $indent indent
      | default $page_url page_url
      | default $new_tab new_tab
      | default $completion_requirement completion_requirement.type
      | default $completion_min_score completion_requirement.min_score
    )

    post $"/courses/($course_id)/modules/(id-of $mod)/items" {module_item: $item}
    | default (id-of $mod) module_id
  }
}

# Update and return a module item in a module.
# Accepts module items in the pipeline.
export def update-item [
  item,
  --module(-m): any
  --course(-c): any
  --title(-t): string # The title of the module item.
  --type(-y): string # The type of the module item. Allowed values: File, Page, Discussion, Assignment, Quiz, SubHeader, ExternalUrl, ExternalTool
  --content-id(-i): any # The id of the content to link to.
  --position(-p): int # The position of this item in the module (1-based).
  --indent(-d): int # The number of indentations for this item.
  --page-url(-u): string # The external URL to display for the module item.
  --new-tab(-n): bool # Whether the external tool opens in a new tab.
  --completion-requirement(-c): string # The type of requirement to mark the item as done. Allowed values: must_view, must_submit, must_contribute, min_score
  --completion-min-score(-s): int # The minimum score to pass.
] {
  $in
  | default $item
  | default []
  | each {|item|
    let course_id = (
      $item
      | default {}
      | default course_id (id-of $course)
      | get course_id
    )

    let module_id = (
      $item
      | default {}
      | default module_id (id-of $module)
      | get module_id
    )

    if $course_id == null {
      error make {
        msg: $"Cannot find course id for module item:\n($item | table)"
      }
    }

    let item = (
      $item
      | default $title title
      | default $type type
      | default $content_id content_id
      | default $position position
      | default $indent indent
      | default $page_url page_url
      | default $new_tab new_tab
      | default $completion_requirement completion_requirement.type
      | default $completion_min_score completion_requirement.min_score
    )

    put $"/courses/($course_id)/modules/($module_id)/items/(id-of $item)" {module_item: $item}
    | default ($module_id) module_id
  }
}
