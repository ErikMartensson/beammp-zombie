local M = {}

local function tableCount(table)
  local getN = 0
  for _ in pairs(table) do
    getN = getN + 1
  end
  return getN
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
  print('Zombie main.lua init')
end

function StartOutbreak(pid, data)
  print('Triggered event to start outbreak', pid, data)

  local allPlayers = MP.GetPlayers()
  M.allPlayers = allPlayers
  local random = math.random(tableCount(allPlayers))

  local firstInfectedPid
  local i = 1
  for id in pairs(allPlayers) do
    if i == random then
      firstInfectedPid = id
    end
    i = i + 1
  end

  table.insert(M.infectedPlayers, firstInfectedPid)

  MP.TriggerClientEvent(firstInfectedPid, 'zombieTurnInfected', '')
  MP.TriggerClientEvent(-1, 'zombieStartOutbreak', '')
  M.outbreak = true

  MP.SendChatMessage(-1, 'An outbreak has started - ' .. MP.GetPlayerName(firstInfectedPid) .. ' is patient zero')

  MP.CreateEventTimer('checkForSurvivors', 100)
end

function StopOutbreak(pid, data)
  print('Triggered event to stop outbreak', pid, data)
  reset()
  MP.TriggerClientEvent(-1, 'zombieStopOutbreak', '')
end

function CheckForSurvivors()
  -- Don't end the game if there's just one player
  if not M.outbreak or tableCount(M.allPlayers) < 2 then
    return
  end

  if tableCount(M.allPlayers) == tableCount(M.infectedPlayers) then
    MP.CancelEventTimer('checkForSurvivors')
    print('Everyone has been infected')
    MP.SendChatMessage(-1, 'Everyone was infected, reset in 5 seconds...')
    MP.CreateEventTimer('delayedReset', 1000)
  end
end

function CountDown()
  M.countDownSeconds = M.countDownSeconds - 1

  if (M.countDownSeconds <= 0) then
      MP.CancelEventTimer('CountDown')
      M.countDownSeconds = 6
      StartOutbreak(-1)
  else
      MP.TriggerClientEvent(-1, 'zombieCountdown', tostring(M.countDownSeconds))
      MP.SendChatMessage(-1, M.countDownSeconds .. '...');
  end
end

function DelayedReset()
  M.resetSeconds = M.resetSeconds - 1

  if (M.resetSeconds < 0) then
      MP.CancelEventTimer('DelayedReset')
      reset()
      MP.TriggerClientEvent(-1, 'zombieReset', '')
  end
end

MP.RegisterEvent('onInit', 'Init')
MP.RegisterEvent('zombieStartOutbreak', 'StartOutbreak')
MP.RegisterEvent('zombieStopOutbreak', 'StopOutbreak')
MP.RegisterEvent('checkForSurvivors', 'CheckForSurvivors')
MP.RegisterEvent('countDown', 'CountDown')
MP.RegisterEvent('delayedReset', 'DelayedReset')

return M
