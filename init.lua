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
	'bucket:bucket_with_water',
	'default:desert_stone',
	'default:desert_sand',
	'default:steel_block',
	'default:sand',
}

print(dump(materials))

textures = materials
textures[1] = 'default:grass' --dirt
textures[2] = 'default:water' --bucket_with_water
cubetex = {}
for t = 1, #textures do
	textures[t], _ = string.gsub(textures[t], ':', '_')
	textures[t] = textures[t]..'.png'
	cubetex[t] = textures[t]..'^rubiks_three.png'
	textures[t] = textures[t]..'^rubiks_outline.png'
end
textures[7] = 'default_stone.png^rubiks_outline.png'

minetest.register_craft({
	type = "shapeless",
	output = "rubiks:cube",
	recipe = materials,
	replacements = {
		{'bucket:bucket_with_water', 'bucket:bucket_empty'},
	},
})

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

function spawn_cube(pos, create)
	for x = pos.x-1, pos.x+1 do
	for y = pos.y-1, pos.y+1 do
	for z = pos.z-1, pos.z+1 do
		pos2 = {x=x, y=y, z=z}
		if create then
			if not(pos.x==x and pos.y==y and pos.z==z) then
				--minetest.env:add_node({x=x, y=y, z=z}, {name = 'default:dirt'})
				cubelet = {unpack(blacktex)}
				dir = {x=pos.x-x, y=pos.y-y, z=pos.z-z}
				cubelet = set_cubelet(cubelet, dir)
				name = 'rubiks:cubelet_'..get_cubelet_name(cubelet)
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

function color_to_texture(color)
	texture = ''
	for t = 1, 7 do
		texture = textures[t]
		if color == colors[t] then
			return texture
		end
	end
end

blacktex = {}
for b = 1, 6 do
	blacktex[b] = 'black'
end

function set_cubelet(cubelet, dir)
	if dir.y == -1 then
		cubelet[1] = colors[1]
	elseif dir.y == 1 then
		cubelet[2] = colors[2]
	end
	if dir.x == -1 then
		cubelet[3] = colors[3]
	elseif dir.x == 1 then
		cubelet[4] = colors[4]
	end
	if dir.z == -1 then
		cubelet[5] = colors[5]
	elseif dir.z == 1 then
		cubelet[6] = colors[6]
	end
	return cubelet
end

function generate_cubelets()
	--centers
	for c = 1, 6 do
		cubelet = {unpack(blacktex)}
		cubelet[c] = colors[c]
		register_cubelet(cubelet, 'center')
	end
	--edges
	for y = 1, -1, -2 do
	for x = 1, -1, -2 do
		cubelet = {unpack(blacktex)}
		cubelet = set_cubelet(cubelet, {x=x, y=y, z=0})
		register_cubelet(cubelet, 'edge')
	end
	end
	for x = 1, -1, -2 do
	for z = 1, -1, -2 do
		cubelet = {unpack(blacktex)}
		cubelet = set_cubelet(cubelet, {x=x, y=0, z=z})
		register_cubelet(cubelet, 'edge')
	end
	end
	for y = 1, -1, -2 do
	for z = 1, -1, -2 do
		cubelet = {unpack(blacktex)}
		cubelet = set_cubelet(cubelet, {x=0, y=y, z=z})
		register_cubelet(cubelet, 'edge')
	end
	end
	--corners
	for x = 1, -1, -2 do
	for y = 1, -1, -2 do
	for z = 1, -1, -2 do
		cubelet = {unpack(blacktex)}
		cubelet = set_cubelet(cubelet, {x=x, y=y, z=z})
		register_cubelet(cubelet, 'corner')
	end
	end
	end
end

function get_cubelet_name(cubelet)
	name = ''
	for n = 1, 6 do
		name = name..cubelet[n]
	end
	return name
end

function register_cubelet(cubelet, piece)
	name = get_cubelet_name(cubelet)
	lettex = {}
	for n = 1, 6 do
		lettex[n] = color_to_texture(cubelet[n])
	end
	print(name)

	if piece == 'center' then
		on_punch = function(pos, node, puncher)
			local meta = minetest.env:get_meta(pos)
			center = minetest.string_to_pos(meta:get_string('cube_center'))
			if center ~= nil then
				dir = {x=pos.x-center.x, y=pos.y-center.y, z=pos.z-center.z}
				rotate_cube(center, dir, true, false)
			end
		end
		--on_rightclick = function(self, clicker)
		--rotate counterclockwise
	else
		on_punch = nil
	end

	minetest.register_node('rubiks:cubelet_'..name, {
		description = "Rubik's Cubelet "..name,
		tiles = lettex,
		inventory_image = minetest.inventorycube(lettex[1], lettex[6], lettex[3]),
		groups = {crumbly=2},
		after_dig_node = function(pos, oldnode, oldmeta, digger)
			pos = minetest.string_to_pos(
				oldmeta.fields.cube_center
			)
			if pos ~= nil then
				spawn_cube(pos, false)
			end
		end,
		drop = 'rubiks:cube',
		on_punch = on_punch,
	})
end
generate_cubelets()

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
		--rotate
		writepos[axes[1]] = loadpos[axes[2]]
		writepos[axes[2]] = loadpos[axes[1]]
		if clockwise then
			writepos[axes[2]] = -writepos[axes[2]]
		else
			writepos[axes[1]] = -writepos[axes[1]]
		end
		--get absolute position
		pos2 = {x=pos.x+writepos[1], y=pos.y+writepos[2], z=pos.z+writepos[3]}
		--write
		loadcubelet = cube[loadpos[1]][loadpos[2]][loadpos[3]]
		minetest.env:add_node(pos2, {
			name = loadcubelet.node.name}
		)
		local meta = minetest.env:get_meta(pos2)
		meta:from_table(loadcubelet.meta)

	end
	end
end

