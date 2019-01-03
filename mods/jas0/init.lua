-- jas0 Glitchtest Support Mod
-- Copyright 2018 James Stevenson
-- GNU GPL 3

jas0 = {}

local store = minetest.get_mod_storage()
local is = {}
is.books = minetest.deserialize(store:get_string("books")) or {}
for i = 1, #is.books do
	give_initial_stuff.add(ItemStack(is.books[i]))
end

minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end
	minetest.after(0.1, function()
		minetest.chat_send_player(player:get_player_name(),
				"Hello.  Welcome to Glitchtest server!  " ..
				"Type /help all for a list of commands.")
		minetest.sound_play("sneak_jump_item", {
			gain = 0.1,
			pos = player:get_pos(),
		})
	end)
end)

minetest.register_on_chat_message(function(name, message)
	local players = minetest.get_connected_players()
	for i = 1, #players do
		--[[local f = ]]minetest.sound_play("walkie_blip", {
			gain = 0.1,
			pos = players[i]:get_pos(),
		})
		--minetest.sound_fade(f, -5, 0.25)
		minetest.chat_send_player(players[i]:get_player_name(),
				minetest.colorize("red", "<") ..
				name .. minetest.colorize("red", "> ") ..
				message)
	end
	return true
end)

minetest.register_on_dieplayer(function(player)
	if not player then
		return
	end
	local p = minetest.pos_to_string(vector.round(player:get_pos()))
	player:get_meta():set_string("death_location", p)
end)

minetest.register_on_respawnplayer(function(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	if not meta then
		return
	end
	minetest.after(0.1, function()
		minetest.chat_send_player(player:get_player_name(),
				"Hello.  Welcome to Glitchtest server!  " ..
				"Type /help all for a list of commands.")
		minetest.sound_play("sneak_jump_item", {
			gain = 0.1,
			pos = player:get_pos(),
		})
	end)
	local inv = player:get_inventory()
	if meta:get("class") == "node" then
		inv:set_stack("main", 1, meta:get("node") or
				"default:dirt")
		return
	end
	local p = meta:get("death_location")
	if p then
		local ii = ItemStack("default:paper")
		ii:get_meta():set_string("description",
				"Died at " .. p)
		inv:add_item("main", ItemStack(ii))
	end
	inv:add_item("main", "walkie:talkie")
	for i = 1, #is.books do
		inv:add_item("main", ItemStack(is.books[i]))
	end
end)

-- OVERRIDES
minetest.override_item("bones:bones", {
	on_use = minetest.item_eat(1)
})
minetest.override_item("farming:seed_wheat", {
	on_use = minetest.item_eat(1)
})
minetest.override_item("farming:seed_cotton", {
	on_use = minetest.item_eat(1)
})

local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
dofile(mod_path .. "/paper.lua")
dofile(mod_path .. "/ui.lua")
dofile(mod_path .. "/players.lua")
dofile(mod_path .. "/classes.lua")
dofile(mod_path .. "/recipes.lua")
dofile(mod_path .. "/chatcommands.lua")
dofile(mod_path .. "/abm.lua")
