local extension = Package:new("tianming")
extension.extensionName = "star_night"

Fk:loadTranslationTable{
  ["tianming"] = "天命所归",
  ["tm"] = "天命"
}

local U = require "packages/utility/utility"

local ouyangmuyi = General(extension, "tm__ouyangmuyi", "tian", 3)

local renjie_active = fk.CreateActiveSkill{
  name = "renjie_active",
  anim_type = "control",
  interaction = function()
    return UI.ComboBox {choices = {"renjie_choice1", "renjie_choice2"}}
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  min_target_num = 0,
  target_filter = function(self, to_select, selected)
    if self.interaction.data == "renjie_choice1" then
      return 0
    elseif self.interaction.data == "renjie_choice2" then
      return #selected < Self:getMark("renjie")
    else return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "renjie_choice1" then
      room:setPlayerMark(player, "renjie_choice", 1)
    else
      room:setPlayerMark(player, "renjie_choice", 2)
    end
  end,
}
Fk:addSkill(renjie_active)

local renjie = fk.CreateTriggerSkill{
  name = "renjie",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to == Player.Discard and #player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e)
      local use = e.data[1]
      return use.from == player.id
    end, Player.HistoryTurn) <= player.maxHp
  end,

  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp
    if n == 0 then return false end
    room:setPlayerMark(player, self.name, n)
    local success, dat = room:askForUseActiveSkill(player, "renjie_active", "#renjie-use:::"..n, true)
    local choice = player:getMark("renjie_choice")
    if success then
      self.cost_data = {dat.targets, choice}
      return true
    end
  end,

  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local tos = table.map(self.cost_data[1], Util.Id2PlayerMapper)
    local choice = self.cost_data[2]
    if choice == 1 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(player.maxHp, self.name)
    else
      room:notifySkillInvoked(player, self.name, "support")
      for _, p in ipairs(tos) do
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,
}
ouyangmuyi:addSkill(renjie)


local tianfu = fk.CreateTriggerSkill{
  name = "tianfu",
  anim_type = "defensive",
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    player:drawCards(player.maxHp, self.name)
    if player.dead then return false end
    if player:isWounded() then
      room:recover({
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = self.name,
      })
      if player.dead then return false end
    end
  end,
}
ouyangmuyi:addSkill(tianfu)

Fk:loadTranslationTable{
  ["tm__ouyangmuyi"] = "欧阳穆翼",
  ["#tm__ouyangmuyi"] = "末裔",
  ["renjie"] = "忍戒",
  [":renjie"] = "弃牌阶段，若你于出牌阶段内使用的牌的数量不超过X，你可以摸X张牌，或令至多X名角色摸1张牌（X为你的体力上限）。",
  ["renjie_active"] = "忍戒",
  ["#renjie-use"] = "你可发动“忍戒”，X为%arg",
  ["renjie_choice1"] = "摸X张牌",
  ["renjie_choice2"] = "令至多X名角色各摸一张牌",
  ["tianfu"] = "天府",
  [":tianfu"] = "当你处于濒死状态时，你可以减1点体力上限，然后回复至X点体力，并摸X张牌（X为你的体力上限）。",

}

local simaxiangtian = General(extension, "tm__simaxiangtian", "tian", 4)

local qicai = fk.CreateTriggerSkill{
  name = "qicai",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return false end
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
    local last_find = false
    for i = #events, 1, -1 do
      local e = events[i]
      if e.data[1].from == player.id then
        if e.id == use_event.id then
          last_find = true
        elseif last_find then
          local last_use = e.data[1]
          return data.card.type == last_use.card.type
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return target == player and player:hasSkill(self, true)
    elseif event == fk.EventLoseSkill then
      return data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      room:setPlayerMark(player, "@qicai", data.card:getTypeString(true))
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@qicai", 0)
    end
  end,
}
simaxiangtian:addSkill(qicai)

local hunyun = fk.CreateTriggerSkill{
  name = "hunyun",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room:getOtherPlayers(player), function(p) return p.hp >= player.hp end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player:isWounded() and not player.dead then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
    room:handleAddLoseSkills(player, "tiantong", nil, true, false)
  end,
}
simaxiangtian:addSkill(hunyun)

local tiantong = fk.CreateTriggerSkill{
  name = "tiantong",
  anim_type = "masochism",
  events = {fk.Damaged},
  --[[

  
  ]]
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,

  on_cost = function(self, event, target, player, data)
    room = player.room
    local targets = table.map(table.filter(room.alive_players, function (p)
      local skills = {}
      for _, s in ipairs(p.player_skills) do
        if s:isPlayerSkill(p) then
          table.insertIfNeed(skills, s.name)
        end
      end
      return #skills ~= 0
    end), Util.IdMapper)

    local to = player.room:askForChoosePlayers(player, targets,
      1, 1, "#tiantong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,

  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local all_choices = {"tiantong_choice1", "tiantong_choice2"}
    local choices = table.clone(all_choices)
    local skills = {}
    for _, s in ipairs(to.player_skills) do
      if s:isPlayerSkill(to) then
        table.insertIfNeed(skills, s.name)
      end
    end


    if #data.to:getCardIds(Player.Equip) == 0 and #data.to:getCardIds(Player.Hand) == 0 then table.remove(choices, 1) end
    local choice = room:askForChoice(to, choices, self.name, nil, false, all_choices)
    if choice == "tiantong_choice1" then
      room:askForDiscard(to, 1, 1, false, self.name, false)
      room:loseHp(to, 1, self.name)
    else
      local choice2 = room:askForChoice(to, skills, self.name, "#tiantong-skill", true)
      room:handleAddLoseSkills(to, "-"..choice2, nil, true, false)
    end
  end,
}

simaxiangtian:addRelatedSkill(tiantong)


Fk:loadTranslationTable{
  ["tm__simaxiangtian"] = "司马翔天",
  ["#tm__simaxiangtian"] = "理智之河",
  ["qicai"] = "奇才",
  [":qicai"] = "当你使用牌时，若此牌与你使用的上一张牌类型相同，你可以摸一张牌。",
  ["@qicai"] = "奇才",
  ["hunyun"] = "魂韵",
  [":hunyun"] = "觉醒技，准备阶段，若你是体力值最小的角色，你减1点体力上限，回复1点体力，然后获得“天同”。",
  ["tiantong"] = "天同",
  [":tiantong"] = "当你受到1点伤害后，你可以令一名有技能的角色选择一项：1.弃置一张牌并失去1点体力；2.失去一个技能。",
  ["#tiantong-choose"] = "你可以令一名有技能的角色选择一项：1.弃置一张牌并失去1点体力；2.失去一个技能。",
  ["#tiantong-skill"] = "天同：选择失去一个技能",
  ["tiantong_choice1"] = "弃置一张牌并失去1点体力",
  ["tiantong_choice2"] = "失去一个技能",

  ["$hunyun1"] = "乃至白头忽一梦，谓我曾是轻狂身",
  ["$hunyun2"] = "只是原谅了自己，却无法被原谅",

}




return extension
