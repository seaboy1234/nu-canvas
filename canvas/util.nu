export def maybe-flatten [] {
  if ($in | describe | str starts-with "record") {
    $in
  } else if ($in | length) == 1 {
    $in | first
  } else {
    $in | flatten
  }
}

export def to-datetime [
  ...path
] {
  each {|it|
    $path
    | reduce -f $it {|column, acc| 
      if $column in ($acc | columns) {
        $acc
        | update $column {|it| $it | get $column | try { into datetime } catch { null }}
      } else {
        $acc
      }
    }
  }
}

export def id-of [
  thing
  --prefix: any
] {
  let column = if $prefix != null { $prefix + "_id" } else { "id" }

  if ($thing | describe | str starts-with "record") {
    return (
      if $column in ($thing | columns) {
          $thing | get $column
        } else {
          $thing | get "id"
        }
    )
  } else if ($thing | describe | str starts-with "list") {
    return (
      $thing
      | each {|it|
        if $column in ($it | columns) {
          $it | get $column
        } else {
          $it | get "id"
        }
      }
    )
  }

  $thing
}

# Reject columns if they exist in the table. 
# This is a wrapper around `reject` because it
# doesn't allow rejecting columns that aren't
# in the table already.
export def maybe-reject [
  ...columns
] {
  let pipe = $in
  let cols_to_remove = (
    $pipe 
    | columns
    | where {|it| $it in $columns}
  )

  $cols_to_remove
  | reduce -f $pipe {|it, acc| $acc | reject $it}
}

export def confirm [prompt: string = "Are you sure?", bypass_prompt = false] {
  let pipe = $in

  print ($pipe | table);

  mut choice = $bypass_prompt
  mut chosen = $bypass_prompt
  while not $chosen {
    let user_input = (input $"($prompt) [Yn]")
    if (["Y", "y", ""] | any {|it| $it == $user_input}) {
      $choice = true
      $chosen = true
    } else if (["N", "n"] | any {|it| $it == $user_input}) {
      $choice = false
      $chosen = true
    } else {
      print "Invalid choice";
    }
  }

  if $choice {
    $pipe
  } else {
    []
  }
}

export def add [
  value 
  column
] {
  if $value != null {
    $in
    | default $value $column
  } else {
    $in
  }
}
