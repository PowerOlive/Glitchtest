-- jas0/players.lua is part of Glitchtest
-- Copyright 2018 James Stevenson
-- GNU GPL 3

local players = {}
local function level(player, repeater)
	if not player then
		return
	end
	local name = player:get_player_name()
	if not players[name] then
		return
	end
	local l = players[name]
	local h = player:get_properties().hp_max
	if l >= 0 and l < 30 and
			h ~= 20 then
		jas0.message(name, "Setting HP Max 20!")
		player:set_properties({hp_max = 20,})
	elseif l >= 30 and l < 40 and
			h ~= 30 then
		jas0.message(name, "Setting HP Max 30!")
		player:set_properties({hp_max = 30,})
	elseif l >= 40 and l < 50 and
			h ~= 40 then
		jas0.message(name, "Setting HP Max 40!")
		player:set_properties({hp_max = 40,})
	elseif l >= 50 and l < 60 and
			h ~= 50 then
		jas0.message(name, "Setting HP Max 50!")
		player:set_properties({hp_max = 50,})
	elseif l >= 60 and l < 70 and
			h ~= 60 then
		jas0.message(name, "Setting HP Max 60!")
		player:set_properties({hp_max = 60,})
	elseif l >= 70 and l < 80 and
			h ~= 70 then
		jas0.message(name, "Setting HP Max 70!")
		player:set_properties({hp_max = 70,})
	elseif l >= 80 and l < 90 and
			h ~= 80 then
		jas0.message(name, "Setting HP Max 80!")
		player:set_properties({hp_max = 80,})
	elseif l >= 90 and l < 99 and
			h ~= 90 then
		jas0.message(name, "Setting HP Max 90!")
		player:set_properties({hp_max = 90,})
	elseif l >= 99 and h ~= 99 then
		jas0.message(name, "Setting HP Max 99!  The MAX!!")
		player:set_properties({hp_max = 99,})
	end
	if players[name] >= 99 then
		if players[name] > 99 then
			players[name] = 99
			return
		else
			return
		end
	end
	if sneak_jump.cdr(player) then
		players[name] = players[name] + 0.1
	else
		players[name] = players[name] + 0.01
	end
	if repeater then
		minetest.after(2, level, player)
	end
end

jas0.level = function(player, change)
	if not player then
		return
	end
	local name = player:get_player_name()
	if not change then
		return players[name]
	end
	if not players[name] or
			(change > 0 and players[name] >= 99) then
		return
	end
	players[name] = players[name] + change
	level(player, false)
end
minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	local name = player:get_player_name()
	if player:get_hp() ~= 0 then
		local hp = meta:get_int("hp")
		if hp == 0 then
			hp = 20
		end
		if hp then
			jas0.message(name,
					"Attempting to restore HP!")
		minetest.after(0.12, function()
				player:set_hp(hp)
			end)
		end
	end
	local l = meta:get_float("level")
	players[name] = l
	level(player)
end)

minetest.register_on_respawnplayer(function(player)
	if not player or not player:get_properties() then
		return
	end
	players[player:get_player_name()] = 0
	player:set_properties({hp_max = 20,})
end)

local function save(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	if not meta then
		return
	end
	local hp = player:get_hp()
	local name = player:get_player_name()
	meta:set_float("level", players[name])
	meta:set_int("hp", hp)
end
minetest.register_on_leaveplayer(function(player)
	-- This doesn't run if the server shuts down.
	save(player)
end)
minetest.register_chatcommand("save", {
	description = "Save player class and level.",
	params = "none",
	privs = "interact",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		save(player)
		return true, "Player class and level saved."
	end,
})
minetest.register_on_shutdown(function()
	local m = minetest.get_connected_players()
	for i = 1, #m do
		save(m[1])
	end
end)

minetest.register_chatcommand("level", {
	description = "Show level",
	params = "none",
	privs = "interact",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		return true, "Level: " .. tostring(jas0.level(player)) .. ", " ..
				"HP " .. tostring(player:get_hp()) .. " / " ..
				tostring(player:get_properties().hp_max)
	end,
})
