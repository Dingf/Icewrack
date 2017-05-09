"use strict";


var MAX_PARTY_MEMBERS = 4;

var nLastSelectTime = 0;
var nLastSelectMask = 0;
var tPartybarMemberPanels = [];

function OnPartyBarSelect(tArgs)
{
	var tSelectedPanelList = [];
	var bIsDoubleSelect = ((Game.Time() - nLastSelectTime < 0.25) && (nLastSelectMask === tArgs.value));
	
	for (var i = 0; i < MAX_PARTY_MEMBERS; i++)
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
	for (var i = 0; i < MAX_PARTY_MEMBERS; i++)
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