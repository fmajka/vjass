struct ProjectilePetoperz extends ProjectileBase
	static ProjectileType ptype

	static method filter takes nothing returns boolean
		return ProjectileBase.filterTargetableEnemy()
	endmethod

	static method onInit takes nothing returns nothing
		set ptype = ProjectileType.create('h000', 900, 1200, 60, Filter(function ProjectilePetoperz.filter), 3)
	endmethod

	static method create takes unit owner, real angle returns ProjectilePetoperz
		return ProjectilePetoperz.allocate(owner, ProjectilePetoperz.ptype, angle)
	endmethod

	method onHit takes unit target returns nothing
		call DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\FireBallMissile\\FireBallMissile.mdl", target, "chest"))
		call UnitDamageTarget(this.owner, target, 66, false, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_CLAW_MEDIUM_SLICE)
	endmethod
endstruct