local M = {}

local function tableCount(table)
  local getN = 0
  for _ in pairs(table) do
    getN = getN + 1
  end
  return getN
end

local function tableFind(table, find)
  for index, value in pairs(table) do
    if value == find then
      return index
    end
  end
  return nil
end

local function keyExistsInTable(table, findKey)
  for key, _ in pairs(table) do
    if key == findKey then
      return true
    end
  end
  return false
end

local function reset()
  M.outbreak = false
  M.allPlayers = {} -- Player IDs
  M.infectedPlayers = {} -- Player IDs
  M.countDownSeconds = 6
  M.resetSeconds = 5
end

function Init()
  reset()
  print('Zombie mod loaded')
end

function pickPatientZero()
  local allPlayers = MP.GetPlayers()
  M.allPlayers = allPlayers
  local random = math.random(tableCount(allPlayers))

  local firstInfectedPid
  local firstInfectedName
  local i = 1
  for id, name in pairs(allPlayers) do
    if i == random then
      firstInfectedPid = id
      firstInfectedName = name
    end
    i = i + 1
  end

  table.insert(M.infectedPlayers, firstInfectedPid)

  MP.TriggerClientEvent(firstInfectedPid, 'zombieTurnInfected', '')

  return firstInfectedName
end

function StartCountdown(pid)
  local patientZero = pickPatientZero()

  MP.SendChatMessage(-1, patientZero .. ' starts coughing...');
  MP.CreateEventTimer('countDown', 1000)
  MP.TriggerClientEvent(-1, 'zombieFreezeVehicle', '')
end

function StartOutbreak(pid, data)
  local patientZero
  if tableCount(M.infectedPlayers) == 0 then
    patientZero = pickPatientZero()
  else
    patientZero = MP.GetPlayerName(M.infectedPlayers[1])
  end

  MP.TriggerClientEvent(-1, 'zombieStartOutbreak', '')
  M.outbreak = true

  MP.TriggerClientEvent(-1, 'zombieUnfreezeVehicle', '')

  MP.SendChatMessage(-1, 'An outbreak has started - ' .. patientZero .. ' is patient zero')

  MP.CreateEventTimer('checkForSurvivors', 100)
end

function StopOutbreak(pid, data)
  print('Triggered event to stop outbreak', pid, data)
  reset()
  MP.TriggerClientEvent(-1, 'zombieStopOutbreak', '')
end

function Collisions(pid, data)
  local collidingVehicleIds = Util.JsonDecode(data)
  for _, collidingVehicleId in pairs(collidingVehicleIds) do
    for playerId, playerName in pairs(M.allPlayers) do
      local playerVehicles = MP.GetPlayerVehicles(playerId)

      if keyExistsInTable(playerVehicles, collidingVehicleId) then
        -- Make sure player isn't already infected
        if not tableFind(M.infectedPlayers, playerId) then
          table.insert(M.infectedPlayers, playerId)
          MP.TriggerClientEvent(playerId, 'zombieTurnInfected', '')
          MP.SendChatMessage(-1, playerName .. ' has been infected by ' .. MP.GetPlayerName(pid))
        end
      end
    end
  end
end

function CheckForSurvivors()
  print('CheckForSurvivors')
  -- Don't end the game if there's just one player
  -- if not M.outbreak or tableCount(M.allPlayers) < 2 then
  if not M.outbreak then
    return
  end

  if tableCount(M.allPlayers) == tableCount(M.infectedPlayers) then
    MP.CancelEventTimer('checkForSurvivors')
    MP.SendChatMessage(-1, 'Infection has taken over, no remaining survivors, reset in 5 seconds...')
    MP.CreateEventTimer('delayedReset', 1000)
  end
end

function CountDown()
  M.countDownSeconds = M.countDownSeconds - 1

  if (M.countDownSeconds <= 0) then
      MP.CancelEventTimer('countDown')
      M.countDownSeconds = 6
      StartOutbreak(-1)
  else
      -- MP.TriggerClientEvent(-1, 'zombieCountdown', tostring(M.countDownSeconds))
      MP.SendChatMessage(-1, M.countDownSeconds .. '...');
  end
end

function DelayedReset()
  M.resetSeconds = M.resetSeconds - 1

  if (M.resetSeconds < 0) then
      MP.CancelEventTimer('delayedReset')
      reset()
      MP.TriggerClientEvent(-1, 'zombieReset', '')
  end
end

MP.RegisterEvent('onInit', 'Init')
MP.RegisterEvent('zombieStartCountdown', 'StartCountdown')
MP.RegisterEvent('zombieStartOutbreak', 'StartOutbreak')
MP.RegisterEvent('zombieStopOutbreak', 'StopOutbreak')
MP.RegisterEvent('zombieCollisions', 'Collisions')
MP.RegisterEvent('checkForSurvivors', 'CheckForSurvivors')
MP.RegisterEvent('countDown', 'CountDown')
MP.RegisterEvent('delayedReset', 'DelayedReset')

return M
