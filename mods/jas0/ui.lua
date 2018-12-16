-- jas0/ui.lua is part of Glitchtest
-- Copyright 2018 James Stevenson
-- GNU GPL 3

jas0.exit_button = function(x, y)
	if not x then
		x = 0
	end
	if not y then
		y = 0
	end
	return "button_exit[" .. 7.44 + x .. "," ..
			-0.034 + y .. ";0.7,0.667;;x]"
end

jas0.help_button = function(x, y)
	if not x then
		x = 0
	end
	if not y then
		y = 0
	end
	return "button_exit[" .. 6.94 + x .. "," ..
			-0.034 + y .. ";0.7,0.667;help;?]"
end

local log1 = {["walkie"] = {
	["nowield"] = "You need to wield a Walkie Talkie in your hand to warp home!",
	["spawn"] = "You need to wield a Walkie Talkie in your hand to warp to your " ..
		"respawn position.\n\nWould you like to warp to the server spawn point?" ..
		"\n\nThis option can be set in the walkie." ..
	"",
	["home"] = "You don't have a home!  To set your home, " ..
		"activate an Intercomm using your " ..
		"Walkie Talkie, or [Set Home] using a Bed." ..
	"",
}}

local function message(player, message, dialog, formname, title, no_chat_msg)
	if not player then
		return
	end

	local name
	if type(player) == "string" then
		name = player
		player = minetest.get_player_by_name(name)
	else
		name = player:get_player_name()
	end

	if not message then
		message = "This space intentionally left blank."
	end

	if not no_chat_msg then
		minetest.chat_send_player(name, message)
	end

	message = minetest.formspec_escape(message)
	local formspec = "size[8,4]" ..
		jas0.exit_button() ..
		"textarea[0.35,0.5;8,4;;;" ..
				message .. "]" ..
	""
	if title then
		formspec = formspec .. "label[0,0;" .. title .. "]"
	end

	if formname then
		formspec = formspec ..
			"button_exit[1,3;2,1;cancel;Cancel]" ..
			"button_exit[6,3;1,1;ok;OK]" ..
		""
	else
		formname = "jas0:message_dialog"
	end

	if dialog then
		return minetest.after(0, minetest.show_formspec,
				name, formname, formspec)
	else
		return formspec
	end
end

jas0.message = message


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "jas0:respawn" and fields.ok then
		spawn.on_spawn(player)
		return
	elseif formname ~= "" then
		return false
	end
	local wielded = player:get_wielded_item():get_name()
	local name = player:get_player_name()
	if fields.spawn then
		local ss = player:get_meta():get_int("spawn_switch")
		if ss and ss == 1 then
			spawn.on_spawn(player)
			return
		end
		if wielded == "walkie:talkie" then
			if beds.spawn[name] then
				player:set_pos(beds.spawn[name])
			else
				spawn.on_spawn(player)
			end
		else
			message(name, log1["walkie"]["spawn"], true, "jas0:respawn", "No Wielded Walkie", true)
			return false
		end
	elseif fields.home then
		if walkie.players[name].waypoints.saved then
			if wielded ~= "walkie:talkie" then
				message(name, log1["walkie"]["nowield"], true)
				return false
			end
			player:set_pos(walkie.players[name].waypoints.saved)
		else
			message(name, log1["walkie"]["home"], true)
			return false
		end
	end
end)
