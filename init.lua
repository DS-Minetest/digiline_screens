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

--~ function digiline_screens.register_screen(name, spec, width, high)
	--~ minetest.register_node(name, spec)
	--~ digiline_screens.registered_screens[name] = minetest.registered_nodes[name]
--~ end

--~ digiline_screens.register_screen("digiline_screens:screen",
	--~ {
		--~ description = "screen",
	--~ },
	--~ 16,
	--~ 16
--~ )

local px = "digiline_screens_px.png"
local function make_texture(base, t, w, h)
	local tex = base
	for y = 1, #t do
		for x = 1, #t[y] do
			tex = tex.."^([combine:"..w.."x"..h..":"..tostring(x-1)..","..
				tostring(y-1).."="..px.."^[colorize:"..t[y][x]..":255)"
		end
	end
	return tex
end

local function on_digiline_receive(pos, node, channel, msg)
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
	--~ minetest.chat_send_all(dump(msg))
	--~ minetest.chat_send_all(make_texture("digiline_screens_screen.png", msg, 16, 16))
	ent:set_properties({
			textures={make_texture("digiline_screens_screen.png", msg, 16, 16)}
		})
end

local box = {
	type = "wallmounted",
	wall_top = {-8/16, 7/16, -8/16, 8/16, 8/16, 8/16}
}

minetest.register_node("digiline_screens:screen", {
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
	digiline = {
		receptor = {},
		effector = {
			action = on_digiline_receive
		},
	},
	light_source = 6,

	after_place_node = function (pos, placer, itemstack)
		local param2 = minetest.get_node(pos).param2
		if param2 == 0 or param2 == 1 then
			minetest.add_node(pos, {name = "digiline_screens:screen", param2 = 3})
		end
	end,

	on_construct = function(pos)
		minetest.add_entity(pos, "digiline_screens:entity")
		minetest.get_meta(pos):set_string("formspec",
				"field[channel;Channel;${channel}]")
	end,

	on_destruct = function(pos)
		for _,obj in pairs(minetest.get_objects_inside_radius(pos, 0.5)) do
			local lent = obj:get_luaentity()
			if lent and lent.name == "digiline_screens:entity" then
				obj:remove()
				break
			end
		end
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) and not
				minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if fields.channel then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
})

minetest.register_entity("digiline_screens:entity", {
	collisionbox = {0,0,0, 0,0,0},
	physical=false,
	visual = "upright_sprite",
	textures = {"digiline_screens_screen.png"},
})


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[digiline_screens] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
