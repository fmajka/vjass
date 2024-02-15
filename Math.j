library Math

    function DistanceBetweenUnits takes unit a, unit b returns real
        local real xDiff = GetUnitX(b) - GetUnitX(a)
        local real yDiff = GetUnitY(b) - GetUnitY(a)
        return SquareRoot(xDiff*xDiff + yDiff*yDiff)
    endfunction

    function DistanceBetweenXY takes real x1, real y1, real x2, real y2 returns real
        local real xDiff = x2 - x1
        local real yDiff = y2 - y1
        return SquareRoot(xDiff*xDiff + yDiff*yDiff)
    endfunction

    function AngleBetweenUnits takes unit a, unit b returns real
        local real xDiff = GetUnitX(b) - GetUnitX(a)
        local real yDiff = GetUnitY(b) - GetUnitY(a)
        return bj_RADTODEG * Atan2(yDiff, xDiff)
    endfunction

    function AngleBetweenXY takes real x1, real y1, real x2, real y2 returns real
        local real xDiff = x2 - x1
        local real yDiff = y2 - y1
        return bj_RADTODEG * Atan2(yDiff, xDiff)
    endfunction

endlibrary