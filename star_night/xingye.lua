local extension = Package:new("xingye")
extension.extensionName = "star_night"

Fk:loadTranslationTable{
  ["xingye"] = "星夜之下",
  ["xy"] = "星夜",
  ["syr"] = "守夜人",
  ["ssr"] = "说书人",
}

local U = require "packages/utility/utility"

local zhushenwuxian_syr = General(extension, "syr__zhushenwuxian", "yi", 4)
Fk:loadTranslationTable{
  ["syr__zhushenwuxian"] = "诸神无限",
  ["#syr__zhushenwuxian"] = "守夜人",
}

local zhushenwuxian_ssr = General(extension, "ssr__zhushenwuxian", "yi", 3)
Fk:loadTranslationTable{
  ["ssr__zhushenwuxian"] = "诸神无限",
  ["#ssr__zhushenwuxian"] = "说书人",
}

local zhouyi = General(extension, "xy__zhouyi", "yi", 3)
Fk:loadTranslationTable{
  ["xy__zhouyi"] = "周易",
  ["#xy__zhouyi"] = "星夜之梦",
}


local liuyutian = General(extension, "xy__liuyutian", "yi", 3, 3, General.Female)
local tianjing = fk.CreateTriggerSkill{
  name = "tianjing",
  anim_type = "defensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local n = 0
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        if table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
          n = n + 1
        end
      end, Player.HistoryTurn)
      return n == 2
    end
  end,
  
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageDealt and data.damageDealt[player.id] then
      if player:isWounded() then
        room:recover({
          who = player,
          num = player.maxHp - player.hp,
          recoverBy = player,
          skillName = self.name,
        })
      end
    else
      player:drawCards(1, self.name)
    end
  end,
}
liuyutian:addSkill(tianjing)

local huixin_passive = fk.CreateTriggerSkill{
  name = "huixin_passive",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    local mark = U.getMark(player, "@huixin")
    if type(mark) == "table" and not mark[data.card.trueName] then 
      return target == player and player:hasSkill(self) and (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
     and not table.contains(mark, data.card.trueName)
    end
  end,

  on_use = function(self, event, target, player, data)
    local mark = player:getMark("@huixin")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card.trueName)
    player.room:setPlayerMark(player, "@huixin", mark)
  end,
}

local huixin = fk.CreateViewAsSkill{
  name = "huixin",
  pattern = ".",

  interaction = function()
    local names = U.getMark(Self, "@huixin")
    local all_names = U.getAllCardNames("bt")
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,

  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,

  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,

  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}

huixin:addRelatedSkill(huixin_passive)
liuyutian:addSkill(huixin)


Fk:loadTranslationTable{
  ["xy__liuyutian"] = "刘语恬",
  ["#xy__liuyutian"] = "星夜之花",
  ["tianjing"] = "恬静",
  [":tianjing"] = "当每回合第二张以你为目标的牌结算完成后，若此牌对你造成伤害，你可以回复1点体力，否则你可以摸一张牌。",
  ["huixin"] = "慧心",
  [":huixin"] = "每当你使用一张你未使用过的基本牌或非延时锦囊后，记录该牌名。每轮限一次，你可以将一张手牌当作一张已记录的牌使用或打出。",
  ["huixin_passive"] = "慧心",
  ["@huixin"] = "慧心"
}

local jinzheqi = General(extension, "xy__jinzheqi", "yi", 3)
Fk:loadTranslationTable{
  ["xy__jinzheqi"] = "金喆琪",
  ["#xy__jinzheqi"] = "星夜之海",
}

local yejiahao = General(extension, "xy__yejiahao", "yi", 3)
Fk:loadTranslationTable{
  ["xy__yejiahao"] = "叶佳豪",
  ["#xy__yejiahao"] = "胜天半子",
}

local caojingwen = General(extension, "xy__caojingwen", "yi", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["xy__caojingwen"] = "曹静雯",
  ["#xy__caojingwen"] = "掠影惊鸿",
}

local wangtianle = General(extension, "xy__wangtianle", "yi", 4)
local siji = fk.CreateTriggerSkill{
  name = "siji",
  anim_type = "negative",
  events = {fk.DamageCaused, fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return target == player and player:hasSkill(self) and player:getMark("@@siji-turn") == 0 and data.to ~= player
    else
      return target == player and player:hasSkill(self) and player:getMark("@@siji-turn") == 0
    end

  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      room:damage{
        from = player,
        to = player,
        damageType = data.damageType,
        damage = data.damage,
        skillName = self.name,
        chain = data.chain,
        card = data.card,
      }
      return true
    else
      room:setPlayerMark(player, "@@siji-turn", 1)
    end
  end,
}
wangtianle:addSkill(siji)

local zhuixin = fk.CreateTriggerSkill{
  name = "zhuixin",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.hp, self.name)
    if player.phase == Player.Play then
      local room = player.room
      player.room:addPlayerMark(player, "@@zhuixin-phase")
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase")
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and
    player:getMark("@@zhuixin-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,
}
local zhuixin_damage = fk.CreateTriggerSkill{
  name = "#zhuixin_damage",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card 
    and data.card.trueName == "slash" and U.damageByCardEffect(player.room) and player:getMark("@@zhuixin-phase") > 0
  end,

  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@@zhuixin-phase")
    player.room:setPlayerMark(player, "@@zhuixin-phase", 0)
  end,
}


zhuixin:addRelatedSkill(zhuixin_damage)
wangtianle:addSkill(zhuixin)

Fk:loadTranslationTable{
  ["xy__wangtianle"] = "王天乐",
  ["#xy__wangtianle"] = "寻心者",
  ["siji"] = "思疾",
  [":siji"] = "锁定技，当你对其他角色造成伤害时，防止此伤害，然后对你造成等量伤害。当你受到伤害后，本回合本技能失效。",
  ["@@siji-turn"] = "思疾失效",
  ["zhuixin"] = "锥心",
  [":zhuixin"] = "锁定技，当你受到伤害时，你摸X张牌（X为你当前体力值）。若此时是你的出牌阶段，你使用的下一张【杀】的伤害+1，无次数限制且不能被响应。",
  ["@@zhuixin-phase"] = "锥心",
  ["#zhuixin_damage"] = "锥心",
}

local kongdequan = General(extension, "xy__kongdequan", "yi", 3)
Fk:loadTranslationTable{
  ["xy__kongdequan"] = "孔德荃",
  ["#xy__kongdequan"] = "星夜之镜",
}




return extension
