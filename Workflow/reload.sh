#!/bin/zsh --no-rcs

readonly users=$(curl -s -w "\n%{http_code}" "${baseUrl}/api/users/self" -H "Authorization: Bearer ${token}")
readonly recipes=$(curl -s -w "\n%{http_code}" "${baseUrl}/api/recipes" -H "Authorization: Bearer ${token}")
readonly http_code="${recipes##*$'\n'}"

case "${http_code}" in
	200)
		readonly recipes_file="${alfred_workflow_data}/recipes.json"
		readonly users_file="${alfred_workflow_data}/users.json"

		mkdir -p "${alfred_workflow_data}"
		echo -nE "${recipes%$'\n'*}" > "${recipes_file}"
		echo -nE "${users%$'\n'*}" > "${users_file}"

		# Purge deleted recipes
		deleteRecipes=($(jq -r '"! -name "+.items[].slug+".json"' "${recipes_file}"))
		find "${alfred_workflow_data}/recipes" -type f -maxdepth 1 "${deleteRecipes[@]}" -delete

		printf "Recipes Updated"
		;;
	401)
		printf "Invalid API Token"
		;;
	*)
		printf "Mealie server not found"
		;;
esac