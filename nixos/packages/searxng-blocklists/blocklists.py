# TODO: i18n via flask_babel
name = "Configurable blocklists"
description = "Block unwanted search results"
default_on = True
preference_section = "general"
#allow_api_connections = True


def post_search(request, search):
	print("wooo")
	search.result_container.infoboxes.append({
		"infobox": "foo", 
		"content": "baz",
		"attributes": [
			{
				"label": "label",
				"value": "bar",
			},
		],
	})

