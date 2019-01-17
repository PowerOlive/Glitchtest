local S = mobs.intllib
local boom = function(pos, radius)
	radius = radius or 2
	tnt.boom(pos, {radius = radius,
			damage_radius = radius,})
end
-- Dungeon Master by PilzAdam
mobs:register_mob("mobs:dungeon_master", {
	type = "monster",
	passive = false,
	damage = 6,
	attack_type = "dogshoot",
	dogshoot_switch = 1,
	dogshoot_count_max = 12, -- shoot for 10 seconds
	dogshoot_count2_max = 3, -- dogfight for 3 seconds
	reach = 2,
	shoot_interval = 2.2,
	arrow = "mobs:fireball",
	shoot_offset = 1,
	hp_min = 20,
	hp_max = 20,
	armor = 100,
	collisionbox = {-0.7, -1, -0.7, 0.7, 1.6, 0.7},
	visual = "mesh",
	mesh = "mobs_dungeon_master.b3d",
	textures = {
		{"mobs_dungeon_master.png"},
		{"mobs_dungeon_master2.png"},
		{"mobs_dungeon_master3.png"},
	},
	makes_footstep_sound = true,
	sounds = {
		warcry = "mobs_dungeonmaster",
		attack = "mobs_dungeonmaster",
		die = "mobs_dungeonmaster",
		random = "mobs_dungeonmaster",
		shoot_attack = "mobs_fireball",
	},
	walk_velocity = 1,
	--run_velocity = 1,
	--jump = true,
	view_range = 7,
	drops = {
		{name = "default:mese_crystal", chance = 1, min = 1, max = 2},
		{name = "default:diamond", chance = 2, min = 0, max = 1},
	},
	water_damage = 1,
	lava_damage = 1,
	light_damage = 0,
	fear_height = 3,
	animation = {
		stand_start = 0,
		stand_end = 19,
		walk_start = 20,
		walk_end = 35,
		punch_start = 36,
		punch_end = 48,
		shoot_start = 36,
		shoot_end = 48,
		speed_normal = 15,
		speed_run = 15,
	},
	on_die = function(self, pos)
		boom(pos)
	end,
})

mobs:register_egg("mobs:dungeon_master", S("Dungeon Master"), "fire_basic_flame.png", 1, true)

-- fireball (weapon)
mobs:register_arrow("mobs:fireball", {
	visual = "sprite",
	visual_size = {x = 1.5, y = 1.5},
	textures = {"mobs_fireball.png"},
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	velocity = 9,
	glow = 14,
	expire = 0.1,
	on_activate = function(self, staticdata, dtime_s)
		-- make fireball indestructable
		self.object:set_armor_groups({immortal = 1, fleshy = 100})
	end,
	hit_player = function(self, player)
		boom(self.object:get_pos())
	end,
	hit_mob = function(self, player)
		boom(self.object:get_pos())
	end,
	hit_node = function(self, pos, node)
		boom(self.object:get_pos())
	end
})
