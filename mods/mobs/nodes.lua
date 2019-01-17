-- mobs/nodes.lua is part of Glitchtest
-- Copyright 2018 James Stevenson
-- GNU GPL 3

local random = math.random
local redo = mobs.redo
local limiter = mobs.limiter

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
	on_timer = function(pos, elapsed)
		if elapsed >= 30 then
			local node = minetest.get_node_or_nil({
				x = pos.x,
				y = pos.y - 1,
				z = pos.z,
			})
			if node and node.name then
				local node_below = minetest.registered_nodes[node.name]
				if node_below and not node_below.walkable then
					return redo(pos)
				end
			end
			local light = minetest.get_node_light(pos)
			limiter(pos)
			local mobs = {
				"mobs:rat",
				"mobs:npc",
			}
			local biome = minetest.get_biome_name(minetest.get_biome_data(pos).biome)
			local tod = (minetest.get_timeofday() or 0) * 24000
			local night = tod > 19000 or tod < 06000
			local protection = minetest.find_node_near(pos, 13,
					{"protector:protect", "protector:protect2"}, true)
			if not protection and (biome == "underground" or night) and
						light < 3 then
				local mobs_to_insert = {
					"mobs:dungeon_master",
					"mobs:oerkki",
					"mobs:zombie" .. random(4),
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
			local mob = mobs[random(#mobs)]
			local colbox = minetest.registered_entities[mob].collisionbox
			local spawn_pos = {
				x = pos.x,
				y = pos.y + 1.6,
				z = pos.z,
			}
			local p1 = {
				x = spawn_pos.x + colbox[1],
				y = spawn_pos.y + colbox[2],
				z = spawn_pos.z + colbox[3],
			}
			local p2 = {
				x = spawn_pos.x + colbox[4],
				y = spawn_pos.y + colbox[5],
				z = spawn_pos.z + colbox[6],
			}
			-- Check mob's collisionbox for adequate space to spawn.
			local d = vector.distance(p1, p2)
			local r, s = minetest.find_nodes_in_area(p1, p2, "air", true)
			if s["air"] < d then
				return redo(pos)
			end
			minetest.add_entity(spawn_pos, mob)
			redo(pos)
		else
			minetest.get_node_timer(pos):set(elapsed + 1, elapsed)
		end
	end,
})

minetest.register_abm({
	label = "Spawner Limiter",
	nodenames = {"mobs:spawner"},
	--neighbors = {},
	interval = 5,
	chance = 1,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		--print(active_object_count, active_object_count_wider)
		limiter(pos)
	end,
})

--minetest.register_lbm()
--minetest.register_on_mapgen()
