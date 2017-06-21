iw_lina_lesser_fireball = class({})

function iw_lina_lesser_fireball:OnAbilityLearned()
	local hEntity = self:GetCaster()
	local hAbility = hEntity:AddAbility("iw_lina_lesser_fireball_orb")
	hAbility:SetLevel(1)
	hAbility:SetActivated(false)
	
	local hAttackSource = self._hAttackSource
	if not hAttackSource then
		hAttackSource = CExtItem(CreateItem("iw_lina_lesser_fireball_source", nil, nil))
		hAttackSource:SetOwner(hEntity)
		hEntity:AddToRefreshList(hAttackSource)
		hAttackSource._hParentAbility = self
		self._hAttackSource = hAttackSource
	end
end

function iw_lina_lesser_fireball:OnAbilityBind()
	local hEntity = self:GetCaster()
	local hAbility = hEntity:FindAbilityByName("iw_lina_lesser_fireball_orb")
	hAbility:SetActivated(true)
end

function iw_lina_lesser_fireball:OnAbilityUnbind()
	local hEntity = self:GetCaster()
	local hAbility = hEntity:FindAbilityByName("iw_lina_lesser_fireball_orb")
	hAbility:SetActivated(false)
end

function iw_lina_lesser_fireball:OnSpellStartAutoCast(hTarget)
	local hEntity = self:GetCaster()
	local hAbility = hEntity:FindAbilityByName("iw_lina_lesser_fireball_orb")
	hEntity:SetOrbAttackSource(self._hAttackSource)
	hEntity:IssueOrder(DOTA_UNIT_ORDER_CAST_TARGET, hTarget, hAbility, nil, false)
	return false
end

function iw_lina_lesser_fireball:OnToggleAutoCast()
	local hEntity = self:GetCaster()
	local hAbility = hEntity:FindAbilityByName("iw_lina_lesser_fireball_orb")
	if hAbility:GetAutoCastState() == self:GetAutoCastState() then
		hAbility:ToggleAutoCast()
	end
	
	local hAttackSource = self._hAttackSource
	if not self:GetAutoCastState() then
		hAttackSource:AddChild(hEntity)
		hEntity:AddAttackSource(hAttackSource, 2)
	else
		hAttackSource:RemoveChild(hEntity)
		hEntity:RemoveAttackSource(hAttackSource, 2)
	end
	return true
end

function OnLesserFireballOrbFire(args)
	local hEntity = args.caster
	local hAbility = hEntity:FindAbilityByName("iw_lina_lesser_fireball")
	hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_POST_ABILITY_CAST, hAbility)
end

function OnLesserFireballOrbImpact(args)
	local hEntity = args.caster
	local hTarget = args.target
	local hAbility = hEntity:FindAbilityByName("iw_lina_lesser_fireball")
	local hAttackSource = hAbility._hAttackSource
	
	local tDamageTable =
	{
		attacker = hEntity,
		target = hTarget,
		source = hAttackSource,
		damage =
		{
			[IW_DAMAGE_TYPE_FIRE] = 
			{
				min = hAttackSource:GetPropertyValue(IW_PROPERTY_DMG_FIRE_BASE),
				max = hAttackSource:GetPropertyValue(IW_PROPERTY_DMG_FIRE_BASE) + hAttackSource:GetPropertyValue(IW_PROPERTY_DMG_FIRE_VAR),
			}
		}
	}
	DealPrimaryDamage(hAbility, tDamageTable)
end