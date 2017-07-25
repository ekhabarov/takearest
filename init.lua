local takearest = {}

local attr_time = "takearest.time"
local attr_ban_at = "takearest.ban_at"

local warn_msg = [[
=====================================
=== ATTENTION! YOU WILL BE BANNED ===
=== IN 3 MINUTES FOR NEXT 6 HOURS ===
===       TAKE A REST A BIT.      ===
=====================================
]]

local BAN_TIME = 21600 -- 6 hours
local CHECK_INTERVAL = 180 -- 3 minutes
local WARN_INTERVAL = 300 -- 5 minutes

-- Register privilege.
minetest.register_privilege("take_a_rest", {
  description = "Allows to set peridically ban timer for any player.",
  give_to_singleplayer = false
})

-- Set ban_time attr on player join.
minetest.register_on_joinplayer(function(player)
  local atime = player:get_attribute(attr_time) or "none"
  takearest.set_player_ban_time(player, atime)
end)

-- Set ban time for player if ban_at attribute exists on player.
function takearest.set_player_ban_time(player, time)
  if (tonumber(time) or -1) <  0 then
    return
  end

  local player_name = player:get_player_name()

  player:set_attribute(attr_ban_at, os.time() + time)

  minetest.chat_send_player(
    player_name,
    minetest.colorize(
      "#569874",
      "You can play the game only " .. tostring(time/60.0) .. " minutes for each 6 hours."
    )
  )
end

-- Register tar_time command
minetest.register_chatcommand("tar_time", {
  params = "<player_name> <seconds>",
  description = "Set max number of seconds for one game per 6 hours.",
  privs = { take_a_rest = true },

  func = function(name, params)
    local pl, time = params:match("(%S+)%s+(.+)")
    if not (pl and time) then
      return false, "Usage: /tar_time <player> <seconds>"
    end

    local player = minetest.get_player_by_name(pl)

    if (tonumber(time) or -1) < 0 then
      return false, "Invalid <seconds> value."
    end

    if not player then
      return false, "Player " .. pl .. " not found."
    end

    player:set_attribute(attr_time, time)
    takearest.set_player_ban_time(player, time)

    return true, "Time for player " .. pl .. " set."
  end
})

-- Set timer.
local timer = 0
minetest.register_globalstep(function(dtime)
  timer = timer + dtime
  if timer >= CHECK_INTERVAL then
    players = minetest.get_connected_players()

    for k, p in pairs(players) do
      local bt = p:get_attribute(attr_ban_at) or "none"
      local ban_time = tonumber(bt) or -1
      local now = os.time()

      if not ban_time or ban_time < 0 then
        do break end
      end

      local warn = ban_time - WARN_INTERVAL

      -- Ban player if ban_time has come.
      if now > ban_time then
        xban.ban_player(
          p:get_player_name(),
          "By TakeARest mod.",
          os.time() + BAN_TIME,
          "Take a rest."
        )
      else
        -- Otherwise send warn message
        if now > warn then
          minetest.chat_send_player(p:get_player_name(), warn_msg)
        end
      end
    end

  timer = 0
  end
end)
