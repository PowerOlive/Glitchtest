-- jas0/classes.lua is part of Glitchtest
-- Copyright 2018 James Stevenson
-- GNU GPL 3

local function particles(pos, texture)
	return {
		pos = pos,
		velocity = {x = 0, y = 0.1, z = 0},
		acceleration = {x = 0, y = 0.01, z = 0},
		expirationtime = math.random(),
		size = 0.34 + math.random() + math.random(),
		collisiondetection = false,
		collision_removal = false,
		object_collision = false,
		verticle = false,
		texture = texture,
		--playername = "singleplayer",
		--animation = {Tile Animation definition},
		glow = 14,
	}
end

local old_item_drop = minetest.item_drop
minetest.item_drop = function(itemstack, dropper, pos)
	if dropper:get_meta():get("class") == "node" then
		return
	else
		return old_item_drop(itemstack, dropper, pos)
	end
end
local function boom(pos)
	local def = {
		radius = 3,
	}
	return tnt.boom(pos, def)
end
minetest.register_entity("jas0:mage_fireball", {
	description = "Fireball",
	visual = "sprite",
	textures = {"mobs_fireball.png"},
	glow = 14,
	on_activate = function(self, staticdata, dtime_s)
		self.owner = staticdata or "singleplayer"
	end,
	on_step = function(self, dtime)
		local step = self.step or 0
		self.step = step + 1
		local pos = self.object:get_pos()
		if step > 36 then
			self.object:remove()
			return boom(pos)
		end
		local objects = minetest.get_objects_inside_radius(pos, 0.85)
		for i = 1, #objects do
			if objects[i]:is_player() then
				if objects[i]:get_player_name() ~= self.owner then
					self.object:remove()
					return boom(pos)
				end
			elseif objects[i]:get_luaentity().horny ~= nil then
				-- It's a mob!
				self.object:remove()
				return boom(pos)
			end
		end
		local node = minetest.get_node_or_nil(pos)
		if not node then
			return
		end
		local node_name = node.name
		if not node_name then
			return
		end
		local node_def = minetest.registered_nodes[node_name]
		if not node_def then
			return
		end
		local walkable = node_def.walkable
		if not walkable then
			return
		end
		self.object:remove()
		return boom(pos)
	end,
})

local generated = {}
for k, v in pairs(minetest.registered_nodes) do
	if v.drawtype == "normal" then
		generated[k] = ""
	end
end
old_item_place_node = minetest.item_place_node
minetest.item_place_node = function(itemstack, placer, pointed_thing, param2, prevent_after_place)
	if placer and placer:is_player() and placer:get_meta():get("class") == "node" then
		local p = pointed_thing.above
		if p then
			placer:set_pos(p)
		end
		return
	else
		return old_item_place_node(itemstack, placer, pointed_thing, param2, prevent_after_place)
	end
end

minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
	if player:get_meta():get("class") == "node" then
		return 0
	end
end)

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	if node and node.name then
		local meta = puncher:get_meta()
		if meta:get("class") ~= "node" or
				not generated[node.name] then
			return
		end
		meta:set_string("node", node.name)
		local inv = puncher:get_inventory()
		inv:set_stack("main", 1, node.name)
		puncher:set_properties({textures = {node.name}})
	end
end)

minetest.register_tool("jas0:node", {
	type = "none",
	wield_image = "[combine:16x16",
	range = 9,
	stack_max = 1,
	tool_capabilities = {
		full_punch_interval = 2,
		max_drop_level = 1,
		groupcaps = {
			crumbly = {},
			snappy = {},
			oddly_breakable_by_hand = {},
		},
		damage_groups = {fleshy = 0},
	},
})

minetest.register_tool("jas0:mage", {
	type = "none",
	wield_image = "empty.png",
	tool_capabilities = {
		full_punch_interval = 2,
		max_drop_level = 1,
		groupcaps = {
			crumbly = {},
			snappy = {},
			oddly_breakable_by_hand = {},
		},
		damage_groups = {fleshy = 0},
	},
})

local function charge(player, amount)
	if not player then
		return
	end
	local pos = player:get_pos()
	if not pos then
		return
	end
	local meta = player:get_meta()
	if not meta then
		return minetest.after(0.1, charge, player, 0)
	end
	if meta:get_string("class") ~= "mage" then
		return
	end
	local wielded_item = player:get_wielded_item()
	if wielded_item:get_name() ~= "" then
		if not minetest.registered_items[wielded_item:to_table().name].on_use then
			local o = minetest.add_item(pos, wielded_item)
			if o then
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
			player:set_wielded_item("")
		end
		return minetest.after(0.1, charge, player, 0)
	end
	pos.y = pos.y + 1.25
	local dir = player:get_look_dir()
	if amount >= 9 then
		pos = vector.add(pos, dir)
		local arrow = minetest.add_entity(pos, "jas0:mage_fireball", player:get_player_name())
		arrow:set_acceleration(dir)
		arrow:set_velocity(vector.multiply(dir, 12))
		player:set_hp(player:get_hp() * 0.8)
		return minetest.after(0.1, charge, player, -9)
	elseif amount < 0 then
		return minetest.after(0.1, charge, player, amount + 0.25)
	end
	local ctrl = player:get_player_control()
	if not ctrl.LMB then
		return minetest.after(0.1, charge, player, 0)
	else
		if amount > 0 then
			pos = vector.add(pos, dir)
			minetest.add_particle(particles(pos, "default_item_smoke.png"))
			minetest.add_particle(particles(pos, "tnt_smoke.png"))
			minetest.add_particle(particles(pos, "default_mese_crystal.png"))
		end
		return minetest.after(0.1, charge, player, amount + 1)
	end
end

local formspec_prepend = {}
formspec_prepend.miner = "background[5,5;1,1;gui_formbg.png;true]" ..
	"listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]" ..
""

formspec_prepend.mage = "background[5,5;1,1;gui_formbg.png;true]" ..
	"listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]" ..
""

formspec_prepend.scout = "background[5,5;1,1;gui_formbg.png;true]" ..
	"listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]" ..
""

formspec_prepend.node = "background[5,5;1,1;gui_formbg.png;true]" ..
	"listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]" ..
""

local formspec = {}
formspec.miner = "size[8,8.5]" ..
	jas0.exit_button() ..
	"list[current_player;main;0,4.25;8,1]" ..
	"list[current_player;main;0,5.5;8,3;8]" ..
	"list[current_player;craft;2,0.5;3,3]" ..
	"button_exit[0.25,1;1.5,1;spawn;Spawn]" ..
	"button_exit[0.25,2;1.5,1;home;Home]" ..
	"list[current_player;craftpreview;6,1.5;1,1]" ..
	"image[5,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
	"listring[current_player;main]" ..
	"listring[current_player;craft]" ..
	default.get_hotbar_bg(0, 4.25) ..
""

formspec.scout = "size[8,7.5]" ..
	jas0.exit_button() ..
	"list[current_player;main;0,4.25;8,1]" ..
	"list[current_player;main;0,5.5;8,2;8]" ..
	"list[current_player;craft;2,0.5;2,2]" ..
	"button_exit[0.25,1;1.5,1;spawn;Spawn]" ..
	"button_exit[0.25,2;1.5,1;home;Home]" ..
	"list[current_player;craftpreview;6,1.5;1,1]" ..
	"image[5,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
	"listring[current_player;main]" ..
	"listring[current_player;craft]" ..
	default.get_hotbar_bg(0, 4.25) ..
""

formspec.mage = "size[8,5.5]" ..
	jas0.exit_button() ..
	"button_exit[0.25,1;1.5,1;spawn;Spawn]" ..
	"button_exit[0.25,2;1.5,1;home;Home]" ..
	"list[current_player;main;0,4.25;8,1;]" ..
	"list[current_player;craft;3,1.5;1,1;]" ..
	"image[4,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
	"list[current_player;craftpreview;5,1.5;1,1;]" ..
	"listring[current_player;main]" ..
	"listring[current_player;craft]" ..
	default.get_hotbar_bg(0, 4.25) ..
""

formspec.node = "size[8,5.5]" ..
	jas0.exit_button() ..
	"button_exit[0.25,1;1.5,1;spawn;Spawn]" ..
	"button_exit[0.25,2;1.5,1;home;Home]" ..
	"list[current_player;main;0,4.25;1,1;]" ..
	--"list[current_player;craft;3,1.5;1,1;]" ..
	--"image[4,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
	--"list[current_player;craftpreview;5,1.5;1,1;]" ..
	--"listring[current_player;main]" ..
	--"listring[current_player;craft]" ..
	default.get_hotbar_bg(0, 4.25, 1) ..
""

local function reset_skin(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		minetest.after(0.1, function()
			reset_skin(name)
		end)
	end
	local skin = player:get_meta():get_string("multiskin_skin")
	multiskin.set_player_skin(player, skin)
	multiskin.update_player_visuals(player)
end

local function throw_contents(list, player, new_size)
	if not list then
		return
	end
	for i = new_size, #list, 1 do
		local o = minetest.add_item(player:get_pos(), list[i])
		if o then
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
local function class_update(player, class, reset)
	if not player then
		return
	end
	local meta = player:get_meta()
	if not meta then
		return
	end
	if class ~= "miner" and
			class ~= "mage" and
			class ~= "scout" and
			class ~= "node" then
		class = meta:get_string("class")
		if class == "" then
			class = "miner"
		end
	end
	local level = jas0.level(player)
	local inv = player:get_inventory()
	local name = player:get_player_name()
	if meta:get("class") == "node" then
		inv:set_list("main", {}) 
	end
	if class == "mage" then
		meta:set_string("class", "mage")
		player:set_formspec_prepend(formspec_prepend.mage)
		if reset then
			jas0.level(player, -level)
		end
		throw_contents(inv:get_list("main"), player, 8)
		inv:set_size("main", 8)
		inv:set_size("craft", 1)
		inv:set_size("hand", 1)
		inv:set_stack("hand", 1, "jas0:mage")
		player:set_properties({
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
			eye_height = 1.47,
			visual = "mesh",
			visual_size = {x = 1, y = 1},
		})
		player:set_nametag_attributes({text = ""})
		charge(player, 0)
		player:hud_set_hotbar_itemcount(8)
		reset_skin(name)
		player:hud_change(sneak_jump.meters[name].satiation, "number",
				math.ceil(meta:get_float("satiation")))
		player:set_inventory_formspec(formspec.mage)
		player:hud_set_flags({healthbar = true, wieldhand = true})
		player:hud_set_hotbar_itemcount(8)
	elseif class == "miner" then
		meta:set_string("class", "miner")
		player:set_formspec_prepend(formspec_prepend.miner)
		if reset then
			jas0.level(player, -level)
		end
		inv:set_size("main", 8 * 4)
		inv:set_size("craft", 3 * 3)
		inv:set_list("hand", nil)
		player:set_properties({
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
			eye_height = 1.47,
			visual = "mesh",
			visual_size = {x = 1, y = 1},
		})
		player:set_nametag_attributes({text = ""})
		player:hud_set_hotbar_itemcount(8)
		reset_skin(name)
		player:hud_change(sneak_jump.meters[name].satiation, "number",
				math.ceil(meta:get_float("satiation")))
		player:set_inventory_formspec(formspec.miner)
		player:hud_set_flags({healthbar = true, wieldhand = true})
	elseif class == "scout" then
		meta:set_string("class", "scout")
		player:set_formspec_prepend(formspec_prepend.scout)
		if reset then
			jas0.level(player, -level)
		end
		throw_contents(inv:get_list("main"), player, 24)
		inv:set_size("main", 8 * 3)
		inv:set_size("craft", 2 * 2)
		inv:set_list("hand", nil)
		player:set_properties({
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
			eye_height = 1.47,
			visual = "mesh",
			visual_size = {x = 1, y = 1},
		})
		player:set_nametag_attributes({text = ""})
		player:hud_set_hotbar_itemcount(8)
		reset_skin(name)
		player:hud_change(sneak_jump.meters[name].satiation, "number",
				math.ceil(meta:get_float("satiation")))
		player:set_inventory_formspec(formspec.scout)
		player:hud_set_flags({healthbar = true, wieldhand = true})
	elseif class == "node" then
		meta:set_string("class", "node")
		player:set_formspec_prepend(formspec_prepend.node)
		if reset then
			jas0.level(player, -level)
		end
		throw_contents(inv:get_list("main"), player, 0)
		throw_contents(inv:get_list("craft"), player, 0)
		inv:set_size("main", 1)
		local n = meta:get("node") or "default:dirt"
		inv:set_stack("main", 1, n)
		inv:set_size("craft", 0)
		inv:set_size("hand", 1)
		inv:set_stack("hand", 1, "jas0:node")
		player:set_properties({
			collisionbox = {-0.49, -0.49, -0.49, 0.49, 0.49, 0.49},
			eye_height = 0.07,
			visual = "item",
			visual_size = {x = 0.667, y = 0.667},
			textures = {n},
		})
		player:set_nametag_attributes({text = "\n"})
		player:hud_change(sneak_jump.meters[name].stamina, "number", 0)
		player:hud_change(sneak_jump.meters[name].satiation, "number", 0)

		-- Prevent sunken position.
		local p = player:get_pos()
		p.y = p.y + 1
		player:set_pos(p)

		player:set_inventory_formspec(formspec.node)
		minetest.after(0.1, function()
			player:hud_set_hotbar_itemcount(1)
			player:hud_set_flags({healthbar = false, wieldhand = false})
		end)
	end
	return class
end
jas0.change_class = function(player, class, reset)
	class_update(player, class, reset)
end
minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end
	local fb = class_update(player)
	jas0.message(player:get_player_name(), "Your class is " .. fb)
end)

-- /class command resets player's level!
minetest.register_chatcommand("class", {
	description = "Change or display your class",
	privs = "interact",
	params = "[miner|mage|scout|node]",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		local meta = player:get_meta()
		if not meta then
			return
		end
		local class = meta:get_string("class")
		-- Display class
		if param ~= "mage" and
				param ~= "miner" and
				param ~= "scout" and
				param ~= "node" then
			return true, "Your current class is " .. class ..
					".  Type /help class for more information."
		end
		-- Change class
		if param == "mage" and class ~= "mage" then
			class_update(player, "mage", true)
			return true, "You are now a mage!"
		elseif param == "miner" and class ~= "miner" then
			class_update(player, "miner", true)
			return true, "You are now a miner!"
		elseif param == "scout" and class ~= "scout" then
			class_update(player, "scout", true)
			return true, "You are now a scout!"
		elseif param == "node" and class ~= "node" then
			class_update(player, "node", true)
			return true, "You are now a node!"
		else
			return true, "You're already a " .. class .. "!"
		end
	end,
})
