local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/api.lua")
dofile(modpath.."/loom.lua")
local function is_clothing(item)
	return minetest.get_item_group(item, "clothing") > 0 or
		minetest.get_item_group(item, "cape") > 0
end

local function save_clothing_metadata(player, clothing_inv)
	local player_inv = player:get_inventory()
	local is_empty = true
	local clothes = {}
	for i = 1, 6 do
		local stack = clothing_inv:get_stack("clothing", i)
		-- Move all non-clothes back to the player inventory
		if not stack:is_empty() and not is_clothing(stack:get_name()) then
			player_inv:add_item("main",
				clothing_inv:remove_item("clothing", stack))
			stack:clear()
		end
		if not stack:is_empty() then
			clothes[i] = stack:to_string()
			is_empty = false
		end
	end
	if is_empty then
		player:get_meta():set_string("clothing:inventory", nil)
	else
		player:get_meta():set_string("clothing:inventory",
			minetest.serialize(clothes))
	end
end
local function load_clothing_metadata(player, clothing_inv)
	local player_inv = player:get_inventory()
	local clothing_meta = player:get_meta():get_string("clothing:inventory")
	local clothes = clothing_meta and minetest.deserialize(clothing_meta) or {}
	local dirty_meta = false
	if not clothing_meta then
		-- Backwards compatiblity
		for i = 1, 6 do
			local stack = player_inv:get_stack("clothing", i)
			if not stack:is_empty() then
				clothes[i] = stack:to_string()
				dirty_meta = true
			end
		end
	end
	-- Fill detached slots
	clothing_inv:set_size("clothing", 6)
	for i = 1, 6 do
		clothing_inv:set_stack("clothing", i, clothes[i] or "")
	end

	if dirty_meta then
		-- Requires detached inventory to be set up
		save_clothing_metadata(player, clothing_inv)
	end

	-- Clean up deprecated garbage after saving
	player_inv:set_size("clothing", 0)
end

local colors = {
	white = "FFFFFF",
	grey = "C0C0C0",
	black = "121212",
	red = "DD0000",
	yellow = "FFEE00",
	green = "32CD32",
	cyan = "00959D",
	blue = "003376",
	magenta = "D80481",
	orange = "E0601A",
	violet = "480080",
	brown = "391A00",
	pink = "FFA5A5",
	dark_grey = "696969",
	dark_green = "154F00",
}
local function clothing_on_use(itemstack, user, pointed_thing)
	local name = user:get_player_name()
	local inv = minetest.get_inventory({type = "detached",
			name = name .. "_clothing"})
	local list = inv:get_list("clothing")
	local index = 0
	for i = 1, #list do
		if list[i]:get_name() == "" then
			inv:set_stack("clothing", i, itemstack)
			index = i
			break
		end
	end
	if index == 0 then
		return itemstack
	end
	save_clothing_metadata(user, inv)
	clothing:run_callbacks("on_equip", user, index, itemstack)
	clothing:set_player_clothing(user)
	return ""
end
for color, hex in pairs(colors) do
	local desc = color:gsub("%a", string.upper, 1)
	desc = desc:gsub("_", " ")
	minetest.register_craftitem("clothing:hat_" .. color, {
		description = desc.." Cotton Hat",
		inventory_image = "clothing_inv_hat.png^[multiply:#" .. hex,
		uv_image = "(clothing_uv_hat.png^[multiply:#" .. hex .. ")",
		groups = {clothing = 1},
		on_use = clothing_on_use,
	})
	minetest.register_craftitem("clothing:shirt_"..color, {
		description = desc.." Cotton Shirt",
		inventory_image = "clothing_inv_shirt.png^[multiply:#"..hex,
		uv_image = "(clothing_uv_shirt.png^[multiply:#"..hex..")",
		groups = {clothing=1},
		on_use = clothing_on_use,
	})
	minetest.register_craftitem("clothing:pants_"..color, {
		description = desc.." Cotton Pants",
		inventory_image = "clothing_inv_pants.png^[multiply:#"..hex,
		uv_image = "(clothing_uv_pants.png^[multiply:#"..hex..")",
		groups = {clothing=1},
		on_use = clothing_on_use,
	})
	minetest.register_craftitem("clothing:cape_"..color, {
		description = desc.." Cotton Cape",
		inventory_image = "clothing_inv_cape.png^[multiply:#"..hex,
		uv_image = "(clothing_uv_cape.png^[multiply:#"..hex..")",
		groups = {cape=1},
		on_use = clothing_on_use,
	})
end
-- Inventory mod support
--[[
if minetest.get_modpath("inventory_plus") then
	clothing.inv_mod = "inventory_plus"
	clothing.formspec = clothing.formspec..
		"button[6,0;2,0.5;main;Back]"
elseif minetest.get_modpath("unified_inventory") and
		not unified_inventory.sfinv_compat_layer then
	clothing.inv_mod = "unified_inventory"
	unified_inventory.register_button("clothing", {
		type = "image",
		image = "inventory_plus_clothing.png",
	})
	unified_inventory.register_page("clothing", {
		get_formspec = function(player, perplayer_formspec)
			local fy = perplayer_formspec.formspec_y
			local name = player:get_player_name()
			local formspec = "background[0.06,"..fy..
				";7.92,7.52;clothing_ui_form.png]"..
				"label[0,0;Clothing]"..
				"list[detached:"..name.."_clothing;clothing;0,"..fy..";2,3;]"..
				"listring[current_player;main]"..
				"listring[detached:"..name.."_clothing;clothing]"
			return {formspec=formspec}
		end,
	})
elseif minetest.get_modpath("sfinv") then
	clothing.inv_mod = "sfinv"
	sfinv.register_page("clothing:clothing", {
		title = "Clothing",
		get = function(self, player, context)
			local name = player:get_player_name()
			local formspec = clothing.formspec..
				"list[detached:"..name.."_clothing;clothing;0,0.5;2,3;]"..
				"listring[current_player;main]"..
				"listring[detached:"..name.."_clothing;clothing]"
			return sfinv.make_formspec(player, context,
				formspec, false)
		end
	})
end
--]]
--[[
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if clothing.inv_mod == "inventory_plus" and fields.clothing then
		inventory_plus.set_inventory_formspec(player, clothing.formspec..
			"list[detached:"..name.."_clothing;clothing;0,0.5;2,3;]"..
			"listring[current_player;main]"..
			"listring[detached:"..name.."_clothing;clothing]")
	end
end)
--]]
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	--local player_inv = player:get_inventory()
	local clothing_inv = minetest.create_detached_inventory(name .. "_clothing", {
		on_put = function(inv, listname, index, stack, player)
			save_clothing_metadata(player, inv)
			clothing:run_callbacks("on_equip", player, index, stack)
			clothing:set_player_clothing(player)
		end,
		on_take = function(inv, listname, index, stack, player)
			save_clothing_metadata(player, inv)
			clothing:run_callbacks("on_unequip", player, index, stack)
			clothing:set_player_clothing(player)
		end,
		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			save_clothing_metadata(player, inv)
			clothing:set_player_clothing(player)
		end,
		allow_put = function(inv, listname, index, stack, player)
			local item = stack:get_name()
			if is_clothing(item) then
				return 1
			end
			return 0
		end,
		allow_take = function(inv, listname, index, stack, player)
			return stack:get_count()
		end,
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			return count
		end,
	}, name)
	if clothing.inv_mod == "inventory_plus" then
		inventory_plus.register_button(player,"clothing", "Clothing")
	end

	load_clothing_metadata(player, clothing_inv)
	minetest.after(3, function(name) -- TODO FIXME Doesn't apply if executes too soon.
		-- Ensure the ObjectRef is valid after 1s
		clothing:set_player_clothing(minetest.get_player_by_name(name))
	end, name)
end)
