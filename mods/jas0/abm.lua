-- Dedicated to hecks!

local random = math.random
local liquids = {
	"default:water_source",
	"default:river_water_source",
	"default:lava_source",
}
local liquid_drop = function(pos, node)
	local n = node.name
	local p = {
		x = pos.x,
		y = pos.y - 1,
		z = pos.z,
	}
	local py = minetest.get_node_or_nil(p)
	if py and py.name and
			(py.name == n:sub(1, -7) .. "flowing" or
			py.name == "air") then
		minetest.set_node(pos, {name = "air"})
		minetest.set_node(p, {name = n})
	end
end

for i = 1, #liquids do
	local liq = liquids[i]
	minetest.register_abm({
		label = liq .. " drop",
		nodenames = {liq},
		neighbors = {liq:sub(1, -7) .. "flowing"},
		interval = 3.6,
		chance = 1,
		catch_up = false,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local r1, r2 = random(), random()
			minetest.after(r1 + r2, liquid_drop, pos, node)
		end,
	})
end
