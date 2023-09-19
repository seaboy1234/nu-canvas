# List enrollment terms in an account
export def list [
  account?
  --include(-i): list
  --state(-s): list
] {
  $in
  | default $account
  | each {|it|
    paginated-fetch --unwrap enrollment_terms $"/accounts/(id-of $it)/terms" {include: $include, workflow_state: $state}
    | each {|it| try {into datetime start_at} catch {$it} } # These fields can be null, but `into datetime` throws on null
    | each {|it| try {into datetime end_at} catch {$it} }
    | each {|it| try {into datetime created_at} catch {$it} }
  }
  | maybe-flatten
}

# Get an enrollment term
export def main [
  term?
  --account(-a): int = 1
] {
  $in
  | default $term
  | each {|it|
    fetch $"/accounts/(id-of $account)/terms/(id-of $it)"
  }
  | maybe-flatten
}
