-- Mobs & NPC are part of Glitchtest game
-- Copyright 2018 James Stevenson
-- GNU GPL 3

-- NPC by TenPlus1
-- Trader enhancements by jas

local random = math.random
local S = mobs.intllib

local price_guide = {}
for k, v in pairs(minetest.registered_items) do
	local c = v.groups.trade_value
	if not c then
		c = 1
	end
	price_guide[k] = c
end
local pg_s = ""
for item, cost in pairs(price_guide) do
	if item:match(":") then
		item = minetest.registered_items[item].description
		if item ~= "" then
			if item:find("\n") then
				item = item:gsub("[\n].*$", "")
			elseif item:find(",") then
				item = item:gsub(",", "\\,")
			end
			pg_s = pg_s .. item .. "," .. cost .. ","
		end
	end
end
pg_s = pg_s:sub(1, -2)
local pg_fs = "size[8,8]" ..
	"tablecolumns[text,width=8;text,padding=1.0]" ..
	--"tableoptions[]" ..
	"table[0,0;7.8,8.1;pg;" .. pg_s .. ";1]" ..
""

mobs.npc_drops = {
	"default:pick_steel", "default:apple 3", "default:sword_steel",
	"default:shovel_steel", "farming:bread", "fireflies:bug_net",
	"walkie:talkie", "craftguide:book", "default:book",
	"mobs:shears", "default:axe_steel", "default:mese_crystal_fragment",
	"default:papyrus",
}

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if (formname == "mobs:npc" or formname == "mobs:npc_trade") and
			fields.help then
		minetest.show_formspec(player:get_player_name(), "mobs:npc_trade_list", pg_fs)
	end
end)

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
				allow_put = function(r_inv, r_listname, r_index, r_stack, r_player)
					if r_index ~= 2 then
						return 0
					else
						local v = minetest.get_item_group(r_stack:get_name(),
								"trade_value")
						if v == 0 then
							v = 1
						end
						v = v * r_stack:get_count()
						local t_v = minetest.get_item_group(stack:get_name(),
								"trade_value")
						if t_v == 0 then
							t_v = 1
						end
						t_v = t_v * stack:get_count()
						if v >= t_v then
							return r_stack:get_count()
						else
							jas0.message(name,
									"Is that all?  I'm afraid it's not enough.",
									true)
							return 0
						end
					end
				end,
				allow_move = function()
					return 0
				end,
				allow_take = function(inv, listname, index, stack, player)
					return 0
				end,
				on_put = function(p_inv, p_listname, p_index, p_stack, p_player)
					inv:set_stack(listname, index, "")
					local player_inv = p_player:get_inventory()
					local y = player_inv:add_item("main", p_inv:get_stack("exchange", 1))
					if y then
						local p = player:get_pos()
						if p then
							minetest.add_item(p, y)
						end
					end
					if inv:room_for_item("trade", p_stack) then
						inv:add_item("trade", p_stack)
					else
						self.shop = "probably_closed"
					end
					local list = inv:get_list("trade")
					for i = 1, #list do
						list[i] = list[i]:to_string()
					end
					self.inv = minetest.serialize(list)
					p_inv:set_list("exchange", {})
					jas0.message(name, "Thank you for your patronage!", true)

					return -1
				end,
			})
			detached:set_size("exchange", 2 * 1)
			detached:add_item("exchange", stack)
			local trade_fs = "size[8,6.5]" ..
				jas0.exit_button() ..
				jas0.help_button() ..
				"label[0,0;I'll need something from you.]" ..
				"list[detached:trade_" .. self.tid .. ";exchange;3,1;2,1]" ..
				"list[current_player;main;0,2.5;8,1]" ..
				"list[current_player;main;0,3.6;8,3;8]" ..
				default.get_hotbar_bg(0, 2.5) ..
			""
			local list = inv:get_list("trade")
			for i = 1, #list do
				list[i] = list[i]:to_string()
			end
			self.inv = minetest.serialize(list)
			return 0, minetest.show_formspec(name, "mobs:npc_trade", trade_fs)
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

			local ls = {
				"dresser:skin_" .. dresser.skins[random(#dresser.skins)][1],

			}
			for i = random(1, 2), #mobs.npc_drops, 2 do
				table.insert(ls, mobs.npc_drops[i])
			end
			local d_loot = dungeon_loot.registered_loot
			local c = d_loot.count or {1, 2}
			for i = random(1, random(2, 3)), #d_loot, 2 do
				if d_loot[i].chance > random() then
					table.insert(ls,
							d_loot[i].name .. " " ..
							random(c[1], c[2]))
				end
			end
			for i = #ls, 1, -1 do
				local r = random(#ls)
				ls[i], ls[r] = ls[r], ls[i]
			end
			inv_id:set_list("trade", ls)
			ls = inv_id:get_list("trade")
			for i = 1, #ls do
				ls[i] = ls[i]:to_string()
			end
			self.inv = minetest.serialize(ls)
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
				jas0.help_button(-0.1, -0.075) ..
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
