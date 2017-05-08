"use strict";

var bUpdateScale = true;
var fZoomFactor = 16.0;

var tHeroIcons = {};
var tUnitIcons = [];

var MAX_ZOOM_FACTOR = 32.0;
var MIN_ZOOM_FACTOR = 8.0;

function OnZoomIn()
{
	if (fZoomFactor > MIN_ZOOM_FACTOR)
	{
		fZoomFactor -= 1.0;
		bUpdateScale = true;
	}
}

function OnZoomOut()
{
	if (fZoomFactor < MAX_ZOOM_FACTOR)
	{
		fZoomFactor += 1.0;
		bUpdateScale = true;
	}
}

function UpdateMinimap()
{
	var tMapInfo = $.GetContextPanel()._tMapInfo;
	var nMapWidth = $.GetContextPanel()._nMapWidth;
	var nMapHeight = $.GetContextPanel()._nMapHeight;
	var fYawRadians = GameUI._fCameraYaw * 0.0174532925;
	
	if (bUpdateScale)
	{
		$("#Texture").style.width = Math.floor(nMapWidth/fZoomFactor) + "px";
		$("#Texture").style.height = Math.floor(nMapHeight/fZoomFactor) + "px";
		bUpdateScale = false;
	}
	
	var vCameraPosition = Game.ScreenXYToWorld(Game.GetScreenWidth()/2, Game.GetScreenHeight()/2);
	var fCameraX = vCameraPosition[0];
	var fCameraY = vCameraPosition[1];
	if ((fCameraX < tMapInfo.left) || (fCameraX > tMapInfo.right) || (fCameraY < tMapInfo.top) || (fCameraY > tMapInfo.bottom))
	{
		$.Schedule(0.03, UpdateMinimap);
		return;
	}
	
	var fCameraCoordX = fCameraX - tMapInfo.left;
	var fCameraCoordY = tMapInfo.bottom - fCameraY;
	$("#Texture").style.position = (-fCameraCoordX/fZoomFactor + 110) + "px " + (-fCameraCoordY/fZoomFactor + 110) + "px 0px";
	$("#Texture").style["transform-origin"] = (fCameraCoordX/nMapWidth * 100) + "% " + (fCameraCoordY/nMapHeight * 100) + "%";
	$("#Texture").style["transform"] = "rotateZ(" + GameUI._fCameraYaw + "deg)";
	$("#Pointer").style["transform"] = "rotateZ(" + GameUI._fCameraYaw + "deg)";
	
	var tHeroUnits = Entities.GetAllHeroEntities();
	for (var k in tHeroIcons)
	{
		tHeroIcons[k].visible = false;
	}
	
	for (var k in tHeroUnits)
	{
		var nEntityIndex = parseInt(tHeroUnits[k]);
		var hHeroIcon = tHeroIcons[nEntityIndex];
		if (!hHeroIcon)
		{
			var szUnitName = Entities.GetUnitName(nEntityIndex);
			hHeroIcon = $.CreatePanel("Image", $("#Container"), "HeroIcon" + nEntityIndex);
			hHeroIcon.SetImage("file://{images}/custom_game/minimap/icons/" + szUnitName + ".tga");
			tHeroIcons[nEntityIndex] = hHeroIcon;
		}
		
		hHeroIcon.visible = true;
		var vPlayerPosition = Entities.GetAbsOrigin(nEntityIndex);
		var fPlayerCoordX = vPlayerPosition[0] - vCameraPosition[0];
		var fPlayerCoordY = vCameraPosition[1] - vPlayerPosition[1];
		var fRotatedCoordX = Math.cos(fYawRadians) * fPlayerCoordX - Math.sin(fYawRadians) * fPlayerCoordY;
		var fRotatedCoordY = Math.sin(fYawRadians) * fPlayerCoordX + Math.cos(fYawRadians) * fPlayerCoordY;
			
		hHeroIcon.style.position = (fRotatedCoordX/fZoomFactor + 94) + "px " + (fRotatedCoordY/fZoomFactor + 94) + "px 0px";
		hHeroIcon.SetHasClass("MinimapIconDead", !Entities.IsAlive(nEntityIndex));
	}
	
	/*var tEntityList = Entities.GetAllEntitiesByClassname("npc_dota_creep_neutral");
	var nEntityListSize = 0;
	for (var k in tEntityList)
		nEntityListSize++;
	
	if (nEntityListSize > tUnitIcons.length)
	{
		var hTextureContainer = $("#Container");
		for (var i = tUnitIcons.length; i < nEntityListSize; i++)
		{
			var hIcon = $.CreatePanel("Image", hTextureContainer, "UnitIcon" + (i + 1));
			hIcon.SetImage("file://{images}/custom_game/minimap/icons/npc_generic_unit.tga");
			tUnitIcons.push(hIcon);
		}
	}
	
	var i = 1;
	for (var k in tEntityList)
	{
		var nEntityIndex = parseInt(tEntityList[k]);
		var vUnitPosition = Entities.GetAbsOrigin(nEntityIndex);
		if (typeof vUnitPosition !== "undefined")
		{
			var nIconXOffset = (tMapInfo.left - vUnitPosition[0])/nMapWidth * nTexWidth + 6;
			var nIconYOffset = (vUnitPosition[1] - tMapInfo.top)/nMapHeight * nTexHeight + 6;
			$("#UnitIcon" + i).style.position = (nTextureXOffset - nIconXOffset) + "px " + (nTextureYOffset - nIconYOffset) + "px 0px";
			$("#UnitIcon" + i).style.saturation = Entities.IsEnemy(nEntityIndex) ? 1.0 : 0.0;
			$("#UnitIcon" + i).visible = true;
			i++;
		}
	}
	
	for (var j = i; j <= tUnitIcons.length; j++)
		$("#UnitIcon" + j).visible = false;
	*/
	$.Schedule(0.03, UpdateMinimap);
}

(function()
{
	var tMapInfo = CustomNetTables.GetTableValue("game", "map");
	if (tMapInfo.override !== 1)
	{
		$.GetContextPanel()._tMapInfo = tMapInfo
		$("#Texture").SetImage("file://{images}/maps/" + tMapInfo.name + ".png");
		$.GetContextPanel()._nMapWidth = tMapInfo.right - tMapInfo.left;
		$.GetContextPanel()._nMapHeight = tMapInfo.bottom - tMapInfo.top;
		$.Schedule(0.1, UpdateMinimap);
	}
})();