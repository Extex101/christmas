christmas = {}
christmas.players = {}
christmas.path = minetest.get_modpath("christmas")
christmas.rewards = {}
local mod_storage = minetest.get_mod_storage()
dofile(christmas.path.."/functions.lua" )
dofile(christmas.path.."/crafting.lua")
local data = christmas.data


------------------------------------ Craft Items ------------------------------------
minetest.register_craftitem("christmas:candy_cane", {
	description = "Candy Cane",
	inventory_image = "christmas_candy_cane.png",
	on_use = christmas.eat_candy(1)
})
minetest.register_craftitem("christmas:mince_pie", {
	description = "Mince Pie",
	inventory_image = "christmas_mincepie.png",
	on_use = minetest.item_eat(6)
})
minetest.register_craftitem("christmas:sugar", {
	description = "Sugar",
	inventory_image = "christmas_sugar.png",
})

minetest.register_craftitem("christmas:gingerbread_man", {
	description = "Gingerbread Man",
	inventory_image = "christmas_gingerbread_man.png",
	on_use = minetest.item_eat(4)
})

minetest.register_craftitem("christmas:bauble_red", {
	description = "Bauble (Red)",
	inventory_image = "christmas_bauble_red.png",
	groups = {tree_bauble=1},
	colour_code = 1,--Future support
})
minetest.register_craftitem("christmas:star", {
	description = "Star",
	inventory_image = "christmas_star_inv.png",
	groups = {tree_topper=1},
})


------------------------------------ Nodes ------------------------------------
minetest.register_node("christmas:eggnog", {
	description = "Eggnog",
	drawtype = "plantlike",
	tiles = {"christmas_eggnog.png"},
	inventory_image = "christmas_eggnog.png",
	on_use = minetest.item_eat(10),
	groups = {vessel = 1, dig_immediate = 3, attached_node = 1},
})
minetest.register_node("christmas:present", {
	description = "Christmas present",
	tiles = {
			"christmas_present.png",
			"christmas_present_top.png"
	},
	drawtype = "mesh",
	paramtype = "light",
	mesh = "christmas_present.obj",
	groups = {oddly_breakable_by_hand = 3, attached_node = 1},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.3125, -0.5, -0.3125, 0.3125, 0.125, 0.3125},
		}	
	},
	on_construct = function(pos, itemstack, placer, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Christmas Present")
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 1)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", "Present from ".. meta:get_string("owner"))
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		minetest.after(0.2, 
			minetest.show_formspec, 
			player:get_player_name(), 
			"christmas:present", 
			christmas.get_present_formspec(pos))
	end,
})
minetest.register_node("christmas:stocking", {
	description = "Christmas Stocking",
	drawtype = "signlike",
	tiles = {"christmas_stocking.png"},
	inventory_image = "christmas_stocking.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true, 
	selection_box = {
		type = "wallmounted",
	},
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, attached_node = 1},
	walkable = false,
	on_construct = function(pos, itemstack, placer, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Stocking: No owner")
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 3)
	end,
	after_place_node = function(pos, player, itemstack, pointed_thing)
		local name = player:get_player_name()
		local meta = minetest.get_meta(pos)
		
		local stocking_pos = mod_storage:get_string(name.."_stocking_pos")
		local spos = minetest.string_to_pos(stocking_pos)
		if (spos and minetest.get_node(spos).name ~= "christmas:stocking") or stocking_pos == (nil or "") then
			mod_storage:set_string(name.."_stocking_pos", minetest.pos_to_string(pos))
		elseif spos and minetest.get_node(spos).name == "christmas:stocking" then
			minetest.set_node(pos, {name="air"})
			minetest.chat_send_player(name, "You already have a stocking at: ".. stocking_pos)
			return itemstack
		end
		meta:set_string("infotext", player:get_player_name().."'s Stocking")
		meta:set_string("owner", player:get_player_name())
		local timer = minetest.get_node_timer(pos)
		timer:start(5400)
	end,
	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local stocking_pos = mod_storage:get_string(owner.."_stocking_pos")
		local spos = minetest.string_to_pos(stocking_pos)
		
		if minetest.string_to_pos(stocking_pos) == pos then
			mod_storage:set_string(owner.."_stocking_pos", " ")
		end
	end,
	on_timer = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		minetest.chat_send_player(owner, "Your stocking has refilled")--Hooray
		local inv = meta:get_inventory()
		inv:set_stack("main", 1, christmas.random_reward())
		inv:set_stack("main", 2, christmas.random_reward())
		inv:set_stack("main", 3, christmas.random_reward())
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local timer = minetest.get_node_timer(pos)
		local owner = meta:get_string("owner")
		local playerinv = player:get_inventory()
		if player:get_player_name() ~= owner then
			minetest.chat_send_player(player:get_player_name(), "This isn't your stocking")--Imposter!!
			return itemstack
		end
		local inv = meta:get_inventory()
		if inv:is_empty("main") then
			local time = christmas.to_time(math.floor(timer:get_timeout() - timer:get_elapsed()))
			minetest.chat_send_player(owner, "Your stocking is empty. (refill in: "..time..")")--Whyyyyyyy??? 😭
		elseif not inv:is_empty("main") then
			local item1 = inv:get_stack("main", 1)
			local leftover1 = playerinv:add_item("main", item1)
			local item2 = inv:get_stack("main", 2)
			local leftover2 = playerinv:add_item("main", item2)
			local item3 = inv:get_stack("main", 3)
			local leftover3 = playerinv:add_item("main", item3)
			timer:start(5400)
		end
	end, 
})

minetest.register_node("christmas:lights", {
	description = "Christmas lights",
	drawtype = "signlike",
	tiles = {
		{
			name = "christmas_lights_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
	},
	inventory_image = "christmas_lights.png",
	wield_image = "christmas_lights.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	light_source = 3,
	selection_box = {
		type = "wallmounted",
	},
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, attached_node = 1},
	walkable = false,
})

------------------------------------ Christmas tree ------------------------------------
minetest.register_node("christmas:tree", {
	description = "Christmas Tree",
	tiles = {
			"christmas_tree_leaves.png"
	},
	inventory_image = "christmas_tree_inv.png",
	drawtype = "mesh",
	paramtype = "light",
	mesh = "christmas_tree.obj",
	groups = {snappy = 2, attached_node = 1},
	collision_box = {
		type = "fixed",
		fixed = {-0.625, -0.5, -0.625, 0.625, 2, 0.625},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.75, -0.5, -0.75, 0.75, 2.3125, 0.75},
	},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local pos1 = {x=pos.x, y=pos.y+1, z=pos.z}
		local pos2 = {x=pos.x, y=pos.y+2, z=pos.z}
		local node1 = minetest.get_node(pos1)
		local node2 = minetest.get_node(pos2)
		if node1.name ~= "air" or node2.name ~= "air" then
			minetest.set_node(pos, {name="air"})
			minetest.chat_send_player(placer:get_player_name(), "You need a 3 block tall space to place the tree")
			return itemstack
		end
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local item = minetest.registered_items[itemstack:get_name()]
		if item.groups.tree_bauble ~= nil then
			local pos2 = {x=pos.x, y=pos.y+1, z=pos.z}
			local name = minetest.get_node(pos2).name
			if minetest.registered_nodes[name].buildable_to then
				minetest.set_node(pos2, {name="christmas:ornament"})
			end
			itemstack:take_item()
		elseif item.groups.tree_topper ~= nil then
			local pos2 = {x=pos.x, y=pos.y+2, z=pos.z}
			local name = minetest.get_node(pos2).name
			if minetest.registered_nodes[name].buildable_to then
				minetest.set_node(pos2, {name="christmas:topper"})
			end
			itemstack:take_item()
		end
	end,
	on_destruct = function(pos)
		local pos1 = {x=pos.x, y=pos.y+1, z=pos.z}
		local pos2 = {x=pos.x, y=pos.y+2, z=pos.z}
		local name = minetest.get_node(pos1).name
		local name2 = minetest.get_node(pos2).name
		minetest.after(0.01, function()
			if name == "christmas:ornament" then
				minetest.set_node(pos1, {name="air"})
				minetest.add_item(pos1, "christmas:bauble_red")
			end
			if name2 == "christmas:topper" then
				minetest.set_node(pos2, {name="air"})
				minetest.add_item(pos2, "christmas:star")
			end
		end)
	end,
})

minetest.register_node("christmas:ornament", {
	description = "Bauble",
	tiles = {
			"christmas_bauble.png"
	},
	drawtype = "mesh",
	paramtype = "light",
	paramtype2 = "color",
	color = "red",
	mesh = "christmas_tree_balls.obj",
	groups = {not_in_creative_inventory = 1},
	walkable = false,
	pointable = false,
	on_construct = function(pos)
		local npos = {x=pos.x, y=pos.y-1, z=pos.z}
		local name = minetest.get_node(npos).name
		if name ~= "christmas:tree" then
			minetest.set_node(pos, {name="air"})
		end
	end,
})
minetest.register_node("christmas:topper", {
	description = "Topper",
	tiles = {
			"christmas_star.png"
	},
	drawtype = "mesh",
	paramtype = "light",
	light_source = 8,
	paramtype2 = "color",
	color = "yellow",
	mesh = "christmas_star.obj",
	groups = {not_in_creative_inventory = 1},
	walkable = false,
	pointable = false,
	on_construct = function(pos)
		local npos = {x=pos.x, y=pos.y-2, z=pos.z}
		local name = minetest.get_node(npos).name
		if name ~= "christmas:tree" then
			minetest.set_node(pos, {name="air"})
		end
	end,
})



christmas.register_reward("christmas:lights",          {min=1, max=5},   0.5)
christmas.register_reward("christmas:candy_cane",      {min=3, max=15},  0.15)
christmas.register_reward("christmas:eggnog",          {min=1, max=3},   0.15)
christmas.register_reward("christmas:gingerbread_man", {min=1, max=9},   0.5)
christmas.register_reward("christmas:mince_pie",       {min=6, max=12},  0.3)
christmas.register_reward("christmas:tree",            {min=0, max=1},   0.15)
christmas.register_reward("christmas:bauble_red",      {min=0, max=1},   0.15)
christmas.register_reward("christmas:star",            {min=0, max=1},   0.1)
christmas.register_reward("christmas:sugar",           {min=1, max=7},   0.36)
christmas.register_reward("christmas:present",         {min=1, max=2},   0.26)




