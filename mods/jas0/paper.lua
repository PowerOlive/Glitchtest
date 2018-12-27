-- jas0/paper.lua is part of Glitchtest
-- Copyright 2018 James Stevenson
-- GNU GPL 3

local paper_on_place = function(itemstack, player, pointed_thing)
	if pointed_thing.type == "node" then
		local node = minetest.get_node(pointed_thing.under)
		local pdef = minetest.registered_nodes[node.name]
		if pdef and pdef.on_rightclick then
			return pdef.on_rightclick(pointed_thing.under,
					node, player, itemstack, pointed_thing)
		end
	end
	local count = itemstack:get_count()
	local desc = itemstack:get_meta():get_string("description")
	local text = ""
	if desc ~= "Paper" then
		text = desc
	end
	minetest.show_formspec(player:get_player_name(), "default:paper",
			"field[text;;" .. text .. "]")
end

minetest.override_item("default:paper", {
	on_use = minetest.item_eat(1),
	on_place = function(itemstack, placer, pointed_thing)
		paper_on_place(itemstack, placer, pointed_thing)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		paper_on_place(itemstack, user, pointed_thing)
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not player then
		return
	end
	if formname ~= "default:paper" then
		return
	end
	if fields.text then
		local count = player:get_wielded_item():get_count()
		local is = ItemStack({name = "default:paper"})
		is:get_meta():set_string("description", fields.text)
		player:set_wielded_item(is)
		if count > 1 then
			local iii = player:get_inventory():add_item("main",
					"default:paper " .. tostring(count - 1))
			if iii then
				minetest.add_item(player:get_pos(), iii)
			end
		end
	end
end)

local paper_display = {}
local function paper_displayer(player)
	if not player then
		return
	end
	local name = player:get_player_name()
	local wielded = player:get_wielded_item()
	local text = wielded:get_meta():get_string("description")
	if wielded:get_name() ~= "default:paper" or
			text == "" or
			text == "Paper" then
		if paper_display[name] then
			player:hud_remove(paper_display[name])
			paper_display[name] = nil
		end
		return minetest.after(0.15, paper_displayer, player)
	end
	local hd = {
		hud_elem_type = "text",
		position = {x = 0.0334, y = 0.667},
		alignment = {x = 1, y = 1},
		direction = 1,
		text = text,
		number = 0xFFFFFF,
	}
	if not paper_display[name] then
		paper_display[name] = player:hud_add(hd)
		return minetest.after(0.15, paper_displayer, player)
	end
	player:hud_change(paper_display[name],
			"text", text)
	minetest.after(0.25, paper_displayer, player)
end
minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end
	minetest.after(0.25, paper_displayer, player)
end)
