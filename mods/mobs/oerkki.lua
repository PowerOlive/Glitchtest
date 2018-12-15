-- Oerkki by PilzAdam

local S = mobs.intllib
mobs:register_mob("mobs:oerkki", {
	type = "monster",
	passive = false,
	attack_type = "dogfight",
	pathfinding = true,
	reach = 2,
	damage = 5,
	hp_min = 5,
	hp_max = 7,
	armor = 100,
	collisionbox = {-0.4, -1, -0.4, 0.4, 0.9, 0.4},
	visual = "mesh",
	mesh = "mobs_oerkki.b3d",
	textures = {
		{"mobs_oerkki.png"},
		--{"mobs_oerkki2.png"},
	},
	makes_footstep_sound = false,
	sounds = {
		random = "mobs_oerkki",
	},
	walk_velocity = 1,
	run_velocity = 1,
	--view_range = 10,
	--jump = true,
	drops = {
		{name = "default:mese_crystal", chance = 2, min = 1, max = 2},
		{name = "default:obsidian", chance = 2, min = 0, max = 1},
	},
	water_damage = 7,
	lava_damage = 4,
	fear_height = 4,
	animation = {
		stand_start = 0,
		stand_end = 23,
		walk_start = 24,
		walk_end = 36,
		run_start = 37,
		run_end = 49,
		punch_start = 37,
		punch_end = 49,
		speed_normal = 15,
		speed_run = 15,
	},
})

mobs:register_egg("mobs:oerkki", S("Oerkki"), "default_obsidian.png", 1)
