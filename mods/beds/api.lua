
local reverse = true

local function destruct_bed(pos, n)
	local node = minetest.get_node(pos)
	local other

	if n == 2 then
		local dir = minetest.facedir_to_dir(node.param2)
		other = vector.subtract(pos, dir)
	elseif n == 1 then
		local dir = minetest.facedir_to_dir(node.param2)
		other = vector.add(pos, dir)
	end

	if reverse then
		reverse = not reverse
		minetest.remove_node(other)
		minetest.check_for_falling(other)
	else
		reverse = not reverse
	end
end

function beds.register_bed(name, def)
	minetest.register_node(name .. "_bottom", {
		description = def.description,
		inventory_image = def.inventory_image,
		wield_image = def.wield_image,
		drawtype = "nodebox",
		tiles = def.tiles.bottom,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		stack_max = 1,
		groups = {
			choppy = 2,
			oddly_breakable_by_hand = 2,
			flammable = 3,
			bed = 1,
			fall_damage_add_percent = -80,
			bouncy = 101
		},
		sounds = {footstep = {name = "xdecor_bouncy", gain = 0.8}},
		node_box = {
			type = "fixed",
			fixed = def.nodebox.bottom,
		},
		selection_box = {
			type = "fixed",
			fixed = def.selectionbox,
		},
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", "Bed")
			meta:set_string("owner", "")
			meta:set_int("public", -1)
		end,
		on_place = function(itemstack, placer, pointed_thing)
			local under = pointed_thing.under
			local node = minetest.get_node(under)
			local udef = minetest.registered_nodes[node.name]
			if udef and udef.on_rightclick and
					not (placer and placer:is_player() and
					placer:get_player_control().sneak) then
				return udef.on_rightclick(under, node, placer, itemstack,
					pointed_thing) or itemstack
			end

			local pos
			if udef and udef.buildable_to then
				pos = under
			else
				pos = pointed_thing.above
			end

			local player_name = placer and placer:get_player_name() or ""

			if minetest.is_protected(pos, player_name) and
					not minetest.check_player_privs(player_name, "protection_bypass") then
				minetest.record_protection_violation(pos, player_name)
				return itemstack
			end

			local node_def = minetest.registered_nodes[minetest.get_node(pos).name]
			if not node_def or not node_def.buildable_to then
				return itemstack
			end

			local dir = placer and placer:get_look_dir() and
				minetest.dir_to_facedir(placer:get_look_dir()) or 0
			local botpos = vector.add(pos, minetest.facedir_to_dir(dir))

			if minetest.is_protected(botpos, player_name) and
					not minetest.check_player_privs(player_name, "protection_bypass") then
				minetest.record_protection_violation(botpos, player_name)
				return itemstack
			end

			local botdef = minetest.registered_nodes[minetest.get_node(botpos).name]
			if not botdef or not botdef.buildable_to then
				return itemstack
			end

			minetest.set_node(pos, {name = name .. "_bottom", param2 = dir})
			minetest.set_node(botpos, {name = name .. "_top", param2 = dir})
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", player_name)
			meta:set_string("infotext", player_name .. "'s Bed")
			if not (creative and creative.is_enabled_for
					and creative.is_enabled_for(player_name)) then
				itemstack:take_item()
			end
			return itemstack
		end,
		on_destruct = function(pos)
			destruct_bed(pos, 1)
		end,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not clicker then
				return
			end
			local meta = minetest.get_meta(pos)
			local public = meta:get_int("public")
			local name = clicker:get_player_name()
			if public == -1 and minetest.is_protected(pos, name) then
				return
			end
			beds.selected[name] = pos
			local home_name = minetest.get_meta(pos):get_string("home_name")
			if home_name == "" then
				home_name = "Set home name!"
			end
			local fs = "size[8,8.5;]" ..
				jas0.exit_button() ..
				"button_exit[0,-0.167;2,1;sethome;Set Home]" ..
				"button_exit[2,-0.167;2,1;setspawn;Set Spawn]" ..
				"button_exit[4,-0.167;2,1;sleep;Sleep]" ..
				"checkbox[6,-0.13;public;Public;" ..
						tostring(public == 1) .."]" ..
				"button_exit[7,3.767;1,1;list;List]" ..
				"button_exit[6,3.767;1,1;ok;OK]" ..
				"field[0.29,4.14;6,0.89;home_name;;" ..
						home_name .. "]" ..
				"list[current_player;bed;0,0.8;8,4;]" ..
				"list[current_player;main;0,4.75;8,4;]" ..
				"listring[]" ..
			""
			minetest.after(0, minetest.show_formspec,
					name, "beds:inventory", fs)
			return itemstack
		end,
		on_rotate = function(pos, node, user, mode, new_param2)
			local dir = minetest.facedir_to_dir(node.param2)
			local p = vector.add(pos, dir)
			local node2 = minetest.get_node_or_nil(p)
			if not node2 or not minetest.get_item_group(node2.name, "bed") == 2 or
					not node.param2 == node2.param2 then
				return false
			end
			if minetest.is_protected(p, user:get_player_name()) then
				minetest.record_protection_violation(p, user:get_player_name())
				return false
			end
			if mode ~= screwdriver.ROTATE_FACE then
				return false
			end
			local newp = vector.add(pos, minetest.facedir_to_dir(new_param2))
			local node3 = minetest.get_node_or_nil(newp)
			local node_def = node3 and minetest.registered_nodes[node3.name]
			if not node_def or not node_def.buildable_to then
				return false
			end
			if minetest.is_protected(newp, user:get_player_name()) then
				minetest.record_protection_violation(newp, user:get_player_name())
				return false
			end
			node.param2 = new_param2
			-- do not remove_node here - it will trigger destroy_bed()
			minetest.set_node(p, {name = "air"})
			minetest.set_node(pos, node)
			minetest.set_node(newp, {name = name .. "_top", param2 = new_param2})
			return true
		end,
		can_dig = function(pos, player)
			return beds.can_dig(pos)
		end,
	})

	minetest.register_node(name .. "_top", {
		drawtype = "nodebox",
		tiles = def.tiles.top,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		pointable = false,
		groups = {
			choppy = 2,
			oddly_breakable_by_hand = 2,
			flammable = 3,
			bed = 2,
			fall_damage_add_percent = -80,
			bouncy = 101
		},
		sounds = {footstep = {name = "xdecor_bouncy", gain = 0.8}},
		drop = name .. "_bottom",
		node_box = {
			type = "fixed",
			fixed = def.nodebox.top,
		},
		on_destruct = function(pos)
			destruct_bed(pos, 2)
		end,
		can_dig = function(pos, player)
			local node = minetest.get_node(pos)
			local dir = minetest.facedir_to_dir(node.param2)
			local p = vector.add(pos, dir)
			return beds.can_dig(p)
		end,
	})

	minetest.register_alias(name, name .. "_bottom")

	minetest.register_craft({
		output = name,
		recipe = def.recipe
	})
end
