function b=B(a,t)
    % bends a set of points (down if t>0) with the radius of curvature 1/t
    if abs(t)<1/10000000, b=a; return; end
    R = sign(t)*max(1/abs(t),1.1*max(-a(:,2)));
    b(:,1)=(a(:,2)+R).*sin(a(:,1)/R);
    b(:,2)=(a(:,2)+R).*cos(a(:,1)/R)-R;
end