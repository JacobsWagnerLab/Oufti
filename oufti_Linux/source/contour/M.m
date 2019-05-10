function a=M(a,t)
    % rotates a set of points clockwise by an angle t and scales it by a factor s
    cost = cos(t);
    sint = sin(t);
    mt = [cost -sint; sint cost];
    for i=1:size(a,1)
        a(i,:)=a(i,:)*mt;
    end
end