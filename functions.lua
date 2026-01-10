function christmas.get_present_formspec(pos)
	local source = "nodemeta:"..pos.x .. "," .. pos.y .. "," .. pos.z
	
	local formspec = ""
	if core.global_exists("mcl_formspec") then
		formspec = formspec..
		"size[9,9]"..
		mcl_formspec.get_itemslot_bg(4, 2.5, 1, 1) ..
		"list["..source..";gift;4,2.5;1,1;]" ..
		mcl_formspec.get_itemslot_bg(0, 4.85, 9, 1) ..
		"list[current_player;main;0,4.85;9,1;]" ..
		mcl_formspec.get_itemslot_bg(0, 6.08, 9, 3) ..
		"list[current_player;main;0,6.08;9,3;9]"
	else
		formspec = formspec..
		"size[8,9]"..
		"list["..source..";gift;3.5,2.5;1,1;]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]"
	end

	formspec = formspec ..
		"listring[".. source ..";gift]" ..
		"listring[current_player;main]" 
	return formspec
end

function christmas.to_time(time)
  local minutes = math.floor(time / 60)
  local seconds = math.floor(time - minutes * 60)
  local answer = string.format("%02d:%02d", minutes, seconds)
  return answer
end

function christmas.register_reward(item, quantity, rarity)
	table.insert(christmas.rewards, {item=item, quantity=quantity, rarity=rarity})
end

function christmas.random_reward()--Adapted from Dungeontest room selection "dungeon_rooms.random_roomdata"
	local pool = christmas.rewards

	local candidates = {}
	local raresum = 0

	for i=1, #pool do
		local reward = pool[i]
		table.insert(candidates, reward)
		raresum = raresum + reward.rarity
	end

	local rarepick = math.random() * raresum
	local rarecount = 0
	for c=1, #candidates do
		rarecount = rarecount + christmas.rewards[c].rarity
		local q = christmas.rewards[c].quantity
		local quantity = math.random(q.min, q.max)
		if rarecount >= rarepick then
			return ItemStack(christmas.rewards[c].item.." "..quantity)
		end
	end
end

function christmas.eat_candy(hp_change, sugar_time, replace_with_item)
    return function(itemstack, user, pointed_thing)
	    if not user or not user:is_player() then return itemstack end
	    local name = user:get_player_name()
		local p = christmas.players[name]
		p.sugar_rush_time = p.sugar_rush_time + sugar_time
        return core.do_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
    end
end

function christmas.save_stocking_timers()
	for name, time in pairs(christmas.stocking_timers) do
		if time > 0 then
			christmas.storage:set_int(name, math.floor(time))
		end
	end
end

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if not christmas.stocking_timers[name] then
		christmas.stocking_timers[name] = 0
	end
	christmas.players[name] = {
		hud = {},
		rush = false,
		sugar_rush_time = 0
	}
end)

core.register_on_shutdown(function()
	christmas.save_stocking_timers()
end)

core.register_on_leaveplayer(function(player)
	christmas.save_stocking_timers()
end)

-- Periodically save stocking timers
local timer_duration = 5
local timer_save = timer_duration
core.register_globalstep (function(dtime)
	timer_save = timer_save - dtime
	if timer_save > 0 then
		for name, time in pairs(christmas.stocking_timers) do
			if time > 0 then
				christmas.stocking_timers[name] = time - dtime
			end
		end
	end
	if timer_save <= 0 then
		christmas.save_stocking_timers()
		timer_save = timer_duration
	end

	-- Sugar Rush
	for _, player in ipairs(core.get_connected_players()) do
		local p = christmas.players[player:get_player_name()]
		if p.sugar_rush_time > 0 then
			p.sugar_rush_time = p.sugar_rush_time - dtime
			if p.rush then
				player:hud_change(p.hud.sugar_rush_time, "text", christmas.to_time(p.sugar_rush_time))
			else
				if p.sugar_rush_time > 60 then
					p.hud.ui = player:hud_add({
						hud_elem_type = "image",
						text      = "christmas_sugar_rush_hud.png",
						position  = {x = 1, y = 0},
						offset    = {x = 0, y = 0},
						scale     = { x = 4, y = 4},
						alignment = { x = -1, y = 1 },
					})
					p.hud.sugar_rush_time = player:hud_add({
						hud_elem_type = "text",
						position  = {x = 1, y = 0},
						offset    = {x = -120, y = 39*4},
						text      = christmas.to_time (p.sugar_rush_time),
						number = 0xffffff,
						scale     = { x = 10, y = 10},
						alignment = { x = 0, y = 1},
					})
					player:set_physics_override({
						speed = 2.5,
					})
					p.rush = true
				end
			end
		end
		if p.sugar_rush_time <= 0 and p.rush then
			player:set_physics_override({
				speed = 1,
			})
			if p.hud.ui then
				player:hud_remove(p.hud.ui)
			end
			if p.hud.sugar_rush_time then
				player:hud_remove(p.hud.sugar_rush_time)
			end
		end
	end
end)
