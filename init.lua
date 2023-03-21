persistent_monoids = fmod.create()

local f = string.format

local monoids = {}

local PersistentMonoid = futil.class1()

function PersistentMonoid:_init(name, def)
	assert(name, "persistent monoids must specify a unique name")
	assert(not monoids[name], "persistent monoids must specify a unique name. name is not unique.")
	monoids[name] = self
	self._name = name
	local monoid_def = {
		fold = def.fold,
		apply = def.apply,
		on_change = def.on_change,
	}
	if def.identity == nil then
		monoid_def.identity = def.fold({})
	else
		monoid_def.identity = def.identity
	end
	self._monoid = player_monoids.make_monoid(monoid_def)
end

function PersistentMonoid:_key()
	return f("persistent_monoids:%s", self._name)
end

function PersistentMonoid:_get_values(meta)
	local key = self:_key()
	return minetest.deserialize(meta:get(key)) or {}
end

function PersistentMonoid:_set_values(meta, values)
	local key = self:_key()
	if futil.table.is_empty(values) then
		meta:set_string(key, "")
	else
		meta:set_string(key, minetest.serialize(values))
	end
end

function PersistentMonoid:_remember_value(player, id, value)
	local meta = player:get_meta()
	local values = self:_get_values(meta)
	if values[id] ~= value then
		values[id] = value
		self:_set_values(meta, values)
	end
end

function PersistentMonoid:add_change(player, value, id)
	assert(id, "changes to persistent monoids must specify an ID")
	self._monoid:add_change(player, value, id)
	self:_remember_value(player, id, value)
	return id
end

function PersistentMonoid:add_ephemeral_change(player, value, id)
	self:_remember_value(player, id, nil)
	return self._monoid:add_change(player, value, id)
end

function PersistentMonoid:del_change(player, id)
	self:_remember_value(player, id, nil)
	self._monoid:del_change(player, id)
end

function PersistentMonoid:del_all(player)
	local meta = player:get_meta()
	for id in pairs(self._monoid.player_map[player:get_player_name()] or {}) do
		self._monoid:del_change(player, id)
	end
	self:_remember_values(meta, {})
end

function PersistentMonoid:value(player, key)
	if key then
		return (self._monoid.player_map[player:get_player_name()] or {})[key]
	else
		return self._monoid:value(player)
	end
end

function PersistentMonoid:values(player)
	return table.copy(self._monoid.player_map[player:get_player_name()] or {})
end

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	for _, monoid in pairs(monoids) do
		local values = monoid:_get_values(meta)
		for id, value in pairs(values) do
			monoid._monoid:add_change(player, value, id)
		end
	end
end)

persistent_monoids.make_monoid = PersistentMonoid
