# Canvas Admin Toolbox (CAT)
NuShell scripts for managing Canvas LMS instances

```shell
# Get all published courses that use Zoom
> canvas courses list --published=true
  | insert using_zoom? {
    not ( 
      canvas courses tabs
      | where label == "Zoom" and hidden == false
      | is-empty
    )
  }
  | select id name using_zoom?

╭───┬────┬────────────┬─────────────╮
│ # │ id │    name    │ using_zoom? │
├───┼────┼────────────┼─────────────┤
│ 0 │  1 │ Admin Test │ true        │
│ 1 │  2 │ Test 2     │ false       │
╰───┴────┴────────────┴─────────────╯

# Get all manually enrolled (non-SIS) users in courses
> canvas courses list
| insert manual_enrollments {
  canvas enrollments list
  | where sis_import_id == null
  | flatten user --all
  | select role name user_id
}
| flatten manual_enrollments --all
| select id name manual_enrollments_name user_id role
| rename course_id course user user_id role

╭───┬───────────┬────────────┬────────────┬─────────┬───────────────────╮
│ # │ course_id │   course   │    user    │ user_id │       role        │
├───┼───────────┼────────────┼────────────┼─────────┼───────────────────┤
│ 0 │         1 │ Admin Test │ Admin Alex │       5 │ TeacherEnrollment │
│ 1 │         2 │ Test 2     │ Student    │       6 │ StudentEnrollment │
╰───┴───────────┴────────────┴────────────┴─────────┴───────────────────╯
```

## Quick Start
After installing [NuShell](https://www.nushell.sh/), add this repository to your `$env.NU_LIB_DIRS`. Next, in Canvas,
[generate a personal access token](https://community.canvaslms.com/t5/Admin-Guide/How-do-I-manage-API-access-tokens-as-an-admin/ta-p/89).
Then, define the following environment variables in your NuShell environment:

```shell
let-env CANVAS_URL = "https://yourschool.instructure.com" # No trailing slash
let-env CANVAS_TOKEN = "YOUR-CANVAS-ACCESS-TOKEN"
let-env CANVAS_ROOT_ACCOUNT_ID = 1 # Optional, set this if you're self-hosting Canvas or have an odd account structure
```

Personally, I have each Canvas instance I manage in its own file that I can `use`. For example, for a production
environment, I define a URL and token in `prod.nu` inside of an `export-env` block.

Once your environment is configured, just `use canvas.nu` from a NuShell prompt. Run `canvas my user` to verify
the script is working correctly.

```shell
> canvas my user
╭──────────────────┬─────────────────────────────────────────────────────────────╮
│ id               │ 1                                                           │
│ name             │ Site Admin                                                  │
│ created_at       │ a week ago                                                  │
│ sortable_name    │ site-admin@localhost                                        │
│ short_name       │ site-admin@localhost                                        │
│ sis_user_id      │                                                             │
│ integration_id   │                                                             │
│ sis_import_id    │                                                             │
│ login_id         │ site-admin@localhost                                        │
│ avatar_url       │ http://canvas.instructure.com/images/messages/avatar-50.png │
│ email            │ site-admin@localhost                                        │
│ locale           │                                                             │
│ effective_locale │ en                                                          │
│                  │ ╭─────────────────────────────┬───────╮                     │
│ permissions      │ │ can_update_name             │ true  │                     │
│                  │ │ can_update_avatar           │ false │                     │
│                  │ │ limit_parent_app_web_access │ false │                     │
│                  │ ╰─────────────────────────────┴───────╯                     │
╰──────────────────┴─────────────────────────────────────────────────────────────╯
```

## Philosophy
Managing multiple Canvas LMS instances can be time-consuming, especially when it comes to tasks that involve
bulk operations, such as adding users or courses. While there has been
[some](https://community.canvaslms.com/t5/Canvas-Developers-Group/CANBASH-Canvas-BASH-Scripting/ba-p/268228) limited
effort to develop shell scripts that interact with the Canvas API, there is a lack of comprehensive command-line tools
to manage Canvas LMS instances. For anyone familiar with other excellent tools, such as
[gam](https://github.com/GAM-team/GAM), this toolbox aims to provide a similar level of comfort and flexibility.

The main goal of the toolbox is to provide a simple and efficient way to perform common, low-level Canvas LMS management
tasks, such as creating and deleting courses, managing users and groups, and performing course enrollment operations. By
using the shell, admins can quickly and easily automate routine tasks, reducing the time and effort required to manage
Canvas LMS instances.

At the moment, this project is a thin wrapper around the limited bits of the Canvas API that I've bothered to implement.
Currently, the criteria for what API endpoints have been implemented is those that I need for my day-to-day work. As
this project matures, I hope to include more high-level workflows.

## Why NuShell?
NuShell is awesome.

But seriously, being able to easily pipe and filter data is extremely useful for the bulk tasks I run daily. For the
Canvas tasks I've automated in the past, I mostly used python and UCF's wonderful
[canvasapi](https://github.com/ucfopen/canvasapi) library. The examples above consisted of about 10 minutes of work
each and  are extremely readable whereas my equivalent python scripts would likely not be as succient and would have
taken about an hour to implement.
