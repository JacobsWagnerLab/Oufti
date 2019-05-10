function w=waitbarN(n,s)
    w = waitbar(n,s);
    p = rand^2;
    q = sin(rand*2*pi);
    color = [p (1-p)*q^2 (1-p)*(1-q^2)];
    set(findobj(w,'Type','patch'),'FaceColor',color,'EdgeColor',color)
    set(findobj(w,'Type','axes'),'Children',get(findobj(w,'Type','axes'),'Children'))
end