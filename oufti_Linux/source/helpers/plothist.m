function varargout = plothist(expr,xlabel1,xlabel2,varargin)
% this function produces a histogram
% not intended to be used alone, only from other functions
%
% plothist(expr,xlabel1,xlabel2,cellList) 
% plothist(...,cellList1,cellList2)
% plothist(...,cellList,xarray) 
% plothist(...,cellList1,cellList2,xarray)
% plothist(...,cellList1,pix2mu)
% plothist(...,cellList1,pix2mu1,cellList2,pix2mu2)
% plothist(...,cellList1,cellList2,'overlap')
% plothist(...,'nooutput')
% plothist(...,'nodisp')
% [lengthlist] = plothist(cellList)
% [lengthlist1,lengthlist2] = plothist(cellList1,cellList2)
%
% <expt> - expressin to evaluate, i.g.:
% 'value = cellList{frame}{cell}.length;'
% <cellList> is an array that contains the meshes
% <cellList1>, <cellList2>, ... - several array can be loaded
% <xarray> - array of x values for the histogram
% <pix2mu>, <pix2mu1>, <pix2mu2> - conversion factor, i.e. pixel size in 
%     microns
% 'overlap' - indicate this for the histograms to overlap
% 'nodisp' - suppresses displaying the results as a figure
% lengthlist1,lengthlist2 - arrays of extracted, but not binned data for 
%     each cellList

% collect parameters
n = length(varargin{1});
pix2muT = [];
overlap = false;
c = [];
lengtharray = {};
output = true;
dispfigure = true;
if ~isfield(varargin{1}{1},'meshData')
for i=1:n
    if strcmp(class(varargin{1}{i}),'double') && length(varargin{1}{i})==1
        pix2muT = [varargin{1}{i} pix2muT];
    elseif strcmp(class(varargin{1}{i}),'double') && length(varargin{1}{i})>1
        c = varargin{1}{i};
    elseif ischar(varargin{1}{i}) && strcmp(varargin{1}{i},'overlap')
        overlap = true;
    elseif ischar(varargin{1}{i}) && strcmp(varargin{1}{i},'nooutput')
        output = false;
    elseif ischar(varargin{1}{i}) && strcmp(varargin{1}{i},'nodisp')
        dispfigure = false;
    elseif iscell(varargin{1}{i})
        lengtharrayT = [];
        cellList = varargin{1}{i};
            for frame = 1:length(cellList)
                for cell=1:length(cellList{frame})
                    if cell<=length(cellList{frame}) && ~isempty(cellList{frame}{cell}) && ...
                           ((isfield(cellList{frame}{cell},'mesh') && length(cellList{frame}{cell}.mesh)>4) || ...
                            (isfield(cellList{frame}{cell},'contour') && length(cellList{frame}{cell}.contour)>1))  
                        try
                            if ischar(expr)
                                eval(expr);
                            elseif length(expr)==n
                                eval(expr{i});
                            else
                                eval(expr{1});
                            end
                            lengtharrayT = [lengtharrayT value];
                        catch
                            disp(['Warning: unable to evaluate expression for frame' num2str(frame) ', cell ' num2str(cell)])
                        end
                    end
                end
            end
     %------------------------------------------------------------------
        lengtharray = [lengtharray lengtharrayT];
    end
end

else
    for i=1:n
        if strcmp(class(varargin{1}{i}),'double') && length(varargin{1}{i})==1
            pix2muT = [varargin{1}{i} pix2muT];
        elseif strcmp(class(varargin{1}{i}),'double') && length(varargin{1}{i})>1
            c = varargin{1}{i};
        elseif ischar(varargin{1}{i}) && strcmp(varargin{1}{i},'overlap')
            overlap = true;
        elseif ischar(varargin{1}{i}) && strcmp(varargin{1}{i},'nooutput')
            output = false;
        elseif ischar(varargin{1}{i}) && strcmp(varargin{1}{i},'nodisp')
            dispfigure = false;
        elseif isstruct(varargin{1}{i})
            lengtharrayT = [];
            cellList = varargin{1}{i};
        %------------------------------------------------------------------
        %update:  Feb. 20, 2013 Ahmad.P new data format
            cellList = oufti_makeCellListDouble(cellList);
            for ii = 1:length(cellList.meshData)
                for jj = 1:length(cellList.meshData{ii})
                    cellList.meshData{ii}{jj} = getextradata(cellList.meshData{ii}{jj});
                end
            end
            for frame = 1:length(cellList.meshData)
                [~,cellId] = oufti_getFrame(frame,cellList);
                for cell = cellId
                    cellStructure = oufti_getCellStructure(cell,frame,cellList);
                    if oufti_doesCellStructureHaveMesh(cell,frame,cellList) || oufti_doesCellHaveContour(cell,frame,cellList)
                        try
                            if ischar(expr)
                                eval(expr);
                            elseif length(expr)==n
                                eval(expr{i});
                            else
                                eval(expr{1});
                            end
                            lengtharrayT = [lengtharrayT value];
                        catch
                            disp(['Warning: unable to evaluate expression for frame' num2str(frame) ', cell ' num2str(cell)])
                        end
                    end
                end
            end
                    lengtharray = [lengtharray lengtharrayT];
        end
     %------------------------------------------------------------------

    end

end
if ~output && ~dispfigure, return; end
m = length(lengtharray);
cfactorcount = length(pix2muT);
if cfactorcount==0 || cfactorcount>m
    for i=1:m, pix2mu(i)=1; end
elseif cfactorcount<m
    for i=1:m, pix2mu(i)=pix2muT; end
elseif cfactorcount==m
    pix2mu = pix2muT;
end
for i=1:m % normalize and eliminate erroneus entries
    lengtharray{i} = lengtharray{i}(~isnan(lengtharray{i}))*pix2mu(i);
end
varargout = {lengtharray};

if isempty(lengtharray), disp('No data to plot'); return; end
% make the histograms
if isempty(c)
    totalhist = lengtharray{1}(:);
    for i=2:m, totalhist=[totalhist;lengtharray{i}(:)]; end
    [h,c] = hist(totalhist);
end
h = hist(lengtharray{1},c);
h = (100*h/sum(h))';
for i=2:m
    hc = hist(lengtharray{i},c);
    hc = 100*hc/sum(hc);
    h = [h hc'];
end

% % % % make the histograms
% % % if isempty(c)
% % %     [h,c] = hist(lengtharray{1});
% % % else
% % %     h = hist(lengtharray{1},c);
% % % end
% % % h = (100*h/sum(h))';
% % % for i=2:m
% % %     hc = hist(lengtharray{i},c);
% % %     hc = 100*hc/sum(hc);
% % %     h = [h hc'];
% % % end

% plot the histograms
if dispfigure
    figure;
    cmap = lines;
    if ~overlap || m~=2
        hnd = bar(c,h);
        for i=1:m
            set(hnd(i),'EdgeColor',cmap(i,:))
            set(hnd(i),'FaceColor',cmap(i,:))
        end
    else
        bar(c,h(:,1),'EdgeColor',[1 0 0],'FaceColor',[1 0 0])
        hold on
        bar(c,h(:,2),'EdgeColor',[0 1 0],'FaceColor',[0 1 0])
        bar(c,min(h(:,1),h(:,2)),'EdgeColor',[1 1 0],'FaceColor',[1 1 0])
        hold off
    end
    set(gca,'FontSize',14)
end
    
% create axes label
if cfactorcount==0
    if dispfigure, xlabel(xlabel1,'FontSize',16); end
    if output, disp(xlabel1); end
else
    if dispfigure, xlabel(xlabel2,'FontSize',16); end
    if output, disp(xlabel2); end
end
if dispfigure, ylabel('% cells','FontSize',16); end

% display data
if output
    if m==1, disp('Processed 1 dataset'); elseif m>1, disp(['Processed ' num2str(m) ' datasets:']); end
    for i=1:m
        disp(['Set ' num2str(i) ': mean ' num2str(mean(lengtharray{i})) ', std ' num2str(std(lengtharray{i}))])
    end
    disp(' ')
end