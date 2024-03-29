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
    if ($head | columns | any {|| $in == Link}) {
      $head
      | get Link
      | split row ','
      | flatten
      | each {|| $in | parse '<{url}>; rel="{link}"' | move link --before url}
      | flatten
      | flatten --all
      | transpose -i -r -d
    }
  )

  let next = ($links | get next -i)

  let last_line = ($resp | lines | last)
  let body = ($last_line | from json)

  {
    status: {
      code: ($status.code?.0 | into int)
      value: $status.value?.0
    }
    links: $links
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
  | each {|x| $"($x.key)=($x.value)"}
  | str join "&"
}

export def check-rate-limit [] {
  get-url (build-url $env.CANVAS_URL "/users/self")
  | get headers
  | get x-rate-limit-remaining
}

def get-url [url] {
  if $env.CANVAS_DEBUG {  
    print $"GET ($url)";
  }

  let resp = (^curl $url -s -D - -X GET -H $"Authorization: Bearer ($env.CANVAS_TOKEN)")

  let resp = (parse-curl-response $resp)

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

def fetch-page [
  path 
  params 
  page
  --unwrap: string
] {
  let query = (
    $params
    | upsert per_page 100
    | insert page $page
    | to query
  )
  let url = (build-url $env.CANVAS_URL $path $query)

  get-url $url
  | update body {|it| 
    if $unwrap != null {
      if ($it.body | get $unwrap -i) != null {
        $it.body | get $unwrap -i
      } else {
        $it.body
      }
    } else {
      $it.body
    }
  }
}

export def paginated-fetch [
  path
  params? = {}
  --unwrap: string
  --spec # Whether to strictly follow the Canvas API pagination spec
] {
  if $spec {
    return (paginated-fetch-spec $path $params --unwrap=$unwrap)
  }
  let first_page = (fetch-page $path $params 1 --unwrap=$unwrap)

  if ($first_page.links | get next -i) != null {
    2..
    | each {|page| fetch-page $path $params $page }
    | take while {|it| ($it.body | length) > 0 and $it.status.code in 200..299}
    | prepend $first_page
    | each {|it| $it.body}
    | flatten --all
  } else {
    $first_page.body
  }
}

export def paginated-fetch-spec [
  path
  params? = {}
  --unwrap: string
] {
  mut current_page = (fetch-page $path $params 1 --unwrap=$unwrap)
  mut pages = [$current_page]

  while ($current_page.links | get next -i) != null {
    let next_page = ($current_page.links.next)
    let page = (
      get-url $next_page
      | update body {|it| 
        if $unwrap != null {
          if ($it.body | get $unwrap -i) != null {
            $it.body | get $unwrap -i
          } else {
            $it.body
          }
        } else {
          $it.body
        }
      }
    )
    $current_page = $page
    $pages = ($pages | append $current_page)
  }
  
  $pages
  | each {|it| $it.body}
  | flatten --all
}

export def fetch [path, params? = {}] {
  let query = ($params | to query)
  let url = (build-url $env.CANVAS_URL $path $query)

  get-url $url
  | get body
}

export def put [path, data] {
  let url = (build-url $env.CANVAS_URL $path)
  let authorization = $"Authorization: Bearer ($env.CANVAS_TOKEN)"
  let content_type = "Content-Type: application/json"
  let body = ($data | to json)
  if $env.CANVAS_DEBUG {
    print $"PUT ($url)";
  }

  ^curl $url -s -X PUT -H $authorization -H $content_type -d $body
  | from json
}

export def post-file [
  path 
  data
  attachment
] {
  let file_path = if ($attachment | describe) == "string" {
    $attachment
  } else {
    ([$env.TEMP, "CanvasLMS-CLI", (random uuid)] | path join)
  }

  let url = (build-url $env.CANVAS_URL $path)
  let authorization = $"Authorization: Bearer ($env.CANVAS_TOKEN)"
  let content_type = "Content-Type: multipart/form-data"
  let body = ($data | to query)
  if $env.CANVAS_DEBUG {
    print $"POST ($url) WITH ATTACHMENT ($file_path)";
  }

  $body;

  let resp = (^curl $url -s -S --verbose -X POST -H $authorization -H $content_type -d $body -F $"attachment=@($file_path)")

  $resp;
  $resp
}

export def post [path, data] {
  let url = (build-url $env.CANVAS_URL $path)
  let authorization = $"Authorization: Bearer ($env.CANVAS_TOKEN)"
  let content_type = "Content-Type: application/json"
  let body = ($data | to json)
  if $env.CANVAS_DEBUG {
    print $"POST ($url)";
  }

  ^curl $url -s -X POST -H $authorization -H $content_type -d $body
  | from json
}

export def delete [path, data?] {
  let url = (build-url $env.CANVAS_URL $path)
  let authorization = $"Authorization: Bearer ($env.CANVAS_TOKEN)"
  let content_type = "Content-Type: application/json"
  let body = ($data | to json)
  if $env.CANVAS_DEBUG {
    print $"DELETE ($url)";
  }

  ^curl $url -s -X DELETE -H $authorization -H $content_type -d $body
  | from json
}
