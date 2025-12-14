christmas = {}
christmas.rewards = {}
christmas.players = {}
christmas.dyes = {
	black = "#323232",
	dark_grey = "#686868",
	grey = "#a6a6a6",
	white = "#ffffff",
	pink = "#fdafba",
	red = "#f70d0d",
	orange = "#eb6e00",
	brown = "#955431",
	gold = "#d7ae56",
	yellow = "#ffde00",
	green = "#00d82a",
	dark_green = "#18991f",
	cyan = "#00e1f5",
	blue = "#007fde",
	violet = "#7841d1",
	magenta = "#fb4ccf"
}
christmas.light_dyes = {
	white = "#eeeeee",
	pink = "#FB96D1",
	red = "#f70d0d",
	orange = "#eb6e00",
	yellow = "#ffde00",
	green = "#54F305",
	cyan = "#00f2ff",
	blue = "#1F61F0",
	violet = "#b424ff",
	magenta = "#fa74ff",
}

-- Track stocking timers even if player is offline
christmas.stocking_refill_time = 15 -- refill after X minutes
christmas.stocking_timers = {}
christmas.storage = core.get_mod_storage()
for player_name in pairs(christmas.storage:to_table().fields) do
	if not christmas.storage:get_int(player_name) then 
		goto next -- Likely a string from older version coordinate storage
	end
	christmas.stocking_timers[player_name] = christmas.storage:get_int(player_name)
	::next::
end

local path = core.get_modpath("christmas")
dofile(path.."/functions.lua" )
dofile(path.."/crafting.lua")
dofile(path.."/tree.lua")

------------------------------------ Goodie Bag ------------------------------------
local col_styling = ""
for name, col in pairs(christmas.dyes) do
	col_styling = col_styling.."style["..name..";bgcolor="..col.."]"
end
local function make_form(item_name)
	local order = {"red", "orange", "yellow", "gold", "brown", "black", "dark_grey", "grey", "white", "pink", "magenta", "violet", "blue", "cyan", "green", "dark_green"}
	if item_name == "lights" then
		order = {"red", "orange", "yellow", "green", "cyan", "blue", "violet", "magenta", "pink", "white"}
	end
	local formspec = "size["..#order..",1]"..col_styling
	for i, col in ipairs(order) do
		local name = item_name.."_"..col
		formspec = formspec.."item_image_button["..(i-1)..",0.1;1,1;christmas:"..name..";"..col..";]"
	end
	return formspec
end

christmas.goodie_bag_categories = {
	{
		formname="angel",
		formspec = make_form("angel"),
		count = 1
	},
	{
		formname="lights",
		formspec = make_form("lights"),
		count = {min=1, max=5}
	},
	{
		formname="tinsel",
		formspec = make_form("tinsel"),
		count = 1
	},
	{
		formname="ornament",
		formspec = make_form("ornament"),
		count = {min=1, max=2}
	},
	{
		formname="present",
		formspec = make_form("present"),
		count = {min=1, max=3}
	}
}
core.register_tool("christmas:goodie_bag", {
	description = "Christmas Goodie Bag",
	inventory_image = "christmas_goodie_bag.png",
	on_use = function(itemstack, user, pointed_thing)
		local name = user:get_player_name()
		local meta = itemstack:get_meta()
		local index = meta:get_int("category")
		if not index or index == 0 then
			index = math.random(#christmas.goodie_bag_categories)
			meta:set_int("category", index)
			meta:set_string("inventory_image", "christmas_goodie_bag.png^christmas_goodie_bag_overlay_"..christmas.goodie_bag_categories[index].formname..".png")
			meta:set_string("wield_image", "christmas_goodie_bag.png^christmas_goodie_bag_overlay_"..christmas.goodie_bag_categories[index].formname..".png")
			local title = (christmas.goodie_bag_categories[index].formname:gsub("^%l", string.upper))
			meta:set_string("description", "Christmas "..title.." Goodie Bag")
		end
		local selection = christmas.goodie_bag_categories[index]
		core.show_formspec(name, "christmas:select_"..selection.formname, selection.formspec)
		return itemstack
	end
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname:match("christmas:select_") then
		local category = formname:match("christmas:select_(.*)")
		local color = ""
		for name, _ in pairs(christmas.dyes) do
			if fields[name] then
				color = name
				break
			end
		end
		if color == "" then
			return true
		end
		local wielditem = player:get_wielded_item()
		if wielditem:get_name() == "christmas:goodie_bag" then
			local new_item = ItemStack("christmas:"..category.."_"..color)
			local num = christmas.goodie_bag_categories[wielditem:get_meta():get_int("category")].count
			if type(num) == "table" then
				num = math.random(num.min, num.max)
			end
			new_item:set_count(num)
			local inv = player:get_inventory()
			if inv:contains_item("main", new_item) and inv:room_for_item("main", new_item) then
				inv:add_item("main", new_item)
				player:set_wielded_item("")
			else
				player:set_wielded_item(new_item)
			end
		end
		core.close_formspec(player:get_player_name(), formname)
		return true
	end
	return false
end)


------------------------------------ Food Items ------------------------------------
core.register_craftitem("christmas:candy_cane", {
	description = "Candy Cane",
	inventory_image = "christmas_candy_cane.png",
	on_use = christmas.eat_candy(1, 8.5)
})
core.register_craftitem("christmas:mince_pie", {
	description = "Mince Pie",
	inventory_image = "christmas_mincepie.png",
	on_use = christmas.eat_candy(6, 2)
})
core.register_craftitem("christmas:sugar", {
	description = "Sugar",
	inventory_image = "christmas_sugar.png",
})
core.register_craftitem("christmas:gingerbread_man", {
	description = "Gingerbread Man",
	inventory_image = "christmas_gingerbread_man.png",
	on_use = christmas.eat_candy(4, 4)
})
core.register_node("christmas:eggnog", {
	description = "Eggnog",
	drawtype = "mesh",
	mesh = "christmas_eggnog.obj",
	tiles = {"christmas_eggnog.png"},
	use_texture_alpha = "clip",
	paramtype = "light",
	sunlight_propagates = true,
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.2, -0.5, -0.2, 0.2, 0.1, 0.2},
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.2, -0.5, -0.2, 0.2, 0.1, 0.2},
		}
	},
	paramtype2 = "degrotate",
	on_use = christmas.eat_candy(10, 1, "vessels:drinking_glass"),
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local dir = math.deg(placer:get_look_horizontal())/1.5
		core.swap_node(pos, {name = "christmas:eggnog", param2 = dir})
	end,
	sounds = default.node_sound_glass_defaults(),
	groups = {vessel = 1, dig_immediate = 3, attached_node = 3},
})


------------------------------------ Nodes ------------------------------------
core.register_node("christmas:stocking", {
	description = "Christmas Stocking",
	drawtype = "signlike",
	tiles = {"christmas_stocking.png"},
	use_texture_alpha = "blend",
	inventory_image = "christmas_stocking.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true, 
	selection_box = {
		type = "wallmounted",
	},
	groups = {oddly_breakable_by_hand = 2, attached_node = 1},
	walkable = false,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = core.get_meta(pos)
		meta:set_string("infotext", "Christmas Stocking")
		meta:set_string("owner", placer:get_player_name() or "")
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local meta = player:get_meta()
		local inv = player:get_inventory()
		local owner = core.get_meta(pos):get_string("owner")
		if player:get_player_name() ~= owner then
			core.chat_send_player(player:get_player_name(), "This isn't your stocking")--Imposter!!
			return itemstack
		end
		local time = christmas.stocking_timers[owner]
		if time > 0 then
			core.chat_send_player(player:get_player_name(), "Stocking will refill in: "..christmas.to_time(math.floor(time)))
			return itemstack
		end
		christmas.stocking_timers[owner] = christmas.stocking_refill_time*60
		local drops = {christmas.random_reward(), christmas.random_reward(), christmas.random_reward()}
		for _, drop in pairs(drops) do
            if not inv:room_for_item("main", drop) then
                core.add_item(pos, drop)
            else
                inv:add_item("main", drop)
            end
		end
	end,
})

christmas.register_reward("christmas:candy_cane",      {min=3, max=15},  0.15)
christmas.register_reward("christmas:eggnog",          {min=1, max=3},   0.15)
christmas.register_reward("christmas:gingerbread_man", {min=1, max=9},   0.5)
christmas.register_reward("christmas:mince_pie",       {min=6, max=12},  0.3)
christmas.register_reward("christmas:tree",            {min=0, max=1},   0.15)
christmas.register_reward("christmas:star",            {min=0, max=1},   0.1)
christmas.register_reward("christmas:sugar",           {min=1, max=7},   0.36)
christmas.register_reward("christmas:goodie_bag",      {min=0, max=1},   0.71)