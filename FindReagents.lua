function FindReagents_OnLoad()
   SLASH_FINDREAGENTS1 = "/fr"
   SlashCmdList["FINDREAGENTS"] = FindReagents_Handler
end


function FindReagents_Handler(msg)
   if msg == "" then
      r = FindReagents_GetTradeskillReagents(1)
      for i, v in pairs(r) do
	 print(i .. ": " .. tostring(v))
      end
      return nil
   end
   local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
   r = FindReagents_GetTradeskillReagents(tonumber(cmd))
   for i, v in pairs(r) do
      print(i .. ": " .. tostring(v))
   end
end

function FindReagents_GetTradeskillReagents(count)
   local tradeSkillRecipeId = GetTradeSkillSelectionIndex()
   return FindReagents_GetTradeskillReagents1(tradeSkillRecipeId, count, {})
end

function FindReagents_GetTradeskillReagents1(tradeSkillRecipeId, count, haveUsed)
   local numReagents = GetTradeSkillNumReagents(tradeSkillRecipeId)
   local nonCraftableReagents = {}
   for reagentId = 1,numReagents do
      local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(tradeSkillRecipeId, reagentId)
      local reagentId = FindReagents_IdFromName(reagentName)
      local minMade, maxMade = GetTradeSkillNumMade(reagentId)
      local trueReagentCount = nil
      if haveUsed[reagentName] then
	 trueReagentCount = max(count * reagentCount - playerReagentCount + haveUsed[reagentName], 0)
	 haveUsed[reagentName] = haveUsed[reagentName] + count * reagentCount - trueReagentCount
      else
	 trueReagentCount = max(count * reagentCount - playerReagentCount, 0)
	 haveUsed[reagentName] = count * reagentCount - trueReagentCount
      end
      if reagentId == -1 then
	 if not nonCraftableReagents[reagentName] then
	    nonCraftableReagents[reagentName] = trueReagentCount
	 else
	    nonCraftableReagents[reagentName] = nonCraftableReagents[reagentName] + trueReagentCount
	 end
      else
	 local nonCraftableReagents1 = FindReagents_GetTradeskillReagents1(reagentId, ceil(trueReagentCount / minMade), haveUsed)
	 for reagent, reagentcount in pairs(nonCraftableReagents1) do
	    if not nonCraftableReagents[reagent] then
	       nonCraftableReagents[reagent] = reagentcount
	    else
	       nonCraftableReagents[reagent] = nonCraftableReagents[reagent] + reagentcount
	    end
	 end
      end
   end
   return nonCraftableReagents
end

function FindReagents_IdFromName(name)
   for skillIndex = 1,GetNumTradeSkills() do
      local skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(skillIndex)
      if skillName == name then
	 return skillIndex
      end
   end
   return -1
end
