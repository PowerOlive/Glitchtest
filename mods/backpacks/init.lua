-- Backpacks mod for Glitchtest game
-- Copyright 2018 James Stevenson
-- GNU GPL version 3 and above


local backpacks = {}

backpacks.form = "size[8,7.5]" ..
	jas0.exit_button() ..
	"list[current_name;main;0,0.7;8,2]" ..
	"field[0.3,3;7,1;rename;;${infotext}]" ..
	"button_exit[7,2.67;1,1;ok;OK]" ..
	"list[current_player;main;0,3.65;8,1]" ..
	"list[current_player;main;0,4.75;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0, 3.65) ..
""

backpacks.on_construct = function(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", "Backpack")
	meta:set_string("formspec", backpacks.form)
	local inv = meta:get_inventory()
	inv:set_size("main", 8 * 2)
end

backpacks.after_place_node = function(pos, placer, itemstack, pointed_thing)
	local n_meta = minetest.get_meta(pos)
	local i_meta = itemstack:get_meta()
	local description = i_meta:get_string("description")
	local infotext = description
	if infotext == "" then
		infotext = itemstack:get_definition().description
	end
	n_meta:set_string("description", description)
	n_meta:set_string("infotext", infotext)
	local inv = n_meta:get_inventory()
	if i_meta:get_string("inventory") ~= "" then
		inv:set_list("main", minetest.deserialize(i_meta:get_string("inventory")))
	end
	itemstack:take_item()
end

backpacks.on_dig = function(pos, node, digger)
	if minetest.is_protected(pos, digger:get_player_name()) then
		return false
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local list = {}
	for i, stack in ipairs(inv:get_list("main")) do
		if stack:get_name() == "" then
			list[i] = ""
		else 
			list[i] = stack:to_string()
		end
	end
	local fields = {fields = {
		description = meta:get_string("description"),
		infotext = meta:get_string("description"),
		formspec = backpacks.form
	}}
	local new_list_as_string = minetest.serialize(list)
	local new = ItemStack(node)
	new:get_meta():from_table(fields)
	new:get_meta():set_string("inventory", new_list_as_string)
	minetest.remove_node(pos)
	local player_inv = digger:get_inventory()
	if player_inv:room_for_item("main", new) then
		player_inv:add_item("main", new)
	else
		minetest.add_item(pos, new)
	end
end

backpacks.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
	if not string.match(stack:get_name(), "backpacks:backpack_") then
		return stack:get_count()
	else
		return 0
	end
end

backpacks.preserve_metadata = function(pos, oldnode, oldmeta, drops)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local list = {}
	for i, stack in ipairs(inv:get_list("main")) do
		if stack:get_name() == "" then
			list[i] = ""
		else
			list[i] = stack:to_string()
		end
	end
	local fields = {fields = {
		description = meta:get_string("description"),
		infotext = meta:get_string("description"),
		formspec = backpacks.form,
	}}
	local new_list_as_string = minetest.serialize(list)
	local new = ItemStack(oldnode)
	new:get_meta():from_table(fields)
	new:get_meta():set_string("inventory", new_list_as_string)
	if drops and drops[1] then
		drops[1] = new
	end
end

backpacks.on_receive_fields = function(pos, formname, fields, sender)
	if formname ~= "" then
		return
	end
	if fields.rename or
			(fields.key_enter and
			fields.key_enter_field == "rename") then
		local new_name = minetest.formspec_escape(fields.rename)
		local meta = minetest.get_meta(pos)
		meta:set_string("description", new_name)
		meta:set_string("infotext", new_name)
	end
end

backpacks.on_blast = function() -- TODO throw_contents
end

local wield_index = {}
local function update_wielded(player, inv)
	local p_inv = player:get_inventory()
	local wielded = p_inv:get_stack("hand", 1)
	local list = inv:get_list("dmain")
	for i = 1, #list do
		list[i] = list[i]:to_string()
	end
	wielded:get_meta():set_string("inventory", minetest.serialize(list))
	p_inv:set_stack("hand", 1, wielded)
end

minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
	local name = player:get_player_name()
	if (inventory_info.to_index and inventory_info.to_index == wield_index[name]) or
			(inventory_info.from_index and inventory_info.from_index == wield_index[name]) or
			(inventory_info.index and inventory_info.index == wield_index[name]) then
		return 0
	--else
		--return inventory_info.count or inventory_info.stack:get_count()

	end
end)

--minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
--end)

backpacks.d_inv = {
	--[[
	allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
		return count
	end,
	--]]
	allow_put = function(inv, listname, index, stack, player)
		if stack:get_name():match("backpacks:backpack_") then
			return 0
		end
		return stack:get_count()
	end,
	--[[
	allow_take = function(inv, listname, index, stack, player)
		return stack:get_count()
	end,
	--]]
	on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
		update_wielded(player, inv)
	end, 
	on_put = function(inv, listname, index, stack, player)
		update_wielded(player, inv)
	end,
	on_take = function(inv, listname, index, stack, player)
		update_wielded(player, inv)
	end,
}
backpacks.on_use = function(itemstack, user, pointed_thing)
	if not user then
		return
	end
	local name = user:get_player_name()
	wield_index[name] = user:get_wield_index()
	local d_inv = minetest.get_inventory({type = "detached",
			name = "backpack_" .. name})
	if not d_inv then
		d_inv = minetest.create_detached_inventory("backpack_"
				.. name, backpacks.d_inv)
		d_inv:set_size("dmain", 8 * 2)
	end
	local meta = itemstack:get_meta()
	local list = minetest.deserialize(meta:get_string("inventory")) or {}
	d_inv:set_list("dmain", list)
	local formspec = "size[8,7.5]" ..
		jas0.exit_button() ..
		"list[detached:backpack_" .. name .. ";dmain;0,0.7;8,2]" ..
		"field[0.3,3;7,1;rename;;" .. (meta:get("description") or
				itemstack:get_definition().description) .. "]" ..
		"button_exit[7,2.67;1,1;ok;OK]" ..
		"list[current_player;main;0,3.65;8,1]" ..
		"list[current_player;main;0,4.75;8,3;8]" ..
		"listring[detached:backpack_" .. name .. ";dmain]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0, 3.65) ..
	""
	minetest.show_formspec(name, "backpacks:backpack", formspec)
	local h = user:get_inventory()
	h:set_size("hand", 1)
	h:set_stack("hand", 1, itemstack)
	local faux = ItemStack(itemstack:get_name())
	faux:get_meta():set_string("description", meta:get("description") or
			itemstack:get_definition().description)
	return faux
end

minetest.register_on_leaveplayer(function(player)
	if not player then
		return
	end
	minetest.remove_detached_inventory("backpack_" .. player:get_player_name())
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "backpacks:backpack" then
		return
	end
	if fields.rename or
			(fields.key_enter and
			fields.key_enter_field == "rename") then
		local new_name = minetest.formspec_escape(fields.rename)
		local wielded = player:get_inventory():get_stack("hand", 1)
		local meta = wielded:get_meta()
		meta:set_string("description", new_name)
		meta:set_string("infotext", new_name)
		player:get_inventory():set_stack("hand", 1, wielded)
	end
	if fields.quit then
		player:set_wielded_item(player:get_inventory():get_stack("hand", 1))
		if player:get_meta():get_string("class") == "mage" then
			player:get_inventory():set_stack("hand", 1, "jas0:mage")
		else
			player:get_inventory():set_list("hand", {})
		end
		wield_index[player:get_player_name()] = nil
	end
end)

minetest.register_alias("backpacks:backpack", "backpacks:backpack_wool_white")

-- Colored Wool Backpacks
for k, v in ipairs(dye.dyes) do
	minetest.register_node("backpacks:backpack_wool_" .. v[1], {
		description = v[2] .. " Wool Backpack",
		tiles = {
			"wool_" .. v[1] .. ".png^backpacks_backpack_topbottom.png", -- Top
			"wool_" .. v[1] .. ".png^backpacks_backpack_topbottom.png", -- Bottom
			"wool_" .. v[1] .. ".png^backpacks_backpack_sides.png", -- Right Side
			"wool_" .. v[1] .. ".png^backpacks_backpack_sides.png", -- Left Side
			"wool_" .. v[1] .. ".png^backpacks_backpack_back.png", -- Back
			"wool_" .. v[1] .. ".png^backpacks_backpack_front.png" -- Front
		},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.4375, -0.5, -0.375, 0.4375, 0.5, 0.375},
				{0.125, -0.375, 0.4375, 0.375, 0.3125, 0.5},
				{-0.375, -0.375, 0.4375, -0.125, 0.3125, 0.5},
				{0.125, 0.1875, 0.375, 0.375, 0.375, 0.4375},
				{-0.375, 0.1875, 0.375, -0.125, 0.375, 0.4375},
				{0.125, -0.375, 0.375, 0.375, -0.25, 0.4375},
				{-0.375, -0.375, 0.375, -0.125, -0.25, 0.4375},
				{-0.3125, -0.375, -0.4375, 0.3125, 0.1875, -0.375},
				{-0.25, -0.3125, -0.5, 0.25, 0.125, -0.4375},
			}
		},
		groups = {dig_immediate = 3, oddly_diggable_by_hand = 3, attached_node = 1},
		stack_max = 1,
		on_construct = backpacks.on_construct,
		after_place_node = backpacks.after_place_node,
		on_dig = backpacks.on_dig,
		allow_metadata_inventory_put = backpacks.allow_metadata_inventory_put,
		preserve_metadata = backpacks.preserve_metadata,
		on_receive_fields = backpacks.on_receive_fields,
		on_use = backpacks.on_use,
		on_bast = backpacks.on_blast,
	})
	minetest.register_craft({
		output = "backpacks:backpack_wool_" .. v[1],
		recipe = {
			{"wool:" .. v[1], "wool:" .. v[1], "wool:" .. v[1]},
			{"wool:" .. v[1], "", "wool:" .. v[1]},
			{"wool:" .. v[1], "wool:" .. v[1], "wool:" .. v[1]},
		}
	})
	minetest.register_craft({
		output = "wool:" .. v[1],
		type = "shapeless",
		recipe = {"backpacks:backpack_wool_" .. v[1]},
	})
end

-- Leather backpack
minetest.register_node("backpacks:backpack_leather", {
	description = "Leather Backpack",
	tiles = {
		"backpacks_leather.png^backpacks_backpack_topbottom.png", -- Top
		"backpacks_leather.png^backpacks_backpack_topbottom.png", -- Bottom
		"backpacks_leather.png^backpacks_backpack_sides.png",     -- Right Side
		"backpacks_leather.png^backpacks_backpack_sides.png",     -- Left Side
		"backpacks_leather.png^backpacks_backpack_back.png",      -- Back
		"backpacks_leather.png^backpacks_backpack_front.png"      -- Front
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.5, -0.375, 0.4375, 0.5, 0.375},
			{0.125, -0.375, 0.4375, 0.375, 0.3125, 0.5},
			{-0.375, -0.375, 0.4375, -0.125, 0.3125, 0.5},
			{0.125, 0.1875, 0.375, 0.375, 0.375, 0.4375},
			{-0.375, 0.1875, 0.375, -0.125, 0.375, 0.4375},
			{0.125, -0.375, 0.375, 0.375, -0.25, 0.4375},
			{-0.375, -0.375, 0.375, -0.125, -0.25, 0.4375},
			{-0.3125, -0.375, -0.4375, 0.3125, 0.1875, -0.375},
			{-0.25, -0.3125, -0.5, 0.25, 0.125, -0.4375},
		}
	},
	groups = {dig_immediate = 3, oddly_diggable_by_hand = 3, attached_node = 1},
	stack_max = 1,
	on_construct = backpacks.on_construct,
	after_place_node = backpacks.after_place_node,
	on_dig = backpacks.on_dig,
	allow_metadata_inventory_put = backpacks.allow_metadata_inventory_put,
	preserve_metadata = backpacks.preserve_metadata,
	on_receive_fields = backpacks.on_receive_fields,
	on_use = backpacks.on_use,
	on_bast = backpacks.on_blast,
})

minetest.register_craft({
	output = "backpacks:backpack_leather",
	recipe = {
		{"mobs:leather", "mobs:leather", "mobs:leather"},
		{"mobs:leather", "", "mobs:leather"},
		{"mobs:leather", "mobs:leather", "mobs:leather"},
	}
})
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if not player then
		return
	end
	local pos = player:get_pos()
	for i = 1, player:get_inventory():get_size("craft") do
		if old_craft_grid[i]:get_name():match("backpacks:backpack_") then
			local contents = minetest.deserialize(old_craft_grid[i]:get_meta():get("inventory"))
			if not contents then
				return
			end
			for i = 1, 16 do
				local it = contents[i]
				if it ~= "" then
					local o = minetest.add_item(pos, it)
					if o then
						-- from tnt
						o:set_acceleration({
							x = 0,
							y = -10,
							z = 0,
						})
						o:set_velocity({
							x = math.random(-3, 3),
							y = math.random(0, 10),
							z = math.random(-3, 3),
						})
					end
				end
			end
			return
		end
	end
end)
