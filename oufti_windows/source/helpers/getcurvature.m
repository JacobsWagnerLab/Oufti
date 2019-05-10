function curvlist = getcurvature(clist,varargin)
% curvlist = getcurvature(cellList)
% curvlist = getcurvature(cellList,'long mean')
% curvlist = getcurvature(cellList,'long mean',window)
% curvlist = getcurvature(cellList,'long all')
% curvlist = getcurvature(cellList,'long all',window)
% curvlist = getcurvature(...,'addstat')
% 
% This function calculates radius of curvature for every cell in a list
% obtained by MicrobeTracker.
% 
% <cellList> - input cell list.
% <curvlist> - output table. Each row corresponds to a cell (or a segment
%     of a cell in 'long all' mode). The columns are: radius of curvature,
%     frame number, cell number, cell length, cell area, cell volume. The
%     last three values are only added if 'addstat' option is selected.
%     [:,radius_of_curvature frame cell_number [length] [area] [volume]]
% 'long mean' or 'long' - splits every cell to segments and outputs the
%     mean curvature of all the segments.
% 'long all' - splits every cell to segments and outputs the curvature of
%     every segment in a separate row.
% <window> - maximum length of the segments used in ;long mean' and
%      'long all' modes'. If a non-integer number of windows fits into a
%      cell, the number of windows is rounded up and each window is
%      shortened accordingly. Default: 30.
% 'addstat' - add extra statistics for the cells: cell length, cell area,
%      and cell volume.
%

%------------------------------------------------------------------
%update:  Feb. 20, 2013 Ahmad.P new data format
if isfield(clist,'meshData')
    cellList = oufti_makeCellListDouble(clist);
    for ii = 1:length(cellList.meshData)
        for jj = 1:length(cellList.meshData{ii})
            cellList.meshData{ii}{jj} = getextradata(cellList.meshData{ii}{jj});
        end
    end
end
%------------------------------------------------------------------

    n = length(varargin);
    window = 30;
    mode = 1; % 1 - small cell, 2 - long all, 3 - long mean
    addstat = false;
    for i=1:n
        if ischar(varargin{i}) && (strcmp(varargin{i},'long') || strcmp(varargin{i},'long mean'))
            mode = 3;
            if i<n && strcmp(class(varargin{i+1}),'double')
                window = varargin{i+1};
            end
        elseif ischar(varargin{i}) && strcmp(varargin{i},'long all')
            mode = 2;
            if i<n && strcmp(class(varargin{i+1}),'double')
                window = varargin{i+1};
            end
        elseif ischar(varargin{i}) && strcmp(varargin{i},'addstat')
            addstat = true;
        end
    end
    
    curvlist = [];
    stat = [];
if ~isfield(cellList,'meshData')
    for frame=1:length(clist)
        for cell=1:length(clist{frame})
            if ~isempty(clist{frame}{cell}) && length(clist{frame}{cell}.mesh)>4
                if addstat
                    stat = [clist{frame}{cell}.length clist{frame}{cell}.area ...
                            clist{frame}{cell}.volume];
                end
                mesh = clist{frame}{cell}.mesh;
                s = size(mesh,1);
                if mode==1 || s<=window
                    crv = getcurve(mesh);
                    curvlist = [curvlist; [crv frame cell stat]];
                elseif mode==2 % long all
                    n = max(1,floor(s/window));
                    for i=1:n
                        crv = getcurve(mesh(floor((i-1)*s/n)+1:floor(i*s/n),:));
                        curvlist = [curvlist;[crv frame cell stat]];
                    end
                elseif mode==3 % long mean
                    n = max(1,floor(s/window));
                    crv = zeros(1,n);
                    for i=1:n
                        crv(i) = getcurve(mesh(floor((i-1)*s/n)+1:floor(i*s/n),:));
                    end
                    crv = abs(crv);
                    crv = 1./mean(1./crv);
                    curvlist = [curvlist;[crv frame cell stat]];
                end

            end
        end
    end
else
      for frame=1:length(cellList.meshData)
          [~,cellId] = oufti_getFrame(frame,cellList);
            for cell = cellId
                if oufti_doesCellStructureHaveMesh(cell,frame,cellList)
                    cellStructure = oufti_getCellStructure(cell,frame,cellList);
                    if addstat
                        stat = [cellStructure.length cellStructure.area ...
                            cellStructure.volume];
                    end
                    mesh = cellStructure.mesh;
                    s = size(mesh,1);
                    if mode==1 || s<=window
                        crv = getcurve(mesh);
                        curvlist = [curvlist; [crv frame cell stat]];
                    elseif mode==2 % long all
                        n = max(1,floor(s/window));
                        for i=1:n
                            crv = getcurve(mesh(floor((i-1)*s/n)+1:floor(i*s/n),:));
                            curvlist = [curvlist;[crv frame cell stat]];
                        end
                    elseif mode==3 % long mean
                        n = max(1,floor(s/window));
                        crv = zeros(1,n);
                        for i=1:n
                            crv(i) = getcurve(mesh(floor((i-1)*s/n)+1:floor(i*s/n),:));
                        end
                        crv = abs(crv);
                        crv = 1./mean(1./crv);
                        curvlist = [curvlist;[crv frame cell stat]];
                    end
                end
            end
      end
end

function res = getcurve(mesh)
    X = (mesh(:,1)+mesh(:,3))/2;
    Y = (mesh(:,2)+mesh(:,4))/2;
    x = X([1 ceil(end/2) end]);
    y = Y([1 ceil(end/2) end]);
    x0 = det([x(1)^2+y(1)^2 y(1) 1; x(2)^2+y(2)^2 y(2) 1; x(3)^2+y(3)^2 y(3) 1])/2/det([x(1) y(1) 1; x(2) y(2) 1; x(3) y(3) 1]);
    y0 = det([x(1) x(1)^2+y(1)^2 1; x(2) x(2)^2+y(2)^2 1; x(3) x(3)^2+y(3)^2 1])/2/det([x(1) y(1) 1; x(2) y(2) 1; x(3) y(3) 1]);
    r0 = sqrt((x(1)-x0)^2+(y(1)-y0)^2);
    options.MaxFunEvals = 5000;
    options.MaxIter = 2000;
    options.optimset = 'off';
    [res,fval,exitflag,output] = fminsearch(@circfiterror,[x0 y0 r0],options);
    res = res(3);
    function res=circfiterror(in)
        x = in(1); y = in(2); r = in(3);
        % also uses X, Y
        res = sum((sqrt((X-x).^2+(Y-y).^2)-r).^2);
    end
end

end