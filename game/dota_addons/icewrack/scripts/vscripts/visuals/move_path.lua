--[[require("pathfinding")

function CreateMovePath(hEntity, vStartPos, vTargetPos)
	local tPathVectors = CPathfinding:FindPathVectors(vStartPos, vTargetPos)
	if tPathVectors then
		for i=1,#tPathVectors-1 do
			local v1 = GetGroundPosition(GridToWorldVector(tPathVectors[i][1], tPathVectors[i][2]), hEntity)
			local v2 = GetGroundPosition(GridToWorldVector(tPathVectors[i+1][1], tPathVectors[i+1][2]), hEntity)
			DebugDrawLine(v1, v2, 255, 0, 0, true, 4.0)
		end
	end
end]]