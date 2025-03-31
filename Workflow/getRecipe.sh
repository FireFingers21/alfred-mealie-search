#!/bin/zsh --no-rcs

readonly recipe_file="${alfred_workflow_data}/recipes/${slug}.json"
readonly recipes_file="${alfred_workflow_data}/recipes.json"

# Auto Update
if [[ -f "${recipe_file}" ]]; then
    readonly itemUpdatedAt=$(jq -r '.updatedAt' "${recipe_file}")
    readonly listUpdatedAt=$(jq -r --arg slug "$slug" '.items[] | select(.slug == $slug) | .updatedAt' "${recipes_file}")
fi

# Download Recipe Data
mkdir -p "${alfred_workflow_data}/recipes"
if [[ "${forceReload}" -eq 1 || "${itemUpdatedAt:0:20}" != "${listUpdatedAt:0:20}" || ! -f "${recipe_file}" ]]; then
    recipe=$(curl -s -w "\n%{http_code}" "${baseUrl}/api/recipes/${slug}" -H "Authorization: Bearer ${token}")
    http_code="${recipe##*$'\n'}"
    ./reload.sh &>/dev/null &
    [[ "${http_code}" -eq 200 ]] && echo -nE "${recipe%$'\n'*}" > "${recipe_file}" || errorUpdating=1
fi

# Format Last Updated Time
[[ -f "${recipe_file}" ]] && minutes="$((($(date +%s)-$(date -r "${recipe_file}" +%s))/60))"
if [[ ! -f "${recipe_file}" || ${minutes} -eq 0 ]]; then
    lastUpdated="Just now"
elif [[ ${minutes} -eq 1 ]]; then
    lastUpdated="${minutes} minute ago"
elif [[ ${minutes} -lt 60 ]]; then
    lastUpdated="${minutes} minutes ago"
elif [[ ${minutes} -ge 60 && ${minutes} -lt 120 ]]; then
    lastUpdated="$((${minutes}/60)) hour ago"
elif [[ ${minutes} -ge 120 && ${minutes} -lt 1440 ]]; then
    lastUpdated="$((${minutes}/60)) hours ago"
else
    lastUpdated="$(date -r "${recipe_file}" +'%Y-%m-%d')"
fi
[[ "${errorUpdating}" -eq 1 ]] && lastUpdated+=" (Error Updating)"

# Format Recipe to Markdown
if [[ -f "${recipe_file}" ]]; then
    mdRecipe=$(jq -crs \
        --arg showReqTools "$showReqTools" \
        --arg showNotes "$showNotes" \
    '.[] |
        "# "+.name,
        "\n**Prep Time:** \(.prepTime // "N/A")    ·    **Cook Time:** \(.performTime // "N/A")    ·    **Total Time:** \(.totalTime // "N/A")",
        "\n***\n\n## Ingredients\n",
        ((.recipeIngredient[] | .food.name as $foodname | .display |= sub("(?<name>\($foodname)[s]?)"; "**\(.name)**") | "* "+.display) // "N/A"),
        (if ($showReqTools == "1" and .tools[0]) then "\n###### Required Tools\n\n" else "" end),
        (if ($showReqTools == "1" and .tools[0]) then (.tools[] | "* "+.name) else "" end),
        "\n## Instructions\n",
        ((.recipeInstructions | to_entries | map("\(1 + .key). \(.value.text)") | join("\n")) // "N/A"),
        (if ($showNotes == "1" and .notes[0]) then "\n***\n\n## Notes\n" else "" end),
        (if ($showNotes == "1" and .notes[0]) then (.notes[] | "###### "+.title+"\n\n"+.text+"\n") else "" end)
    ' "${recipe_file}" | sed 's/\"/\\"/g')
else
    mdRecipe='# '${slug}'\n\n**Prep Time:** \"N/A\"    ·    **Cook Time:** \"N/A\"    ·    **Total Time:** \"N/A\"\n***\n*Unable to connect to Mealie server*'
fi

# Output Formatted Recipe to Text View
cat << EOB
{
    "variables": { "forceReload": 1 },
    "response": "${mdRecipe//$'\n'/\n}",
    "footer": "Last Updated: ${lastUpdated}            ⌥↩ Update Now   ·   ⌘↩ Open in Browser"
}
EOB