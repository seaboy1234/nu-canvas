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
