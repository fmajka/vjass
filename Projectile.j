library Projectile requires Math

	struct ProjectileType
		integer unitId
		real distance
		real speed
		real radius
		filterfunc filter
		integer hitCount

		static method create takes integer unitId, real distance, real speed, real radius, filterfunc filter, integer hitCount returns ProjectileType
			local ProjectileType new = ProjectileType.allocate()
			set new.unitId = unitId
			set new.distance = distance
			set new.speed = speed
			set new.radius = radius
			set new.filter = filter
			set new.hitCount = hitCount
			return new
		endmethod
	endstruct

	struct ProjectileBase
		// Struct
		private static real MAX_COLLISION_SIZE = 72.0
		private static ProjectileBase array projectileArr
		private static integer projectileCount = 0
		public static ProjectileBase triggerProjectile

		public static method filterDefault takes nothing returns boolean
			local boolean inRange = DistanceBetweenUnits(GetFilterUnit(), triggerProjectile.u) < triggerProjectile.projectileType.radius + BlzGetUnitCollisionSize(GetFilterUnit())
			local boolean wasntHitBefore = not IsUnitInGroup(GetFilterUnit(), triggerProjectile.hitGroup)
			return GetFilterUnit() != triggerProjectile.u and wasntHitBefore and inRange
		endmethod

		public static method filterTargetable takes nothing returns boolean
			return filterDefault() and IsUnitAliveBJ(GetFilterUnit()) and not BlzIsUnitInvulnerable(GetFilterUnit())
		endmethod

		public static method filterTargetableEnemy takes nothing returns boolean
			return filterDefault() and filterTargetable() and IsUnitEnemy(GetFilterUnit(), GetOwningPlayer(triggerProjectile.owner))
		endmethod

		static method update takes real dt returns nothing
			local integer i = 0
			local ProjectileBase p
			loop
				exitwhen i == projectileCount
				set p = projectileArr[i]
				call p.move(dt)
				call p.collide()
				set i = i + 1
			endloop
			if projectileCount == 0 then
				return
			endif
			set p = projectileArr[projectileCount - 1]
			if not IsUnitAliveBJ(p.u) then
				call p.destroy()
				set projectileCount = projectileCount - 1 
			endif
		endmethod

		// Instance
		unit u
		unit owner
		group hitGroup
		real distance
		real angle
		ProjectileType projectileType
		
		static method create takes unit owner, ProjectileType projectileType, real angle returns ProjectileBase
			local ProjectileBase new = ProjectileBase.allocate()
			set new.u = CreateUnit(GetOwningPlayer(owner), projectileType.unitId, GetUnitX(owner), GetUnitY(owner), angle)
			set new.hitGroup = CreateGroup()
			set new.distance = projectileType.distance
			set new.owner = owner
			set new.projectileType = projectileType
			set new.angle = angle * bj_DEGTORAD
			set projectileArr[projectileCount] = new
			set projectileCount = projectileCount + 1
			return new
		endmethod

		public method getHitsRemaining takes nothing returns integer
			return this.projectileType.hitCount - CountUnitsInGroup(this.hitGroup)
		endmethod

		method move takes real dt returns nothing
			local real dist = this.projectileType.speed * dt
			call SetUnitX(this.u, GetUnitX(this.u) + dist * Cos(this.angle))
			call SetUnitY(this.u, GetUnitY(this.u) + dist * Sin(this.angle))
			set this.distance = this.distance - dist
			if this.distance <= 0 then
				call KillUnit(this.u)
			endif
		endmethod

		method collide takes nothing returns nothing
			local group g = CreateGroup()
			local unit u
			set triggerProjectile = this
			call GroupEnumUnitsInRange(g, GetUnitX(this.u), GetUnitY(this.u), this.projectileType.radius + MAX_COLLISION_SIZE, this.projectileType.filter)
			loop
				exitwhen CountUnitsInGroup(g) == 0 or this.getHitsRemaining() == 0
				// TODO: find nearest target
				set u = FirstOfGroup(g)
				call GroupRemoveUnit(g, u)
				call GroupAddUnit(this.hitGroup, u)
				call this.onHit(u)
			endloop
			call DestroyGroup(g)
			set u = null
			set g = null
			if this.getHitsRemaining() == 0 then
				call KillUnit(this.u)
			endif
		endmethod

		// Overridable
		stub method onHit takes unit target returns nothing
		endmethod
	endstruct

endlibrary