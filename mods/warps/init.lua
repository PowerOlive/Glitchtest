-- Copyright (C) 2017, 2018 James Stevenson
-- Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>
-- GNU GPL 3

local warps = {
	mese = "yellow",
	--amethyst = "0x542164CC",
	diamond = "blue",
	--ruby = "red",
	--emerald = "emerald",
}

local function switch_class_fs(player)
	local formspec = "size[8,3.5]" ..
		jas0.exit_button() ..
		jas0.help_button() ..
		"button_exit[4.6,1.9;2,1;switch;Switch]" ..
		"dropdown[2.7,2;2;class;Mage,Miner,Scout,Node;1]" ..
	""
	local meta = player:get_meta()
	local class = meta:get("class")
	local level = jas0.level(player)
	local xp = tostring(level):gsub("(.*)%.", "")
	formspec = formspec ..
		"label[0,0;Current Stats]" ..
		"label[0.34,0.5;Class: " .. class .. "]" ..
		"label[0.34,1;Level: " .. tostring(level):gsub("%.(.*)", "") .. "]" ..
		"label[0.34,1.5;XP: " .. xp:sub(1, 2) .. "]" ..
	""
	return formspec
end

local selected = {}
local function warp_formspec(name)
	local dest = selected[name]
	if dest then
		dest = minetest.get_meta(dest):get_string("destination")
	end
	return "size[7.76,2.9]" ..
		jas0.exit_button(-0.25, -0.1) ..
		"field[1.15,1.2;5.25,1;warp;Destination;" .. dest .. "]" ..
		"button_exit[6,0.88;1,1;ok;OK]" ..
		"field_close_on_enter[warp;true]" ..
	""
end

local timer
local on_punch = function(pos, node, puncher, pointed_thing)
	if node.name == "warps:warpstone_diamond" then
		local meta = minetest.get_meta(pos)
		if meta and meta:get_string("warp") ~= "" and
				meta:get_string("state") == "" then
			local sid = minetest.sound_play("warps_woosh", {
				object = puncher,
			})
			meta:set_string("state", "timeout")
			local warp = minetest.deserialize(meta:get_string("warp"))
			local p = puncher:get_pos()
			jas0.message(puncher, "Hold still.")
			timer = function(p, player, time, meta, sid, warp)
				if vector.equals(p, player:get_pos()) then
					if time >= 4.4 then
						minetest.sound_fade(sid, -1, 0)
						meta:set_string("state", "")
						player:set_pos(warp)
						warp.y = warp.y + 2
						jas0.message(player, "Warped to "
								.. meta:get_string("destination") .. ".")
						return minetest.sound_play("sneak_jump_item",
								{pos = warp, max_hear_distance = 64})
					end
					minetest.after(0.334, timer, p, player, time + 0.334, meta, sid, warp)
				else
					jas0.message(puncher,
							"Stand still for 5 seconds after punching to warp.")
					minetest.sound_fade(sid, -0.89, 0)
					meta:set_string("state", "")
					return
				end
			end
			return timer(p, puncher, 0, meta, sid, warp)
		elseif meta:get_string("state") == "timeout" then
			jas0.message(puncher, "Waiting.")
		else
			jas0.message(puncher, "No destination set.")
		end
	end
end

local on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
	local name = clicker:get_player_name()
	selected[name] = pos
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if node.name == "warps:warpstone_diamond" then
		if name ~= owner then
			jas0.message(name, "Only the owner of this warpstone can set its destination.", true)
			return
		end
		minetest.show_formspec(name, "warps:warpstone_diamond", warp_formspec(name))
		return
	elseif node.name == "warps:warpstone_mese" then
		if name ~= owner then
			minetest.show_formspec(name, "warps:warpstone_mese_switch",
					switch_class_fs(clicker))
			return
		end
		local codex = minetest.deserialize(meta:get_string("codex"))
		local formspec = "size[8,3.5]" ..
			jas0.exit_button() ..
			jas0.help_button() ..
			"button_exit[1.8,2.65;2,1;save;Save]" ..
			"button_exit[4.7,2.65;2,1;switch;Switch]" ..
		""
		for class, level in pairs(codex) do
			local xp = tostring(level):gsub("(.*)%.", "")
			formspec = formspec ..
				"label[0,0;Saved Stats]" ..
				"label[0.34,0.5;Class: " .. class .. "]" ..
				"label[0.34,1;Level: " .. tostring(level):gsub("%.(.*)", "") .. "]" ..
				"label[0.34,1.5;XP: " .. xp:sub(1, 2) .. "]" ..
			""
		end
		minetest.show_formspec(name, "warps:warpstone_mese", formspec)
	end
end

local on_blast = function()
end

local can_dig = function(pos, player)
	local meta = minetest.get_meta(pos)
	if meta:get_string("owner") ~= player:get_player_name() then
		jas0.message(player, "Only the owner of this warpstone may break it.")
		return false
	else
		return true
	end
end

after_dig_node = function(pos, oldnode, oldmetadata, digger)
	if oldnode.name == "warps:warpstone_mese" then
		local name = digger:get_player_name()
		selected[name] = oldmetadata
		jas0.message(digger, "Would you like to apply the stored class and level?", true, "warps:warpstone_mese_apply")
	end
end

local after_place_node = function(pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta(pos)
	local name = placer:get_player_name()
	if not name or not meta then
		return
	end
	meta:set_string("owner", name)
	if itemstack:get_name() == "warps:warpstone_mese" then
		local p_meta = placer:get_meta()
		local class = p_meta:get("class")
		local level = jas0.level(placer)
		meta:set_string("infotext",
				"Mese Warpstone\nOwned by " .. name ..
				"\n" .. class .. ": " .. tostring(level):gsub("%.(.*)", ""))
		meta:set_string("codex", minetest.serialize({[class] = level}))
		jas0.level(placer, -jas0.level(placer))
		jas0.message(name, "Your level and class have been preserved in the warpstone.\n" ..
				"However, your level has been reset to 0.")
	elseif itemstack:get_name() == "warps:warpstone_diamond" then
		meta:set_string("infotext", "Uninitialized warpstone\n" ..
				"Right-click to set destination.")
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if formname == "warps:warpstone_diamond" then
		local w = fields.warp
		if w then
			local b = beds.beds[name]
			if b[w] then
				local n = minetest.get_meta(selected[name])
				selected[name] = nil
				if n then
					n:set_string("warp",
							minetest.serialize(b[w]))
					n:set_string("destination", w)
					n:set_string("infotext", "Warp to " .. w ..
							"\nPunch and stand still to warp")
				end
				return
			end
			for name, warps in pairs(beds.beds_public) do
				for warp, pos in pairs(warps) do
					if w == warp then
						local n = minetest.get_meta(selected[name])
						selected[name] = nil
						if n then
							n:set_string("warp",
									minetest.serialize(pos))
							n:set_string("destination", w)
							n:set_string("infotext", "Warp to " .. w ..
									"\nPunch and stand still to warp")
						end
						return
					end
				end
			end
		end
	end
	if formname == "warps:warpstone_mese" then
		if fields.save then
			jas0.message(name, "The cost is one mese crystal.",
					true, "warps:warpstone_mese_cost")
		elseif fields.switch then
			minetest.show_formspec(name,
					"warps:warpstone_mese_switch",
					switch_class_fs(player))
		elseif fields.help then
			jas0.message(name, "Placing this node resets your class level." ..
					"  However, your class and level are preserved " ..
					"in this warpstone.  Digging it will restore them" ..
					" after a dialog confirmation.\n\nIf this is not " ..
					"your warpstone, then you can only switch your class" ..
					" here.  You cannot save, nor dig the warpstone.",
					true, nil, "Mese Warpstone Help", true)
		end
	elseif formname == "warps:warpstone_mese_switch" and fields.switch then
		jas0.change_class(player, string.lower(fields.class), true)
		jas0.message(player, "Switched to " ..
				string.lower(fields.class) .. " class.")
	elseif formname == "warps:warpstone_mese_switch" and fields.help then
		jas0.message(name, "Placing this node resets your class level." ..
				"  However, your class and level are preserved " ..
				"in this warpstone.  Digging it will restore them" ..
				" after a dialog confirmation.\n\nIf this is not " ..
				"your warpstone, then you can only switch your class" ..
				" here.  You cannot save, nor dig the warpstone.",
				true, nil, "Mese Warpstone Help", true)
	elseif formname == "warps:warpstone_mese_cost" and fields.ok then
		local inv = player:get_inventory()
		if inv:contains_item("main", "default:mese_crystal") then
			inv:remove_item("main", "default:mese_crystal")
			local name = player:get_player_name()
			local meta = minetest.get_meta(selected[name])
			selected[name] = nil
			local class = player:get_meta():get("class")
			local level = jas0.level(player)
			meta:set_string("codex", minetest.serialize({[class] = level}))
			meta:set_string("infotext", "Mese Warpstone\nOwned by " .. name ..
					"\n" .. class .. ": " .. tostring(level):gsub("%.(.*)", ""))
			jas0.message(player, "Your class and level have been saved.", true)
		else
			jas0.message(player, "You do not have a mese crystal!", true)
		end
	elseif formname == "warps:warpstone_mese_apply" and fields.ok then
		local name = player:get_player_name()
		local codex = minetest.deserialize(selected[name].fields.codex)
		selected[name] = nil
		for k, v in pairs(codex) do
			jas0.change_class(player, k)
			local level = jas0.level(player)
			if v < level then
				return jas0.message(name, "That is a level lower than your current one.")
			end
			jas0.level(player, v - level)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	if not player then
		return
	end
	selected[player:get_player_name()] = nil
end)

for label, color in pairs(warps) do
	minetest.register_node("warps:warpgoo_" .. label, {
		description = label .. " Warp Goo",
		drawtype = "glasslike",
		sounds = default.node_sound_water_defaults(),
		paramtype = "light",
		drop = "vessels:glass_fragments 3", -- TODO Use bucket instead.
		tiles = {{
			name = "warps_warpgoo_" .. label .. ".png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		}},
		post_effect_color = color,
		sunlight_propagates = true,
		walkable = false,
		drowning = 3,
		groups = {oddly_breakable_by_hand = 1},
		light_source = 13,
		-- `alpha' and `use_texture_alpha' do not seem to have an effect,
		-- but removing them results in an invisible node!
		alpha = 191,
		use_texture_alpha = true,
	})
	minetest.register_node("warps:warpstone_" .. label, {
		visual = "mesh",
		mesh = "warps_warpstone.obj",
		description = label .. " Warp Stone",
		tiles = {"warps_" .. label .. "_warpstone.png"},
		drawtype = "mesh",
		wield_scale = {x = 1.5, y = 1.5, z = 1.5},
		stack_max = 1,
		sunlight_propagates = true,
		walkable = false,
		paramtype = "light",
		paramtype2 = "facedir",
		use_texture_alpha = true,
		groups = {cracky = 3, oddly_breakable_by_hand = 1},
		light_source = 11,
		sounds = default.node_sound_glass_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.25, -0.5, -0.25,  0.25, 0.5, 0.25}
		},
		on_rightclick = on_rightclick,
		on_blast = on_blast,
		after_place_node = after_place_node,
		can_dig = can_dig,
		after_dig_node = after_dig_node,
		on_punch = on_punch,
	})
	local mat
	if label ~= "mese" then
		mat = label .. "block"
	else
		mat = label
	end
	minetest.register_craft({
		output = "warps:warpstone_" .. label,
		recipe = {
			{"group:glass", "group:glass", "group:glass"},
			{"group:glass", "default:" .. mat, "group:glass"},
			{"group:glass", "group:glass", "group:glass"}
		}
	})
end
