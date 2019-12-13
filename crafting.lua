local depends = {}
depends.default = minetest.get_modpath("default")
depends.farming = minetest.get_modpath("farming")
depends.wool = minetest.get_modpath("wool")
depends.dye = minetest.get_modpath("dye")

if depends.default then
	if depends.farming then
		minetest.register_craft({
			type = "shapeless",
			output = "christmas:mince_pie 3",
			recipe = {
				"default:blueberries",
				"farming:flour",
				"default:apple",
				"default:blueberries",
				"christmas:sugar"
			},
		})
	end
	minetest.register_craft({
		output = "christmas:present",
		recipe = {
			{"default:paper","default:paper","default:paper"},
			{"default:paper","","default:paper"},
			{"default:paper","default:paper","default:paper"},
		},
	})
	minetest.register_craft({
		output = "default:paper 8",
		recipe = {
			{"christmas:present"},
		},
	})
end



if depends.wool then
	minetest.register_craft({
		output = "christmas:stocking",
		recipe = {
			{"","wool:white","wool:white"},
			{"default:gold_ingot","wool:red","wool:red"},
			{"wool:red","wool:red","wool:red"},
		},
	})
end

if depends.dye then
	minetest.register_craft({
		output = "christmas:candy_cane 12",
		recipe = {
			{"dye:red","christmas:sugar","dye:white"},
			{"christmas:sugar","dye:white","christmas:sugar"},
			{"christmas:sugar","dye:red",""},
		},
	})
end

minetest.register_craft({
	output = "christmas:tree",
	recipe = {
		{"group:leaves","group:leaves","group:leaves"},
		{"group:leaves","group:leaves","group:leaves"},
		{"group:leaves","group:tree","group:leaves"},
	},
})
