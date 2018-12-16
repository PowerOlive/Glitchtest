dresser.skins = {
	{"blass", "Blass"},
	{"urotsuki", "Urotsuki"},
	{"temerlime", "Temerlime"},
	{"me_only", "Me Only"},
	{"blockcolor", "Blockcolor"},
	{"cheapie", "Cheapie"},
	{"sam_ii_winter", "Winter Sam"},
}

minetest.register_alias("jas0:skin_character", "dresser:skin_blass")
minetest.register_alias("dresser:skin_dusty", "dresser:skin_blass")

for i = 1, #dresser.skins do
	local file = dresser.skins[i][1]
	local name = dresser.skins[i][2]
	minetest.register_alias("jas0:skin_" .. file,
			"dresser:skin_" .. file)
	minetest.register_craftitem("dresser:skin_" .. file, {
		description = name,
		inventory_image = "multiskin_" .. file .. "_inv.png",
		stack_max = 1,
		groups = {trade_value = 2,},
		on_use = function(itemstack, user, pointed_thing)
			multiskin.set_player_skin(user,
					"multiskin_" .. file .. ".png")
			multiskin.update_player_visuals(user)
			local inv = user:get_inventory()
			if not inv:is_empty("skin", 1) then
				local object = minetest.add_item(user:get_pos(), inv:get_stack("skin", 1))
				inv:set_list("skin", {})
			end
			inv:add_item("skin", itemstack)
			return ""
		end,
		_skin = "multiskin_" .. file .. ".png",
	})
end
