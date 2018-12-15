-- Dresser mod for Glitchtest
-- Copyright 2018 James Stevenson
-- GNU GPL 3


dresser = {}
dresser.players = {}
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/skins.lua")
local function formspec(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end
	player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = -10, z = 0})
	dresser.players[name] = true
	return "size[8,10.5]" ..
		"no_prepend[]" ..
		"bgcolor[#FFFFFF00]" ..
		"box[-0.15,-0.15;8,1.2;#000000FF]" .. -- Top border
		"box[6.85,-0.15;1.1,11.2;#000000FF]" .. -- Right border
		"box[-0.15,6.85;8.1,4.2;#000000FF]" .. -- Bottom border
		"box[-0.15,-0.15;1.1,10;#000000FF]" .. -- Left border
		"box[-0.1,-0.1;1,10;#343434FF]" .. -- Left
		"box[-0.1,-0.1;8,1.1;#343434FF]" .. -- Top
		"box[6.9,-0.1;1,10;#343434FF]" .. -- Right
		"box[-0.1,6.9;8,4.1;#343434FF]" .. -- Bottom
		"listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]" ..
		jas0.help_button() ..
		jas0.exit_button() ..
		"list[current_player;skin;3.5,0;1,1]" ..
		"list[detached:" .. name .. "_clothing;clothing;0,1;1,6]" ..
		"list[detached:" .. name .. "_armor;armor;7,1;1,6]" ..
		"list[current_player;main;0,7;8,4]" ..
	""
end

local dresser_help = "The dresser can be used to change clothing, " ..
	"armor, and skins.  Use third person view to check yourself out!" ..
	"\n\nThe clothing goes on the left side, and the armor on the right.  " ..
	"The skin goes on top.  Armor, skins, and clothing, can be applied " ..
	"by swinging the items in your hand!" ..
""

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "dresser:dresser" then
		return
	end
	if fields.quit then
		player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
		dresser.players[player:get_player_name()] = nil
		if fields.help then
			jas0.message(player, dresser_help, true, nil, "Dresser Help", true)
		end
	end
end)
minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end
	local inv = player:get_inventory()
	inv:set_size("skin", 1)
end)
minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
	if action == "move" then
		if inventory_info.from_list == "main" and inventory_info.to_list == "skin" then
			if inventory:get_stack(inventory_info.from_list,
					inventory_info.from_index):get_definition()._skin then
				return 1
			else
				return 0
			end
		end
	end
end)
minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
	if action == "move" and inventory_info.to_list == "skin" then
		local skin = inventory:get_stack("skin", 1):get_definition()._skin
		if skin then
			multiskin.set_player_skin(player, skin)
			multiskin.update_player_visuals(player)
		end
	elseif (action == "move" and
				inventory_info.from_list == "skin") or
				(action == "take" and
				inventory_info.listname == "skin") then
		local gender = player:get_meta():get_string("gender")
		local skin = "multiskin_" .. gender .. ".png"
		if skin ~= player:get_meta():get_string("multiskin_skin") then
			multiskin.set_player_skin(player, skin)
			multiskin.update_player_visuals(player)
		end
	end
end)
minetest.register_on_respawnplayer(function(player)
	if not player then
		return
	end
	player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
end)
minetest.register_on_dieplayer(function(player)
	if not player then
		return
	end
	dresser.players[player:get_player_name()] = nil
end)
minetest.register_on_leaveplayer(function(player)
	if not player then
		return
	end
	dresser.players[player:get_player_name()] = nil
end)
minetest.register_craft({
	output = "dresser:dresser",
	recipe = {
		{"group:wool", "group:wool", "group:wool"},
		{"group:wool", "default:chest", "group:wool"},
		{"group:wool", "group:wool", "group:wool"},
	},
})
minetest.register_node("dresser:dresser", {
	description = "Dresser",
	paramtype2 = "facedir",
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"dresser_dresser.png",
		"dresser_dresser.png",
	},
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy = 3, flammable = 3},
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("infotext", "Dresser")
	end,
	on_use = function(itemstack, user, pointed_thing)
		local name = user:get_player_name()
		minetest.show_formspec(name, "dresser:dresser", formspec(name))
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local name = clicker:get_player_name()
		minetest.show_formspec(name, "dresser:dresser", formspec(name))
	end,
})
