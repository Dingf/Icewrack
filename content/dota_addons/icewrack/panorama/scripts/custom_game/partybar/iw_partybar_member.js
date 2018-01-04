"use strict";

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

function OnPartybarSelectUnit(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if ((nEntityIndex !== -1) && (Entities.IsAlive(nEntityIndex)))
	{
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

function OnPartybarCenterUnit(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		GameUI.SetCameraTarget(nEntityIndex);
		$.Schedule(0.03, GameUI.SetCameraTarget.bind(hContextPanel, -1));
	}
}

function OnActivatePortraitUnit()
{
	DispatchCustomEvent($.GetContextPanel(), "PartybarMemberSelect");
}

function OnDoubleClickPortraitUnit()
{
	DispatchCustomEvent($.GetContextPanel(), "PartybarMemberCenter");
}

function OnPartybarIndicatorActivate(hContextPanel, tArgs)
{
	var szPanelID = tArgs.panel.id;
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		if (szPanelID === "AAMIndicator")
		{
			var tEntityAAMInfo = CustomNetTables.GetTableValue("aam", String(nEntityIndex));
			GameEvents.SendCustomGameEventToServer("iw_aam_change_state", { entindex:nEntityIndex, state:(tEntityAAMInfo.State+1)%3, hidden:false });
		}
		else if (szPanelID === "RunIndicator")
		{
			GameEvents.SendCustomGameEventToServer("iw_toggle_run", { entindex:nEntityIndex });
		}
		else if (szPanelID === "HoldIndicator")
		{
			GameEvents.SendCustomGameEventToServer("iw_toggle_hold", { entindex:nEntityIndex });
		}
	}
	return true;
}

function UpdatePartyBarMemberValues()
{
	var hPanel = $.GetContextPanel();
	var nEntityIndex = hPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		var nPlayerID = Players.GetLocalPlayer();
		var tSelectedEntities = Players.GetSelectedEntities(nPlayerID);
		var bIsEntityAlive = (Entities.IsAlive(nEntityIndex) && !Entities.IsCommandRestricted(nEntityIndex));
		
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
		
		var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
		var fStamina = bIsEntityAlive ? Entities.GetStamina(nEntityIndex) : 0;
		var fMaxStamina = tEntityData.stamina_max;
		$("#SPLabel").text = Math.floor(fStamina) + " / " + Math.floor(fMaxStamina);
		$("#SPBar").style.width = (Math.floor(fStamina * 182)/((fMaxStamina === 0) ? 1 : fMaxStamina)) + "px";
		
		var fStaminaRechargeTime = GetPropertyValue(tEntityData, Instance.IW_PROPERTY_SP_RECHARGE_TIME);
		var fCurrentRechargeTime = bIsEntityAlive ? Game.GetGameTime() - Entities.GetStaminaRechargeTime(nEntityIndex) + fStaminaRechargeTime : 0;
		var nRechargeBarWidth = (fCurrentRechargeTime * 182)/fStaminaRechargeTime;
		if (nRechargeBarWidth < 8.0)
			nRechargeBarWidth = 0.0;
		$("#SPRechargeBar").style.width = nRechargeBarWidth + "px";
		
		var szCurrentActionName = tEntityData.current_action;
		var nCurrentActionIndex = parseInt(tEntityData.current_actionindex);
		var szAbilityTextureName = nCurrentActionIndex ? Abilities.GetAbilityTextureName(nCurrentActionIndex) : szCurrentActionName;
		if (szCurrentActionName && bIsEntityAlive)
		{
			$("#ActionImage").SetImage("file://{images}/spellicons/" + szAbilityTextureName + ".png");
			$("#ActionLabel").text = $.Localize("DOTA_Tooltip_Ability_" + szCurrentActionName);
			$("#ActionContainer").visible = true;
		}
		else
		{
			$("#ActionContainer").visible = false;
		}
		
		var tEntityAAMData = CustomNetTables.GetTableValue("aam", nEntityIndex);
		var nAAMState = bIsEntityAlive ? tEntityAAMData.State : 0;
		var nPrevAAMState = $("#AAMIndicator").GetAttributeInt("state", 0);
		if (nPrevAAMState !== nAAMState)
		{
			$("#AAMIndicator").SetAttributeInt("state", nAAMState);
			DispatchCustomEvent($("#AAMIndicator"), "PartybarIndicatorRefresh");
		}
		
		var nRunState = bIsEntityAlive ? tEntityData.run_mode : 0;
		var nPrevRunState = $("#RunIndicator").GetAttributeInt("state", 0);
		if (nPrevRunState !== nRunState)
		{
			$("#RunIndicator").SetAttributeInt("state", nRunState);
			DispatchCustomEvent($("#RunIndicator"), "PartybarIndicatorRefresh");
		}
		
		var nHoldState = bIsEntityAlive ? tEntityData.hold_position : 0;
		var nPrevHoldState = $("#HoldIndicator").GetAttributeInt("state", 0);
		if (nPrevHoldState !== nHoldState)
		{
			$("#HoldIndicator").SetAttributeInt("state", nHoldState);
			DispatchCustomEvent($("#HoldIndicator"), "PartybarIndicatorRefresh");
		}
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
	
	var hContextPanel = $.GetContextPanel();
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		hContextPanel.visible = true;
		$("#Portrait").SetImage("file://{images}/portraits/" + Entities.GetUnitName(nEntityIndex) + ".png");
	}
	
	CreatePartybarIndicator(hContextPanel, "AAMIndicator", "iw_partybar_aam_indicator_", "iw_ui_aam_mode_", 3);
	CreatePartybarIndicator(hContextPanel, "RunIndicator", "iw_partybar_run_indicator_", "iw_ui_run_mode_", 2);
	CreatePartybarIndicator(hContextPanel, "HoldIndicator", "iw_partybar_hold_indicator_", "iw_ui_hold_mode_", 2);
	
	RegisterCustomEventHandler(hContextPanel, "PartybarMemberSelect", OnPartybarSelectUnit);
	RegisterCustomEventHandler(hContextPanel, "PartybarMemberCenter", OnPartybarCenterUnit);
	RegisterCustomEventHandler(hContextPanel, "PartybarIndicatorActivate", OnPartybarIndicatorActivate);
	
	UpdatePartyBarMemberValues();
};