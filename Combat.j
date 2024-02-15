library Combat initializer init requires Math

    globals
        private real MAX_COLL_SIZE = 72.0

        private player Filter_player = null
        private real Filter_x = 0.0
        private real Filter_y = 0.0
        private real Filter_radius = 0.0

        private unit GetMainTarget_unit
        private group GetMainTarget_group = CreateGroup()

        public boolexpr IN_RANGE
        public boolexpr IN_RANGE_ENEMY
        public boolexpr ATTACKABLE
        public boolexpr ATTACKABLE_ORGANIC
        public boolexpr IN_RANGE_ENEMY_ATTACKABLE
    endglobals

    // Include collision size for edge-to-edge range checking
    public function GetMaxRange takes real r returns real
        return r + MAX_COLL_SIZE
    endfunction

    /////////////
    // FILTERS //
    /////////////

    private function PrepareFilter takes player p, real x, real y, real r returns nothing
        set Filter_player = p
        set Filter_x = x
        set Filter_y = y
        set Filter_radius = r
    endfunction

    // Filter for proper range that includes unit's hitbox
    private function filterInRange takes nothing returns boolean
        local unit f = GetFilterUnit()
        local boolean test = DistanceBetweenXY(Filter_x, Filter_y, GetUnitX(f), GetUnitY(f)) - BlzGetUnitCollisionSize(f) < Filter_radius
        set f = null
        return test
    endfunction

    private function filterInRangeEnemy takes nothing returns boolean
        return IsUnitEnemy(GetFilterUnit(), Filter_player) and filterInRange()
    endfunction

    // Generic function for combat spells
    private function filterAttackable takes nothing returns boolean
        return IsUnitAliveBJ(GetFilterUnit()) and not BlzIsUnitInvulnerable(GetFilterUnit())
    endfunction

    // Checks for organic targets
    private function filterAttackableOrganic takes nothing returns boolean
        return not IsUnitType(GetFilterUnit(), UNIT_TYPE_MECHANICAL) and filterAttackable()
    endfunction

    //////////
    // INIT //
    //////////

    private function init takes nothing returns nothing
        set IN_RANGE = Condition(function filterInRange)
        set IN_RANGE_ENEMY = Condition(function filterInRangeEnemy)
        set ATTACKABLE = Condition(function filterAttackable)
        set ATTACKABLE_ORGANIC = Condition(function filterAttackableOrganic)
        //
        set IN_RANGE_ENEMY_ATTACKABLE = And(IN_RANGE_ENEMY, ATTACKABLE)
    endfunction

    /////////////////////
    // ENUMS FUNCTIONS //
    /////////////////////

    // Main function that looks for units in range (respects their hitbox)
    public function GetInRange takes group g, real x, real y, real r returns nothing
        call PrepareFilter(null, x, y, r)
        call GroupEnumUnitsInRange(g, x, y, r + MAX_COLL_SIZE, IN_RANGE)
    endfunction

    // Generic function for getting units in range when a player is needed for filtering
    public function GetPlayerInRangeMatching takes group g, player p, real x, real y, real r, boolexpr filter returns nothing
        call PrepareFilter(p, x, y, r)
        call GroupEnumUnitsInRange(g, x, y, r + MAX_COLL_SIZE, filter)
    endfunction

    // Often used for combat
    public function GetPlayerEnemyInRange takes group g, player p, real x, real y, real r returns nothing
        call GetPlayerInRangeMatching(g, p, x, y, r, IN_RANGE_ENEMY_ATTACKABLE)
    endfunction

    //////////////////////
    // OTHER COMBAT API //
    //////////////////////

    // Returns unit in the group nearest to the specified coordinates
    public function GetMainTarget takes group g, real x, real y returns unit
        local unit u
        local real dist
        local real minDist = 99999

        call GroupAddGroup(g, GetMainTarget_group) // <-- It's reversed! Hahah!
        set GetMainTarget_unit = null
        
        loop
            set u = FirstOfGroup(GetMainTarget_group)
            exitwhen u == null

            set dist = DistanceBetweenXY(x, y, GetUnitX(u), GetUnitY(u))
            if dist < minDist then
                set minDist = dist
                set GetMainTarget_unit = u
            endif
            call GroupRemoveUnit(GetMainTarget_group, u)
        endloop

        set u = null
        return GetMainTarget_unit
    endfunction

    // Backstab - ranges from 0 to 180, values close to 0 indicate backstab
    public function GetBackstabAngle takes unit source, unit target returns real
        // TODO: math func?
        local real dmgAngle = bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(source), GetUnitX(target) - GetUnitX(source))
        local real facingAngle = GetUnitFacing(target)
        // Map between (0 - 360)
        if dmgAngle < 0.0 then
            set dmgAngle = 360.0 + dmgAngle
        endif
        set dmgAngle = RAbsBJ(dmgAngle - facingAngle)
        // Map between (0 - 180)
        if dmgAngle > 180 then
            return 360 - dmgAngle
        endif
        return dmgAngle
    endfunction

    // Cleave...
    public function GetCleaveAngle takes unit source, unit target returns real
        // TODO: math func?
        local real dmgAngle = AngleBetweenUnits(source, target)
        local real facingAngle = GetUnitFacing(source)
        // Map between (0 - 360)
        if dmgAngle < 0.0 then
            set dmgAngle = 360.0 + dmgAngle
        endif
        set dmgAngle = RAbsBJ(dmgAngle - facingAngle)
        // Map between (0 - 180)
        if dmgAngle > 180 then
            return 360 - dmgAngle
        endif
        return dmgAngle
    endfunction

endlibrary

