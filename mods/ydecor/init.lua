-- Coal Stone Tile
minetest.register_node("ydecor:coalstone_tile", {
	description = "Coal Stone Tile",
	tiles = {"ydecor_coalstone_tile.png"},
	groups = {cracky = 1, stone = 1},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = "ydecor:coalstone_tile 8",
	recipe = {
		{"default:coalblock", "default:stone"},
		{"default:stone", "default:coalblock"},
	}
})
stairs.register_stair_and_slab("coalstone", "ydecor:coalstone_tile",
	{cracky = 1, stone = 1}, {"ydecor_coalstone_tile.png"},
	"Coal Stone Stair", "Coal Stone Slab",
	default.node_sound_stone_defaults(),
	false)

-- Moon Brick
minetest.register_node("ydecor:moonbrick", {
	description = "Moon Brick",
	tiles = {"ydecor_moonbrick.png"},
	groups = {cracky = 1},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = "ydecor:moonbrick",
	recipe = {
		{"default:brick", "default:stone"},
	}
})
stairs.register_stair_and_slab("moonbrick", "ydecor:moonbrick",
	{cracky = 1}, {"ydecor_moonbrick.png"},
	"Moon Brick Stair", "Moon Brick Slab",
	default.node_sound_stone_defaults(),
	false)

-- Runestone
minetest.register_node("ydecor:stone_rune", {
	description = "Runestone",
	tiles = {"ydecor_stone_rune.png"},
	groups = {cracky = 1, stone = 1},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = "ydecor:stone_rune 8",
	recipe = {
		{"default:stone", "default:stone", "default:stone"},
		{"default:stone", "", "default:stone"},
		{"default:stone", "default:stone", "default:stone"},
	},
})
stairs.register_stair_and_slab("stone_rune", "ydecor:stone_rune",
	{cracky = 1, stone = 1}, {"ydecor_stone_rune.png"},
	"Runestone Stair", "Runestone Slab",
	default.node_sound_stone_defaults(),
	false)

-- Hardened Clay
minetest.register_node("ydecor:hard_clay", {
	description = "Hardened Clay",
	tiles = {"ydecor_hard_clay.png"},
	groups = {cracky = 1},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = "ydecor:hard_clay",
	recipe = {
		{"default:clay", "default:clay"},
		{"default:clay", "default:clay"}
	}
})
stairs.register_stair_and_slab("hard_clay", "ydecor:hard_clay",
	{cracky = 1}, {"ydecor_hard_clay.png"},
	"Hard Clay Stair", "Hard Clay Slab",
	default.node_sound_stone_defaults(),
	false)

-- Packed Ice
minetest.register_node("ydecor:packed_ice", {
	description = "Packed Ice",
	tiles = {"ydecor_packed_ice.png"},
	groups = {cracky = 1, slippery = 3},
	sounds = default.node_sound_glass_defaults(),
})
minetest.register_craft({
	output = "ydecor:packed_ice",
	recipe = {
		{"default:ice", "default:ice"},
		{"default:ice", "default:ice"}
	}
})
stairs.register_stair_and_slab("packed_ice", "ydecor:packed_ice",
	{cracky = 1, slippery = 3}, {"ydecor_packed_ice.png"},
	"Packed Ice Stair", "Packed Ice Slab",
	default.node_sound_stone_defaults(),
	false)

-- Wooden Tile
minetest.register_node("ydecor:wood_tile", {
	description = "Wooden Tile",
	tiles = {"ydecor_wood_tile.png"},
	groups = {choppy = 1, wood = 1, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
})
minetest.register_craft({
	output = "ydecor:wood_tile 2",
	recipe = {
		{"", "group:wood", ""},
		{"group:wood", "", "group:wood"},
		{"", "group:wood", ""}
	}
})
stairs.register_stair_and_slab("wood_tile", "ydecor:wood_tile",
	{choppy = 1, wood = 1, flammable = 2}, {"ydecor_wood_tile.png"},
	"Wooden Tile Stair", "Wooden Tile Slab",
	default.node_sound_stone_defaults(),
	false)

-- Cobweb
minetest.register_node("ydecor:cobweb", {
	description = "Cobweb",
	drawtype = "plantlike",
	tiles = {"ydecor_cobweb.png"},
	inventory_image = "ydecor_cobweb.png",
	liquid_viscosity = 8,
	liquidtype = "source",
	liquid_alternative_flowing = "ydecor:cobweb",
	liquid_alternative_source = "ydecor:cobweb",
	liquid_renewable = false,
	liquid_range = 0,
	walkable = false,
	selection_box = {type = "regular"},
	groups = {snappy = 3, liquid = 3, flammable = 3},
	sounds = default.node_sound_leaves_defaults(),
	paramtype = "light",
	sunlight_propagates = true,
})

minetest.register_craft({
	output = "ydecor:cobweb",
	recipe = {
		{"farming:string", "", "farming:string"},
		{"", "farming:string", ""},
		{"farming:string", "", "farming:string"}
	}
})

-- Baricade
minetest.register_node("ydecor:baricade", {
	description = "Baricade",
	drawtype = "plantlike",
	paramtype = "light",
	paramtype2 = "facedir",
	inventory_image = "ydecor_baricade.png",
	tiles = {"ydecor_baricade.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	damage_per_second = 4,
	selection_box = {type = "fixed", fixed = {-0.3, -0.5, -0.3, 0.3, 0.1, 0.3}},
	collision_box = {type = "fixed", fixed = {-0.1, -0.5, -0.1, 0.1, 0.1, 0.1}},
	sunlight_propagates = true,
})

minetest.register_craft({
	output = "ydecor:baricade",
	recipe = {
		{"group:stick", "", "group:stick"},
		{"", "default:steel_ingot", ""},
		{"group:stick", "", "group:stick"}
	}
})

-- Ivy
minetest.register_node("ydecor:ivy", {
	description = "Ivy",
	drawtype = "signlike",
	walkable = false,
	climbable = true,
	groups = {snappy = 3, flora = 1, attached_node = 1, plant = 1, flammable = 3},
	paramtype = "light",
	paramtype2 = "wallmounted",
	selection_box = {type = "wallmounted"},
	tiles = {"ydecor_ivy.png"},
	inventory_image = "ydecor_ivy.png",
	wield_image = "ydecor_ivy.png",
	sounds = default.node_sound_leaves_defaults(),
	sunlight_propagates = true,
})

minetest.register_craft({
	output = "ydecor:ivy 2",
	recipe = {
		{"group:leaves"},
		{"group:leaves"}
	}
})
