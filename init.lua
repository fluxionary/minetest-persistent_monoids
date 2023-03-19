persistent_monoids = fmod.create()

local f = string.format

local monoids = {}

local PersistentMonoid = futil.class1()

function PersistentMonoid:_init(name, def)
	assert(name, "persistent monoids must specify a unique name")
	assert(not monoids[name], "persistent monoids must specify a unique name. name is not unique.")
	monoids[name] = self
	self._name = name
	self._monoid = player_monoids.make_monoid(def)
end

function PersistentMonoid:_ids_key()
	return f("monoid_ids:%s", self._name)
end

function PersistentMonoid:_get_ids(meta)
	local ids_key = self:_ids_key()
	return minetest.deserialize(meta:get(ids_key)) or {}
end

function PersistentMonoid:_remember_ids(meta, ids)
	local ids_key = self:_ids_key()
	if futil.table.is_empty(ids) then
		meta:set_string(ids_key, "")
	else
		meta:set_string(ids_key, minetest.serialize(ids))
	end
end

function PersistentMonoid:_value_key(id)
	return f("monoid_value:%s:%s", self._name, id)
end

function PersistentMonoid:_get_value(meta, id)
	local value_key = self:_value_key(id)
	return minetest.deserialize(meta:get(value_key))
end

function PersistentMonoid:_remember_value(player, id, value)
	local meta = player:get_meta()
	local value_key = self:_value_key(id)
	meta:set_string(value_key, minetest.serialize(value))
	local ids = self:_get_ids(meta)
	ids[id] = true
	self:_remember_ids(meta, ids)
end

function PersistentMonoid:_forget_value(player, id)
	local meta = player:get_meta()
	local value_key = self:_value_key(id)
	meta:set_string(value_key, "")
	local ids = self:_get_ids(meta)
	ids[id] = nil
	self:_remember_ids(meta, ids)
end

function PersistentMonoid:add_change(player, value, id)
	assert(id, "changes to persistent monoids must specify an ID")
	self._monoid:add_change(player, value, id)
	self:_remember_value(player, id, value)
	return id
end

function PersistentMonoid:add_ephemeral_change(player, value, id)
	self:_forget_value(player, id)
	return self._monoid:add_change(player, value, id)
end

function PersistentMonoid:del_change(player, id)
	self._monoid:del_change(player, id)
	self:_forget_value(player, id)
end

function PersistentMonoid:del_all(player)
	local meta = player:get_meta()
	for id, value in pairs(self:_get_ids(meta)) do
		self._monoid:del_change(player, id)
	end
	self:_remember_ids(meta, {})
end

function PersistentMonoid:value(player)
	return self._monoid:value(player)
end

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	for _, monoid in pairs(monoids) do
		local ids = monoid:_get_ids(meta)
		for id in pairs(ids) do
			local value = monoid:_get_value(meta, id)
			monoid._monoid:add_change(player, value, id)
		end
	end
end)

persistent_monoids.make_monoid = PersistentMonoid
