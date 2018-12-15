local pi = math.pi
local player_in_bed = 0
local is_sp = minetest.is_singleplayer()
local enable_respawn = minetest.settings:get_bool("enable_bed_respawn")
if enable_respawn == nil then
	enable_respawn = true
end

-- Helper functions

local function get_look_yaw(pos)
	local rotation = minetest.get_node(pos).param2
	if rotation > 3 then
		rotation = rotation % 4 -- Mask colorfacedir values
	end
	if rotation == 1 then
		return pi / 2, rotation
	elseif rotation == 3 then
		return -pi / 2, rotation
	elseif rotation == 0 then
		return pi, rotation
	else
		return 0, rotation
	end
end

local function is_night_skip_enabled()
	local enable_night_skip = minetest.settings:get_bool("enable_bed_night_skip")
	if enable_night_skip == nil then
		enable_night_skip = true
	end
	return enable_night_skip
end

local function check_in_beds(players)
	local in_bed = beds.player
	if not players then
		players = minetest.get_connected_players()
	end

	for n, player in ipairs(players) do
		local name = player:get_player_name()
		if not in_bed[name] then
			return false
		end
	end

	return #players > 0
end

local function lay_down(player, pos, bed_pos, state, skip)
	local name = player:get_player_name()
	local hud_flags = player:hud_get_flags()

	if not player or not name then
		return
	end

	-- stand up
	if state ~= nil and not state then
		local p = beds.pos[name] or nil
		if beds.player[name] ~= nil then
			beds.player[name] = nil
			beds.bed_position[name] = nil
			player_in_bed = player_in_bed - 1
		end
		-- skip here to prevent sending player specific changes (used for leaving players)
		if skip then
			return
		end
		if p then
			player:set_pos(p)
		end

		-- physics, eye_offset, etc
		player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
		player:set_look_horizontal(math.random(1, 180) / 100)
		default.player_attached[name] = false
		player:set_physics_override(1, 1, 1)
		hud_flags.wielditem = true
		default.player_set_animation(player, "stand" , 30)

	-- lay down
	else
		beds.player[name] = 1
		beds.pos[name] = pos
		beds.bed_position[name] = bed_pos
		player_in_bed = player_in_bed + 1

		-- physics, eye_offset, etc
		player:set_eye_offset({x = 0, y = -13, z = 0}, {x = 0, y = 0, z = 0})
		local yaw, param2 = get_look_yaw(bed_pos)
		player:set_look_horizontal(yaw)
		local dir = minetest.facedir_to_dir(param2)
		local p = {x = bed_pos.x + dir.x / 2, y = bed_pos.y, z = bed_pos.z + dir.z / 2}
		player:set_physics_override(0, 0, 0)
		player:set_pos(p)
		default.player_attached[name] = true
		hud_flags.wielditem = false
		default.player_set_animation(player, "lay" , 0)
	end

	player:hud_set_flags(hud_flags)
end

local function update_formspecs(finished)
	local ges = #minetest.get_connected_players()
	local form_n
	local is_majority = (ges / 2) < player_in_bed

	if finished then
		form_n = beds.formspec .. "label[2.7,11; Good morning.]"
	else
		form_n = beds.formspec .. "label[2.2,11;" .. tostring(player_in_bed) ..
			" of " .. tostring(ges) .. " players are in bed]"
		if is_majority and is_night_skip_enabled() then
			form_n = form_n .. "button_exit[2,8;4,0.75;force;Force night/day skip]"
		end
	end

	for name,_ in pairs(beds.player) do
		minetest.show_formspec(name, "beds_form", form_n)
	end
end


-- Public functions

function beds.kick_players()
	for name, _ in pairs(beds.player) do
		local player = minetest.get_player_by_name(name)
		lay_down(player, nil, nil, false)
	end
end

function beds.skip_night(f)
	if f then
		return
	end
	if beds.night_toggle then
		minetest.set_timeofday((beds.time.hour * 60 + beds.time.min) / 1440)
		beds.night_toggle = false
	else
		minetest.set_timeofday(((beds.time.hour + 12) % 24 * 60 + beds.time.min) / 1440)
		beds.night_toggle = true
	end
end

function beds.on_rightclick(pos, player)
	local name = player:get_player_name()
	local ppos = player:get_pos()
	local tod = minetest.get_timeofday()

	-- move to bed
	if not beds.player[name] then
		lay_down(player, ppos, pos)
		beds.set_spawns() -- save respawn positions when entering bed
	else
		lay_down(player, nil, nil, false)
	end

	if not is_sp then
		update_formspecs(false)
	end

	-- skip the night and let all players stand up
	if check_in_beds() then
		minetest.after(2, function()
			if not is_sp then
				update_formspecs(is_night_skip_enabled())
			end
			if is_night_skip_enabled() then
				beds.skip_night()
				beds.kick_players()
			end
		end)
	end
end

function beds.can_dig(bed_pos)
	-- Check all players in bed which one is at the expected position
	for _, player_bed_pos in pairs(beds.bed_position) do
		if vector.equals(bed_pos, player_bed_pos) then
			return false
		end
	end
	return true
end

-- Callbacks
-- Only register respawn callback if respawn enabled
if enable_respawn then
	-- respawn player at bed if enabled and valid position is found
	minetest.register_on_respawnplayer(function(player)
		local name = player:get_player_name()
		local pos = beds.spawn[name]
		if pos then
			player:set_pos(pos)
			return true
		end
	end)
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	lay_down(player, nil, nil, false, true)
	beds.player[name] = nil
	if check_in_beds() then
		minetest.after(2, function()
			update_formspecs(is_night_skip_enabled())
			if is_night_skip_enabled() then
				beds.skip_night()
				beds.kick_players()
			end
		end)
	end
end)

beds.gdi = {}
local function beds_list_fs(player, index, tab)
	if not player then
		return
	end
	index = index or 1
	tab = tonumber(tab) or 1
	local name = player:get_player_name()
	beds.gdi[name] = {}
	local beds_list_string = ""
	if tab == 1 and not beds.beds[name] then
		return jas0.message(name, "You do not have any beds saved.")
	end
	local formspec = "size[6,4.75]" ..
		--"box[-0.9,-1.1;6.67,0.5;black]" ..
		"tabheader[0,0;tab;Private,Public;" .. tostring(tab) ..
				";false;true]" ..
		"button_exit[4,4.25;2,1;warp;Warp]" ..
	""
	if tab == 1 then
		formspec = formspec ..
			"button[0,4.25;2,1;delete;Delete]" ..
		""
		for warp_name, destination in pairs(beds.beds[name]) do
			beds_list_string = beds_list_string .. "," .. warp_name
			beds.gdi[name][#beds.gdi[name] + 1] = warp_name
		end
	else
		formspec = formspec ..
			"button[0,4.25;2,1;show;Show]" ..
			"tablecolumns[color;tree;text]" ..
		""
		for player_name, destination in pairs(beds.beds_public) do
			beds_list_string = beds_list_string .. "," ..
				"#FFF,0," .. player_name .. "," ..
			""
			beds.gdi[name][#beds.gdi[name] + 1] = {name = player_name}
			for dest_name, _ in pairs(destination) do
				beds_list_string = beds_list_string ..
					"#FFF,1," .. dest_name .. "," ..
				""
				beds.gdi[name][#beds.gdi[name] + 1] = {name = player_name, dest = dest_name}
			end
			beds_list_string = beds_list_string:sub(1, -2)
		end
	end
	formspec = formspec .. "table[-0.1,-0.1;6,4.34;beds_list_item;" ..
		beds_list_string:sub(2, -1) .. ";" .. index .. "]" ..
	""
	return formspec
end

local beds_list_index = {}
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "beds:inventory" then
		if not player then
			return
		end
		local pos = player:get_pos()
		local name = player:get_player_name()
		local bed_pos = beds.selected[name]
		local meta = minetest.get_meta(bed_pos)
		if fields.sethome then
			walkie.players[name].waypoints.saved = pos
			walkie.players[name].waypoints.pos = pos
			player:hud_change(walkie.meters[name].waypoint,
					"world_pos", pos)
			player:get_meta():set_string("waypoints",
					minetest.serialize(walkie.players[name].waypoints))
			minetest.chat_send_player(name, "Saved home position!")
		elseif fields.setspawn then
			beds.spawn[name] = pos
			minetest.chat_send_player(name, "Saved spawn position!")
		elseif fields.sleep then
			return beds.on_rightclick(bed_pos, player)
		elseif fields.public then
			local owner = meta:get_string("owner")
			if minetest.is_protected(bed_pos, name) or
					owner ~= name then
				jas0.message(name,
						"This bed is protected.  " ..
						"Its state cannot be changed.", true)
				return
			end
			if owner == "" then
				meta:set_string("owner", name)
			end
			meta:set_int("public", -meta:get_int("public"))
		elseif fields.list then
			local tab = 2
			if beds.beds[name] then
				tab = 1
			end
			return minetest.after(0.1, minetest.show_formspec, name,
					"beds:list", beds_list_fs(player, 1, tab))
		elseif fields.home_name then
			if fields.home_name == "Set home name!" or
					not fields.ok and 
					not (fields.key_enter and
					fields.key_enter_field == "home_name") then
				return
			end
			if name ~= meta:get_string("owner") then
				return jas0.message(name,
						"You are not the owner of this bed!",
						true)
			end
			local home_name = fields.home_name
			home_name = minetest.formspec_escape(home_name):gsub("%W", "")
			if not beds.beds[name] then
				beds.beds[name] = {}
			end
			if beds.beds[name][home_name] or beds.beds_public[name][home_name] then
				return jas0.message(name, "This name already exists!",
						true)
			end
			if not bed_pos then
				return
			end
			local old_home_name = meta:get_string("home_name")
			if old_home_name ~= "" then
				if beds.beds[name][old_home_name] then
					beds.beds[name][old_home_name] = nil
				end
				if beds.beds_public[name][old_home_name] then
					beds.beds_public[name][old_home_name] = nil
				end
			end

			meta:set_string("home_name", home_name)
			beds.beds[name][home_name] = pos
			if meta:get_int("public") == 1 then
				if not beds.beds_public[name] then
					beds.beds_public[name] = {}
				end
				beds.beds_public[name][home_name] = pos
			end
			return jas0.message(name, "Saved " .. home_name, true)
		end
	elseif formname == "beds:list" then
		local name = player:get_player_name()
		if fields.tab then
			return minetest.after(0.1, minetest.show_formspec, name,
					"beds:list",
					beds_list_fs(player, 1, fields.tab))
		end
		if not beds_list_index[name] then
			beds_list_index[name] = 1
		end
		if fields.beds_list_item then
			local item = fields.beds_list_item
			local exploded = minetest.explode_table_event(item)
			if exploded.type == "CHG" then
				beds_list_index[name] = exploded.row
			end
		end
		if fields.delete then
			local index = beds_list_index[name]
			local warp_name = beds.gdi[name][index]
			if warp_name then
				return jas0.message(name,
						"Are you certain you wish to " ..
						"delete " .. warp_name .. "?", true,
						"beds:list_delete")
			end
		end
		if fields.warp then
			local index = beds_list_index[name]
			local owner_name
			if beds.gdi[name][index] then
				owner_name = beds.gdi[name][index]["name"]
			end
			local warp_name
			if owner_name then
				warp_name = beds.gdi[name][index]["dest"]
			else
				warp_name = beds.gdi[name][index]
			end
			local pos
			if owner_name then
				pos = beds.beds_public[owner_name][warp_name]
			else
				pos = beds.beds[name][warp_name]
			end
			if pos then
				jas0.message(name, "Warped to " ..
						warp_name .. ".")
				player:set_pos(pos)
			end
		end
		if fields.quit then
			beds_list_index[name] = nil
		end
	elseif formname == "beds:list_delete" and fields.ok then
		local name = player:get_player_name()
		if not beds_list_index[name] then
			beds_list_index[name] = 1
		end
		local index = beds_list_index[name]
		local warp_name = beds.gdi[name][index]
		if warp_name then
			jas0.message(name, "Deleted " .. warp_name .. ".")
			beds.beds[name][warp_name] = nil
			beds.beds_public[name][warp_name] = nil
		end
		return minetest.after(0.1, minetest.show_formspec,
				name, "beds:list", beds_list_fs(player, index))
	elseif formname == "beds_form" then
		-- Because "Force night skip" button is a button_exit,
		-- it will set fields.quit and lay_down call will change
		-- value of player_in_bed, so it must be taken earlier.
		local last_player_in_bed = player_in_bed
		if fields.quit or fields.leave then
			lay_down(player, nil, nil, false)
			update_formspecs(false)
		end
		if fields.force then
			local is_majority = (#minetest.get_connected_players() / 2) < last_player_in_bed
			if is_majority and is_night_skip_enabled() then
				update_formspecs(true)
				beds.skip_night(true)
				beds.kick_players()
			else
				update_formspecs(false)
			end
		end
	end
	return
end)
