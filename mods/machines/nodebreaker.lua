minetest.register_node("machines:nodebreaker", {
	description = "Nodebreaker Machine",
	tiles = {"default_tin_block.png"},
	groups = {cracky = 2,},
	paramtype = "light",
	--[[
	on_timer = function(pos, elapsed)
		if elapsed >= 1 then
			local l_pos = {
				x = pos.x,
				y = pos.y - 1,
				z = pos.z
			}
			local drop = minetest.get_node_or_nil(l_pos)
			if drop and drop.name then
				drop = minetest.registered_nodes[drop.name]
				if drop and drop.drop then
					drop = drop.drop
				end
			end
			minetest.add_item(pos, drop)
			minetest.set_node(pos, {name = "air"})
			minetest.set_node(l_pos, {name = "machines:nodebreaker"})
			minetest.after(1, function(p)
				local n = minetest.get_node_or_nil(p)
				if not n or not n.name or n.name ~= "machines:nodebreaker" then
					return
				end
				p = {
					x = p.x,
					y = p.y + 1,
					z = p.z
				}
				minetest.set_node(p, {name = "air"})
				minetest.set_node(pos, {name = "machines:nodebreaker"})
			end, pos)
			elapsed = 0
		else
			elapsed = elapsed + 0.1
		end
	end,
	--]]
})
minetest.register_abm({
	nodenames = {"machines:nodebreaker"},
	interval = 2,
	chance = 1,
	action = function(pos)
		local t = minetest.get_node_timer(pos)
		if t and not t:is_started() then
			t:start(1)
		end
	end,
})
