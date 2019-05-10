function [tx,ty] = getnormals(x,y)
    tx = circShiftNew(y,-1) - circShiftNew(y,1);
    ty = circShiftNew(x,1) - circShiftNew(x,-1);
    dtxy = sqrt(tx.^2 + ty.^2);
    tx = tx./dtxy;
    ty = ty./dtxy;
end