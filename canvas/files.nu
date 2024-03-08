export def main [
  --id: any # The ID of the file to retrieve
  --course: any # The course to which the file belongs
  --user: any # The user to whom the file belongs
  --group: any # The group to which the file belongs

  --include: list # Array of additional fields to include in the response. Valid values are: user, usage_rights
  --replacement-chain-type: string # Set this to 'course' or 'account' to instruct Canvas to follow the replacement chain if the requsted file was deleted or replaced by another
  --replacement-chain-id: any # The ID of the course or account to search for the file in. Required if replacement_chain_type is set
] {
  let path = (match {course: $course, user: $user, group: $group} {
    {course: $course} if $course != null => $"/courses/(id-of $course)/files/($id)"
    {user: $user} if $user != null => $"/users/(id-of $user)/files/($id)"
    {group: $group} if $group != null => $"/groups/(id-of $group)/files/($id)"
    _ => $"/files/($id)"
  })

  fetch $path {
    include: $include
    replacement_chain_type: $replacement_chain_type
    replacement_chain_id: $replacement_chain_id
  }
}

export def list [
  --course: any # The course to which the files belong. Exclusive with user, group, and folder.
  --user: any # The user to whom the files belong. Exclusive with course, group, and folder.
  --group: any # The group to which the files belong. Exclusive with course, user, and folder.
  --folder: any # The folder to list files from. Exclusive with course, user, and group.

  --content-types: list # Filter by content-type. You can specify type/subtype pairs like 'image/jpeg', or just types like 'image', 'video', etc.
  --exclude-content-types: list # Exclude content-type. You can specify type/subtype pairs like 'image/jpeg', or just types like 'image', 'video', etc.
  --search-term: string # The partial name of the files to match and return.
  --include: list # Array of additional fields to include in the response. Valid values are: user, usage_rights
  --only: list # Array of information to restrict to. Overrides include[]. Valid values are: names.
  
  --sort: string # Sort results by this field. Defaults to 'name.' Valid values are: 'name', 'size', 'created_at', 'updated_at, 'content_type', 'user'
  --order: string # The sorting order. Defaults to 'asc.' Valid values are: 'asc', 'desc' 
] {
  let path = (match {course: $course, user: $user, group: $group, folder: $folder} {
    {course: $course} if $course != null => $"/courses/(id-of $course)/files"
    {user: $user} if $user != null => $"/users/(id-of $user)/files"
    {group: $group} if $group != null => $"/groups/(id-of $group)/files"
    {folder: $folder} if $folder != null => $"/folders/(id-of $folder)/files"
    _ => (error make {msg: "One of course, user, group, or folder must be provided."})
  })

  paginated-fetch $path {
    content_types: $content_types
    exclude_content_types: $exclude_content_types
    search_term: $search_term
    include: $include
    only: $only
    sort: $sort
    order: $order
  }
}
