--Okay, so we're making a Rubik's Cube!
--Let's start with the basics.
local colors = {
	'green',  -- +Y
	'blue',   -- -Y
	'red',    -- +X
	'orange', -- -X
	'white',  -- +Z
	'yellow', -- -Z
}

local materials = {} --what you craft the spawner with
local textures = {} --what is on the cubelets
local spawntex = {} --what is on the spawner
for color = 1, #colors do
	materials[color] = 'wool:'..colors[color]
	textures[color] = 'wool_'..colors[color]..'.png'
	spawntex[color] = textures[color]..'^rubiks_three.png'
	--textures[color] = textures[color]..'^rubiks_outline.png'
end

--is this the center of a face, on the edge, or is it a corner?
function get_axesoff(pos)
	local meta = minetest.env:get_meta(pos)
	local string = meta:get_string('cube_center')
	if string ~= nil then
		center = minetest.string_to_pos(string)
		if center ~= nil then
			dir = {x=pos.x-center.x, y=pos.y-center.y, z=pos.z-center.z}
			axesoff = (dir.x ~= 0 and 1 or 0)
			+ (dir.y ~= 0 and 1 or 0)
			+ (dir.z ~= 0 and 1 or 0)
			return axesoff
		end
	end
end

--this isn't in the cubelets' on_construct
--because the meta already needs to be set
function set_cubelet_formspec(pos, size)
	if get_axesoff(pos) == 1 then
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec",
			"size["..size..","..size.."]"..
			
			"image_button_exit[0,0;1,1;rubiks_larger.png;larger;]"..
			"image_button_exit[0,1;1,1;rubiks_reset.png;reset;]"..
			--"image_button_exit[0,2;1,1;rubiks_scramble.png;scramble;]"..
			"image_button_exit[0,2;1,1;rubiks_smaller.png;smaller;]"..
			
			"image_button_exit[1,0;1,1;rubiks_L3.png;L3;]"..
			"image_button_exit[1,1;1,1;rubiks_L1.png;L1;]"..
			"image_button_exit[1,2;1,1;rubiks_L2.png;L2;]"..
			
			"image_button_exit[2,0;1,1;rubiks_R3.png;R3;]"..
			"image_button_exit[2,1;1,1;rubiks_R1.png;R1;]"..
			"image_button_exit[2,2;1,1;rubiks_R2.png;R2;]"..
		'')
	end
end

function expand_cube(pos, spawn)
	for x = pos.x-1, pos.x+1 do
	for y = pos.y-1, pos.y+1 do
	for z = pos.z-1, pos.z+1 do
	pos2 = {x=x, y=y, z=z}
		if spawn then --create
			--don't overwrite the spawner
			if not(pos2.x==pos.x and pos2.y==pos.y and pos2.z==pos.z) then
				--always starts the same direction
				name = 'rubiks:cubelet1'
				minetest.env:add_node(pos2, {name = name})
				--keep track of center for the purpose of rotating the cube
				local meta = minetest.env:get_meta(pos2)
				meta:set_string('cube_center',
					minetest.pos_to_string(pos)
				)
				set_cubelet_formspec(pos2, 3)
			end
		else --delete
			minetest.env:remove_node(pos2)
		end
	end
	end
	end
	if create then
		--keep a record so you can't get two cubes from one, or something like that
		local meta = minetest.env:get_meta(pos)
		meta:set_int('has_spawned', 1)
	end
end

--can't make a rubik's cube without the cube
minetest.register_node('rubiks:cube', {
	--spawner because I don't get the uv pos yet
	description  = "Rubik's Cube",
	tiles = spawntex,
	--show green, yellow, red sides to look 3d in inventory
	inventory_image = minetest.inventorycube(spawntex[1], spawntex[6], spawntex[3]),
	--want it to be diggable, quickly
	groups = {crumbly=3},
	on_punch = function(pos, node, puncher)
		for x = pos.x-1, pos.x+1 do
		for y = pos.y-1, pos.y+1 do
		for z = pos.z-1, pos.z+1 do
			if not(pos.x==x and pos.y==y and pos.z==z) then
				if minetest.env:get_node({x=x, y=y, z=z}).name ~= 'air' then
					--put it on a pedestal then remove the pedestal
					minetest.chat_send_player(puncher:get_player_name(), "Clear some space for Rubik's cube to expand")
					return
				end
			end
		end
		end
		end
		--surrounded by air, so
		expand_cube(pos, true)
	end,
	can_dig = function(pos, digger)
		--digging the center of a spawned cube yields
		--an extra cube without this - don't cheat when flying
		local meta = minetest.env:get_meta(pos)
		if meta:get_int('has_spawned') == 1 then
			return false
		end
		return true
	end,

})

--100% wool, need a way to get wool now.
minetest.register_craft({
	type = "shapeless",
	output = "rubiks:cube",
	recipe = materials,
})

--from the tiles of a node definition, get the actual tiles based on the facedir
function facedir_to_tiles(tilestocopy, facedir)
	--copying tables is annoying
	tiles = {unpack(tilestocopy)}
	--minus one because an equal facedir doesn't need rotating
	for f = 0, facedir-1 do
		--+Y, -Y, +X, -X, +Z, -Z
		placeholder = tiles[3]
		tiles[3] = tiles[5]
		tiles[5] = tiles[4]
		tiles[4] = tiles[6]
		tiles[6] = placeholder
	end
	return tiles
end

--I have the colors of two sides, so give me the cubelet that has that
function match_cubelet(matchtiles)
	--for rotation "axis" one, do
	for topcolor = 1, 6 do
	nodetiles = {unpack(cubelettiles[topcolor])}
	--for rotation "axis" two, do
	for facedir = 0, 3 do
	testtiles = facedir_to_tiles(nodetiles, facedir)
		for tile = 1, 6 do
			--unless it matches or isn't a side that is being checked for a match, continue
			if not(
				matchtiles[tile] == testtiles[tile] or
				matchtiles[tile] == nil
			) then break
			elseif tile == 6 then
				--match found
				return 'rubiks:cubelet'..topcolor, facedir
			end
		end
	end
	end
	print("Couldn't rotate cubelet! Assume crash position!")
end

function rotate_cube(pos, dir, clockwise, layer)
	--save cube to rotate without losing data
	cube = {}
	for x = -1, 1 do cube[x] = {}
	for y = -1, 1 do cube[x][y] = {}
	for z = -1, 1 do
		--read absolute position, save relative position
		pos2 = {x=pos.x+x, y=pos.y+y, z=pos.z+z}
		cube[x][y][z] = {
			node = minetest.env:get_node(pos2),
			meta = minetest.env:get_meta(pos2):to_table()
		}
	end
	end
	end

	--what side of the cube will be rotated on what axes
	loadpos, axes = {0, 0, 0}, {}
	if dir.x ~= 0 then
		loadpos[1] = dir.x
		for l=1, layer-1 do
			loadpos[1] = loadpos[1] - dir.x
		end
		axes[1] = 3--z
		axes[2] = 2--y
	end
	if dir.y ~= 0 then
		loadpos[2] = dir.y
		for l=1, layer-1 do
			loadpos[2] = loadpos[2] - dir.y
		end
		axes[1] = 1--x
		axes[2] = 3--z

	end
	if dir.z ~= 0 then
		loadpos[3] = dir.z
		for l=1, layer-1 do
			loadpos[3] = loadpos[3] - dir.z
		end
		axes[1] = 2--y
		axes[2] = 1--x
	end

	if dir.x == -1 or dir.y == -1 or dir.z == -1 then
		clockwise = not clockwise
		--still clockwise, just from the opposite perspective
	end

	--start rotating
	for firstaxis = -1, 1 do loadpos[axes[1]] = firstaxis
	for secondaxis = -1, 1 do loadpos[axes[2]] = secondaxis

		--don't lose data here either
		writepos = {unpack(loadpos)}

		--rotate around center of face
		writepos[axes[1]] = loadpos[axes[2]] * (clockwise and 1 or -1)
		writepos[axes[2]] = loadpos[axes[1]] * (clockwise and -1 or 1)

		--get absolute position
		pos2 = {x=pos.x+writepos[1], y=pos.y+writepos[2], z=pos.z+writepos[3]}

		--rotate cubelet itself
		loadcubelet = cube[loadpos[1]][loadpos[2]][loadpos[3]]
		if loadcubelet.node.name ~= 'rubiks:cube' then--continue end
			--string.gsub
			topcolor = loadcubelet.node.name:gsub('rubiks:cubelet', '')
			oldtiles = facedir_to_tiles(
				cubelettiles[topcolor+0],
				loadcubelet.node.param2
			)
			matchtiles = {
				--match the face
				dir.y ==  1 and oldtiles[1]..'' or nil,
				dir.y == -1 and oldtiles[2]..'' or nil,
				dir.x ==  1 and oldtiles[3]..'' or nil,
				dir.x == -1 and oldtiles[4]..'' or nil,
				dir.z ==  1 and oldtiles[5]..'' or nil,
				dir.z == -1 and oldtiles[6]..'' or nil,
			}
			--match a turning side
			--+Y, -Y, +X, -X, +Z, -Z
			if dir.x ~= 0 then
				-- +Y = -Z or +Z
				matchtiles[1] = oldtiles[clockwise and 6 or 5]..''
			end
			if dir.y ~= 0 then
				-- -Z = +X or -X
				matchtiles[6] = oldtiles[clockwise and 3 or 4]..''
			end
			if dir.z ~= 0 then
				-- -X = +Y or -Y
				matchtiles[4] = oldtiles[clockwise and 1 or 2]..''
	
			end
	
			--get new cubelet
			name, param2 = match_cubelet(matchtiles)
			
			--place it
			minetest.env:add_node(pos2, {name = name, param2 = param2})
			local meta = minetest.env:get_meta(pos2)
			meta:from_table(loadcubelet.meta)
		end
	end
	end
end

function start_rotation(pos, clockwise, layer)
	axesoff = get_axesoff(pos)
	if axesoff == 1 then --center
		if layer == 6 then
			for layer = 1, 3 do
				rotate_cube(center, dir, clockwise, layer)
			end
		else
			rotate_cube(center, dir, clockwise, layer)
		end
	elseif axesoff == 2 then --edge

	else --corner

	end
end

function register_cubelets()
	tiles = {unpack(textures)}
	direction = true
	cubelettiles = {}
	for rotations = 1, 6 do
		--save the tiles, I don't trust minetest.registered_nodes[node.name].tiles
		cubelettiles[rotations] = {unpack(tiles)}
		minetest.register_node('rubiks:cubelet'..rotations, {
			description = "Rubik's Cubelet #"..rotations,
			tiles = tiles,
			inventory_image = minetest.inventorycube(tiles[1], tiles[6], tiles[3]),
			groups = {crumbly=2, not_in_creative_inventory = 1},
			after_dig_node = function(pos, oldnode, oldmeta, digger)
				local string = oldmeta.fields.cube_center
				if string ~= nil then
					pos = minetest.string_to_pos(string)
					expand_cube(pos, false)
				end
			end,
			drop = 'rubiks:cube',
			on_punch = function(pos, node, puncher)
				start_rotation(pos, true, 1)
			end,
			--cubelets not in the center of the face never get formspecs
			on_receive_fields = function(pos, formname, fields, sender)
				if fields.L1 then
					start_rotation(pos, false, 1)
				elseif fields.L2 then
					start_rotation(pos, false, 3)
				elseif fields.L3 then
					start_rotation(pos, false, 6)
				elseif fields.R1 then
					start_rotation(pos, true, 1)
				elseif fields.R2 then
					start_rotation(pos, true, 3)
				elseif fields.R3 then
					start_rotation(pos, true, 6)
				elseif fields.larger then
					minetest.chat_send_player(sender:get_player_name(),
						'TODO: make the cube have more layers'
					)
				elseif fields.smaller then
					minetest.chat_send_player(sender:get_player_name(),
						'TODO: make the cube have less layers'
					)
				else --reset
					minetest.chat_send_player(sender:get_player_name(),
						'TODO: toggle between reset/scramble'
					)
				end
			end,
			paramtype2 = 'facedir',
		})
		--+Y, -Y, +X, -X, +Z, -Z
		if direction == true then
			--x rotation
			placeholder = tiles[1]
			tiles[1] = tiles[6]
			tiles[6] = tiles[2]
			tiles[2] = tiles[5]
			tiles[5] = placeholder
		else
			--z rotation
			placeholder = tiles[1]
			tiles[1] = tiles[3]
			tiles[3] = tiles[2]
			tiles[2] = tiles[4]
			tiles[4] = placeholder
		end
		direction = not direction
		--rotating x, then z alternating will cause each color to be on the top once.
		--Then adding facedir (y rotation) will get the rest of the rotations.
	end
end register_cubelets()

--temporary aliases to update cleanly
for rotations = 1, 6 do
	minetest.register_alias('rubiks:cubelet'..rotations, 'rubiks:cubelet')
end

function axisRotate(facedir, turnaxis, turnrot)
	turnrot = math.floor(turnrot / 90) % 4
	axis = math.floor(facedir / 4)
	rot = facedir % 4
	    if turnaxis == 'x' then
		if 3 == axis or axis == 4 then
			if axis == 4 then turnrot = -turnrot end
			rot = (rot + turnrot) % 4
		else
			for r = 0, turnrot do
				    if  axis == 0 then	axis = 1
				elseif  axis == 1 then	axis = 5
							rot=rot+2
				elseif  axis == 5 then	axis = 2
							rot=rot-2
				else--[[axis == 2 then]]axis = 0
				end
			end
		end
	elseif turnaxis == 'y' then
		if 0 == axis or axis == 5 then
			if axis == 5 then turnrot = -turnrot end
			rot = (rot + turnrot) % 4
		else
			for r = 0, turnrot do
				    if  axis == 1 then	axis = 3
				elseif  axis == 3 then	axis = 2
				elseif  axis == 2 then	axis = 4
				else--[[axis == 4 then]]axis = 1
				end	rot = (rot + 1) % 4
			end
		end
	elseif turnaxis == 'z' then
		if 1 == axis or axis == 2 then
			if axis == 4 then turnrot = -turnrot end
			rot = (rot + turnrot) % 4
		else
			for r = 0, turnrot do
				    if  axis == 0 then	axis = 4
				elseif  axis == 4 then	axis = 5
				elseif  axis == 5 then	axis = 3
				else--[[axis == 3 then]]axis = 0
				end
			end
		end
	else
		print('axis not xyz')
	end
	return axis * 4 + rot -- = facedir
end
print(axisRotate(23, 'y', 270))
