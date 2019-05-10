function cellList = peakfinder(cellList,varargin)
% cellList2 = peakfinder(cellList,[cnd_new],[cnd_old],[range],[mindistold],[smooth],[signalfield],[spotsfield],[mindistnew])
% cellList2 = peakfinder(cellList,...,'plot')
% 
% This function detects peaks using a signal profile, an alternative to
% SpotFinder. All parameters except for <cellList> are optional. The 
% optional numeric parameters must follow the order; to use the default 
% value of a particular parameter but still to provide the value of the 
% following one, supply [] (empty array) for its value. All detected peaks 
% are saved as spots in SpotFinder format with zero background, width, 
% height, and magnitude.
% 
% <cellList> is an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <cellList2> - output array of meshes.
% <cnd_new> - condition to detect a spot where no spots are present.
%     Default: 0.25.
% <cnd_old> - condition to detect a spots where a spot already exists.
%     Default: equal to <cnd_new>.
% <range> - range of comparison area, i.e. the number of cell segments 
%     before and after the potential peak that are taken into 
%     consideration. Default: 20.
% <mindistold> - minimum distance from the peaks existing before running
%     peakfinder and the newly detected peaks so that they are considered
%     identical. In such case the old peak is kept with all its properties.
%     Default: 4.
% <smooth> - degree of smoothing, number of smoothing cycles. Default: 10.
% <signalfield> - the signal field which will be processed. Must be in 
%     single quotes and must start from the word 'signal'. Default: 
%     'signal1'.
% <spotsfield> - the spots field to which the data will be saved. Must be
%     in single quotes and must start from the word 'spots'. Default: 
%     'spots'.
% <mindistnew> - minimum distance separating the peaks so that they are
%     considered distinct. Default: 0 (all peaks are distinct).
% 'plot' - display the graph and spot information for each cell as the 
%     processing goes in order to test the parameters. When the figure is
%     displayed, press 'Enter' to continue or 'Escape' to exit.
% 'diagram' - display a diagram of the number of spots vs. cell length for
%     quality control. 

plotdata = false;
dgr = false;
ind = [];
signal = 'signal1';
spotsfield = 'spots';
for i=1:length(varargin)
    if ischar(varargin{i}) && strcmp(varargin{i},'plot')
        plotdata = true;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'diagram')
        dgr = true;
    elseif ischar(varargin{i}) && length(varargin{i})>=6 && strcmp(varargin{i}(1:6),'signal')
        signal = varargin{i};
    elseif ischar(varargin{i}) && length(varargin{i})>=5 && strcmp(varargin{i}(1:5),'spots')
        spotsfield = varargin{i};
    elseif strcmp(class(varargin{i}),'double')
        ind = [ind i];
    end
end
varargin = varargin(ind);
if length(varargin)>=1 && length(varargin{1})==1
    cndmin2 = varargin{1};
else
    cndmin2 = 0.25;
end
if length(varargin)>=2 && length(varargin{2})==1
    cndmin = varargin{2};
else
    cndmin = cndmin2;
end
if length(varargin)>=3 && length(varargin{3})==1
    rng = varargin{3};
else
    rng = 20; % range of comparison area (in one direction)
end
if length(varargin)>=4 && length(varargin{4})==1
    mindistold = varargin{4}^2;
else
    mindistold = 36; % minimum squared distance old peaks are same as new
end
if length(varargin)>=5 && length(varargin{5})==1
    smooth = varargin{5};
else
    smooth = 20; % degree of smoothing, cycles
end
if length(varargin)>=6 && length(varargin{6})==1
    mindistnew = varargin{6};
else
    mindistnew = 0; % minimum distance new peaks are considered distinct
end

nval = 0; % nomber of evaluated cells (i.e. with the signal)
ntot = 0; % all number of processed cells
if plotdata, fig=figure; end
if ~isfield(cellList,'meshData')
for frame=1:length(cellList)
    for cell=1:length(cellList{frame})
        if ~isempty(cellList{frame}{cell})
            ntot = ntot+1;
            f=isfield(cellList{frame}{cell},signal) && ~isempty(cellList{frame}{cell}.(signal));
            if f
                nval = nval+1;
                signal1 = cellList{frame}{cell}.(signal)./cellList{frame}{cell}.steparea;
                if plotdata
                    figure(fig)
                    plot(signal1,'b')
                    hold on
                end
                for i=1:smooth,
                    signal1(2:end-1) = signal1(2:end-1)*0.5 + signal1(3:end)*0.25+signal1(1:end-2)*0.25; % smoothing the curve
                    signal1([1 end]) = 0.75*signal1([1 end]) + 0.25*signal1([2 end-1]);
                end
                f = find(signal1(2:end-1)>signal1(1:end-2) & signal1(2:end-1)>signal1(3:end));
                if signal1(1)>signal1(2), f = [0;f]; end
                if signal1(end)>signal1(end-1), f = [f;length(signal1)-1]; end
                if plotdata
                    plot(f+1,signal1(f+1),'.g')
                    plot(signal1,'--g')
                    xlim([0 length(signal1)])
                    xlabel('Cell coordinate, pixels','FontSize',14)
                    ylabel('Signal intensity','FontSize',14)
                    set(gca,'FontSize',12)
                end
                cndarray = [];
                for i=1:length(f)
                    mn = f(i)-rng+1;
                    mx = f(i)+2+rng-1 + 1 - min(mn,1);
                    mn = max(1,mn - max(mx-length(signal1),0));
                    mx = min(mx,length(signal1));
                    cnd = (signal1(f(i)+1)-mean(signal1([mn:f(i) f(i)+2:mx])))/mean(signal1);
                    if i<rng || i>length(f)-rng
                        cnd = cnd/2;
                    end
                    cndarray = [cndarray cnd];
                    if plotdata
                        disp(['cell: ' num2str(cell) ', spot: ' num2str(i) ' condition: ' num2str(cnd) ' true: ' num2str(cnd>cndmin)])
                    end
                end
                fa = max(1,f(cndarray>cndmin));
                fb = max(1,f(cndarray>cndmin2));
                if sum(signal1)>0 && plotdata
                    plot(fa+1,signal1(round(fa+1)),'.r')
                    hold off
                    disp(' ')
                end
                
                % combine closely located spots (closer than mindistnew)
                if ~isempty(fa)
                    l = cellList{frame}{cell}.lengthvector(round(fa));
                    sptdist = l(2:end)-l(1:end-1);
                    c = sptdist<mindistnew;
                    lnew = [];
                    i = 0;
                    j = 0;
                    while i<=length(c)
                        i = i+1;
                        if i>length(c) || c(i)==0, 
                            j=0;
                            lnew=[lnew l(i)];
                            continue
                        else 
                            j=j+1;
                        end
                        if c(i)==1 && (i==length(c) || c(i+1)==0)
                            lnew=[lnew mean(l(i-j+1:i+1))];
                            i = i+1;
                            j=0;
                        end
                    end
                end
                
                % combine spots with preexisting ones
                f2 = [];
                l3 = [];
                if ~isfield(cellList{frame}{cell},spotsfield)
                    str = [];
                    str.l = [];
                    str.d = [];
                    str.x = [];
                    str.y = [];
                    str.b = [];
                    str.w = [];
                    str.h = [];
                    str.magnitude = [];
                    str.positions = [];
                    cellList{frame}{cell}.(spotsfield)=str;
                end
                spotsLold=cellList{frame}{cell}.(spotsfield).l;
                for u=1:length(lnew)
                    l = lnew(u);
                    dst2 = (spotsLold - l).^2;
                    [dstmin,indmin]=min(dst2);
                    if dstmin<mindistold
                        f2 = [f2 indmin];
                    elseif find(fb,u)
                        l3 = [l3 l];
                    end
                end
                f2 = unique(f2);
                f3=[]; cs=cumsum(cellList{frame}{cell}.steplength); for i=1:length(l3), f3=[f3 1+sum(l>cs)]; end
                str = [];
                strold = cellList{frame}{cell}.(spotsfield);
                str.l = [strold.l(f2) l3];
                str.d = [strold.d(f2) l3*0];
                str.x = [strold.x(f2) mean(cellList{frame}{cell}.mesh(f3,[1 3]),2)'];
                str.y = [strold.y(f2) mean(cellList{frame}{cell}.mesh(f3,[2 4]),2)'];
                if isfield(strold,'b') % adding zero values to b/w/h fields
                    str.b = [strold.b(f2) l3*0];
                    str.w = [strold.w(f2) l3*0];
                    str.h = [strold.h(f2) l3*0];
                else % if the spots were detected before adding b/w/h fields to SpotFinder
                    str.b = [f2*0 l3*0];
                    str.w = [f2*0 l3*0];
                    str.h = [f2*0 l3*0];
                end
                str.magnitude = [strold.magnitude(f2) l3*0];
                str.positions = [strold.positions(f2) f3];
                [str.l,ind] = sort(str.l);
                str.d = str.d(ind);
                str.x = str.x(ind);
                str.y = str.y(ind);
                str.b = str.b(ind);
                str.w = str.w(ind);
                str.h = str.h(ind);
                str.magnitude = str.magnitude(ind);
                str.positions = str.positions(ind);
                if sum(signal1)>0 && plotdata
                    hold on
                    stem(str.l,str.magnitude/3000,'.-k')
                    hold off
                end
                cellList{frame}{cell}.(spotsfield) = str;
                % cellList{frame}{cell}.spotpos = f;
                if plotdata
                    figure(fig)
                    set(fig,'KeyPressFcn',@mainkeypress);
                    exitflag = true;
                    uiwait(fig);
                    if exitflag, return; end
                end
            end
        end
    end
end
else
    cellList = oufti_makeCellListDouble(cellList);
    for ii = 1:length(cellList.meshData)
        for jj = 1:length(cellList.meshData{ii})
            cellList.meshData{ii}{jj} = getextradata(cellList.meshData{ii}{jj});
        end
    end
    for frame=1:length(cellList.meshData)
        [~,cellId] = oufti_getFrame(frame,cellList);
        for cell = cellId
            cellStructure = oufti_getCellStructure(cell,frame,cellList);
            ntot = ntot+1;
            f = isfield(cellStructure,signal) && ~isempty(cellStructure.(signal));
            if f
                nval = nval+1;
                signal1 = cellStructure.(signal)./cellStructure.steparea;
                if plotdata
                    figure(fig)
                    plot(signal1,'b')
                    hold on
                end
                for i=1:smooth,
                    signal1(2:end-1) = signal1(2:end-1)*0.5 + signal1(3:end)*0.25+signal1(1:end-2)*0.25; % smoothing the curve
                    signal1([1 end]) = 0.75*signal1([1 end]) + 0.25*signal1([2 end-1]);
                end
                f = find(signal1(2:end-1)>signal1(1:end-2) & signal1(2:end-1)>signal1(3:end));
                if signal1(1)>signal1(2), f = [0;f]; end
                if signal1(end)>signal1(end-1), f = [f;length(signal1)-1]; end
                if plotdata
                    plot(f+1,signal1(f+1),'.g')
                    plot(signal1,'--g')
                    xlim([0 length(signal1)])
                    xlabel('Cell coordinate, pixels','FontSize',14)
                    ylabel('Signal intensity','FontSize',14)
                    set(gca,'FontSize',12)
                end
                cndarray = [];
                for i=1:length(f)
                    mn = f(i)-rng+1;
                    mx = f(i)+2+rng-1 + 1 - min(mn,1);
                    mn = max(1,mn - max(mx-length(signal1),0));
                    mx = min(mx,length(signal1));
                    cnd = (signal1(f(i)+1)-mean(signal1([mn:f(i) f(i)+2:mx])))/mean(signal1);
                    if i<rng || i>length(f)-rng
                        cnd = cnd/2;
                    end
                    cndarray = [cndarray cnd];
                    if plotdata
                        disp(['cell: ' num2str(cell) ', spot: ' num2str(i) ' condition: ' num2str(cnd) ' true: ' num2str(cnd>cndmin)])
                    end
                end
                fa = max(1,f(cndarray>cndmin));
                fb = max(1,f(cndarray>cndmin2));
                if sum(signal1)>0 && plotdata
                    plot(fa+1,signal1(round(fa+1)),'.r')
                    hold off
                    disp(' ')
                end
                
                % combine closely located spots (closer than mindistnew)
                if ~isempty(fa)
                    l = cellStructure.lengthvector(round(fa));
                    sptdist = l(2:end)-l(1:end-1);
                    c = sptdist<mindistnew;
                    lnew = [];
                    i = 0;
                    j = 0;
                    while i<=length(c)
                        i = i+1;
                        if i>length(c) || c(i)==0, 
                            j=0;
                            lnew=[lnew l(i)];
                            continue
                        else 
                            j=j+1;
                        end
                        if c(i)==1 && (i==length(c) || c(i+1)==0)
                            lnew=[lnew mean(l(i-j+1:i+1))];
                            i = i+1;
                            j=0;
                        end
                    end
                end
                
                % combine spots with preexisting ones
                f2 = [];
                l3 = [];
                if ~isfield(cellStructure,spotsfield)
                    str = [];
                    str.l = [];
                    str.d = [];
                    str.x = [];
                    str.y = [];
                    str.b = [];
                    str.w = [];
                    str.h = [];
                    str.magnitude = [];
                    str.positions = [];
                    cellStructure.(spotsfield)=str;
                end
                spotsLold = cellStructure.(spotsfield).l;
                for u=1:length(lnew)
                    l = lnew(u);
                    dst2 = (spotsLold - l).^2;
                    [dstmin,indmin]=min(dst2);
                    if dstmin<mindistold
                        f2 = [f2 indmin];
                    elseif find(fb,u)
                        l3 = [l3 l];
                    end
                end
                f2 = unique(f2);
                f3=[]; cs=cumsum(cellStructure.steplength); for i=1:length(l3), f3=[f3 1+sum(l>cs)]; end
                str = [];
                strold = cellStructure.(spotsfield);
                str.l = [strold.l(f2) l3];
                str.d = [strold.d(f2) l3*0];
                str.x = [strold.x(f2) mean(cellStructure.mesh(fa+1,[1 3]),2)'];
                str.y = [strold.y(f2) mean(cellStructure.mesh(fa+1,[2 4]),2)'];
                if isfield(strold,'b') % adding zero values to b/w/h fields
                    str.b = [strold.b(f2) l3*0];
                    str.w = [strold.w(f2) l3*0];
                    str.h = [strold.h(f2) l3*0];
                else % if the spots were detected before adding b/w/h fields to SpotFinder
                    str.b = [f2*0 l3*0];
                    str.w = [f2*0 l3*0];
                    str.h = [f2*0 l3*0];
                end
                str.magnitude = [strold.magnitude(f2) l3*0];
                str.positions = [strold.positions(f2) f3];
                [str.l,ind] = sort(str.l);
                str.d = str.d(ind);
                str.x = str.x(ind);
                str.y = str.y(ind);
                str.b = str.b(ind);
                str.w = str.w(ind);
                str.h = str.h(ind);
                str.magnitude = str.magnitude(ind);
                str.positions = str.positions(ind);
                if sum(signal1)>0 && plotdata
                    hold on
                    stem(str.l,str.magnitude/3000,'.-k')
                    hold off
                end
                cellStructure.(spotsfield) = str;
                cellList = oufti_addCell(cell,frame,cellStructure,cellList);
                % cellList{frame}{cell}.spotpos = f;
                if plotdata
                    figure(fig)
                    set(fig,'KeyPressFcn',@mainkeypress);
                    exitflag = true;
                    uiwait(fig);
                    if exitflag, return; end
                end
            end
        end
    end
end
    


if dgr, spotvslength(cellList); end
if nval==0 && ntot>0, disp(['Peakfinder: no cells processed. ''' signal ''' field is missing.']); end
if ntot==0, disp('Peakfinder: no cells processed. No good cells in the list.'); end
if nval>0 && ntot==nval, disp(['Peakfinder: all ' num2str(ntot) ' cells processed successfully.']); end
if nval>0 && ntot>nval, disp(['Peakfinder: not all cells processed (' num2str(nval) ' out of ' num2str(ntot) '). ''' signal ''' field is missing in some.']); end
    function mainkeypress(hObject, eventdata) %#ok<INUSL>
        if double(eventdata.Character)==13
            uiresume(fig)
            exitflag = false;
        elseif double(eventdata.Character)==27
            uiresume(fig)
        end
    end
end