function b = makeccw(a)
    if isempty(a)
        b = [];
    else
        if isContourClockwise(a)
            b = circShiftNew(double(flipud(a)),1);
        else
            b=a;
        end
    end
end