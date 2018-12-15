local S = mobs.intllib
local hairball = minetest.settings:get("mobs_hairball")

-- Kitten by Jordach / BFD
mobs:register_mob("mobs:kitten", {
	--stepheight = 0.6,
	type = "animal",
	specific_attack = {"mobs:rat"},
	damage = 1,
	attack_type = "dogfight",
	attack_animals = true, -- so it can attack rat
	attack_players = false,
	reach = 1,
	passive = false,
	hp_min = 5,
	hp_max = 10,
	armor = 200,
	collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.1, 0.3},
	visual = "mesh",
	visual_size = {x = 0.5, y = 0.5},
	mesh = "mobs_kitten.b3d",
	textures = {
		{"mobs_kitten_striped.png"},
		{"mobs_kitten_splotchy.png"},
		{"mobs_kitten_ginger.png"},
		--{"mobs_kitten_sandy.png"},
	},
	makes_footstep_sound = false,
	sounds = {
		random = "mobs_kitten",
	},
	walk_velocity = 0.6,
	walk_chance = 15,
	run_velocity = 2,
	runaway = true,
	--jump = false,
	drops = {
		{name = "mobs:meat_raw", chance = 1, min = 1, max = 2},
		{name = "mobs:hairball", chance = 2, min = 0, max = 1},
	},
	water_damage = 1,
	lava_damage = 5,
	fear_height = 3,
	animation = {
		speed_normal = 42,
		stand_start = 97,
		stand_end = 192,
		walk_start = 0,
		walk_end = 96,
		stoodup_start = 0,
		stoodup_end = 0,
	},
	follow = {"mobs:rat"},
	--view_range = 8,
	on_rightclick = function(self, clicker)
		if mobs:feed_tame(self, clicker, 4, true, true) then return end
		if mobs:protect(self, clicker) then return end
		if mobs:capture_mob(self, clicker, 50, 50, 90, false, nil) then return end

		-- by right-clicking owner can switch between staying and walking
		if self.owner and self.owner == clicker:get_player_name() then
			if self.order ~= "stand" then
				self.order = "stand"
				self.state = "stand"
				self.object:set_velocity({x = 0, y = 0, z = 0})
				mobs:set_animation(self, "stand")
			else
				self.order = ""
				mobs:set_animation(self, "stoodup")
			end
		end
	end,
	do_custom = function(self, dtime)
		if hairball == "false" then
			return
		end
		self.hairball_timer = (self.hairball_timer or 0) + dtime
		if self.hairball_timer < 10 then
			return
		end
		self.hairball_timer = 0
		if self.child
		or math.random(1, 250) > 1 then
			return
		end
		local pos = self.object:get_pos()
		minetest.add_item(pos, "mobs:hairball")
		minetest.sound_play("mobs_kitten", {
			pos = pos,
			gain = 0.5,
			max_hear_distance = 128,
		})
	end,
})
mobs:register_egg("mobs:kitten", S("Kitten"), "mobs_kitten_ginger.png", 1)
