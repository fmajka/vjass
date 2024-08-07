library Combat initializer init requires Math

    globals
        private real MAX_COLL_SIZE = 72.0

        private real Filter_x = 0.0
        private real Filter_y = 0.0
        private real Filter_radius = 0.0
        private player Filter_player = null

        private unit GroupGetNearestXY_unit
        private group GroupGetNearestXY_group = CreateGroup()

        public boolexpr IN_RANGE
        public boolexpr IN_RANGE_ENEMY
        public boolexpr ATTACKABLE
        public boolexpr ATTACKABLE_ORGANIC
        public boolexpr IN_RANGE_ENEMY_ATTACKABLE
    endglobals

    // Include collision size for edge-to-edge range checking
    // public function GetMaxRange takes real r returns real
    //     return r + MAX_COLL_SIZE
    // endfunction

    /////////////
    // FILTERS //
    /////////////

    private function PrepareFilter takes real x, real y, real r, player p returns nothing
        set Filter_x = x
        set Filter_y = y
        set Filter_radius = r
        set Filter_player = p
    endfunction

    // Filter for proper range that includes unit's hitbox
    private function filterInRange takes nothing returns boolean
        return DistanceBetweenXY(Filter_x, Filter_y, GetUnitX(GetFilterUnit()), GetUnitY(GetFilterUnit())) - BlzGetUnitCollisionSize(GetFilterUnit()) < Filter_radius
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

    // Generic function for getting units in range when a player is needed for filtering
    function GetInRangePlayerMatching takes group g, real x, real y, real r, player p, boolexpr filter returns nothing
        call PrepareFilter(x, y, r, p)
        call GroupEnumUnitsInRange(g, x, y, r + MAX_COLL_SIZE, filter)
    endfunction

    // Often used for combat
    function GetInRangePlayerEnemy takes group g, real x, real y, real r, player p returns nothing
        call GetInRangePlayerMatching(g, x, y, r, p, IN_RANGE_ENEMY_ATTACKABLE)
    endfunction

    //////////////////////
    // OTHER COMBAT API //
    //////////////////////

    // Returns unit in the group nearest to the specified coordinates
    function GroupGetNearestXY takes group g, real x, real y returns unit
        local unit u
        local real dist
        local real minDist = 99999
        call GroupAddGroup(g, GroupGetNearestXY_group) // <-- It's reversed! Hahah!
        set GroupGetNearestXY_unit = null
        loop
            set u = FirstOfGroup(GroupGetNearestXY_group)
            exitwhen u == null
            set dist = DistanceBetweenXY(x, y, GetUnitX(u), GetUnitY(u))
            if dist < minDist then
                set minDist = dist
                set GroupGetNearestXY_unit = u
            endif
            call GroupRemoveUnit(GroupGetNearestXY_group, u)
        endloop
        set u = null
        return GroupGetNearestXY_unit
    endfunction

    // Backstab - ranges from 0 to 180, values close to 0 indicate backstab
    function GetBackstabAngle takes unit source, unit target returns real
        local real dmgAngle = AngleBetweenUnits(source, target)
        if dmgAngle < 0.0 then
            set dmgAngle = 360.0 + dmgAngle // Map between (0 - 360)
        endif
        set dmgAngle = RAbsBJ(dmgAngle - GetUnitFacing(target))
        if dmgAngle > 180 then
            return 360 - dmgAngle // Map between (0 - 180)
        endif
        return dmgAngle
    endfunction

    // Difference between caster's facing and angle between units
    function GetCleaveAngle takes unit source, unit target returns real
        local real dmgAngle = AngleBetweenUnits(source, target)
        if dmgAngle < 0.0 then
            set dmgAngle = 360.0 + dmgAngle // Map between (0 - 360)
        endif
        set dmgAngle = RAbsBJ(dmgAngle - GetUnitFacing(source))
        if dmgAngle > 180 then
            return 360 - dmgAngle // Map between (0 - 180)
        endif
        return dmgAngle
    endfunction

endlibrary

