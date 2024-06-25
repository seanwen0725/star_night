local extension = Package:new("mingyun")
extension.extensionName = "star_night"

Fk:loadTranslationTable{
  ["mingyun"] = "命运序章",
  ["my"] = "命运",
}

local U = require "packages/utility/utility"

local feiyu = General(extension, "my__feiyu", "yi", 3)
Fk:loadTranslationTable{
  ["my__feiyu"] = "飞鱼",
  ["#my__feiyu"] = "天平裁决者",
}

local shier = General(extension, "my__shier", "yi", 3)
local zhenshen = fk.CreateTriggerSkill{
  name = "zhenshen",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.DamageInflicted, fk.AfterCardsMove, fk.BeforeCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.phase == Player.NotActive then
      if event == fk.Damaged then
        return target == player and player:hasSkill(self)
      elseif event == fk.DamageInflicted then
        return target == player and player:getMark("@@zhenshendamage-turn") > 0
      elseif event == fk.AfterCardsMove then
        if player:hasSkill(self) and player.phase == Player.NotActive then
          for _, move in ipairs(data) do
            if move.from == player.id then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand then
                  return true
                end
              end
            end
          end
        end
      end
    else
      return player:getMark("@@zhenshencard-turn") > 0 and (move.moveReason == fk.ReasonPrey or move.moveReason == fk.ReasonDiscard) and move.from == player.id and move.proposer ~= player.id
    end
  end,

  on_use = function(self, event, target, player, data)
    if event == fk.Damaged then
      player.room:setPlayerMark(player, "@@zhenshendamage-turn", 1)
    elseif event == fk.DamageInflicted then
      return true
    elseif event == fk.AfterCardsMove then
      player.room:setPlayerMark(player, "@@zhenshencard-turn", 1)
    else
      local ids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonPrey or fk.ReasonDiscard and move.proposer ~= player.id then
          local move_info = {}
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if info.fromArea == Card.PlayerHand then
              table.insert(ids, id)
            else
              table.insert(move_info, info)
            end
          end
          if #ids > 0 then
            move.moveInfo = move_info
          end
        end
      end
      if #ids > 0 then
        player.room:sendLog{
          type = "#cancelDismantle",
          card = ids,
          arg = self.name,
        }
      end
    end
  end,
}

local mingche = fk.CreateTriggerSkill{
  name = "mingche",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,

  target_filter = function(self, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Judge] > 0
  end,

  target_num = 1,

  on_use = function(self, room, effect)
    local to = room:getPlayerById(effect.tos[1])
    if to.dead then return end
    local judges = to:getCardIds(to.player_cards[Player.Judge])
    if #judges > 0 then
      room:moveCardTo(judges, Card.PlayerHand, to, fk.ReasonPrey, "mingche", nil, true, player.id)
      if target ~= player then
        player:skip(Player.Draw)
      end
    end

  end,

}


--[[

local mingding = fk.CreateTriggerSkill{

}


shier:addSkill(mingding)

]]


shier:addSkill(zhenshen)
shier:addSkill(mingche)

Fk:loadTranslationTable{
  ["my__shier"] = "第十二愿望使",
  ["#my__shier"] = "心星祈圣",

  ["zhenshen"] = "镇神",
  [":zhenshen"] = "锁定技，你的回合外，当你受到伤害后，本回合防止你即将受到的伤害；当你失去手牌后，本回合你的手牌无法被其他角色弃置或获得。",
  ["#cancelDismantle"] = "由于 %arg 的效果，%card 的弃置被取消",
  ["mingche"] = "明澈",
  [":mingche"] = "回合开始阶段，你可以令一名角色获得其判定区里的所有牌，然后若该角色不是你，你跳过本回合摸牌阶段。",
  ["mingding"] = "命定",
  [":mingding"] = "出牌阶段开始时，你可以选择一种花色，然后展示牌堆顶的两张牌，获得其中与你声明花色相同的所有牌，并将剩余牌置入弃牌堆。若你因此获得了至少一张牌，你可以重复此流程。",

  ["@@zhenshendamage-turn"] = "镇神-伤害",
  ["@@zhenshencard-turn"] = "镇神-手牌",

}




return extension
