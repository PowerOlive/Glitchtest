machines = {}

local function get_sat_time(stack)
	if stack then
		stack = stack[1]
		local c = stack:get_count()
		if c > 1 then
			stack:set_count(stack:get_count() - 1)
		else
			stack = ""
		end
	else
		stack = ""
	end
	return {
		time = 11,
		item = ItemStack("default:mossycobble"),
	},
	{
		items = {stack},
	}
end
local function get_soak_time()
	return {
		time = 99,
	},
	{
		items = {ItemStack("bucket:bucket_empty")},
	}
end

--
-- Formspecs
--

function machines.get_furnace_active_formspec(fuel_percent, item_percent)
	return "size[8,8.5]"..
		--default.gui_bg..
		--default.gui_bg_img..
		--default.gui_slots..
		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;fuel;2.75,2.5;1,1;]"..
		"image[2.75,1.5;1,1;machines_warrow_bg.png^[lowpart:"..
		(100-fuel_percent)..":machines_warrow_fg.png]"..
		"image[3.75,1.5;1,1;machines_arrow_bg.png^[lowpart:"..
		(item_percent)..":machines_arrow_fg.png^[transformR270]"..
		"list[context;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

function machines.get_furnace_inactive_formspec()
	return "size[8,8.5]"..
		--default.gui_bg..
		--default.gui_bg_img..
		--default.gui_slots..
		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;fuel;2.75,2.5;1,1;]"..
		"image[2.75,1.5;1,1;machines_warrow_bg.png]"..
		"image[3.75,1.5;1,1;machines_arrow_bg.png^[transformR270]"..
		"list[context;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

--
-- Node callback functions that are the same for active and inactive furnace
--

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src")
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "fuel" then
		--if minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
		if stack:get_name() == "bucket:bucket_water" or
				stack:get_name() == "bucket:bucket_empty" then
			if inv:is_empty("src") then
				meta:set_string("infotext", "Generator is empty")
			end
			return stack:get_count()
		else
			return 0
		end
	elseif listname == "src" then
		return stack:get_count()
	elseif listname == "dst" then
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

local function furnace_node_timer(pos, elapsed)
	--
	-- Inizialize metadata
	--
	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local src_time = meta:get_float("src_time") or 0
	local fuel_totaltime = meta:get_float("fuel_totaltime") or 0

	local inv = meta:get_inventory()
	local srclist, fuellist

	local cookable, cooked
	local fuel

	local update = true
	while elapsed > 0 and update do
		update = false

		srclist = inv:get_list("src")
		fuellist = inv:get_list("fuel")

		--
		-- Cooking
		--

		-- Check if we have cookable content
		local aftercooked
		--cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
		cooked, aftercooked = get_sat_time(srclist)
		--cookable = cooked.time ~= 0
		cookable = cooked.time ~= 0 and inv:get_stack("src", 1):get_name() == "default:cobble"

		local el = math.min(elapsed, fuel_totaltime - fuel_time)
		if cookable then -- fuel lasts long enough, adjust el to cooking duration
			el = math.min(el, cooked.time - src_time)
		end

		-- Check if we have enough fuel to burn
		if fuel_time < fuel_totaltime then
			-- The furnace is currently active and has enough fuel
			fuel_time = fuel_time + el
			-- If there is a cookable item then check if it is ready yet
			if cookable then
				src_time = src_time + el
				if src_time >= cooked.time then
					-- Place result in dst list if possible
					if inv:room_for_item("dst", cooked.item) then
						inv:add_item("dst", cooked.item)
						inv:set_stack("src", 1, aftercooked.items[1])
						src_time = src_time - cooked.time
						update = true
					end
				else
					-- Item could not be cooked: probably missing fuel
					update = true
				end
			end
		else
			-- Furnace ran out of fuel
			if cookable then
				-- We need to get new fuel
				local afterfuel
				--fuel, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})
				fuel, afterfuel = get_soak_time()

				--if fuel.time == 0 then
				if inv:get_stack("fuel", 1):get_name() ~= "bucket:bucket_water" then
					-- No valid fuel in fuel list
					fuel_totaltime = 0
					src_time = 0
				else
					-- Take fuel from fuel list
					inv:set_stack("fuel", 1, afterfuel.items[1])
					update = true
					fuel_totaltime = fuel.time + (fuel_totaltime - fuel_time)
				end
			else
				-- We don't need to get new fuel since there is no cookable item
				fuel_totaltime = 0
				src_time = 0
			end
			fuel_time = 0
		end

		elapsed = elapsed - el
	end

	if fuel and fuel_totaltime > fuel.time then
		fuel_totaltime = fuel.time
	end
	if srclist[1]:is_empty() then
		src_time = 0
	end

	--
	-- Update formspec, infotext and node
	--
	local formspec
	local item_state
	local item_percent = 0
	if cookable then
		item_percent = math.floor(src_time / cooked.time * 100)
		if item_percent > 100 then
			item_state = "100% (output full)"
		else
			item_state = item_percent .. "%"
		end
	else
		if srclist[1]:is_empty() then
			item_state = "Empty"
		else
			item_state = "Not water"
		end
	end

	local fuel_state = "Empty"
	local active = "inactive"
	local result = false

	if fuel_totaltime ~= 0 then
		active = "active"
		local fuel_percent = math.floor(fuel_time / fuel_totaltime * 100)
		fuel_state = fuel_percent .. "%"
		formspec = machines.get_furnace_active_formspec(fuel_percent, item_percent)
		swap_node(pos, "machines:generator_mossycobble_active")
		-- make sure timer restarts automatically
		result = true
	else
		if not fuellist[1]:is_empty() then
			fuel_state = "0%"
		end
		formspec = machines.get_furnace_inactive_formspec()
		swap_node(pos, "machines:generator_mossycobble")
		-- stop timer on the inactive furnace
		minetest.get_node_timer(pos):stop()
	end

	local infotext = "Generator " .. active .. "\n(Item: " .. item_state ..
		"; Water: " .. fuel_state .. ")"

	--
	-- Set meta values
	--
	meta:set_float("fuel_totaltime", fuel_totaltime)
	meta:set_float("fuel_time", fuel_time)
	meta:set_float("src_time", src_time)
	meta:set_string("formspec", formspec)
	meta:set_string("infotext", infotext)

	return result
end
minetest.register_abm({
	nodenames = {"machines:generator_mossycobble"},
	neighbors = {"default:water_source"},
	interval = 6.3,
	chance = 1,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local m = minetest.get_node_or_nil({
			x = pos.x,
			y = pos.y - 1,
			z = pos.z
		})
		if m and m.name and m.name == "default:water_source" then
			local inv = minetest.get_inventory({type = "node", pos = pos})
			if inv and inv:get_stack("fuel", 1):get_name() == "bucket:bucket_empty" then
				inv:remove_item("fuel", inv:get_stack("fuel", 1))
				inv:add_item("fuel", ItemStack("bucket:bucket_water"))
			end
		end
	end,
})
--
-- Node definitions
--

minetest.register_node("machines:generator_mossycobble", {
	description = "Mossy Cobble Generator",
	tiles = {
		"machines_mcgen_top.png", "machines_mcgen_bottom.png",
		"machines_mcgen_side.png", "machines_mcgen_side.png",
		"machines_mcgen_back.png", "machines_mcgen_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	can_dig = can_dig,

	on_timer = furnace_node_timer,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", machines.get_furnace_inactive_formspec())
		local inv = meta:get_inventory()
		inv:set_size('src', 1)
		inv:set_size('fuel', 1)
		inv:set_size('dst', 4)
	end,

	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "src", drops)
		default.get_inventory_drops(pos, "fuel", drops)
		default.get_inventory_drops(pos, "dst", drops)
		drops[#drops+1] = "machines:generator_mossycobble"
		minetest.remove_node(pos)
		return drops
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

minetest.register_node("machines:generator_mossycobble_active", {
	description = "Mossy Cobble Generator (You hacker you!)",
	tiles = {
		"machines_mcgen_top.png", "machines_mcgen_bottom.png",
		"machines_mcgen_side.png", "machines_mcgen_side.png",
		"machines_mcgen_back.png",
		{
			image = "machines_mcgen_front_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			},
		}
	},
	paramtype2 = "facedir",
	light_source = 8,
	drop = "machines:generator_mossycobble",
	groups = {cracky=2, not_in_creative_inventory=1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	on_timer = furnace_node_timer,

	can_dig = can_dig,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

minetest.register_craft({
	output = "machines:generator_mossycobble",
	recipe = {
		{"default:mossycobble", "default:mossycobble", "default:mossycobble"},
		{"default:mossycobble", "default:furnace", "default:mossycobble"},
		{"default:mossycobble", "default:mossycobble", "default:mossycobble"},
	},
})
