-- See through nodes
local rocks = { 'mcl_core:stone', 'mcl_core:cobble', 'mcl_core:diorite', 'mcl_core:granite',
				'mcl_core:andesite', 'mcl_deepslate:deepslate', 'mcl_nether:netherrack', 'mcl_blackstone:basalt' }
local c_ids = {}
for _, rock in ipairs(rocks) do
	local c_id = minetest.get_content_id(rock)
	c_ids[c_id] = true
end

local drop = 'mcl_core:cobble'

-- expose api
xray = {}

-- the range of the xray effect
xray.range = 7

-- how long before the nodes turn back to stone
xray.timer = 1

-- mode is used to store the xray mode for each player
xray.mode = false

-- should we spew out log messages?
xray.debug = false

-- log
xray.log = function(message)
	if not xray.debug then
		return
	end
	minetest.log('action', '[xray] '..message)
end

-- register_node
minetest.register_node('xray:stone', {
	description = 'Xray Stone',
	tiles = {'xray_stone.png'},
	is_ground_content = true,
	groups = {pickaxey=1, material_stone=1},
	_mcl_blast_resistance = 0.4,
	_mcl_hardness = 0.4,
	drop = drop,
	legacy_mineral = true,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	drawtype = 'glasslike',
	paramtype = 'light',
	light_source = 12,
	walkable = true,
	use_texture_alpha = 'clip'
})

local c_xray = minetest.get_content_id('xray:stone')
--[[local c_sto = minetest.get_content_id('mcl_core:stone')
local c_cob = minetest.get_content_id('mcl_core:cobble')
local c_dio = minetest.get_content_id('mcl_core:diorite')
local c_gra = minetest.get_content_id('mcl_core:granite')
local c_and = minetest.get_content_id('mcl_core:andesite')
local c_dsl = minetest.get_content_id('mcl_deepslate:deepslate')
local c_nrk = minetest.get_content_id('mcl_nether:netherrack')]]

-- replace stone with xray
xray.replace = function(pos)
	local count = 0

	-- Gen pos1 and pos2
	pos = vector.round(pos)
	local pos1 = vector.subtract(pos, xray.range)
	local pos2 = vector.add(pos, xray.range)

	-- Read data into LVM
	--local vm = VoxelManip(pos1, pos2)
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(pos1, pos2)
	local area = VoxelArea:new({
		MinEdge = emin,
		MaxEdge = emax
	})
	local data = vm:get_data()
	local orig = vm:get_data()

	-- Modify data
	--[[for i, node in ipairs(data) do
		if c_ids[node] then
			data[i] = c_xray
			count = count + 1
		end
	end]]
	for z = pos1.z, pos2.z do
		for y = pos1.y, pos2.y do
			for x = pos1.x, pos2.x do
				local vi = area:index(x, y, z)
				if c_ids[data[vi]] then
					data[vi] = c_xray
					count = count + 1
				end
			end
		end
	end

	-- Write data
	vm:set_data(data)
	vm:write_to_map()
	
	minetest.after(xray.timer, xray.restore, pos, orig)

	-- Log
	xray.log('Replaced ' .. count .. ' default:stone nodes near ' .. minetest.pos_to_string(pos))
end

--[[local function player_in_range(pos)
	for _, object in ipairs(minetest.get_objects_inside_radius(pos, xray.range + 2)) do
		if object:is_player() and xray.mode then
			return true
		end
	end
	return false
end]]

-- restore xray to stone
xray.restore = function(pos, orig)
	--[[if player_in_range(pos) then
		return
	end]]

	local count = 0

	-- Bulk update nodes around
	local pos1 = vector.subtract(pos, xray.range)
	local pos2 = vector.add(pos, xray.range)

	-- Read data into LVM
	--local vm = VoxelManip(pos1, pos2)
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(pos1, pos2)
	local area = VoxelArea:new({
		MinEdge = emin,
		MaxEdge = emax
	})
	local data = vm:get_data()

	-- Modify data
	--[[for i, node in ipairs(data) do
		if data[i] == c_xray then
			data[i] = orig[i]
			count = count + 1
		end
	end]]
	for z = pos1.z, pos2.z do
		for y = pos1.y, pos2.y do
			for x = pos1.x, pos2.x do
				local vi = area:index(x, y, z)
				if data[vi] == c_xray then
					data[vi] = orig[vi]
					count = count + 1
				end
			end
		end
	end
	vm:set_data(data)
	vm:write_to_map()

	-- Log
	xray.log('Restored ' .. count .. ' xray:stone nodes near ' .. minetest.pos_to_string(pos))
end

-- register_chatcommand
minetest.register_chatcommand('xray', {
	params = 'on | off',
	description = 'Make stone invisible.',
	privs = {shout=true},
	func = function(name, param)
		if param == 'on' then xray.mode = true
			minetest.chat_send_all(name .. ' turned xray on.')
			--xray.run(xray.replace)
		elseif param == 'off' then xray.mode = false
			minetest.chat_send_all(name .. ' turned xray off.')
			--xray.run(xray.restore)
		else
			minetest.chat_send_player(name, 'Please enter on or off.')
		end
	end,
})

minetest.register_chatcommand('x', {
	--params = '[range]',
	description = 'Make stone invisible.',
	privs = {shout=true},
	func = function(name, param)
		if xray.mode then
			xray.mode = false
			minetest.chat_send_all(name .. ' turned xray off.')
		else
			xray.mode = true
			minetest.chat_send_all(name .. ' turned xray on.')
			--[[if param then
				xray.range = tonumber(param)
				minetest.chat_send_player(name, 'Xray range changed to '..param)
			end]]
		end
	end,
})

minetest.register_chatcommand('xr', {
	params = 'range',
	description = 'Set xray range.',
	privs = {shout=true},
	func = function(name, param)
		if tonumber(param) > 0 then
			xray.range = tonumber(param)
			minetest.chat_send_all(name .. ' set xray range to ' .. param)
		end
	end,
})

-- register_globalstep - replace default:stone with xray:stone in range of players with xray
local timer = 0 
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < xray.timer then return end
--xray.run = function(func)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pos = player:get_pos()
		if xray.mode then
			xray.replace(pos)
		end
	end
	timer = 0
end)

--[[ register_abm - restore any stray xray:stone nodes to default:stone
minetest.register_abm({
	nodenames = {'xray:stone'},
	interval = xray.timer,
	chance = 1,
	action = function(pos) xray.restore(pos) end,
})]]
