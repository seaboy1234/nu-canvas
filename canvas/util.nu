def dynamic-into [
  type
  filename?
] {
  let val = $in

  if $type == "binary" {
    return ($val | into binary)
  }
  if $type == "bool" {
    return ($val | into bool)
  }
  if $type == "datetime" {
    return ($val | into datetime)
  }
  if $type == "decimal" {
    return ($val | into decimal)
  }
  if $type == "duration" {
    return ($val | into duration)
  }
  if $type == "filesize" {
    return ($val | into filesize)
  }
  if $type == "int" {
    return ($val | into int)
  }
  if $type == "record" {
    return ($val | into record)
  }
  if $type == "sqlite" {
    return ($val | into sqlite $filename)
  }
  if $type == "string" {
    return ($val | into string)
  }
  let span = (metadata $type).span;
  error make {
    msg: $"Cannot convert to ($type)",
    label: {
      text: "Unknown type",
      start: $span.start,
      end: $span.end
    }
  }
}

export def cast [
  column
  type
] {
  $in
  | each { $in | update $column {|it| if ($it | get $column -i) != null {$it | get $column | dynamic-into $type}}}
}

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
