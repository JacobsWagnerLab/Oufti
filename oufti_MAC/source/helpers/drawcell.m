function [xlimit,ylimit,nspotsdrawn]=drawcell(clst,mode,spotfieldnames,signalfieldnames,markersize,colortable,marker,numbers,margin,p,shift,cellId)
% Service function for dispspots, dispspotsall, and dispspotsgrid functions
% 
% clst = cellList{frame}.
% mode: 1=spotFinderZ's cellList, 2=spotFinderF's spotList.
% spotfieldnames: cell array of spot field names, only first is used for
%     filtering but all will be displayed.
% signalfieldnames: cell array of signal field names, only first is used
%     for filtering.
% markersize: size of the marker in pixels.
% colortable: Nx3 table of colors, N=length(spotfieldnames) or
%     N=length(spotfieldnames)+1
% marker: 0=dot, 1=disk, 2=circle.
% numbers: true = display cell numbers
% margin: 0=none, 1=box, 2=tight bound.
% p: structure of filtering parameters.
% shift: [x y] shift coordinates.


nfields = length(spotfieldnames);
if isempty(shift), shift = [0 0]; end
if margin>=1
    xlimit = [Inf 0];
    ylimit = [Inf 0];
else
    xlimit = [];
    ylimit = [];
end
if mode==1
    if ~isempty(p) && (~isempty(p.spotmagnitude) || ~isempty(p.spotheight) || ~isempty(p.spotwidth) || ~isempty(p.spotposition) || ~isempty(p.spotrelposition))
        spotcheck = true;
    else
        spotcheck = false;
    end
    nspotsdrawn = -ones(length(clst),nfields);
    if isempty(cellId)
      cellId = 1:length(clst);
    end
    for cell=cellId
        idx = cellId == cell;
        if ~isempty(clst{idx}) && length(clst{idx}.mesh)>1
            % check all filters if the cell fails any of them
            if ~isempty(p)
                if ~isempty(p.cellintensity)
                    a = sum(clst{idx}.(signalfieldnames{1}));
                    if a<p.cellintensity(1) || a>p.cellintensity(2), continue; end
                end
                if ~isempty(p.cellmeanintensity)
                    a = sum(clst{idx}.(signalfieldnames{1}))/clst{idx}.area;
                    if a<p.cellmeanintensity(1) || a>p.cellmeanintensity(2), continue; end
                end
                if ~isempty(p.celllength)
                    a = clst{idx}.length;
                    if a<p.celllength(1) || a>p.celllength(2), continue; end
                end
                if ~isempty(p.cellarea)
                    a = clst{idx}.area;
                    if a<p.cellarea(1) || a>p.cellarea(2), continue; end
                end
                if ~isempty(p.cellvolume)
                    a = clst{idx}.volume;
                    if a<p.cellvolume(1) || a>p.cellvolume(2), continue; end
                end
                if ~isempty(p.cellmeanwidth)
                    a = clst{idx}.mesh;
                    a = mean(sqrt((a(:,1)-a(:,3)).^2+(a(:,2)-a(:,4)).^2));
                    if a<p.cellmeanwidth(1) || a>p.cellmeanwidth(2), continue; end
                end
                if ~isempty(p.cellmaxwidth)
                    a = clst{idx}.mesh;
                    a = sqrt(max((a(:,1)-a(:,3)).^2+(a(:,2)-a(:,4)).^2));
                    if a<p.cellmaxwidth(1) || a>p.cellmaxwidth(2), continue; end
                end
                if ~isempty(p.cellcurvature)
                    a = getcurvature({{clst{idx}}});
                    a = a(1);
                    if a<p.cellcurvature(1) || a>p.cellcurvature(2), continue; end
                end
                if spotcheck
                    if ~isfield(clst{idx},spotfieldnames{1}),continue; end
                    s = eval(['clst{cell}.' eval('spotfieldnames{1}')]);
                    spotindex = s.x<Inf;
                    dispcell = false;
                    if ~isempty(p.nspots)
                        a = length(clst{idx}.(spotfieldnames{1}).x);
                        if a==0, dispcell=true; end
                        if a<p.nspots(1) || a>p.nspots(2), continue; end
                    end
                    if ~isempty(p.spotmagnitude)
                        a = clst{idx}.(spotfieldnames{1}).magnitude;
                        spotindex(a<p.spotmagnitude(1) | a>p.spotmagnitude(2))=0;
                    end
                    if ~isempty(p.spotheight)
                        a = clst{idx}.(spotfieldnames{1}).h;
                        spotindex(a<p.spotheight(1) | a>p.spotheight(2))=0;
                    end
                    if ~isempty(p.spotwidth)
                        a = clst{idx}.(spotfieldnames{1}).w;
                        spotindex(a<p.spotwidth(1) | a>p.spotwidth(2))=0;
                    end
                    if ~isempty(p.spotposition)
                        a = clst{idx}.(spotfieldnames{1}).l;
                        b=0; for i=1:length(p.spotposition), b=b+(a<p.spotposition(i)); end
                        spotindex(mod(b,2)==0)=0;
                    end
                    if ~isempty(p.spotrelposition)
                        a = clst{idx}.(spotfieldnames{1}).l/clst{idx}.length;
                        b=0; for i=1:length(p.spotrelposition), b=b+(a<p.spotrelposition(i)); end
                        spotindex(mod(b,2)==0)=0;
                    end
                    if ~dispcell && sum(spotindex)==0, continue; end
                end
            end
            
            % draw the cell if good
            if isempty(cellId)
                mesh = clst{cell}.mesh;
            else
                idx = cellId == cell;
                mesh = clst{idx}.mesh;
            end
            plot(mesh(:,1)+shift(1),mesh(:,2)+shift(2),'-g',mesh(:,3)+shift(1),mesh(:,4)+shift(2),'-g')
            if strcmp(get(gca,'nextplot'),'replace'), set(gca,'nextplot','add'); plotmodechanged = 1; else plotmodechanged = 0; end
            if numbers
                e = round(size(mesh,1)/2);
                text(round(mean([mesh(e,1);mesh(e,3)])+shift(1)),...
                    round(mean([mesh(e,2);mesh(e,4)])+shift(2)),...
                    num2str(cell),'HorizontalAlignment','center','FontSize',8,'color',[0 1 0]);
            end
            if margin==1
                box = clst{idx}.box;
                xlimit = [min(xlimit(1),box(1)) max(xlimit(2),box(1)+box(3))];
                ylimit = [min(ylimit(1),box(2)) max(ylimit(2),box(2)+box(4))];
            elseif margin==2
                xlimit = [min(xlimit(1),min(min(mesh(:,[1 3])))) max(xlimit(2),max(max(mesh(:,[1 3]))))];
                ylimit = [min(ylimit(1),min(min(mesh(:,[2 4])))) max(ylimit(2),max(max(mesh(:,[2 4]))))];
            end
            xarray = {};
            yarray = {};
            for f=1:nfields
                if ~isfield(clst{idx},spotfieldnames{f})
                    x = [];
                    y = [];
                else
                    if ~isempty(clst{idx}.spots)
                        x = clst{idx}.(spotfieldnames{f}).x;
                        y = clst{idx}.(spotfieldnames{f}).y;
                    else
                        x = [];
                        y = [];
                    end
                end
                if spotcheck && f==1
                    x = x(spotindex);
                    y = y(spotindex);
                end
                nspotsdrawn(idx,f) = length(x);
                xarray = [xarray x+shift(1)];
                yarray = [yarray y+shift(2)];
            end
            drawcircle(xarray,yarray,markersize,colortable,marker)
            if plotmodechanged, set(gca,'nextplot','replace'); end
        end
    end
else
    x = zeros(1,length(clst));
    y = zeros(1,length(clst));
    nspotsdrawn = length(clst);
    ind = 0;
    for spot=1:length(clst)
        if ~isempty(clst{spot})
            ind = ind+1;
            x(ind) = clst{spot}.x;
            y(ind) = clst{spot}.y;
        end
    end
    drawcircle({x+shift(1)},{y+shift(2)},markersize,colortable(1,:),marker)
end


function drawcircle(x,y,r,c,marker)
if r<=0 || isempty(x), return, end
if marker==0 % dot
    for i=1:length(x), 
        plot(x{i},y{i},'.','color',c(i,:),'MarkerSize',r); 
    end
else % disk / circle
    dx = r*sin(0:pi/20:2*pi);
    dy = r*cos(0:pi/20:2*pi);
    if marker==1 % disk
        for j=1:length(x), for i=1:length(x{j}), patch(x{j}(i)+dx,y{j}(i)+dy,c(j,:),'EdgeColor',c(j,:)); end; end
        if size(c,1)>length(x) % overlap regions in a different color
            ox = {};
            oy = {};
            for j=2:length(x{:})
                for k=1:j-1
                    for i=1:length(x)
                            [a,b] = polybool('intersection',x{i}(j)+dx,y{i}(j)+dy,x{i}(k)+dx,y{i}(k)+dy);
                            if ~isempty(a), ox=[ox a]; oy=[oy b]; end
                    end
                end
            end
            for j=1:length(ox), patch(ox{j},oy{j},c(end,:),'EdgeColor',c(end,:)); end
        end
    elseif marker==2 % circle
        for j=1:length(x), for i=1:length(x{j}), plot(x{j}(i)+dx,y{j}(i)+dy,'color',c(j,:)); end; end
    end
end