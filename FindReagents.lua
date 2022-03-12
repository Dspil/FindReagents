function FindReagents_OnLoad()
   SLASH_FINDREAGENTS1 = "/fr"
   SlashCmdList["FINDREAGENTS"] = FindReagents_Handler
   StaticPopupDialogs["FINDREAGENTS_CRAFT"] = {
      text = "Craft %s?",
      button1 = "Ok",
      button2 = "Cancel",
      timeout = 0,
      OnShow = function(self, itemName)
	 return nil
      end,
      OnAccept = function()
	 DoTradeSkill(FindReagents_recipe[1], FindReagents_recipe[2])
	 FindReagents_wait(1, FindReagents_makeParts1by1, FindReagents_partsTable, FindReagents_newindex, FindReagents_itemName, FindReagents_newAmount)
      end,
      preferredIndex = 3,
   }
end


function FindReagents_Handler(msg)
   if msg == "" then
      r = FindReagents_GetTradeskillReagents(1)
      FindReagents_PrintResults(r[1])
      return nil
   end
   local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
   local num = tonumber(cmd)
   if num then 
      r = FindReagents_GetTradeskillReagents(num)
      FindReagents_PrintResults(r[1])
   else
      if cmd == "make" then
	 r = FindReagents_GetTradeskillReagents(tonumber(args))
	 FindReagents_makeParts(r)
      end
   end
end

function FindReagents_PrintResults(r)
   DEFAULT_CHAT_FRAME:AddMessage("|cffFF8000[FindReagents]|r Reagents needed:")
   for i, v in pairs(r) do
      DEFAULT_CHAT_FRAME:AddMessage("|cffFF8000->|r" .. " " .. i .. ": " .. v)
   end
end

-- Find reagents logic

function FindReagents_GetTradeskillReagents(count)
   local tradeSkillRecipeId = GetTradeSkillSelectionIndex()
   local partsTable = {}
   return {FindReagents_GetTradeskillReagents1(tradeSkillRecipeId, count, {}, partsTable), partsTable}
end

function FindReagents_GetTradeskillReagents1(tradeSkillRecipeId, count, haveUsed, partsTable)
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
	 local nonCraftableReagents1 = FindReagents_GetTradeskillReagents1(reagentId, ceil(trueReagentCount / minMade), haveUsed, partsTable)
	 for reagent, reagentcount in pairs(nonCraftableReagents1) do
	    if not nonCraftableReagents[reagent] then
	       nonCraftableReagents[reagent] = reagentcount
	    else
	       nonCraftableReagents[reagent] = nonCraftableReagents[reagent] + reagentcount
	    end
	 end
      end
   end
   if count > 0 then
      tinsert(partsTable, {tradeSkillRecipeId, count})
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

-- creating recipE logic

function FindReagents_makeParts(r)
   reagents = r[1]
   for i, v in pairs(reagents) do
      if v > 0 then
	 DEFAULT_CHAT_FRAME:AddMessage("|cffFF8000[FindReagents]|r Not Enough Reagents!")
	 FindReagents_PrintResults(reagents)
	 return nil
      end
   end
   partsTable = r[2]
   local recipe = partsTable[1]
   DoTradeSkill(recipe[1], recipe[2])
   local itemName, skillType, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(recipe[1])
   local amount = GetItemCount(itemName)
   FindReagents_makeParts1by1(partsTable, 1, itemName, amount)
end

function FindReagents_makeParts1by1(partsTable, index, itemName, amount)
   local tomake = partsTable[index][2]
   local inInventory = GetItemCount(itemName)
   if inInventory >= tomake + amount then
      local recipe = partsTable[index + 1]
      if recipe then
	 local newItemName, skillType, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(recipe[1])
	 FindReagents_itemName = newItemName
	 FindReagents_partsTable = partsTable
	 FindReagents_newindex = index + 1
	 FindReagents_newAmount = GetItemCount(newItemName)
	 FindReagents_recipe = recipe
	 StaticPopup_Show("FINDREAGENTS_CRAFT", newItemName);
      end
   else
      FindReagents_wait(1, FindReagents_makeParts1by1, partsTable, index, itemName, amount)
   end
end
   

-- wait function below

local waitTable = {};
local waitFrame = nil;

function FindReagents_wait(delay, func, ...)
   if(type(delay)~="number" or type(func)~="function") then
      return false;
   end
   if(waitFrame == nil) then
      waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
      waitFrame:SetScript("onUpdate",function (self,elapse)
			     local count = #waitTable;
			     local i = 1;
			     while(i<=count) do
				local waitRecord = tremove(waitTable,i);
				local d = tremove(waitRecord,1);
				local f = tremove(waitRecord,1);
				local p = tremove(waitRecord,1);
				if(d>elapse) then
				   tinsert(waitTable,i,{d-elapse,f,p});
				   i = i + 1;
				else
				   count = count - 1;
				   f(unpack(p));
				end
			     end
      end);
   end
   tinsert(waitTable,{delay,func,{...}});
   return true;
end
