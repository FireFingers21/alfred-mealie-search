#!/bin/zsh --no-rcs

readonly recipes_file="${alfred_workflow_data}/recipes.json"
readonly groupId=$(jq -r '.groupId' "${alfred_workflow_data}/users.json")

# Auto Update
[[ -f "${recipes_file}" ]] && [[ "$(date -r "${recipes_file}" +%s)" -lt "$(date -v -"${autoUpdate}"H +%s)" && "${autoUpdate}" -ne 0 ]] && reload=$(./reload.sh)

# Load Recipes
jq -cs \
   --arg useDesc "$useDesc" \
   --arg useCategory "$useCategory" \
   --arg useTag "$useTag" \
   --arg useTool "$useTool" \
   --arg organizer "$organizer" \
   --arg groupId "$groupId" \
'{
	"items": (if (length != 0) and (.[].items | length > 0) then
		.[].items | map(select(.groupId == $groupId) | {
			"uid": .id,
			"title": .name,
			"subtitle": "\((if $organizer == "cat" then .recipeCategory elif $organizer == "tag" then .tags else .tools end) | map(.name) | if .[0] then ("["+join(", ")+"] ") else "" end)\(.description)",
			"arg": .slug,
			"match": "\(.name) \(if $useDesc == "1" then .description else "" end) \(if $useTag == "1" then (.tags | map("#"+.name) | join(" ")) else "" end) \(if $useCategory == "1" then (.recipeCategory | map("@"+.name) | join(" ")) else "" end) \(if $useTool == "1" then (.tools | map("$"+.name) | join(" ")) else "" end)",
			"variables": { "slug": .slug },
			"mods": {
				"ctrl": {
					"arg": "",
					"variables": {
						"rTitle": .name,
						"rDescription": .description,
						"rSlug": .slug
					}
				}
			}
		})
	elif length == 0 then
		[{
			"title": "No Recipes Found",
			"subtitle": "Press ↩ to load recipes",
			"arg": "reload"
		}]
	else
		[{
			"title": "Search Recipes...",
			"subtitle": "You have no recipes",
			"valid": "false"
		}]
	end)
}' "${recipes_file}"