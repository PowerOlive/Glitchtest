-- Modified Physics (sneak_jump)
-- By James Stevenson (c) 2018
-- GNU GPL v3

local regen_delay = 3
local hunger_delay = 3.1

-- Make a sound on item pickup.
local old_on_step = minetest.registered_entities["__builtin:item"].on_step
minetest.registered_entities["__builtin:item"].on_step = function(self, dtime)
	for _, o in ipairs(minetest.get_objects_inside_radius(self.object:get_pos(), 1)) do
		local pq = o:is_player() and o:get_meta():get("class") ~= "node"
		if pq then
			local i = o:get_inventory()
			if i and self.itemstring ~= "" and self.age > 1 then
				local s = i:add_item("main", self.itemstring)
				if s and not s:is_empty() then
					self:set_item(s)
					break
				end
				minetest.sound_play({name = "sneak_jump_item", gain = 0.033}, {
					object = self.object,
					max_hear_distance = 4,
					pitch = 0.9,
				})
				self.itemstring = ""
				self.object:remove()
				return
			end
		end
	end
	old_on_step(self, dtime)
end
minetest.registered_entities["__builtin:item"].on_punch = function(self, hitter)
	if hitter:get_meta():get("class") == "node" then
		return
	end
	local i = hitter:get_inventory()
	if i and self.itemstring ~= "" then
		local s = i:add_item("main", self.itemstring)
		if s and not s:is_empty() then
			self:set_item(s)
			return
		end
	end
	minetest.sound_play("sneak_jump_item", {
		object = self.object,
		max_hear_distance = 4,
		gain = 0.033,
		pitch = 0.9,
	})
	self.itemstring = ""
	self.object:remove()
end

sneak_jump = {}
sneak_jump.sprinting = {}
sneak_jump.sneaking = {}
sneak_jump.meters = {}

local pitch_table = {
	[1] = 0.98,
	[2] = 0.99,
	[3] = 1,
	[4] = 1.01,
	[5] = 1.034,
	[6] = 1.05,
	[7] = 1.06,
	[8] = 1.09,
	[9] = 1.12,
}

local settings = minetest.settings
local ceil = math.ceil
local floor = math.floor
local random = math.random
-- Whether player has stamina.
local stamina_drains = settings:get("sneak_jump.stamina_drains") or
		settings:get("enable_damage")
stamina_drains = stamina_drains == "true" or nil
-- The rate of stamina drain while sprinting.
local drain_rate = settings:get("sneak_jump.drain_rate") or 0.075
-- The rate of stamina fill while not sprinting.
local fill_rate = settings:get("sneak_jump.fill_rate") or 0.5
-- Creative mode check.
local creative = settings:get("creative_mode") == "true"
-- Hunger
local hunger = settings:get("sneak_jump.hunger") or true
if hunger == "false" then
	hunger = nil
end
local starve_rate = tonumber(settings:get("sneak_jump.starve_rate")) or 0.5
local starve_timer = 0
-- Regen
local regen_rate = tonumber(settings:get("sneak_jump.regen_rate")) or 1
local regen_timer = 0
-- Food governor
local eat_div = tonumber(settings:get("sneak_jump.food_governor")) or 0.5

-- Physics tables.
sneak_jump.default_physics = {
	speed = 1,
	jump = 1,
	gravity = 1,
	new_move = true,
	sneak_glitch = false,
}
default_physics = sneak_jump.default_physics
sneak_jump.default_physics_scout = {
	speed = 1.25,
	jump = 1.25,
	gravity = 0.95,
	new_move = true,
	sneak_glitch = true,
}
default_physics_scout = sneak_jump.default_physics_scout
local jump_setting = settings:get("sneak_jump.jump") or 1.25
local modified_physics = {
	speed = settings:get("sneak_jump.speed") or 1.5,
	jump = jump_setting,
	gravity = settings:get("gravity") or 0.95,
	new_move = false,
	sneak_glitch = true,
}
local modified_physics_scout = {
	speed = 1.999,
	jump = 1.5,
	gravity = 0.89,
	new_move = false,
	sneak_glitch = true,
}
-- Functions
local function set_physics(player, physics_table)
	player:set_physics_override(physics_table)
end

local function eat_sound(pitch, player)
	minetest.sound_play("sneak_jump_eat", {
		object = player,
		pitch = pitch,
	})
end

-- Remove bubbles.
minetest.hud_replace_builtin("breath", {
	hud_elem_type = "statbar",
	text = "",
})

local function regen(player)
	if not player then
		return
	end
	if not player:get_properties() then
		return minetest.after(regen_delay, regen, player)
	end
	local sat = player:get_meta():get_float("satiation") or 0
	local hp = player:get_hp()
	local hp_max = player:get_properties().hp_max
	if sat > 15 and hp ~= hp_max and hp ~= 0 then
		player:set_hp(hp + 1)
	end
	return minetest.after(regen_delay, regen, player)
end

local function starve(player, amount)
	if not player then
		return
	end
	local meta = player:get_meta()
	local sat = meta:get_float("satiation") or 0
	sat = sat - amount
	jas0.level(player, amount / 2)
	if sat < 0 then
		sat = 0
	end
	meta:set_float("satiation", sat)
	local name = player:get_player_name()
	if sneak_jump.meters[name] and
			sneak_jump.meters[name].satiation and
			meta:get("class") ~= "node" then
		player:hud_change(sneak_jump.meters[name].satiation,
				"number", ceil(sat))
	end
end

function sneak_jump.hud_update(player, repeater)
	if not player then
		return
	end
	local meta = player:get_meta()
	local name = player:get_player_name()
	local armor_wear_level = meta:get_int("3d_armor_wear") or 0
	if meta:get("class") == "node" then
		armor_wear_level = 0
	end
	if sneak_jump.meters[name] and sneak_jump.meters[name].armor then
		player:hud_change(sneak_jump.meters[name].armor,
				"number", ceil(armor_wear_level))
	end
	if repeater then
		return minetest.after(2, sneak_jump.hud_update, player, true)
	end
end

function sneak_jump.cdr(player, tbl)
	if not player then
		return
	end
	local control = player:get_player_control()
	if tbl then
		for i = 1, #tbl do
			if control[tbl[i]] then
				return true
			end
		end
	else
		return control.up or
			control.down or
			control.left or
			control.right or
			control.jumping
	end
end

local function hunger(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	if not meta then
		return
	end
	if player:get_hp() == 0 or
			player:get_meta():get("class") == "node" then
		return minetest.after(hunger_delay, hunger, player)
	end
	if meta:get_float("satiation") < 1 then
		player:set_hp(player:get_hp() - 1)
		starve(player, 1)
	elseif sneak_jump.cdr(player, {"LMB", "RMB"}) then
		starve(player, 0.25)
	elseif sneak_jump.cdr(player) then
		starve(player, 0.1)
	else
		starve(player, 0.02)
	end
	return minetest.after(hunger_delay, hunger, player)
end

local function physics(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	if not meta then
		return
	end
	local name = player:get_player_name()
	if not sneak_jump.meters[name] or
			meta:get("class") == "node" then
		return minetest.after(0.1, physics, player)
	end
	local scout = meta:get_string("class") == "scout"
	local hp = player:get_hp()
	if hp < 1 then
		return minetest.after(0.1, physics, player)
	end
	local control = player:get_player_control()
	local aux1 = control.aux1
	local sneaking = control.sneak
	local jumping = control.jump
	local sprinting = sneak_jump.sprinting[name]
	local stamina = meta:get_float("stamina")
	local sat = meta:get_float("satiation")
	local cdr = control.up or
			control.down or
			control.left or
			control.right or
			jumping
	if sat < 1 then
		if stamina > 1 then
			stamina = stamina - drain_rate
		end
	elseif aux1 and not sprinting and cdr then
		if stamina_drains and stamina > 1 or
				not stamina_drains then
			if scout then
				set_physics(player, modified_physics_scout)
			else
				set_physics(player, modified_physics)
			end
			sprinting = true
		end
	elseif sprinting and not aux1 or
			sprinting and not cdr then
		if scout then
			set_physics(player, default_physics_scout)
		else
			set_physics(player, default_physics)
		end
		sprinting = false
	end
	if sprinting and stamina > 0 then
		local new_sat = sat / 10
		if new_sat <= 0 then
			new_sat = 0.1
		end
		local new_drain_rate = drain_rate / new_sat
		stamina = stamina - new_drain_rate
	elseif sprinting and stamina < 1 then
		if scout then
			set_physics(player, default_physics_scout)
		else
			set_physics(player, default_physics)
		end
	elseif stamina < 20 and not sprinting then
		if hunger and sat < 1 then
			stamina = stamina - drain_rate
		else
			local new_fill_rate = fill_rate
			if cdr then
				new_fill_rate = fill_rate * 0.1
			end
			stamina = stamina + new_fill_rate
		end
	end
	meta:set_float("stamina", stamina)
	player:hud_change(sneak_jump.meters[name].stamina,
			"number", stamina)
	if sneaking and not sneak_jump.sneaking[name] then
		player:set_properties{makes_footstep_sound = false}
	elseif sneak_jump.sneaking[name] and not sneaking then
		if not scout then
			player:set_properties{makes_footstep_sound = true}
		end
	end
	sneak_jump.sprinting[name] = sprinting
	sneak_jump.sneaking[name] = sneaking
	return minetest.after(0.1, physics, player)
end

minetest.register_on_newplayer(function(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	--meta:set_float("stamina", 20)
	meta:set_float("satiation", 20)
end)

minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	if not meta then
		return
	end
	local scout = meta:get_string("class") == "scout"
	if scout then
		set_physics(player, default_physics_scout)
	else
		set_physics(player, default_physics)
	end
	local name = player:get_player_name()
	sneak_jump.sneaking[name] = false
	sneak_jump.meters[name] = {}

	-- Add armor HUD statbar.
	local armor_wear = meta:get_int("3d_armor_wear") or 0
	local class = meta:get("class")
	sneak_jump.meters[name]["armor"] = player:hud_add({
		hud_elem_type = "statbar",
		position = {x = 0.5, y = 1},
		text = "sneak_jump_armor_sb.png",
		number = armor_wear,
		direction = 0,
		size = {x = 24, y = 21},
		offset = {x = 25, y = -(48 + 46 + 16)},
	})

	-- Add stamina HUD statbar.
	meta:set_float("stamina", 20)
	local stam = 20
	if player:get_hp() == 0 or
			class == "node" then
		stam = 0
	end
	sneak_jump.meters[name]["stamina"] = player:hud_add({
		hud_elem_type = "statbar",
		position = {x = 0.5, y = 1},
		text = "sneak_jump_stamina_sb.png",
		number = stam,
		direction = 0,
		size = {x = 24, y = 24},
		offset = {x = 25, y = -(48 + 24 + 16)},
	})
	local sat = meta:get_float("satiation")
	if class == "node" then
		sat = 0
	end
	--[[
	if not sat then
		meta:set_float("satiation", 20)
		sat = 20
	end
	--]]
	local offset = {x = (-10 * 24) - 25, y = -(48 + 24 + 40)}
	if settings:get("enable_damage") == "false" then
		offset.y = -(48 + 24 + 16)
	end
	sneak_jump.meters[name]["satiation"] = player:hud_add({
		hud_elem_type = "statbar",
		position = {x = 0.5, y = 1},
		text = "sneak_jump_satiation_sb.png",
		number = sat,
		direction = 0,
		size = {x = 24, y = 24},
		offset = offset,
	})
	minetest.after(0.1, hunger, player)
	minetest.after(0.2, regen, player)
	minetest.after(0.3, physics, player)
	--minetest.after(0.4, sneak_jump.hud_update, player, true)
end)

minetest.register_on_dieplayer(function(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	local name = player:get_player_name()
	meta:set_float("satiation", 0)
	player:hud_change(sneak_jump.meters[name].satiation,
			"number", 0)
	meta:set_float("stamina", 0)
	player:hud_change(sneak_jump.meters[name].stamina,
			"number", 0)
end)

minetest.register_on_respawnplayer(function(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	meta:set_float("satiation", 20)
	meta:set_float("stamina", 20)
	if meta:get("class") == "node" then
		return
	end
	local name = player:get_player_name()
	player:hud_change(sneak_jump.meters[name].satiation,
			"number", 20)
	player:hud_change(sneak_jump.meters[name].stamina,
			"number", 20)
end)

minetest.register_on_leaveplayer(function(player)
	if not player then
		return
	end
	local name = player:get_player_name()
	sneak_jump.sprinting[name] = nil
	sneak_jump.sneaking[name] = nil
	sneak_jump.meters[name] = nil
end)

minetest.register_on_item_eat(function(hp_change,
		replace_with_item, itemstack, user, pointed_thing)
	if not user then
		return
	end
	local meta = user:get_meta()
	if not meta then
		return
	end
	local sat = meta:get_float("satiation")
	local hp = user:get_hp()
	if hp_change < 0 then
		user:set_hp(hp + hp_change * 1.5)
		if hp + hp_change < 1 then
			eat_sound(pitch_table[random(#pitch_table)], user)
			return ""
		end
	end
	if hp_change > 0 and ceil(sat) >= 20 then
		return itemstack
	end
	if hp + hp_change > 1 then
		if hp_change > 1 then
			hp_change = ceil(hp_change / eat_div)
		end
		sat = sat + hp_change
		if sat > 20 then
			sat = 20
		end
		meta:set_float("satiation", sat)
		local name = user:get_player_name()
		user:hud_change(sneak_jump.meters[name].satiation,
				"number", ceil(sat))
	end
	itemstack:take_item()
	eat_sound(pitch_table[random(#pitch_table)], user)
	return itemstack
end)

minetest.register_craftitem("sneak_jump:bandage", {
	description = "Bandage",
	inventory_image = "sneak_jump_bandage.png",
	on_use = function(itemstack, user, pointed_thing)
		local hp = user:get_hp()
		local hp_max = user:get_properties().hp_max
		if hp < hp_max then
			user:set_hp(hp + 2)
			if not creative then
				itemstack:take_item()
			end
		end
		return itemstack
	end
})

minetest.register_craft({
	output = "sneak_jump:bandage",
	recipe = {
		{"farming:string", "farming:cotton", "farming:string"}
	}
})

minetest.register_craft({
	output = "sneak_jump:bandage",
	recipe = {
		{"farming:string", "default:paper", "farming:string"}
	}
})
