--[[
    .___.__       .__.__  .__
  __| _/|__| ____ |__|  | |__| ____   ____        ______ ___________   ____   ____   ____   ______
 / __ | |  |/ ___\|  |  | |  |/    \_/ __ \      /  ___// ___\_  __ \_/ __ \_/ __ \ /    \ /  ___/
/ /_/ | |  / /_/  >  |  |_|  |   |  \  ___/      \___ \\  \___|  | \/\  ___/\  ___/|   |  \\___ \
\____ | |__\___  /|__|____/__|___|  /\___  >____/____  >\___  >__|    \___  >\___  >___|  /____  >
     \/   /_____/                 \/     \/_____/    \/     \/            \/     \/     \/     \/
--]]

local load_time_start = os.clock()


digiline_screens = {}

digiline_screens.registered_screens = {}

minetest.register_entity("digiline_screens:entity", {
	collisionbox = {0,0,0, 0,0,0},
	physical = false,
	visual = "upright_sprite",
	textures = {"blank.png"},
})

local function make_texture(base, t, w, h)
	local px = "digiline_screens_px.png"
	local tex = base
	if t.format == 1 or t.format == nil then -- Todo: transform this to format 2 instead.
		for y = 1, #t do
			for x = 1, #t[y] do
				tex = tex.."^([combine:"..w.."x"..h..":"..tostring(x-1)..","..
					tostring(y-1).."="..px.."^[colorize:"..t[y][x]..":255)"
			end
		end
	elseif t.format == 2 then -- This format is better.
		for col, poss in pairs(t) do
			if col ~= "format" then
				tex = tex.."^([combine:"..w.."x"..h
				for i = 1, #poss do
					local pos = poss[i]
					local x = pos.x or pos[1]
					local y = pos.y or pos[2]
					tex = tex..":"..tostring(x-1)..","..tostring(y-1).."="..px
				end
				tex = tex.."^[colorize:"..col..":255)"
			end
		end
	end
	return tex
end

function digiline_screens.register_screen(name, spec, width, hight, entposs)
	spec.digiline = {receptor, effector}
	spec.digiline.effector = spec.digiline.effector or {}
	local f = spec.digiline.effector.action
	spec.digiline.effector.action = function(pos, node, channel, msg)
		if f then f(pos, node, channel, msg) end
		local meta = minetest.get_meta(pos)
		local setchan = meta:get_string("channel")
		if setchan ~= channel then
			return
		end
		if type(msg) ~= "table" then
			return
		end
		local ent
		for _,obj in pairs(minetest.get_objects_inside_radius(pos, 0.5)) do
			local lent = obj:get_luaentity()
			if lent and lent.name == "digiline_screens:entity" then
				ent = obj
				break
			end
		end
		ent:set_properties({
				textures={make_texture(spec.tiles[1], msg, 16, 16)}
			})
	end

	local f = spec.after_place_node
	spec.after_place_node = function(pos, placer, itemstack)
		if f then f(pos, placer, itemstack) end
		if spec.paramtype2 == "wallmounted" then
			local entpos = entposs[minetest.get_node(pos).param2]
			if entpos == nil then return end
			local ent = minetest.add_entity(
					vector.add(pos, entpos.delta),
					"digiline_screens:entity")
			ent:setyaw(entpos.yaw or 0)
		else
			minetest.add_entity(pos, "digiline_screens:entity")
		end
	end

	local f = spec.on_construct
	spec.on_construct = function(pos)
		if f then f(pos) end
		minetest.get_meta(pos):set_string("formspec",
				"field[channel;Channel;${channel}]")
	end

	local f = spec.on_destruct
	spec.on_destruct = function(pos)
		if f then f(pos) end
		for _,obj in pairs(minetest.get_objects_inside_radius(pos, 0.5)) do
			local lent = obj:get_luaentity()
			if lent and lent.name == "digiline_screens:entity" then
				obj:remove()
				break
			end
		end
	end

	local f = spec.on_receive_fields
	spec.on_receive_fields = function(pos, formname, fields, player)
		if f then f(pos, formname, fields, player) end
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) and not
				minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if fields.channel then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end

	minetest.register_node(name, spec)
	digiline_screens.registered_screens[name] = minetest.registered_nodes[name]
end

local entposs = {
	[2] = {delta = {x =  0.437, y = 0, z = 0}, yaw = math.pi * 1.5},
	[3] = {delta = {x = -0.437, y = 0, z = 0}, yaw = math.pi * 0.5},
	[4] = {delta = {x = 0, y = 0, z =  0.437}, yaw = 0},
	[5] = {delta = {x = 0, y = 0, z = -0.437}, yaw = math.pi},
}

local box = {
	type = "wallmounted",
	wall_top = {-8/16, 7/16, -8/16, 8/16, 8/16, 8/16}
}

digiline_screens.register_screen("digiline_screens:screen",
	{
		description = "digiline screen",
		drawtype = "nodebox",
		inventory_image = "digiline_screens_screen.png",
		wield_image = "digiline_screens_screen.png",
		tiles = {"digiline_screens_screen.png"},
		paramtype = "light",
		sunlight_propagates = true,
		paramtype2 = "wallmounted",
		node_box = box,
		selection_box = box,
		groups = {choppy = 3, dig_immediate = 2},
		light_source = 6,

		after_place_node = function (pos, placer, itemstack)
			local param2 = minetest.get_node(pos).param2
			if param2 == 0 or param2 == 1 then
				minetest.add_node(pos, {name = "digiline_screens:screen", param2 = 3})
			end
		end,
	},

	16,
	16,
	entposs
)


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[digiline_screens] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
