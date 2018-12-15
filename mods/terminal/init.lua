-- Terminal mod for Minetest `Glitchtest' game
-- (C) 2018 James Alexander Stevenson
-- GNU GPL 3

terminal = {}
local store = minetest.get_mod_storage()

terminal.display = function(source, user, pos, input)
	if not source or not user then
		return
	end
	local pos = pos or user:get_pos()
	local input = input or ""
	local name = user:get_player_name()

	local cmd_table = {
		"+", "broadcast", "bye", "channel", "echo", "guestbook", "help",
		"hi", "hint", "info", "list", "name", "set", "sign", "warp", "waypoint",
	}

	local term_name, hint, info, wielded, meta
	if source == "item" then
		wielded = user:get_wielded_item()
		meta = wielded:get_meta()
	elseif source == "node" then
		meta = minetest.get_meta(pos)
	elseif source == "mod" then
		meta = store
	else
		return
	end
	minetest.sound_play("walkie_blip", {object = user})

	-- Determine input.
	input = minetest.formspec_escape(input)
	term_name = meta:get_string("term_name") or "default"
	hint = "There is no hint."
	info = "Welcome to terminal."

	local feedback = ""

	-- Get table with command/args.
	local command = input
	local args = {}
	if command:match("%w") then
		for i in command:gmatch"%S+" do
			table.insert(args, i)
		end
		command = args[1]
	end
	local output = ""
	if command == "" then
		command = "Yes Master?"
		output = ""
		feedback = ""
	elseif command == "+" then
		local new_args = {}
		for i = 2, #args do
			if type(tonumber(args[i])) == "number" then
				new_args[i] = tonumber(args[i])
			else
				output = "Err"
				break
			end
		end
		command = input
		local math = 0
		for _, v in pairs(new_args) do
			math = math + v
		end
		if output ~= "Err" then
			output = tostring(math)
		end
		feedback = ""
	elseif command == "say" then
		feedback = function()
			local chat_message = input:sub(5, -1)
		end
	elseif command == "broadcast" then
		output = "Broadcasting to all players with a walkie talkie on any channel."
		feedback = ""
	elseif (command == "bye" or
			command == "quit" or
			command == "exit") then
		output = "Shutting down..."
		feedback = ""
		minetest.after(1, function()
			minetest.close_formspec(name, "terminal" .. source ..
					minetest.pos_to_string(pos))
		end)
	elseif command == "channel" then
		local ch = tonumber(args[2])
		if type(ch) == "number" then
			--dcbl.channels[name].channel = ch
		end
		--feedback = "You are on channel " .. tostring(dcbl.channels[name].channel)
		feedback = "TODO: Implement chat channels."
	elseif command == "echo" then
		--[[
		local new_input = input
		if new_input:len() >= 40 then
			command = new_input:sub(1, 40) .. "$"
		else
			command = input
		end
		--]]
		if type(args[2]) == "string" then
			for i = 2, #args do
				if output == "" then
					output = args[i]
				else
					output = output .. " " .. args[i]
				end
			end
		else
			output = "Invalid usage, type help echo for more information."
		end
		feedback = ""
	elseif command == "guestbook" then
		command = input
		output = "Guestbook entries:\n" .. meta:get_string("guestbook") or ""
		feedback = "There you go!"
	elseif command == "help" then
		command = input
		if args[2] then
			output = "I don't know about " .. args[2]
			feedback = "Type help for a list of commands."
		else
			output = ""
			for i = 1, #cmd_table do
				output = output .. cmd_table[i] .. " "
			end
			feedback = "Type help <cmd> for more information"
		end
	elseif (command == "hi" or command == "hello") then
		output = "Hello."
		feedback = ""
	elseif command == "hint" then
		output = minetest.formspec_escape(hint)
		feedback = ""
	elseif command == "info" then
		output = minetest.formspec_escape(info)
		feedback = ""
	elseif command == "list" then
		local chatters = ""
		for _, player in pairs(minetest.get_connected_players()) do
			if player:get_inventory():contains_item("main", "walkie:talkie") then
				chatters = chatters .. player:get_player_name() .. " "
			end
		end
		if chatters == "" then
			output = "No one seems to have a walkie talkie."
		else
			output = chatters
		end
		feedback = "Players on channel 1 or near intercomm listed."
	elseif command == "name" then
		command = input
		local args = args[2]
		if args then
			if args == term_name then
				output = "Correct!"
			elseif args ~= "" then
				meta:set_string("term_name", args)
				if source == "item" then
					user:set_wielded_item(wielded)
				end
				output = "Station name is now " .. args
			else
				output = "Invalid usage. Type help name for more information."
			end
		else
			output = "Station name is " .. term_name
		end
		feedback = ""
	elseif command == "set" then
		if args[2] == "warp" then
			--[[
			local pt_under = meta:get_string("pt_under")
			if not pt_under or pt_under == "" then
				return
			end
			if not args[3] then
				return
			end
			local nn = minetest.string_to_pos(pt_under)
			if minetest.get_node(nn).name ~= "warps:warpgoo_amethyst" or
					minetest.is_protected(nn, name) then
				return
			end
			minetest.get_meta(nn):set_string("warps_destination", args[3])
			meta:set_string("pt_under", nil)
			--]]
			feedback = "TODO"
		end
		feedback = "TODO"
	elseif command == "sign" then
		command = "Signed:" 
		local s = ""
		for i = 2, 120 do
			if not args[i] then
				break
			end
			if s == "" then
				s = args[i]
			else
				s = s .. " " .. args[i]
			end
		end
		meta:set_string("guestbook", s)
		if source == "item" then
			user:set_wielded_item(wielded)
		end
		output = s
		feedback = "[more]"
	elseif command == "warp" then
		local user_beds = beds.beds[name]
		if user_beds and user_beds[args[2]] then
			user:set_pos(user_beds[args[2]])
		end
	elseif command == "waypoint" then
		output = "set|display"
		feedback = "Not yet implemented."
	else
		output = "Unknown command. Type help for a list."
		feedback = ""
	end
	if type(feedback) == "function" then
		return feedback()
	end
	-- Determine output.
	if #output > 40 then
		local old_output = output
		local spos = 0
		local old_spos = 0
		local ln1 = ""
		local ln2 = ""
		local ln3 = ""
		local new_output
		for p in old_output:gmatch"." do
			spos = spos + 1
			if spos >= 40 and p == " " and ln1 == "" then
				ln1 = old_output:sub(1, spos)
				ln2 = old_output:sub(spos + 1, -1)
				old_spos = spos
			end
			if spos >= 80 and p == " " and ln2 ~= "" then
				ln2 = old_output:sub(old_spos + 1, spos)
				ln3 = old_output:sub(spos + 1, 120)
				break
			end
		end
		new_output = ln1 .. "\n" .. ln2 .. "\n" .. ln3
		if old_output:len() > 120 then
			output = new_output ..
					"\n\n" .. minetest.formspec_escape(feedback) ..
					"\n" .. minetest.formspec_escape("[more]")
		else
			output = new_output .. "\n\n" .. minetest.formspec_escape(feedback)
		end
	else
		output = output .. "\n\n\n\n" .. minetest.formspec_escape(feedback)
	end
	local fs_command = "label[0,0.1;> " .. command .. "]"
	local fs_output = "label[0,0.6;" .. output .. "]"
	if command == "echo" then
		fs_command = ""
		fs_output = "label[0,0.1;" .. output .. "]"
	end
		
	-- Collect data and display.
	local formspec = "size[8.8,5.9]" ..
			default.gui_bg_img ..
			"box[-.1,-.0;8.78,5.1;gray]" ..
			fs_command ..
			fs_output ..
			"field[0.18,5.6;8,1;input;;]" ..
			"button[7.78,5.3;1.15,1;ok;OK]" ..
			"field_close_on_enter[input;false]"

	if source == "item" then
		source = 1
	elseif source == "node" then
		source = 2
	elseif source == "mod" then
		source = 3
	end
	return minetest.show_formspec(name, "terminal" .. source ..
			minetest.pos_to_string(pos), formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname:sub(1, 8) ~= "terminal" or
			not player or fields.quit then
		return
	end
	local name = player:get_player_name()
	local pos = minetest.string_to_pos(formname:sub(10))
	local source = tonumber(formname:sub(9, 9))
	if fields.ok and fields.input == "" then
		return minetest.close_formspec(name, "terminal" .. source ..
				minetest.pos_to_string(pos))
	end
	local s = {"item", "node", "mod"}
	source = s[source]
	terminal.display(source, player, pos, fields.input)
end)
--[[
minetest.register_on_chat_message(function(name, message)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end
	local pp = {}
	for _, p in ipairs(minetest.get_connected_players()) do
		local n = p:get_player_name()
		pp[n] = {}
		print(#pp[n])
	end
	terminal.display("mod", player, player:get_pos(), "say " .. message)
	return true
end)
--]]
---[[
minetest.register_privilege("terminal", {
	description = "Can use /terminal command",
	give_to_singleplayer = false,
	give_to_admin = true,
})

minetest.register_chatcommand("terminal", {
	description = "Display terminal interface",
	params = "[<input>]",
	privs = "terminal",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return true, "Invalid usage."
		end
		terminal.display("mod", player, player:get_pos(), param)
	end
})
--]]
