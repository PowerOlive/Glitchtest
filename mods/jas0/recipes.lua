-- jas0/recipes.lua is part of Glitchtest
-- Copyright 2018 James Stevenson
-- GNU GPL 3

minetest.register_craft({
	output = "default:dirt_with_snow",
	recipe = {
		{"default:snow"},
		{"default:dirt"},
	},
})
minetest.register_craft({
	output = "default:dirt_with_snow",
	recipe = {
		{"default:snow"},
		{"group:spreading_dirt_type"},
	},
})

minetest.register_craft({
	output = "default:dirt_with_grass",
	recipe = {
		{"group:grass"},
		{"default:dirt"},
	},
})
minetest.register_craft({
	output = "default:dirt_with_grass",
	recipe = {
		{"group:grass"},
		{"group:spreading_dirt_type"},
	},
})

minetest.register_craft({
	output = "default:dirt_with_dry_grass",
	recipe = {
		{"group:dry_grass"},
		{"default:dirt"},
	},
})
minetest.register_craft({
	output = "default:dirt_with_dry_grass",
	recipe = {
		{"group:dry_grass"},
		{"group:spreading_dirt_type"},
	},
})

minetest.register_craft({
	output = "default:stick",
	type = "shapeless",
	recipe = {"group:tool"},
})

minetest.register_craft({
	output = "dye:white",
	type = "shapeless",
	recipe = {"bones:bones"},
})

minetest.register_craft({
	output = "mobs:leather 2",
	type = "shapeless",
	recipe = {"backpacks:backpack_leather"},
})

minetest.register_craft({
	output = "default:paper",
	type = "shapeless",
	recipe = {"default:book_written"},
})
minetest.register_craft({
	output = "default:paper",
	type = "shapeless",
	recipe = {"default:book"},
})

minetest.register_craft({
	output = "default:book",
	type = "shapeless",
	recipe = {
		"dye:white",
		"default:book_written",
	},
})
minetest.register_craft({
	output = "default:book",
	type = "shapeless",
	recipe = {"craftguide:book"},
})

minetest.register_craft({
	output = "craftguide:book",
	type = "shapeless",
	recipe = {
		"default:book",
		"walkie:talkie",
	},
})
minetest.register_craft({
	output = "craftguide:book",
	type = "shapeless",
	recipe = {
		"default:book_written",
		"walkie:talkie",
	},
})

minetest.register_craft({
	output = "default:steel_ingot",
	type = "shapeless",
	recipe = {"walkie:talkie"},
})
