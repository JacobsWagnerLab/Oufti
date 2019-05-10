function f2=Bf(c,f,t)
    % converts forces from a bend to non-bent frame
    % now c and f2 a are in the non-bent configuration and f is in the bent one
    % essentially the point rotates by angle phi
    if abs(t)<1/10000000, f2=f; return; end
    R = sign(t)*max(1/abs(t),1.1*max(-c(:,2)));
    phi = c(:,1)/R;
    cs = cos(phi);
    sn = sin(phi);
    
    f2(:,1) = cs.*f(:,1) - sn.*f(:,2);
    f2(:,2) = sn.*f(:,1) + cs.*f(:,2);
end