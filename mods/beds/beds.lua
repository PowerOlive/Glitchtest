-- Fancy shaped bed
--[[
beds.register_bed("beds:fancy_bed", {
	description = "Fancy Bed",
	inventory_image = "beds_bed_fancy.png",
	wield_image = "beds_bed_fancy.png",
	tiles = {
		bottom = {
			"beds_bed_top1.png",
			"beds_bed_under.png",
			"beds_bed_side1.png",
			"beds_bed_side1.png^[transformFX",
			"beds_bed_foot.png",
			"beds_bed_foot.png",
		},
		top = {
			"beds_bed_top2.png",
			"beds_bed_under.png",
			"beds_bed_side2.png",
			"beds_bed_side2.png^[transformFX",
			"beds_bed_head.png",
			"beds_bed_head.png",
		}
	},
	nodebox = {
		bottom = {
			{-0.5, -0.5, -0.5, -0.375, -0.065, -0.4375},
			{0.375, -0.5, -0.5, 0.5, -0.065, -0.4375},
			{-0.5, -0.375, -0.5, 0.5, -0.125, -0.4375},
			{-0.5, -0.375, -0.5, -0.4375, -0.125, 0.5},
			{0.4375, -0.375, -0.5, 0.5, -0.125, 0.5},
			{-0.4375, -0.3125, -0.4375, 0.4375, -0.0625, 0.5},
		},
		top = {
			{-0.5, -0.5, 0.4375, -0.375, 0.1875, 0.5},
			{0.375, -0.5, 0.4375, 0.5, 0.1875, 0.5},
			{-0.5, 0, 0.4375, 0.5, 0.125, 0.5},
			{-0.5, -0.375, 0.4375, 0.5, -0.125, 0.5},
			{-0.5, -0.375, -0.5, -0.4375, -0.125, 0.5},
			{0.4375, -0.375, -0.5, 0.5, -0.125, 0.5},
			{-0.4375, -0.3125, -0.5, 0.4375, -0.0625, 0.4375},
		}
	},
	selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.06, 1.5},
	recipe = {
		{"", "", "group:stick"},
		{"wool:red", "wool:red", "wool:white"},
		{"group:wood", "group:wood", "group:wood"},
	},
})
--]]
minetest.register_alias("beds:bed", "beds:bed_red")
for k, v in ipairs(dye.dyes) do
	beds.register_bed("beds:bed_" .. v[1], {
		description = v[2] .. " Bed",
		inventory_image = "beds_bed.png^(wool_" .. v[1] .. ".png^[mask:beds_blanket.png)",
		wield_image = "beds_bed.png^(wool_" .. v[1] .. ".png^[mask:beds_blanket.png)",
		tiles = {
			bottom = {
				"wool_" .. v[1] .. ".png^[transformR90",
				"default_wood.png",
				"[combine:16x16:0,0=wool_" .. v[1] ..
						[[.png:0,11=default_wood.png\^[transformR180]],
				"([combine:16x16:0,0=wool_" .. v[1] ..
						[[.png:0,11=default_wood.png\^[transformR180)^[transformFX]],
				"[combine:16x16",
				"[combine:16x16:0,7=wool_" .. v[1] ..
						[[.png:0,11=default_wood.png\^[transformR180]],
			},
			top = {
				"(wool_" .. v[1] ..
						[[.png^[combine:16x16:8,0=beds_bed_top_top.png\^[transformR180)^[transformR90]],
				"default_wood.png",
				"(beds_bed_side_top_r.png^[combine:8x4:-8,0=wool_" ..
						v[1] .. [[.png)^[lowpart:27:default_wood.png\^[transformFX]],
				"((beds_bed_side_top_r.png^[combine:8x4:-8,0=wool_" ..
						v[1] .. [[.png)^[lowpart:27:default_wood.png\^[transformFX)^[transformFX]],
				"beds_bed_side_top.png^[lowpart:27:default_wood.png",
				"[combine:16x16",
			}
		},
		nodebox = {
			bottom = {-0.5, -0.5, -0.5, 0.5, 0.06, 0.5},
			top = {-0.5, -0.5, -0.5, 0.5, 0.06, 0.5},
		},
		selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.06, 1.5},
		recipe = {
			{"wool:" .. v[1], "wool:" .. v[1], "wool:white"},
			{"group:wood", "group:wood", "group:wood"}
		},
	})
end
-- Aliases for PilzAdam's beds mod

minetest.register_alias("beds:bed_bottom", "beds:bed_red_bottom")
minetest.register_alias("beds:bed_top", "beds:bed_red_top")

-- Fuel
--[[
minetest.register_craft({
	type = "fuel",
	recipe = "beds:fancy_bed_bottom",
	burntime = 13,
})
--]]
minetest.register_craft({
	type = "fuel",
	recipe = "beds:bed_bottom",
	burntime = 12,
})
