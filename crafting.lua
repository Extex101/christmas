local depends = {}
depends.default = core.get_modpath("default")
depends.farming = core.get_modpath("farming")
depends.wool = core.get_modpath("wool")
depends.dye = core.get_modpath("dye")

if depends.default and depends.farming then
	core.register_craft({
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



if depends.wool then
	core.register_craft({
		output = "christmas:stocking",
		recipe = {
			{"","wool:white","wool:white"},
			{"default:gold_ingot","wool:red","wool:red"},
			{"wool:red","wool:red","wool:red"},
		},
	})
end

if depends.dye then
	core.register_craft({
		output = "christmas:candy_cane 12",
		recipe = {
			{"dye:red","christmas:sugar","dye:white"},
			{"christmas:sugar","dye:white","christmas:sugar"},
			{"christmas:sugar","dye:red",""},
		},
	})
end

core.register_craft({
	output = "christmas:tree",
	recipe = {
		{"group:leaves","group:leaves","group:leaves"},
		{"group:leaves","group:leaves","group:leaves"},
		{"group:leaves","group:tree","group:leaves"},
	},
})