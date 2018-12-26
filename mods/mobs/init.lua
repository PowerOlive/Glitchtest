local path = minetest.get_modpath(minetest.get_current_modname())
local stepper = 0
minetest.register_globalstep(function(dtime)
	if stepper < 10 then
		stepper = stepper + dtime
		return
	else
		stepper = 0
	end
	local players = minetest.get_connected_players()
	for i = 1, #players do
		if players[i] == "" then
			break
		end
		local pos = players[i]:get_pos()
		if not pos then
			break
		end
		local t = 0
		for k, v in pairs(minetest.get_objects_inside_radius(pos, 16)) do
			local s = v:get_luaentity()
			if s and s.health then
				t = t + 1
			end
			if t >= 6 then
				return v:remove()
			end
		end
		if minetest.find_node_near(pos, 8, "mobs:spawner") then
			break
		end
		if not minetest.get_node_or_nil(pos) then
			break
		end
		if minetest.get_node_or_nil(pos).name ~= "air" then
			pos.y = pos.y + 1
		end
		if minetest.get_node_or_nil(pos).name ~= "air" then
			break
		end
		local added = minetest.add_node(pos, {name = "mobs:spawner"})
		if not added then
			break
		end
		minetest.get_node_timer(pos):start(0)
	end
end)

dofile(path .. "/api.lua")
dofile(path .. "/crafts.lua")
dofile(path .. "/nodes.lua")
dofile(path .. "/npc.lua")
dofile(path .. "/sheep.lua")
dofile(path .. "/rat.lua")
dofile(path .. "/bunny.lua")
dofile(path .. "/kitten.lua")
dofile(path .. "/dungeon_master.lua")
dofile(path .. "/oerkki.lua")
dofile(path .. "/zombies.lua")
