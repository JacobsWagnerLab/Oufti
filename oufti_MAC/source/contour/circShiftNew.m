function c=circShiftNew(a,b)
    L=size(a,1);
    c = a(mod((0:L-1)-b,L)+1,:);
end
