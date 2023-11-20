# Get the notification preferences for a communication channel on a user
export def main [
  --channel: any # The communication channel to query. Can be supplied by pipeline. Valid values are: map, email address, phone number.
  --user: any # The user to query. Defaults to the user on the communication channel if the channel is an object
] {
  $in
  | default $channel
  | each {|it| 
    let user = (
      match $it {
        {user_id: $id} => $id
        _ => ($user | default self)
      }
    )

    fetch $"/users/(id-of $user)/communication_channels/(id-of $it)/notification_preferences" 
  }
}
