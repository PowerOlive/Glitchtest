-- Mobs & NPC are part of Glitchtest game
-- Copyright 2018 James Stevenson
-- GNU GPL 3

-- NPC by TenPlus1
-- Trader enhancements by jas


local S = mobs.intllib

mobs.npc_drops = {
	"default:pick_steel", "mobs:meat 2", "default:sword_steel",
	"default:shovel_steel", "farming:bread", "bucket:bucket_water",
	"walkie:talkie", "craftguide:book", "default:book",
	"mobs:shears", "default:axe_steel", "default:diamond",
	"default:papyrus",
}

local function mob_detached_inv(self)
	return {
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			return 0
		end,
		allow_put = function(inv, listname, index, stack, player)
			return 0
		end,
		allow_take = function(inv, listname, index, stack, player)
			local name = player:get_player_name()
			local detached = minetest.create_detached_inventory("trade_" .. self.tid, {
				allow_put = function(inv, listname, index, stack, player)
					if index ~= 2 then
						return 0
					else
						return stack:get_count()
					end
				end,
				allow_move = function()
					return 0
				end,
				allow_take = function(inv, listname, index, stack, player)
					return 0
				end,
				on_put = function(p_inv, p_listname, p_index, p_stack, p_player)
					local player_inv = p_player:get_inventory()
					player_inv:add_item("main", p_inv:get_stack("exchange", 1))
					p_inv:set_list("exchange", {})
					minetest.close_formspec(name, "npc:npc_trade")
					--[[
					if not self.owner or self.owner == "" then
						self.object:get_luaentity().owner = p_player:get_player_name()
					end
					--]]
					return -1, minetest.remove_detached_inventory("trade_" .. self.tid)
				end,
			})
			detached:set_size("exchange", 2 * 1)
			detached:add_item("exchange", stack)
			local trade_fs = "size[8,6.5]" ..
				jas0.exit_button() ..
				"label[0,0;I'll need something from you.]" ..
				"list[detached:trade_" .. self.tid .. ";exchange;3,1;2,1]" ..
				"list[current_player;main;0,2.5;8,1]" ..
				"list[current_player;main;0,3.6;8,3;8]" ..
				default.get_hotbar_bg(0, 2.5) ..
			""
			inv:set_stack("trade", index, "")
			local list = inv:get_list("trade")
			for i = 1, #list do
				list[i] = list[i]:to_string()
			end
			self.inv = minetest.serialize(list)
			return 0, minetest.show_formspec(name, "npc:npc_trade", trade_fs)
		end,
		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			return 0
		end,
		on_put = function(inv, listname, index, stack, player)
			return 0
		end,
		on_take = function(inv, listname, index, stack, player)
			return 0
		end,
	}
end

mobs:register_mob("mobs:npc", {
	type = "npc",
	passive = false,
	damage = 3,
	attack_type = "dogfight",
	attacks_monsters = true,
	attack_npcs = false,
	owner_loyal = true,
	pathfinding = true,
	hp_min = 20,
	hp_max = 20,
	armor = 100,
	collisionbox = {-0.25, 0.0, -0.25, 0.25, 1.65 , 0.25},
	visual = "mesh",
	mesh = "character.b3d",
	drawtype = "front",
	textures = {
		{"mobs_npc.png"},
		{"mobs_npc2.png"}, -- female by nuttmeg20
	},
	child_texture = {
		{"mobs_npc_baby.png"}, -- derpy baby by AmirDerAssassine
	},
	makes_footstep_sound = true,
	--sounds = {},
	walk_velocity = 1,
	run_velocity = 2,
	jump = true,
	drops = {
		{name = "shop:coin", chance = 1, min = 1, max = 6},
		{name = "shop:gold_ingot", chance = 2, min = 0, max = 2},
		{name = "shop:goldblock", chance = 3, min = 0, max = 1},
	},
	water_damage = 0,
	lava_damage = 2,
	light_damage = 0,
	follow = {"farming:flour", "mobs:meat_raw", "default:gold_lump"},
	--view_range = 8,
	owner = "",
	order = "follow",
	fear_height = 3,
	animation = {
		speed_normal = 30,
		speed_run = 30,
		stand_start = 0,
		stand_end = 79,
		walk_start = 168,
		walk_end = 187,
		run_start = 168,
		run_end = 187,
		punch_start = 200,
		punch_end = 219,
	},
	on_rightclick = function(self, clicker)
		if mobs:feed_tame(self, clicker, 7, true, true) then
			return
		end
		if mobs:capture_mob(self, clicker, 0, 5, 80, false, nil) then
			return
		end
		if mobs:protect(self, clicker) then
			return
		end

		local item = clicker:get_wielded_item()
		local name = clicker:get_player_name()
		if not self.tid then
			local tid = minetest.get_us_time()
			local inv_id = minetest.create_detached_inventory("npc_" ..
					tid, mob_detached_inv(self))
			inv_id:set_size("trade", 8 * 4)
			for i = math.random(1, 2), #dresser.skins, 2 do
				inv_id:add_item("trade", "dresser:skin_" .. dresser.skins[i][1])
			end
			for i = math.random(1, 2), #mobs.npc_drops, 2 do
				inv_id:add_item("trade", mobs.npc_drops[i])
			end
			for i = math.random(1, 2), #dungeon_loot.registered_loot, 2 do
				if dungeon_loot.registered_loot[i].chance > 0.2 then
					inv_id:add_item("trade", dungeon_loot.registered_loot[i].name)
				end
			end
			local inventory = inv_id:get_list("trade")
			for i = 1, #inventory do
				inventory[i] = inventory[i]:to_string()
			end
			self.inv = minetest.serialize(inventory)
			self.tid = tid
		else
			local mob_inv = minetest.get_inventory({type = "detached",
					name = "npc_" .. self.tid})
			if not mob_inv then
				mob_inv = minetest.create_detached_inventory("npc_" ..
						self.tid, mob_detached_inv(self))
				mob_inv:set_list("trade", minetest.deserialize(self.inv))
			end
		end
		self.order = "stand"
		self.state = "stand"
		minetest.after(0.1, function()
			minetest.show_formspec(name, "mobs:npc",
				"size[8,8.85]" ..
				jas0.exit_button(-0.1, -0.075) ..
				"label[0,0;What would you like?]" ..
				"list[detached:npc_" .. self.tid .. ";trade;0,0.6.9;8,4]" ..
				"list[current_player;main;0,4.79;8,1]" ..
				"list[current_player;main;0,5.84;8,3;8]" ..
				default.get_hotbar_bg(0, 4.79) ..
			"")
		end)
	end,
	--[[
	on_die = function(self, pos)
	end,
	--]]
})

mobs:register_egg("mobs:npc", "NPC", "default_brick.png", 1)
