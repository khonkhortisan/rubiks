colors = {
	'green',
	'blue',
	'red',
	'orange',
	'white',
	'yellow',
	'black',
}

materials = {
	'default:dirt',
	'bucket:bucket_water',
	'default:desert_stone',
	'default:desert_sand',
	'default:steelblock',
	'default:sand',
}

textures = {unpack(materials)}
textures[1] = 'default:grass' --dirt
textures[2] = 'default:water' --bucket_with_water
textures[5] = 'default:steel_block' --stupid naming conventions
cubetex = {}
for t = 1, #textures do
	textures[t], _ = string.gsub(textures[t], ':', '_')
	textures[t] = textures[t]..'.png'
	cubetex[t] = textures[t]..'^rubiks_three.png'
	textures[t] = textures[t]..'^rubiks_outline.png'
end
textures[7] = 'default_stone.png^rubiks_outline.png'

function spawn_cube(pos, create)
	for x = pos.x-1, pos.x+1 do
	for y = pos.y-1, pos.y+1 do
	for z = pos.z-1, pos.z+1 do
		pos2 = {x=x, y=y, z=z}
		if create then
			if not(pos.x==x and pos.y==y and pos.z==z) then
				name = 'rubiks:cubelet1'
				minetest.env:add_node(pos2, {name = name})
				local meta = minetest.env:get_meta(pos2)
				meta:set_string('cube_center',
					minetest.pos_to_string(pos)
				)
			end
		else
			minetest.env:remove_node(pos2)
		end
	end
	end
	end
	if create then
		local meta = minetest.env:get_meta(pos)
		meta:set_int('has_spawned', 1)
	end
end

minetest.register_node('rubiks:cube', {
	description  = "Rubik's Cube Spawner",
	tiles = cubetex,
	inventory_image = minetest.inventorycube(cubetex[1], cubetex[6], cubetex[3]),
	groups = {crumbly=3},
	on_punch = function(pos, node, puncher)
		for x = pos.x-1, pos.x+1 do
		for y = pos.y-1, pos.y+1 do
		for z = pos.z-1, pos.z+1 do
			if not(pos.x==x and pos.y==y and pos.z==z) then
				if minetest.env:get_node({x=x, y=y, z=z}).name ~= 'air' then
					minetest.chat_send_player(puncher:get_player_name(), "Clear some space for Rubik's cube to expand")
					return
				end
			end
		end
		end
		end
		spawn_cube(pos, true)
	end,
	can_dig = function(pos, digger)
		--digging the center of a spawned cube yields
		--two cubes without this
		local meta = minetest.env:get_meta(pos)
		if meta:get_int('has_spawned') == 1 then
			return false
		end
		return true
	end,

})

minetest.register_craft({
	type = "shapeless",
	output = "rubiks:cube",
	recipe = materials,
	replacements = {
		{'bucket:bucket_water', 'bucket:bucket_empty'},
	},
})

function facedir_to_tiles(tilestocopy, facedir)
	tiles = {unpack(tilestocopy)}
	for f = 0, facedir-1 do
		--+Y, -Y, +X, -X, +Z, -Z
		placeholder = tiles[6]
		tiles[6] = tiles[4]
		tiles[4] = tiles[5]
		tiles[5] = tiles[3]
		tiles[3] = placeholder
	end
	return tiles
end

function match_cubelet(matchtiles)
	for wallmounted = 1, 6 do
		--nodetiles = minetest.registered_nodes['rubiks:cubelet'..wallmounted].tiles
		nodetiles = {unpack(cubelettiles[wallmounted])}
	for facedir = 0, 3 do
		testtiles = facedir_to_tiles(nodetiles, facedir)
		--print(wallmounted..' '..facedir..' '..dump(testtiles))
		if
		(matchtiles[1] == testtiles[1] or matchtiles[1] == nil) and
		(matchtiles[2] == testtiles[2] or matchtiles[2] == nil) and
		(matchtiles[3] == testtiles[3] or matchtiles[3] == nil) and
		(matchtiles[4] == testtiles[4] or matchtiles[4] == nil) and
		(matchtiles[5] == testtiles[5] or matchtiles[5] == nil) and
		(matchtiles[6] == testtiles[6] or matchtiles[6] == nil) then
			print('testtiles '..dump(testtiles))
			return 'rubiks:cubelet'..wallmounted, facedir
		end
	end
	end
	print("Couldn't rotate cubelet! Assume crash position!")
end

function rotate_cube(pos, dir, clockwise, all)
	print(dump(dir))
	--save cube to rotate without losing data
	cube = {}
	for x = -1, 1 do
		cube[x] = {}
	for y = -1, 1 do
		cube[x][y] = {}
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

	loadpos = {0, 0, 0}
	axes = {}
	--what side of the cube will be rotated on what axes
	if dir.x ~= 0 then
		loadpos[1] = dir.x
		axes[1] = 3--z
		axes[2] = 2--y
	end
	if dir.y ~= 0 then
		loadpos[2] = dir.y
		axes[1] = 1--x
		axes[2] = 3--z

	end
	if dir.z ~= 0 then
		loadpos[3] = dir.z
		axes[1] = 2--y
		axes[2] = 1--x
	end

	if dir.x == -1 or dir.y == -1 or dir.z == -1 then
		clockwise = not clockwise
		--still clockwise, just from the opposite perspective
	end

	for firstaxis = -1, 1 do
	loadpos[axes[1]] = firstaxis
	for secondaxis = -1, 1 do
	loadpos[axes[2]] = secondaxis

		--don't lose data here either
		writepos = {unpack(loadpos)}

		--rotate globally
		writepos[axes[1]] = loadpos[axes[2]]
		writepos[axes[2]] = loadpos[axes[1]]
		if clockwise then
			writepos[axes[2]] = -writepos[axes[2]]
		else
			writepos[axes[1]] = -writepos[axes[1]]
		end

		--get absolute position
		pos2 = {x=pos.x+writepos[1], y=pos.y+writepos[2], z=pos.z+writepos[3]}

		loadcubelet = cube[loadpos[1]][loadpos[2]][loadpos[3]]
		--rotate locally
		--oldtiles = minetest.registered_nodes[loadcubelet.node.name].tiles
		wallmounted = string.gsub(loadcubelet.node.name, 'rubiks:cubelet', '')
		oldtiles = {unpack(cubelettiles[wallmounted+0])}
		--print('oldtiles '..dump(oldtiles))
		--print('oldparam2 '..dump(loadcubelet.node.param2))
		oldtiles = facedir_to_tiles(oldtiles, loadcubelet.node.param2)
		--print('newoldtiles '..dump(oldtiles))
		matchtiles = {
			--match the side that is spinning
			dir.y ==  1 and oldtiles[1]..'' or nil,
			dir.y == -1 and oldtiles[2]..'' or nil,
			dir.x ==  1 and oldtiles[3]..'' or nil,
			dir.x == -1 and oldtiles[4]..'' or nil,
			dir.z ==  1 and oldtiles[5]..'' or nil,
			dir.z == -1 and oldtiles[6]..'' or nil,
		}
		--match the side that is turning
		--+Y, -Y, +X, -X, +Z, -Z
		if dir.x ~= 0 then
			-- +Y = +Z or -Z
			matchtiles[1] = oldtiles[clockwise and 6 or 5]..''
		end
		if dir.y ~= 0 then
			-- -Z = +X or -X
			matchtiles[6] = oldtiles[clockwise and 4 or 3]..''
		end
		if dir.z ~= 0 then
			-- -X = +Y or -Y
			matchtiles[4] = oldtiles[clockwise and 2 or 1]..''
		end
		print('clockwise '..(clockwise and 1 or 0))
		print(loadcubelet.node.param2..' '..loadcubelet.node.name)
		print('oldtiles'..dump(oldtiles))
		print('matchtiles '..dump(matchtiles))
		
		name, param2 = match_cubelet(matchtiles)

		print(name..' '..param2)

		--loadcubelet.node.param2 = (loadcubelet.node.param2+1)%4
		minetest.env:add_node(pos2, {name = name, param2 = param2})
		local meta = minetest.env:get_meta(pos2)
		meta:from_table(loadcubelet.meta)

	end
	end
	print('done rotating')
end

function color_to_texture(color)
	texture = ''
	for t = 1, 7 do
		texture = textures[t]
		if color == colors[t] then
			return texture
		end
	end
end

function register_cubelets(cubelet)
	lettex = {}
	for n = 1, 6 do
		lettex[n] = color_to_texture(cubelet[n])
	end
	tiles = {unpack(lettex)}
	
	direction = true
	cubelettiles = {}
	for rotations = 1, 6 do
		--save the tiles, I don't trust minetest.registered_nodes[node.name].tiles
		cubelettiles[rotations] = {unpack(tiles)}
		minetest.register_node('rubiks:cubelet'..rotations, {
			description = "Rubik's Cubelet "..rotations,
			tiles = tiles,
			inventory_image = minetest.inventorycube(tiles[1], tiles[6], tiles[3]),
			groups = {crumbly=2},
			after_dig_node = function(pos, oldnode, oldmeta, digger)
				local string = oldmeta.fields.cube_center
				if string ~= nil then
					pos = minetest.string_to_pos(string)
					spawn_cube(pos, false)
				end
			end,
			drop = 'rubiks:cube',
			on_punch = function(pos, node, puncher)
				local meta = minetest.env:get_meta(pos)
				local string = meta:get_string('cube_center')
				if string ~= nil then
					center = minetest.string_to_pos(string)
					dir = {x=pos.x-center.x, y=pos.y-center.y, z=pos.z-center.z}
					axesoff = (dir.x ~= 0 and 1 or 0)
					        + (dir.y ~= 0 and 1 or 0)
					        + (dir.z ~= 0 and 1 or 0)
					if axesoff == 1 then --center
						rotate_cube(center, dir, true, false)
					elseif axesoff == 2 then --edge
	
					else --corner
	
					end
				end
			end,
			--on_rightclick = function(self, clicker)
			--rotate counterclockwise
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
	end
end
register_cubelets(colors)

