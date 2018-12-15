minetest.register_chatcommand("register", {
	description = "Show registers",
	privs = "server",
	params = "none",
	func = function(name, param)
		print(dump(param))
	end
})

minetest.register_chatcommand("debug", {
	description = "Debug command",
	params = "<wielded>",
	privs = "server",
	func = function(name, param)
		local param = param:split(" ")
		local name = minetest.get_player_by_name(name)
		if param[1] == "wielded" then
			if param[2] then
				local bookq = param[2]:sub(1, 4)
				local bookn = tonumber(param[2]:sub(5, -1))
				if bookq == "book" and bookn then
					if bookn >= 1 and bookn <= 9 then
						is.books[bookn] = name:get_wielded_item():to_table()
						store:set_string("books", minetest.serialize(is.books))
						minetest.log("action", "Reboot to set initial stuff again.")
						return true, "Reboot to set initial stuff again."
					end
				end
			end
		end
	end,
})

