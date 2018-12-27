--[[ Walkie Talkie Minetest Mod (Part of Glitchtest Game)
     Copyright (C) 2018 James A. Stevenson
     GNU GPL 3 ]]

walkie = {}
walkie.players = {}
walkie.meters = {}

local hud_elem_compass = {
	hud_elem_type = "image",
	position = {x = 1, y = 1},
	name = "Compass",
	scale = {x = 1, y = 1},
	text = "walkie_empty.png",
	alignment = {x = -1, y = -1},
	offset = {x = -20, y = -156},
}

local hud_elem_coords = {
	hud_elem_type = "text",
	position = {x = 1, y = 1},
	name = "Coordinates",
	scale = {x = 200, y = 20},
	text = "",
	number = 0xFFFFFF,
	direction = 1,
	alignment = {x = -1, y = -1},
	offset = {x = -20, y = -136},
}

local hud_elem_waypoint = {
	hud_elem_type = "waypoint",
	name = "",
	text = "",
	number = 0xFFFFFF,
}

local function updater(player)
	if not player then
		return
	end
	local name = player:get_player_name()
	if not walkie.players[name] then
		return
	end
	local wielded_name = player:get_wielded_item():get_name()
	if wielded_name == "walkie:talkie" then
		-- Show compass & coordinates.
		walkie.players[name].pos = player:get_pos()
		walkie.players[name].dir = player:get_look_horizontal()
		local p = vector.round(walkie.players[name].pos)
		local d = math.floor(walkie.players[name].dir * math.pi)
		if d >= 1 and d < 4 then
			player:hud_change(walkie.meters[name].compass,
					"text",
					"walkie_compass_nw.png")
		elseif d >= 4 and d < 6 then
			player:hud_change(walkie.meters[name].compass,
					"text",
					"walkie_compass_n.png^[transformR270")
		elseif d >= 6 and d < 9 then
			player:hud_change(walkie.meters[name].compass,
					"text",
					"walkie_compass_nw.png^[transformR270")
		elseif d >= 9 and d < 11 then
			player:hud_change(walkie.meters[name].compass,
					"text",
					"walkie_compass_n.png^[transformR180")
		elseif d >= 11 and d < 14 then
			player:hud_change(walkie.meters[name].compass,
					"text",
					"walkie_compass_nw.png^[transformR180")
		elseif d >= 14 and d < 16 then
			player:hud_change(walkie.meters[name].compass,
					"text",
					"walkie_compass_n.png^[transformR90")
		elseif d >= 16 and d < 19 then
			player:hud_change(walkie.meters[name].compass,
					"text",
					"walkie_compass_nw.png^[transformR90")
		else
			player:hud_change(walkie.meters[name].compass,
					"text",
					"walkie_compass_n.png")
		end
		player:hud_change(walkie.meters[name].coords,
				"text",
				p.x .. ", " .. p.y .. ", " .. p.z)
		player:set_properties({zoom_fov = 45})
		player:hud_set_flags({minimap = true, minimap_radar = true})
		-- Add waypoint HUD.
		if not walkie.meters[name].waypoint and
				walkie.players[name].waypoints.pos then
			local pos = walkie.players[name].waypoints.pos
			if pos then
				local hud_def = hud_elem_waypoint
				hud_def.world_pos = pos
				local id = player:hud_add(hud_def)
				walkie.meters[name].waypoint = id
			end
		end
	else
		player:hud_set_flags({minimap = false, minimap_radar = false})
		-- "Remove" compass and coordinate HUDs.
		player:hud_change(walkie.meters[name].coords,
				"text",
				"")
		player:hud_change(walkie.meters[name].compass,
				"text",
				"walkie_empty.png")
		-- Remove waypoints HUD.
		if walkie.meters[name].waypoint then
			player:hud_remove(walkie.meters[name].waypoint)
			player:set_properties({zoom_fov = 0})
			player:hud_set_flags({minimap = false, minimap_radar = false})
			walkie.meters[name].waypoint = nil
		end
	end
	minetest.after(0.12, updater, player)
end

minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end
	local name = player:get_player_name()
	local compass = player:hud_add(hud_elem_compass)
	local coords = player:hud_add(hud_elem_coords)
	walkie.meters[name] = {
		compass = compass,
		coords = coords,
	}
	walkie.players[name] = {waypoints = {}}
	local waypoints = minetest.deserialize(player:get_attribute("waypoints"))
	if waypoints then
		walkie.players[name].waypoints = waypoints
	end
	updater(player)
end)

minetest.register_on_leaveplayer(function(player)
	if not player then
		return
	end
	local name = player:get_player_name()
	walkie.players[name] = nil
	walkie.meters[name] = nil
end)

minetest.register_on_dieplayer(function(player)
	if not player then
		return
	end
	local name = player:get_player_name()
	local pos = player:get_pos()
	if not walkie.players[name] then --TODO Move to respawn?
		return
	end
	walkie.players[name].waypoints.death = pos
	walkie.players[name].waypoints.pos = pos
	player:hud_change(walkie.meters[name].waypoint, "world_pos", pos)
	player:set_attribute("waypoints",
			minetest.serialize(walkie.players[name].waypoints))
end)

-- Walkie Talkie
minetest.register_craftitem("walkie:talkie", {
	description = "Walkie Talkie",
	inventory_image = "walkie_talkie.png",
	stack_max = 1,
	groups = {trade_value = 4,},
	on_use = function(itemstack, user, pointed_thing)
		local sound = minetest.sound_play({name = "walkie_blip", gain = 0.667},
				{object = user,	loop = true})
		minetest.after(0.1, function ()
			minetest.sound_stop(sound)
		end)

		local name = user:get_player_name()
		local pos = user:get_pos()
		local waypoint = walkie.players[name].waypoints.pos
		if waypoint then
			local saved = walkie.players[name].waypoints.saved
			local death = walkie.players[name].waypoints.death
			if waypoint == saved and death then
				walkie.players[name].waypoints.pos = death
				user:hud_change(walkie.meters[name].waypoint,
						"world_pos", death)
			elseif waypoint == death and saved then
				walkie.players[name].waypoints.pos = saved
				user:hud_change(walkie.meters[name].waypoint,
						"world_pos", saved)
			end
		end
		return itemstack
	end,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local node = minetest.get_node(pointed_thing.under)
			local pdef = minetest.registered_nodes[node.name]
			if node.name == "walkie:intercomm" then
				local pos = placer:get_pos()
				local name = placer:get_player_name()
				walkie.players[name].waypoints.saved = pos
				walkie.players[name].waypoints.pos = pos
				placer:hud_change(walkie.meters[name].waypoint,
						"world_pos", pos)
				placer:set_attribute("waypoints",
						minetest.serialize(walkie.players[name].waypoints))
			elseif pdef and pdef.on_rightclick then
				return pdef.on_rightclick(pointed_thing.under,
						node, placer, itemstack, pointed_thing)
			else
				terminal.display("item", placer)
			end
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		terminal.display("item", user)
end,
})

-- Intercomm
minetest.register_node("walkie:intercomm", {
	description = "Intercomm",
	drawtype = "nodebox",
	tiles = {"walkie_intercomm_wall.png"},
	inventory_image = "walkie_intercomm.png",
	wield_image = "walkie_intercomm.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	stack_max = 1,
	light_source = 8,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.4375, 0.5, -0.3125, 0.4375, 0.5, 0.3125},
		wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
		wall_side   = {-0.5, -0.375, -0.4375, -0.4375, 0.375, 0.4375},
	},
	groups = {
		cracky = 3,
		oddly_breakable_by_hand = 1,
		attached_node = 1,
		actuator = 2
	},
	legacy_wallmounted = true,
	sounds = {
		footstep = {name = "default_hard_footstep", gain = 0.5},
		dig = {name = "walkie_blip", gain = 1.0},
		dug = {name = "walkie_blip", gain = 1.0},
		place = {name = "walkie_blip", gain = 1.0},
		place_failed = {name = "walkie_blip", gain = 1.0}
	},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if minetest.get_node(pointed_thing.under).name == "default:mese" then
			minetest.swap_node(pointed_thing.under,
					{name = "default:mese_"})
		end
		local m = minetest.get_meta(pos)
		for k, v in pairs(minetest.deserialize(itemstack:get_meta():get"stuff")) do
			m:set_string(k, v)
		end
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local h = minetest.find_node_near(pos, 1, "default:mese_")
		if h then
			minetest.get_node_timer(h):start(0)
		end
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		terminal.display("node", clicker, pos)
	end,
	_on_function = function(pos)
		local args = minetest.deserialize(minetest.get_meta(pos):get_string("_on_function"))
		return args
	end,
	preserve_metadata = function(pos, oldnode, oldmeta, drops)
		local m = minetest.serialize(oldmeta)
		drops[1]:get_meta():set_string("stuff", m)
	end,
	on_blast = function()
	end,
})

minetest.register_craft({
	output = "walkie:talkie",
	recipe = {
		{"default:copper_ingot", "default:steel_ingot", "default:copper_ingot"},
		{"", "default:mese_crystal", ""},
		{"default:copper_ingot", "default:steel_ingot", "default:copper_ingot"},
	}
})

minetest.register_craft({
	output = "walkie:intercomm",
	recipe = {
		{"default:copper_ingot", "default:mese_crystal", "default:copper_ingot"},
		{"default:steel_ingot", "walkie:talkie", "default:steel_ingot"},
		{"default:copper_ingot", "default:diamond", "default:copper_ingot"},
	}
})
