"use strict";

function OnActionBarChannelRefresh(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	hContextPanel.SetAttributeInt("entindex", nEntityIndex);
	return true;
}

function UpdateActionBarChannel()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
	
	$.GetContextPanel().visible = false;
	if (tEntityData)
	{
		var nAbilityIndex = tEntityData.current_actionindex;
		var nLastAbilityIndex = $.GetContextPanel().GetAttributeInt("last_abilityindex", -1);
		if (nAbilityIndex)
		{
			var fChannelStartTime = Abilities.GetChannelStartTime(nAbilityIndex);
			var fChannelDuration = Abilities.GetChannelTime(nAbilityIndex);
			
			var bIsChannelingUp = false;	//TODO: Add in support for cast time (channel bar goes up instead of down)
			if (fChannelStartTime !== 0 && fChannelDuration !== 0)
			{
				var fCurrentTime = Game.GetGameTime();
				var fChannelTimeSpent = fCurrentTime - fChannelStartTime;
				var fChannelTimeRemaining = fChannelDuration - fChannelTimeSpent;
				var fLastChannelStartTime = $.GetContextPanel()._fLastChannelStartTime;
				if ((nAbilityIndex !== nLastAbilityIndex) || (fChannelStartTime !== fLastChannelStartTime))
				{
					$("#Icon").SetImage("file://{images}/spellicons/" + Abilities.GetAbilityTextureName(nAbilityIndex) + ".png");
					$("#Name").text = $.Localize("DOTA_Tooltip_Ability_" + Abilities.GetAbilityName(nAbilityIndex));
					$.GetContextPanel().SetAttributeInt("last_abilityindex", nAbilityIndex);
					$.GetContextPanel()._fLastChannelStartTime = fChannelStartTime;
					$("#SpacerRight").visible = bIsChannelingUp;
					$("#SpacerLeft").visible = !bIsChannelingUp;
					$("#Fill").RemoveClass("ActionBarChannelUpAnim");
					$("#Fill").RemoveClass("ActionBarChannelDownAnim");
				}
				
				if (fChannelTimeRemaining > 0)
				{
					var hFillPanel = $("#Fill");
					var hFillContainer = $("#FillContainer");
					$("#Duration").text = fChannelTimeRemaining.toFixed(1) + "s";
					
					if (bIsChannelingUp)
					{
						if (!hFillPanel.BHasClass("ActionBarChannelUpAnim") || Game.IsGamePaused() || (nLastAbilityIndex !== nAbilityIndex))
						{
							hFillContainer.style.position = ((1.0 - fChannelTimeSpent/fChannelDuration) * -360) + "px 0px 0px";
							if (!Game.IsGamePaused())
							{
								hFillPanel.AddClass("ActionBarChannelUpAnim");
								hFillPanel.style["animation-duration"] = fChannelDuration + "s";
							}
							else
							{
								hFillPanel.RemoveClass("ActionBarChannelUpAnim");
							}
						}
					}
					else
					{
						if (!hFillPanel.BHasClass("ActionBarChannelDownAnim") || Game.IsGamePaused() || (nLastAbilityIndex !== nAbilityIndex))
						{
							hFillContainer.style.position = (fChannelTimeSpent/fChannelDuration * -360) + "px 0px 0px";
							if (!Game.IsGamePaused())
							{
								hFillPanel.AddClass("ActionBarChannelDownAnim");
								hFillPanel.style["animation-duration"] = fChannelDuration + "s";
							}
							else
							{
								hFillPanel.RemoveClass("ActionBarChannelDownAnim");
							}
						}
					}
					$.GetContextPanel().visible = true;
				}
			}
		}
		else
		{
			$("#Fill").RemoveClass("ActionBarChannelUpAnim");
			$("#Fill").RemoveClass("ActionBarChannelDownAnim");
			$.GetContextPanel().SetAttributeInt("last_abilityindex", -1);
		}
	}
	
	$.Schedule(0.1, UpdateActionBarChannel);
}

function OnActionBarChannelLoad()
{
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarChannelRefresh", OnActionBarChannelRefresh);
	$.Schedule(0.1, UpdateActionBarChannel);
}