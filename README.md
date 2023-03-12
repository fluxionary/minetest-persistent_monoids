# persistent_monoids

player_monoids that persist between player sessions and server restarts/crashes. see
https://github.com/minetest-mods/player_monoids/ for more information.

### API

the API is almost identical to player_monoids, w/ a couple changes

```lua
local my_monoid = persistent_monoids.make_monoid("my_monoid", { -- a unique name for the monoid is obligatory
    ... -- definition as in a regular player_monoid
})

my_monoid:add_change(player, value, "some_id") -- unlike player_monoids, an ID is obligatory
```
