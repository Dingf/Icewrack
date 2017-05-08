"use strict";

function OnIndicatorPressed()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var tEntityAAMInfo = CustomNetTables.GetTableValue("aam", parseInt(nEntityIndex));
	GameEvents.SendCustomGameEventToServer("iw_aam_change_state", { entindex:nEntityIndex, state:(tEntityAAMInfo.State+1)%3, hidden:false });
}

function ShowHPLabel()
{
	if ($("#HPLabel").GetAttributeInt("lock_label", 0) == 0)
	{
		$("#HPLabel").visible = true;
	}
}

function HideHPLabel()
{
	if ($("#HPLabel").GetAttributeInt("lock_label", 0) == 0)
	{
		$("#HPLabel").visible = false;
	}
}

function ToggleHPLabel()
{
	if ($("#HPLabel").GetAttributeInt("lock_label", 0) == 0)
	{
		$("#HPLabel").SetAttributeInt("lock_label", 1);
	}
	else
	{
		$("#HPLabel").SetAttributeInt("lock_label", 0);
	}
}

function ShowMPLabel()
{
	if ($("#MPLabel").GetAttributeInt("lock_label", 0) == 0)
	{
		$("#MPLabel").visible = true;
	}
}

function HideMPLabel()
{
	if ($("#MPLabel").GetAttributeInt("lock_label", 0) == 0)
	{
		$("#MPLabel").visible = false;
	}
}

function ToggleMPLabel()
{
	if ($("#MPLabel").GetAttributeInt("lock_label", 0) == 0)
	{
		$("#MPLabel").SetAttributeInt("lock_label", 1);
	}
	else
	{
		$("#MPLabel").SetAttributeInt("lock_label", 0);
	}
}

function ShowSPLabel()
{
	if ($("#SPLabel").GetAttributeInt("lock_label", 0) == 0)
	{
		$("#SPLabel").visible = true;
	}
}

function HideSPLabel()
{
	if ($("#SPLabel").GetAttributeInt("lock_label", 0) == 0)
	{
		$("#SPLabel").visible = false;
	}
}

function ToggleSPLabel()
{
	if ($("#SPLabel").GetAttributeInt("lock_label", 0) == 0)
	{
		$("#SPLabel").SetAttributeInt("lock_label", 1);
	}
	else
	{
		$("#SPLabel").SetAttributeInt("lock_label", 0);
	}
}

function SelectPortraitUnit(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	var nAbilityIndex = Abilities.GetLocalPlayerActiveAbility();
	if ((nAbilityIndex !== -1) && (nAbilityIndex !== 0))
	{
		//TODO: Figure out a way to deselect the active ability after targeting a party member like this
		Game.PrepareUnitOrders({OrderType:dotaunitorder_t.DOTA_UNIT_ORDER_CAST_TARGET,
								TargetIndex:nEntityIndex,
								AbilityIndex:nAbilityIndex,
								Position:Entities.GetAbsOrigin(nEntityIndex),
								OrderIssuer:PlayerOrderIssuer_t.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
								UnitIndex:Abilities.GetCaster(nAbilityIndex),
								QueueBehavior:GameUI.IsShiftDown(),
								ShowEffects:true});
	}
	else
	{
		if ((nEntityIndex !== -1) && (Entities.IsAlive(nEntityIndex)))
		{
			if (GameUI.IsShiftDown() || (tArgs && tArgs.addflag))
			{
				GameUI.SelectUnit(nEntityIndex, true);
			}
			else if (GameUI.IsControlDown())
			{
				var tPlayerSelectedEntities = Players.GetSelectedEntities(Players.GetLocalPlayer());
				var bEntityInSelection = false;
				var bNewSelection = true;
				for (var i = 0; i < tPlayerSelectedEntities.length; i++)
				{
					if (tPlayerSelectedEntities[i] === nEntityIndex)
					{
						bEntityInSelection = true;
					}
					else
					{
						GameUI.SelectUnit(tPlayerSelectedEntities[i], !bNewSelection);
						bNewSelection = false;
					}
				}
				if (!bEntityInSelection)
				{
					GameUI.SelectUnit(nEntityIndex, true);
				}
			}
			else
			{
				GameUI.SelectUnit(nEntityIndex, false);
			}
		}
	}
}

function CenterPortraitUnit(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		GameUI.SetCameraTarget(nEntityIndex);
		$.Schedule(0.03, GameUI.SetCameraTarget.bind(hContextPanel, -1));
	}
}

function OnSelectPortraitUnit()
{
	SelectPortraitUnit($.GetContextPanel());
}

function OnCenterPortraitUnit()
{
	CenterPortraitUnit($.GetContextPanel());
}

function UpdatePartyBarMemberValues()
{
	var hPanel = $.GetContextPanel();
	var nEntityIndex = hPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		var nPlayerID = Players.GetLocalPlayer();
		var tSelectedEntities = Players.GetSelectedEntities(nPlayerID);
		var bIsEntityAlive = (Entities.IsAlive(nEntityIndex) && !Entities.HasItemInInventory(nEntityIndex, "internal_corpse"));
		
		$("#PrimarySelectOverlay").visible = false;
		$("#SecondarySelectOverlay").visible = false;
		if (bIsEntityAlive)
		{
			var nEntitySelectedIndex = tSelectedEntities.indexOf(nEntityIndex);
			if ((nEntitySelectedIndex == 0) && (tSelectedEntities.length > 1))
			{
				$("#PrimarySelectOverlay").visible = true;
				$("#SecondarySelectOverlay").visible = false;
			}
			else if (nEntitySelectedIndex >= 0)
			{
				$("#PrimarySelectOverlay").visible = false;
				$("#SecondarySelectOverlay").visible = true;
			}
		}
		$("#DeathPortrait").visible = !bIsEntityAlive;
		$("#Portrait").SetHasClass("PartyBarDeathState", !bIsEntityAlive);
		
		var fHealth = bIsEntityAlive ? Entities.GetHealth(nEntityIndex) : 0;
		var fMaxHealth = Entities.GetMaxHealth(nEntityIndex);
		$("#HPLabel").text = Math.floor(fHealth) + " / " + Math.floor(fMaxHealth);
		$("#HPBar").style.width = ((fHealth * 182)/((fMaxHealth === 0) ? 1 : fMaxHealth)) + "px";
		
		var fMana = bIsEntityAlive ? Entities.GetMana(nEntityIndex) : 0;
		var fMaxMana = Entities.GetMaxMana(nEntityIndex);
		$("#MPLabel").text = Math.floor(fMana) + " / " + Math.floor(fMaxMana);
		$("#MPBar").style.width = ((fMana * 182)/((fMaxMana === 0) ? 1 : fMaxMana)) + "px";
		
		var tCharacterData = CustomNetTables.GetTableValue("entities", nEntityIndex);
		var fStamina = bIsEntityAlive ? tCharacterData.stamina : 0;
		var fMaxStamina = tCharacterData.stamina_max;
		$("#SPLabel").text = Math.floor(fStamina) + " / " + Math.floor(fMaxStamina);
		$("#SPBar").style.width = ((fStamina * 182)/((fMaxStamina === 0) ? 1 : fMaxStamina)) + "px";
		
		var szActionName = tCharacterData.current_action;
		if (szActionName && bIsEntityAlive)
		{
			$("#ActionImage").SetImage("file://{images}/spellicons/" + szActionName + ".png");
			$("#ActionLabel").text = $.Localize("DOTA_Tooltip_Ability_" + szActionName);
			$("#ActionContainer").visible = true;
		}
		else
		{
			$("#ActionContainer").visible = false;
		}
		
		var tEntityAAMInfo = CustomNetTables.GetTableValue("aam", parseInt(nEntityIndex));
		var nState = tEntityAAMInfo.State;
		
		$("#IndicatorOff").visible = ((nState === 0) || (!bIsEntityAlive));
		$("#IndicatorOn").visible = ((nState === 1) && (bIsEntityAlive));
		$("#IndicatorNS").visible = ((nState === 2) && (bIsEntityAlive));
	}
	$.Schedule(0.03, UpdatePartyBarMemberValues);
}

function OnPartyBarMemberLoad()
{
	$("#PrimarySelectOverlay").visible = false;
	$("#SecondarySelectOverlay").visible = false;
	$("#HPLabel").visible = false;
	$("#MPLabel").visible = false;
	$("#SPLabel").visible = false;
	$("#IndicatorOn").visible = false;
	$("#IndicatorNS").visible = false;
	
	var hContextPanel = $.GetContextPanel();
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		hContextPanel.visible = true;
		$("#Portrait").SetImage("file://{images}/portraits/" + Entities.GetUnitName(nEntityIndex) + ".png");
	}
	
	RegisterCustomEventHandler(hContextPanel, "PartybarMemberSelect", SelectPortraitUnit);
	RegisterCustomEventHandler(hContextPanel, "PartybarMemberCenter", CenterPortraitUnit);
	
	UpdatePartyBarMemberValues();
};