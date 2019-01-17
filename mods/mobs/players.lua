local random = math.random

mobs.check_for_player = function(pos)
	local objects_in_radius = minetest.get_objects_inside_radius(pos, 16)
	for i = 1, #objects_in_radius do
		local object = objects_in_radius[i]
		local player = object:is_player()
		if player then
			return true
		end
	end
	return
end

mobs.undercrowd = function(pos, radius)
	radius = radius or 3
	local r = minetest.get_objects_inside_radius(pos, radius)
	local t = 0
	for _, v in pairs(r) do
		local s = v:get_luaentity()
		if not s then
			break
		end
		if s.owner ~= "" then
			break
		end
		if s.health > 0 then
			t = t + 1
		end
		if t > 5 then
			print("Overcrowded.")
			return v:remove()
		end
	end
end
local undercrowd = mobs.undercrowd

minetest.register_on_mods_loaded(function()
	for node, def in pairs(minetest.registered_nodes) do
		if def.walkable then
			local g = def.groups
			g.reliable = 1
			minetest.override_item(node, {
				groups = g,
			})
		end
	end
end)

mobs.redo = function(pos, radius)
	print("Redoing.")

	radius = radius or 1

	local p1 = {
		x = pos.x - radius,
		y = pos.y - radius,
		z = pos.z - radius,
	}

	local p2 = {
		x = pos.x + radius,
		y = pos.y + radius,
		z = pos.z + radius,
	}

	local n = minetest.find_node_near(pos, radius, "mobs:spawner")
	if n then
		local t = minetest.get_node_timer(n)
		if not t:is_started() then
			print("Restarting timer.")
			t:start(1)
		end
	end

	local a = minetest.find_nodes_in_area_under_air(p1, p2, "group:reliable")
	if a and a[1] then
		print("Setting spawner.")
		local an = a[random(#a)]
		local np = {
			x = an.x,
			y = an.y + 1,
			z = an.z,
		}
		print("Setting spawner.")
		minetest.set_node(np, {name = "mobs:spawner"})
	end
end
local redo = mobs.redo

mobs.limiter = function(pos, radius, limit, immediate_surrounding, surrounding)
	radius = radius or 6.67
	limit = limit or radius * 3
	immediate_surrounding = immediate_surrounding or
			minetest.get_objects_inside_radius(pos, radius)

	if #immediate_surrounding > 6 then
		return
	end

	local surrounding = surrounding or
			minetest.get_objects_inside_radius(pos, radius * 3)

	if #surrounding > 18 then
		local h = 0
		for i = 1, #surrounding do
			local s = surrounding[i]
			local sl = s:get_luaentity()
			if sl and sl.health then
				h = h + 1
			end
			if s:is_player() then
				h = h + 4
			end
		end
		if h > limit then
			return
		end
	end
end

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

		undercrowd(pos, 8)

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
