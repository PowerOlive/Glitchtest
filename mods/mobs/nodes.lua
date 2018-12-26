-- mobs/nodes.lua is part of Glitchtest
-- Copyright 2018 James Stevenson
-- GNU GPL 3

minetest.register_node("mobs:spawner", {
	description = "I spawn things!",
	drawtype = "airlike",
	groups = {not_in_creative_inventory = 1},
	drop = "",
	air_equivalent = true,
	paramtype = "light",
	inventory_image = "air.png",
	floodable = true,
	pointable = false,
	sunlight_propagates = true,
	walkable = false,
	diggable = false,
	buildable_to = true,
	wield_image = "air.png",
	on_blast = function()
	end,
	--[[
	on_destruct = function(pos)
	end,
	--]]
	on_timer = function(pos, elapsed)
		if elapsed > 48 then
			local immediate_surrounding = minetest.get_objects_inside_radius(pos, 3.12)
			if #immediate_surrounding > 0 then
				return minetest.set_node(pos, {name = "air"})
			end
			local surrounding = minetest.get_objects_inside_radius(pos, 16)
			if #surrounding > 6 then
				local h = 0
				for i = 1, #surrounding do
					local s = surrounding[i]
					local sl = s:get_luaentity()
					if sl and sl.health then
						h = h + 1
					end
					if s:is_player() then
						h = h + 2
					end
				end
				if h > 3 then
					return minetest.set_node(pos, {name = "air"})
				end
			end
			local mob_pos = pos
			if minetest.registered_nodes[minetest.get_node_or_nil(pos).name].walkable then
				mob_pos.y = mob_pos.y + 1
			end
			local mobs = {
				"mobs:rat",
				"mobs:npc",
			}
			local biome = minetest.get_biome_name(minetest.get_biome_data(pos).biome)
			local tod = (minetest.get_timeofday() or 0) * 24000
			local night = tod > 19000 or tod < 06000
			local protection = minetest.find_node_near(mob_pos, 13,
					{"protector:protect", "protector:protect2"}, true)
			if not protection and (biome == "underground" or night) then
				local mobs_to_insert = {
					"mobs:dungeon_master",
					"mobs:oerkki",
					"mobs:zombie" .. math.random(4),
				}
				for i = 1, #mobs_to_insert do
					mobs[#mobs + 1] = mobs_to_insert[i]
				end
			end
			if biome ~= "underground" then
				local mobs_to_insert = {
					"mobs:sheep_white",
					"mobs:kitten",
					"mobs:bunny",
				}
				for i = 1, #mobs_to_insert do
					mobs[#mobs + 1] = mobs_to_insert[i]
				end
			end
			local mob = mobs[math.random(#mobs)]
			minetest.add_entity(mob_pos, mob)
			return minetest.set_node(pos, {name = "air"})
		else
			minetest.get_node_timer(pos):set(elapsed + 1, elapsed)
		end
	end,
})
minetest.register_abm({
	label = "Spawner Limiter",
	nodenames = {"mobs:spawner"},
	--neighbors = {},
	interval = 1,
	chance = 1,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local i = active_object_count
		local s = active_object_count_wider
		local t = minetest.get_node_timer(pos)
		if not t or not t:is_started() or
				s > 2 or i > 1 then
			local things = minetest.get_objects_inside_radius(pos, 16)
			local ttl = 0
			for k, v in pairs(things) do
				local h = v:get_luaentity()
				if h and h.health and h.health > 0 then
					ttl = ttl + 1
				end
				local p = v:is_player()
				if p then
					ttl = ttl + 2
				end
			end
			if ttl > 4 then
				minetest.set_node(pos, {name = "air"})
			end
		end
	end,
})
--minetest.register_lbm()
--minetest.register_on_mapgen()
