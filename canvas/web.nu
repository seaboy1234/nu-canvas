def parse-curl-response [resp] {
  let status = ($resp | parse -r "HTTP/1.1 (?<code>[0-9]+) (?<value>[A-Za-z]+)")
  let head = (
    $resp
    | lines
    | skip
    | drop
    | parse "{key}: {value}"
    | transpose -i -r -d
  )

  let links = (
    if ($head | columns | any {$in == Link}) {
      $head
      | get Link
      | split row ','
      | flatten
      | each {$in | parse '<{url}>; rel="{link}"' | move link --before url}
      | flatten
      | transpose -i -r -d
    }
  )

  let next = ($links | get next -i)

  let body = ($resp | lines | last | from json)

  {
    status: {
      code: ($status.code.0 | into int)
      value: $status.value.0
    }
    next_page: $next
    headers: $head
    body: $body
  }
}

def "to query" [] {
  $in
  | transpose key value
  | where value != null
  | each {|x| if ($x.value | describe | str contains "list") { each {|v| {key: $"($x.key)[]", value: $x.value}} | flatten } else {$x}}
  | flatten
  | update value {|x| $x.value | into string}
  | where value != ''
  | update value {|x| $x.value | url encode}
  | each {$"($in.key)=($in.value)"}
  | str join "&"
}

def get-url [url] {
  $"GET ($url)";

  let resp = ^curl $url -s -D - -X GET -H $"Authorization: Bearer ($env.CANVAS_TOKEN)"

  let resp = parse-curl-response $resp

  if $resp.status.code == 403 {
    $"Error 403: ($resp.status.value)"
    sleep 5sec
    get-url $url
  } else {
    return $resp
  }
}

def build-url [
  base
  path
  query?
] {
  if ($query | is-empty) {
    $"($base)/api/v1($path)"
  } else {
    $"($base)/api/v1($path)?($query)"
  }
}

export def paginated-fetch [
  path
  params? = {}
  --unwrap: string
] {
  1..
  | each {|page| 
    let query = (
      $params
      | upsert per_page 100
      | insert page $page
      | to query
    )
    let url = build-url $env.CANVAS_URL $path $query

    get-url $url
    | update body {|it| 
      if $unwrap != null {
        $it.body | get $unwrap
      } else {
        $it.body
      }
    }
  }
  | take while {|it| ($it.body | length) > 0 and $it.status.code in 200..299}
  | each {|it| $it.body}
  | flatten --all
}

export def fetch [path, params? = {}] {
  let query = ($params | to query)
  let url = build-url $env.CANVAS_URL $path $query

  get-url $url
  | get body
}

export def put [path, data] {
  let url = build-url $env.CANVAS_URL $path
  let authorization = $"Authorization: Bearer ($env.CANVAS_TOKEN)"
  let content_type = "Content-Type: application/json"
  let body = ($data | to json)

  $"PUT ($url)";

  ^curl $url -s -X PUT -H $authorization -H $content_type -d $body
  | from json
}

export def post [path, data] {
  let url = build-url $env.CANVAS_URL $path
  let authorization = $"Authorization: Bearer ($env.CANVAS_TOKEN)"
  let content_type = "Content-Type: application/json"
  let body = ($data | to json)

  $"POST ($url)";

  ^curl $url -s -X POST -H $authorization -H $content_type -d $body
  | from json
}

export def delete [path, data?] {
  let url = build-url $env.CANVAS_URL $path
  let authorization = $"Authorization: Bearer ($env.CANVAS_TOKEN)"
  let content_type = "Content-Type: application/json"
  let body = ($data | to json)

  $"DELETE ($url)";

  ^curl $url -s -X DELETE -H $authorization -H $content_type -d $body
  | from json
}
