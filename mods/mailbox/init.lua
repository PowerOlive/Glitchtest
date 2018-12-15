-- Mailbox mod for Glitchtest
-- Copyright 2018 James Stevenson
-- GNU GPL 3


minetest.register_craft({
	output = "mailbox:mailbox",
	recipe = {
		{"default:clay_brick", "default:steel_ingot", "default:clay_brick"},
		{"default:steel_ingot", "default:paper", "default:steel_ingot"},
		{"default:clay_brick", "default:steel_ingot", "default:clay_brick"},
	},
})

minetest.register_node("mailbox:mailbox", {
	description = "Mailbox",
	tiles = {
		"mailbox_top.png",
		"mailbox_botton.png",
		"mailbox_side.png",
		"mailbox_side.png",
		"mailbox_logo.png",
		"mailbox_logo.png",
	},
	paramtype2 = "facedir",
	groups = {cracky = 3},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		if not meta then
			return
		end
		local name = placer:get_player_name()
		meta:set_string("owner", name)
		meta:set_string("infotext", name .. "'s Mailbox")
		local inv = meta:get_inventory()
		if not inv then
			return
		end
		inv:set_size("mailbox", 8 * 4)
		inv:set_size("send", 1)
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		if not player then
			return
		end
		local meta = minetest.get_meta(pos)
		if not meta then
			return
		end
		local name = player:get_player_name()
		if name == meta:get_string("owner") then
			return
		end

		local inv = meta:get_inventory()
		local overflow = inv:add_item("mailbox", stack)
		inv:set_list("send", {})
		if overflow:get_name() == "" then
		elseif overflow then
			pos.y = pos.y + 1
			minetest.add_item(pos, overflow)
			minetest.chat_send_player(name, "Mailbox is full!")
		end
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if not clicker then
			return
		end
		local meta = minetest.get_meta(pos)
		if not meta then
			return
		end
		local inv = meta:get_inventory()
		pos = minetest.pos_to_string(pos):sub(2, -2)
		local name = clicker:get_player_name()
		local owner = meta:get_string("owner")
		if owner ~= name then
			minetest.show_formspec(name, "mailbox:send",
				"size[8,5.667;]" ..
				jas0.exit_button() ..
				"label[0,0;Send " .. owner .. " some mail!]" ..
				"list[nodemeta:" .. pos .. ";send;3.5,0.667;1,1]" ..
				"list[current_player;main;0,1.9;8,1]" ..
				"list[current_player;main;0,3;8,3;8]" ..
				"listring[nodemeta:" .. pos .. ";send]" ..
				"listring[current_player;main]" ..
				default.get_hotbar_bg(0, 1.9) ..
			"")
			return
		end
		minetest.show_formspec(name, "mailbox:mailbox",
			"size[8,8.334]" ..
			"list[nodemeta:" .. pos .. ";mailbox;0,0;8,4;]" ..
			"list[current_player;main;0,4.5;8,1;]" ..
			"list[current_player;main;0,5.6;8,3;8]" ..
			"listring[nodemeta:" .. pos .. ";mailbox]" ..
			"listring[current_player;main]" ..
			default.get_hotbar_bg(0, 4.5) ..
		"")
	end,
	0
})
