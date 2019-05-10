function res = getdmap(clist,box,sz,rs,n)
    if isempty(box)
        mask = 0;
        for cell=1:length(clist)
            if ~isempty(clist{cell}) && length(clist{cell}.mesh)>1
                mesh = clist{cell}.mesh;
                plgx = ([mesh(1:end-1,1);flipud(mesh(:,3))])*rs;
                plgy = ([mesh(1:end-1,2);flipud(mesh(:,4))])*rs;
                mask = mask+poly2mask(plgx,plgy,sz(1),sz(2));
            end
        end
    else
        mesh = clist.mesh;
        plgx = ([mesh(1:end-1,1);flipud(mesh(:,3))]-box(1)+1)*rs;
        plgy = ([mesh(1:end-1,2);flipud(mesh(:,4))]-box(2)+1)*rs;
        mask = poly2mask(plgx,plgy,sz(1),sz(2));
    end
    mask = ~mask;
    res = mask;
    se = strel('disk',1);
    for i=1:n
        mask = imerode(mask,se);
        res = res+mask;
    end
end