"use strict";

//TODO: Implement back to dashboard with <Button onactivate="DOTAHUDShowDashboard() "/> etc.

var nLastSelectTime = 0;
var nLastSelectMask = 0;
var tPartybarMemberPanels = [];

var tLastHotkeyTime = [];
function OnHotkeyPartyMemberSelect(nSelectFlag)
{
	if (!GameUI.IsHidden())
	{
		var nMask = nSelectFlag & 0x0f;
		var bIsFirstPanel = true;
		for (var i = 0; i < 4; i++)
		{
			if (nMask & (1 << i))
			{
				var hPartyMemberPanel = $("#PartyMember" + (i + 1));
				if (!(nMask & ~(1 << i)) && tLastHotkeyTime[i] && ((Game.Time() - tLastHotkeyTime[i]) < 0.5))
				{
					DispatchCustomEvent(hPartyMemberPanel, "PartybarMemberCenter");
					tLastHotkeyTime[i] = 0.0;
				}
				else
				{
					DispatchCustomEvent(hPartyMemberPanel, "PartybarMemberSelect", { addflag:!bIsFirstPanel });
					tLastHotkeyTime[i] = Game.Time();
				}
				bIsFirstPanel = false;
			}
		}
		return true;
	}
}

Game.RegisterHotkey("F1", OnHotkeyPartyMemberSelect.bind(this, 1));
Game.RegisterHotkey("F2", OnHotkeyPartyMemberSelect.bind(this, 2));
Game.RegisterHotkey("F3", OnHotkeyPartyMemberSelect.bind(this, 4));
Game.RegisterHotkey("F4", OnHotkeyPartyMemberSelect.bind(this, 8));
Game.RegisterHotkey("`", OnHotkeyPartyMemberSelect.bind(this, 15));

function OnPartyBarSelect(tArgs)
{
	var tSelectedPanelList = [];
	var bIsDoubleSelect = ((Game.Time() - nLastSelectTime < 0.25) && (nLastSelectMask === tArgs.value));
	
	for (var i = 0; i < 4; i++)
	{
		if (tArgs.value & (1 << i))
		{
			tSelectedPanelList.push($("#PartyMember" + (i + 1)));
		}
	}
	var bIsFirstPanel = true;
	for (var k in tSelectedPanelList)
	{
		if (bIsDoubleSelect && (tSelectedPanelList.length == 1))
		{
			DispatchCustomEvent(tSelectedPanelList[k], "PartybarMemberCenter");
		}
		else
		{
			DispatchCustomEvent(tSelectedPanelList[k], "PartybarMemberSelect", { addflag:!bIsFirstPanel });
			bIsFirstPanel = false;
		}
	}
	
	nLastSelectTime = bIsDoubleSelect ? 0 : Game.Time();
	nLastSelectMask = tArgs.value;
}

function OnPartyBarToggleRun()
{
	var nPlayerID = Players.GetLocalPlayer();
	var tSelectedEntities = Players.GetSelectedEntities(nPlayerID);
	for (var k in tSelectedEntities)
	{
		GameEvents.SendCustomGameEventToServer("iw_toggle_run", { entindex:tSelectedEntities[k] });
	}
}

function UpdatePartybarInfo()
{
	var tPartyMembers = CustomNetTables.GetTableValue("party", "Members");
	for (var k in tPartyMembers)
	{
		var nEntityIndex = parseInt(tPartyMembers[k]);
		var hMemberPanel = tPartybarMemberPanels[parseInt(k)-1];
		if (nEntityIndex === -1)
		{
			hMemberPanel.visible = false;
		}
		else
		{
			hMemberPanel.visible = true;
			hMemberPanel.FindChildTraverse("Portrait").SetImage("file://{images}/portraits/" + Entities.GetUnitName(nEntityIndex) + ".png");
			hMemberPanel.SetAttributeInt("entindex", nEntityIndex);
		}
	}
}

function OnPartyInfoUpdate(szTableName, szKey, tData)
{
	if (szKey === "Members")
	{
		for (var k in tData)
		{
			var nEntityIndex = parseInt(tData[k]);
			var hMemberPanel = tPartybarMemberPanels[parseInt(k)-1];
			if (nEntityIndex === -1)
			{
				hMemberPanel.visible = false;
			}
			else
			{
				hMemberPanel.visible = true;
				hMemberPanel.FindChildTraverse("Portrait").SetImage("file://{images}/portraits/" + Entities.GetUnitName(nEntityIndex) + ".png");
				hMemberPanel.SetAttributeInt("entindex", nEntityIndex);
			}
		}
	}
}

(function()
{
	var hMemberContainer = $("#MemberContainer");
	for (var i = 0; i < 4; i++)
	{
		var hMember = $.CreatePanel("Panel", hMemberContainer, "PartyMember" + (i + 1));
		hMember.BLoadLayout("file://{resources}/layout/custom_game/partybar/iw_partybar_member.xml", false, false);
		hMember.SetAttributeInt("slot", (i + 1));
		hMember.AddClass("PartyBarMemberLayout");
		hMember.visible = false;
		tPartybarMemberPanels.push(hMember);
	}
	
	var tPartyMembers = CustomNetTables.GetTableValue("party", "Members");
	for (var k in tPartyMembers)
	{
		var nEntityIndex = parseInt(tPartyMembers[k]);
		var hMemberPanel = tPartybarMemberPanels[parseInt(k)-1];
		if (hMemberPanel && nEntityIndex)
		{
			hMemberPanel.SetAttributeInt("entindex", nEntityIndex);
		}
	}
	
	GameEvents.Subscribe("iw_party_select", OnPartyBarSelect);
	GameEvents.Subscribe("iw_toggle_run", OnPartyBarToggleRun);
	CustomNetTables.SubscribeNetTableListener("party", OnPartyInfoUpdate);
})();