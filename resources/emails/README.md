# Email Content Guidelines

Email bodies support [Godot BBCode](https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html) formatting. Useful tags include:

- `[b]bold[/b]`
- `[i]italic[/i]`
- `[u]underline[/u]`
- `[url=ACTION_ID]Link text[/url]` – triggers an email action when clicked.

Use `\n` to insert new lines.

## Action IDs
- If `ACTION_ID` matches the `id` of a button dictionary in `email.buttons`, that action is invoked.
- Otherwise, the `ACTION_ID` is treated as an app name and `WindowManager.launch_app_by_name` is called.

This lets content authors embed inline links that launch apps or reuse existing button actions.
