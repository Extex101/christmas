

local function capitalize(str)
    return str:gsub("_", " "):gsub("(%a)(%w*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

core.register_entity("christmas:tree_ornaments", {
	initial_properties = {
		physical = false,
		collide_with_objects = false,
		pointable = false,
		visual = "mesh",
		visual_size = {x=10, y=10},
	},
	get_staticdata = function(self)
		return core.serialize({
            mesh = self.mesh,
            texture = self.texture,
            color = self.color,
			drop = self.drop,
			pos = self.pos,
			offset = self.offset
		})
	end,
	on_activate = function(self, staticdata)
		self.object:set_armor_groups({immortal=1})

		local data = core.deserialize(staticdata)
		if data then
            self.mesh = data.mesh
            self.color = christmas.dyes[data.color]
            self.texture = data.texture
			if self.color then
				self.texture = self.texture.."^[multiply:"..self.color
			end
			self.drop = data.drop
			self.pos = data.pos or self.object:get_pos()
			self.offset = data.offset or {x=0, y=0, z=0}
            self.object:set_properties({
                mesh = self.mesh,
                textures = {self.texture},
                backface_culling = false,
                visual_size = {x=10, y=10},
            })
		end
		self.timer = 0
		if not self.pos or not self.mesh or not self.texture then
			self.object:remove()
			return
		end
		if self.drop and core.get_node(self.pos).name ~= "christmas:tree" then
			self.remove(self)
			return
		end
	end,
	on_step = function(self, dtime)
		self.object:set_velocity({x=0, y=0, z=0})
		self.object:set_acceleration({x=0, y=0, z=0})
		self.object:set_pos(vector.add(self.pos, self.offset))
		self.timer = self.timer + dtime
		if self.timer > 1 then
			if core.get_node(self.pos).name ~= "christmas:tree" then
				self.remove(self)
				return
			end
			self.timer = 0
		end
	end,
	remove = function(self)
        if not self.drop then return end
        local height = math.random()*2.5 + 0.25
		local dir = math.random() * math.pi * 2
		local random_pos = vector.add(self.pos, {x=math.cos(dir), y=height, z=math.sin(dir)})
        core.add_item(random_pos, self.drop)
		self.object:remove()
	end,
})

local function get_tree_decor(pos)
	local meta = core.get_meta(pos)
	local decor = meta:get_string("decorations")
	local tbl = core.deserialize(decor)
	if not tbl then return false end
	for k,v in pairs(tbl) do
		if core.objects_by_guid[v] == nil then
			tbl[k] = nil
		end
	end
	return tbl
end

core.register_node("christmas:tree", {
	description = "Christmas Tree",
	tiles = {
			"christmas_tree.png"
	},
	use_texture_alpha = "clip",
	inventory_image = "christmas_tree_inv.png",
	drawtype = "mesh",
	paramtype = "light",
	mesh = "christmas_tree.obj",
	groups = {snappy = 2, attached_node = 3, oddly_breakable_by_hand = 2},
	collision_box = {
		type = "fixed",
		fixed = {-0.36, -0.5, -0.36, 0.36, 3, 0.36},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.36, -0.5, -0.36, 0.36, 3, 0.36},
	},
	sounds = {
		place = {name = "default_place_node", gain = 1.0},
		footstep = {name = "default_grass_footstep", gain = 0.45},
		dig = {name = "default_grass_footstep", gain = 0.7},
		dug = {name = "default_dig_choppy", gain = 0.4}
	},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		core.get_meta(pos):set_string("decorations", core.serialize({}))
		for y = 1, 3 do
			local node = core.get_node({x=pos.x, y=pos.y + y, z=pos.z})
			if node.name ~= "air" then
				core.set_node(pos, {name="air"})
				core.chat_send_player(placer:get_player_name(), "You need a 3 block tall space to place the tree")
				return itemstack
			end
		end
	end,
	on_rightclick = function(pos, tree_node, player, itemstack, pointed_thing)
		if core.is_protected(pos, player:get_player_name()) then
			return itemstack
		end
		local creative = core.is_creative_enabled(player:get_player_name()) or core.check_player_privs(player, "creative")
		local def = core.registered_items[itemstack:get_name()]
		local meta = core.get_meta(pos)
		local decor = get_tree_decor(pos) or {}
		if def.on_christmas_attach ~= nil then
            local ref, new_decor = def.on_christmas_attach(pos, player, itemstack, tree_node, decor)
            if ref then
                if new_decor then
                    meta:set_string("decorations", core.serialize(new_decor))
                end
                if not creative then
                    itemstack:take_item()
                end
            end
        end
        return itemstack
	end,
	on_punch = function(pos, node, player)
		if core.is_protected(pos, player:get_player_name()) or not player:get_player_control().sneak then
			return
		end
		local decor = get_tree_decor(pos)
		if not decor then return end
		for _, guid in pairs(decor) do
			local ent = core.objects_by_guid[guid]:get_luaentity()
			ent.remove(ent)
		end
		local light_pos = {x=pos.x, y=pos.y+1, z=pos.z}
		local light_node = core.get_node(light_pos)
		if light_node.name:match("christmas:tree_lights_") then
			local def = core.registered_nodes[light_node.name]
			core.dig_node(light_pos, player)
			local height = math.random()*2.5 + 0.25
			local dir = math.random() * math.pi * 2
			local random_pos = vector.add(pos, {x=math.cos(dir), y=height, z=math.sin(dir)})
			core.add_item(random_pos, def.drop)
		end
		core.get_meta(pos):set_string("decorations", core.serialize({}))
	end,
	on_destruct = function(pos)
		local decor = get_tree_decor(pos)
		if not decor then return end
		for _, guid in pairs(decor) do
			local ent = core.objects_by_guid[guid]:get_luaentity()
			ent.remove(ent)
		end
	end,
})

if core.global_exists("mesecon") and core.get_modpath("mesecons_mvps") and mesecon.register_mvps_stopper then
	mesecon.register_mvps_stopper("christmas:tree")
end

local paper = xcompat.materials.paper

for name, col in pairs(christmas.dyes) do
    local title = capitalize(name)
	local texture = "christmas_bauble_inv.png^[multiply:"..col.."^christmas_bauble_inv_shading.png"
	-- ORNAMENTS
	core.register_craftitem("christmas:ornament_"..name, {
		description = title.. " Christmas Ornament",
		inventory_image = texture,
		wield_image = texture,
        on_christmas_attach = function(pos, player, itemstack, tree, decor)
            -- Check if ornament1 is already filled
            local slot = not decor.ornaments1 and "ornaments1" or "ornaments2"
            -- Double check that the selected slot is empty
            if not decor[slot] then
                local obj = core.add_entity(pos, "christmas:tree_ornaments", core.serialize({
                    mesh = "christmas_tree_ornaments.obj",
                    texture = "christmas_bauble.png",
                    color = name,
                    drop = itemstack:get_name()
                }))
                if slot == "ornaments2" then
                    obj:set_rotation({x=0, y=math.pi/2, z=0})
                end
                decor[slot] = obj:get_guid()
                return obj, decor
            end
            return false, decor
        end,
	})

	-- TINSEL
    core.register_craftitem("christmas:tinsel_"..name, {
		description = title.." Tinsel",
		inventory_image = "christmas_tinsel_inv.png^[multiply:"..col,
		wield_image = "christmas_tinsel_inv.png^[multiply:"..col,
		tiles = {"christmas_tinsel_"..name..".png"},
        on_christmas_attach = function(pos, player, itemstack, tree, decor)
			if decor.tinsel then
				return false, decor
			end
			local obj = core.add_entity(pos, "christmas:tree_ornaments", core.serialize({
				mesh = "christmas_tree_wrap.obj",
				texture = "christmas_tinsel_"..name..".png",
				drop = itemstack:get_name(),
				offset = {x=0, y=1, z=0}
			}))
			obj:set_rotation({x=0, y=math.pi, z=0})
			decor.tinsel = obj:get_guid()
			return obj, decor
        end,
	})
	core.register_node("christmas:angel_"..name, {
		description = title.. " Angel",
		drawtype = "mesh",
		mesh = "christmas_angel.obj",
		tiles = {
			{name = "christmas_angel_"..name..".png", backface_culling = false}
		},
		use_texture_alpha = "clip",
		paramtype = "light",
		paramtype2 = "degrotate",
		light_source = 10,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			local dir = math.deg(placer:get_look_horizontal())/1.5
			core.swap_node(pos, {name = "christmas:angel_"..name, param2 = dir})
		end,
		sounds = {
			place = {name = "default_place_node", gain = 1.0}
		},
		on_christmas_attach = function(pos, player, itemstack, tree, decor)
			if decor.topper then
				return false, decor
			end
			local obj = core.add_entity(pos, "christmas:tree_ornaments", core.serialize({
				mesh = "christmas_angel.obj",
				texture = "christmas_angel_"..name..".png",
				drop = itemstack:get_name(),
				offset = {x=0, y=3.35, z=0},
			}))
			local rot = player and player:get_look_horizontal() or 0
			obj:set_rotation({x=0, y=rot, z=0})
			decor.topper = obj:get_guid()
			return obj, decor
		end,
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
		groups = {oddly_breakable_by_hand = 3},
	})

	core.register_node("christmas:present_"..name, {
		description = "Empty "..title.." Present",
		tiles = {"christmas_present_"..name..".png"},
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "degrotate",
		mesh = "christmas_present.obj",
		groups = {oddly_breakable_by_hand = 3, attached_node = 1},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.3125, -0.5, -0.3125, 0.3125, 0.125, 0.3125},
			}
		},
		on_construct = function(pos, itemstack, placer, pointed_thing)
			local meta = core.get_meta(pos)
			meta:set_string("infotext", "Christmas Present")
			meta:set_string("owner", "")
			local inv = meta:get_inventory()
			inv:set_size("gift", 1)
		end,
		on_dig = function(pos, node, player)
			if core.is_protected(pos, player:get_player_name()) then
				return false
			end
			local meta = core.get_meta(pos)
			local contents = meta:get_inventory():get_stack("gift", 1)
			local inv = player:get_inventory()
			local item = ItemStack("christmas:present_"..name)
			local imeta = item:get_meta()
			if contents:get_count() > 0 then
				imeta:set_string("gift", contents:to_string())
				imeta:set_string("description", "Wraped Present from " .. meta:get_string("owner"))
			end
			if inv:room_for_item("main", item) then
				inv:add_item("main", item)
				core.remove_node(pos)
				return true
			else
				core.add_item(pos, item)
			end
		end,
		on_place = function(itemstack, placer, pointed_thing)
			if not placer or not placer:is_player() then
				return itemstack
			end
			local player_name = placer:get_player_name()

			-- Find the placement position
			local pos = pointed_thing.under
			local node = core.get_node(pos)
			local def = core.registered_nodes[node.name]
			if def.on_rightclick then
				return def.on_rightclick(pos, node, placer, itemstack, pointed_thing) or itemstack
			end
			if not core.registered_nodes[node.name].buildable_to then
				pos = pointed_thing.above
				node = core.get_node(pos)
			end
			
			def = core.registered_nodes[node.name]
			local replacing = node.name ~= "air"
			local under = core.registered_nodes[core.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name]

			if core.is_protected(pos, player_name) and replacing or -- Disallow replacing in protected areas
			not replacing and def.groups.attached_node or -- Disallow placing on attached nodes
			not under.walkable then -- Disallow placing without a solid node beneath
				return itemstack
			end

			if not core.is_creative_enabled(player_name) then
				itemstack:take_item()
			end
			
			local dir = math.floor(math.deg(placer:get_look_horizontal())/1.5)
			core.set_node(pos, {name="christmas:present_"..name, param2=dir})
			local meta = core.get_meta(pos)
			local gift = itemstack:get_meta():get_string("gift")
			if gift then
				meta:get_inventory():set_stack("gift", 1, ItemStack(gift))
			end
			meta:set_string("owner", placer:get_player_name() or "")
			meta:set_string("infotext", "Present from ".. meta:get_string("owner"))

			return itemstack
		end,
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			core.show_formspec(player:get_player_name(),
				"christmas:present",
			christmas.get_present_formspec(pos))
		end,
	})
	local dye = xcompat.materials["dye_"..name]
	if name == "gold" then
		dye = xcompat.materials.gold_ingot
	end
	core.register_craft({
		output = "christmas:present_"..name,
		recipe = {
			{paper,paper,paper},
			{paper,dye,paper},
			{paper,paper,paper},
		},
	})
end

local valid_drawtypes = {
	normal = true,
	nodebox = true,
	glasslike = true,
	glasslike_framed = true,
	glasslike_framed_optional = true,
	allfaces = true,
	allfaces_optional = true,
	plantlike_rooted = true,
}

for name, col in pairs(christmas.light_dyes) do
	local title = capitalize(name)
	core.register_node("christmas:lights_"..name, {
		description = title.." Christmas lights",
		drawtype = "nodebox",
		tiles = {
			{
				name = "christmas_lights_base_animated.png^(christmas_lights_bulbs_animated.png^[multiply:"..col..")",
				backface_culling = true,
				align_style = "world",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0,
				},
			},
		},
		use_texture_alpha = "clip",
		inventory_image = "christmas_lights_inv.png^(christmas_lights_inv_color.png^[multiply:"..col..")",
		wield_image = "christmas_lights_inv.png^(christmas_lights_inv_color.png^[multiply:"..col..")",
		paramtype = "light",
		paramtype2 = "wallmounted",
		light_source = 14,
		node_box = {
			type = "connected",
			connect_front = {-0.5, -0.45, -0.49, 0.5, 0.25, -0.49},
			connect_left = {-0.49, -0.45, -0.5, -0.49, 0.25, 0.5},
			connect_back = {-0.5, -0.45, 0.49, 0.5, 0.25, 0.49},
			connect_right = { 0.49, -0.45, -0.5, 0.49, 0.25, 0.5},
		},
		selection_box = {
			type = "connected",
			connect_front = {-0.5, -0.25, -0.49, 0.5, 0.35, -0.4},
			connect_left = {-0.49, -0.25, -0.5, -0.4, 0.35, 0.5},
			connect_back = {-0.5, -0.25, 0.4, 0.5, 0.35, 0.49},
			connect_right = { 0.4, -0.25, -0.5, 0.49, 0.35, 0.5},
		},
		connects_to = { "group:snappy", "group:cracky", "group:choppy", "group:crumbly"},
		groups = {dig_immediate = 3, attached_node = 1},
		walkable = false,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			local dir = vector.subtract(pointed_thing.under, pointed_thing.above)
			local def = core.registered_nodes[core.get_node(pointed_thing.under).name]
			if valid_drawtypes[def.drawtype] and dir.y == 0 then
				return false
			end
			core.set_node(pos, {name="air"})
			return true
		end,
        on_christmas_attach = function(pos, player, itemstack, tree, decor)
            local wrap_pos = {x=pos.x, y=pos.y+1, z=pos.z}
            local node = core.get_node(wrap_pos)
            if node.name ~= "air" then
                return false, false
            end
            core.set_node(wrap_pos, {name="christmas:tree_lights_"..name})
            return true, false
        end,
	})
	core.register_node("christmas:tree_lights_"..name, {
		drawtype = "mesh",
		tiles = {{
			name = "christmas_tree_lights_base.png^(christmas_tree_lights_bulbs.png^[multiply:"..col..")",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 77,
				aspect_h = 16,
				length = 2.0,
			},
		}},
		use_texture_alpha = "clip",
		paramtype = "light",
		light_source = 14,
		mesh = "christmas_tree_wrap.obj",
		drop = "christmas:lights_"..name,
		groups = {not_in_creative_inventory = 1, attached_node = 3},
		walkable = false,
		pointable = false,
	})
end

core.register_craftitem("christmas:star", {
	description = "Topper",
	inventory_image = "christmas_star_inv.png",
	wield_image = "christmas_star_inv.png",
	on_christmas_attach = function(pos, player, itemstack, tree, decor)
		if decor.topper then
			return false, decor
		end
		local obj = core.add_entity(pos, "christmas:tree_ornaments", core.serialize({
			mesh = "christmas_star.obj",
			texture = "christmas_star.png",
			drop = itemstack:get_name(),
			offset = {x=0, y=0, z=0},
		}))
		local rot = player and player:get_look_horizontal() or 0
		obj:set_rotation({x=0, y=rot, z=0})
		decor.topper = obj:get_guid()
		return obj, decor
	end,
})

-- Update old items and nodes from pre-2.0 versions
core.register_lbm({
	label = "Update pre-2.0 tree ornaments",
	name = "christmas:update_old_tree_ornaments",
	nodenames = {"christmas:tree"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = core.get_meta(pos)
		if not meta:contains("decorations") then
			core.get_meta(pos):set_string("decorations", core.serialize({}))
		end
		local topper = core.get_node({x=pos.x, y=pos.y+2, z=pos.z})
		local bauble = core.get_node({x=pos.x, y=pos.y+1, z=pos.z})
		if topper.name == "christmas:topper" then
			local new_decor = core.registered_items["christmas:star"].on_christmas_attach(pos, nil,
				ItemStack("christmas:star"), node, get_tree_decor(pos))
			if new_decor then
				meta:set_string("decorations", core.serialize(new_decor))
			end
			core.set_node({x=pos.x, y=pos.y+2, z=pos.z}, {name="air"})
		end

		if bauble.name == "christmas:ornament" then
			local new_decor = core.registered_items["christmas:ornament_red"].on_christmas_attach(pos, nil,
				ItemStack("christmas:ornament_red"), node, get_tree_decor(pos))
			if new_decor then
				meta:set_string("decorations", core.serialize(new_decor))
			end
			core.set_node({x=pos.x, y=pos.y+1, z=pos.z}, {name="air"})
		end
	end,
})

core.register_lbm({
	label = "Update presents to present_red",
	name = "christmas:update_presents",
	nodenames = {"christmas:present"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		local contents = inv:get_stack("main", 1)
		inv:set_size("gift", 1)
		inv:set_stack("gift", 1, contents)
		inv:set_size("main", 0)
	end,
})

core.register_alias("christmas:lights", "christmas:lights_red")
core.register_alias("christmas:bauble_red", "christmas:ornament_red")
core.register_alias("christmas:present", "christmas:present_red")

