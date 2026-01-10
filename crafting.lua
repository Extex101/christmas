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



local wool_white = xcompat.materials.wool_white

--Why doesn't xcompat have red wool?
local wool_red = xcompat.gameid == "minetest" and "wool:red" or xcompat.gameid == "mineclonia" and "mcl_wool:red" or white
local gold = xcompat.materials.gold_ingot

core.register_craft({
	output = "christmas:stocking",
	recipe = {
		{"",wool_white,wool_white},
		{gold,wool_red,wool_red},
		{wool_red,wool_red,wool_red},
	},
})

local dye_red = xcompat.materials.dye_red
local dye_white = xcompat.materials.dye_white
if depends.dye then
	core.register_craft({
		output = "christmas:candy_cane 12",
		recipe = {
			{dye_red,"christmas:sugar",dye_white},
			{"christmas:sugar",dye_white,"christmas:sugar"},
			{"christmas:sugar",dye_red,""},
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