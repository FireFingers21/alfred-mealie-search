#!/bin/zsh --no-rcs

# Get lastest cache timestamp
readonly recipes_file="${alfred_workflow_data}/recipes.json"
readonly lastUpdated=$(date -r "${recipes_file}" +"%A, %B %d %Y at %I:%M%p" || printf "Never")

cat << EOB
{"items": [
	{
		"title": "Reload Recipes",
		"subtitle": "Last Update: ${lastUpdated}",
		"variables": { "pref_id": "reload" }
	},
	{
		"title": "New Recipe",
		"variables": { "pref_id": "new" }
	},
	{
		"title": "Open Mealie",
		"variables": { "pref_id": "open" }
	},
	{
		"title": "Browser Settings",
		"subtitle": "Select the default browser for ${alfred_workflow_name}",
		"variables": { "pref_id": "browser" }
	},
]}
EOB