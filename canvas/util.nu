export def maybe-flatten [] {
  if ($in | describe | str starts-with "record") {
    $in
  } else if ($in | length) == 1 {
    $in | first
  } else {
    $in | flatten
  }
}

export def id-of [thing] {
  if ($thing | describe | str starts-with "record") {
    return $thing.id
  } else if ($thing | describe | str starts-with "list") {
    return $thing.id
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
