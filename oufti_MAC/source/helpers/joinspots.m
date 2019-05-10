function joinspots
% A GUI-based program which for linking spots detected with SpotFinder 
% family tools (SpotFinderZ, SpotfinderM, peakfinder). The program can 
% perform automatic joining with a possibility of manual control and 
% correction. It has the initial interface for data and parameter 
% selection, while the main inteface allows for autimatic spot tracking as
% well as for going back and forth between cells and frames in order to 
% visualize the detected spots and to perform manual correction. The 
% output data format includes the original cellList with added fields and 
% arrays of tracks for each individual spot.

bformats = checkbformats(1);

persistent params

% default parameters
if ~exist('params','var') || ~isfield(params,'ifolder') ||~isfield(params,'clstfile')
    params.ifolder = '';
    params.clstfile = '';
    params.pix2mu = 1;
    params.firstframe = 1;
    params.dt = 5;
    params.minframes = 10;
    params.spotsfield = 'spots';
    params.maxlinklength = 8;
    params.markersize = 15;
end

% initializations
cellList = {};
images = [];
cell = [];
frame = [];
maxframe = [];
maxcell = [];
lst = [];
activenode = [];
    
% create setup window
handles.main.fig = figure('Name','Spot joining tool','Toolbar','none','Menubar','none','NumberTitle','off','IntegerHandle','off');
pos = get(handles.main.fig,'pos');
color = get(handles.main.fig,'color');
figdim = [300 240];
set(handles.main.fig,'pos',[round(pos(1:2)+pos(3:4)/2-figdim/2) figdim])

uicontrol(handles.main.fig,'units','pixels','Position',[5 200 165 16],'Style','text','String','Folder (     file) with images','HorizontalAlignment','right','BackgroundColor',color);
uicontrol(handles.main.fig,'units','pixels','Position',[5 180 165 16],'Style','text','String','Meshes file','HorizontalAlignment','right','BackgroundColor',color);
uicontrol(handles.main.fig,'units','pixels','Position',[5 160 165 16],'Style','text','String','Pixel size in microns','HorizontalAlignment','right','BackgroundColor',color);
uicontrol(handles.main.fig,'units','pixels','Position',[5 140 165 16],'Style','text','String','First frame','HorizontalAlignment','right','BackgroundColor',color);
uicontrol(handles.main.fig,'units','pixels','Position',[5 120 165 16],'Style','text','String','Time interval between frames','HorizontalAlignment','right','BackgroundColor',color);
uicontrol(handles.main.fig,'units','pixels','Position',[5 100 165 16],'Style','text','String','Min number of frames','HorizontalAlignment','right','BackgroundColor',color);
uicontrol(handles.main.fig,'units','pixels','Position',[5 80 165 16],'Style','text','String','Spots field name','HorizontalAlignment','right','BackgroundColor',color);
uicontrol(handles.main.fig,'units','pixels','Position',[5 60 165 16],'Style','text','String','Max link length (frames)','HorizontalAlignment','right','BackgroundColor',color);

handles.main.ifilecheck = uicontrol(handles.main.fig,'units','pixels','Position',[77 200 14 17],'Style','checkbox','String','','BackgroundColor',color);
handles.main.ifolder = uicontrol(handles.main.fig,'units','pixels','Position',[175 200 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
handles.main.ifolderselect = uicontrol(handles.main.fig,'units','pixels','Position',[247 200 43 16],'String','Select','BackgroundColor',color,'Callback',@ifolderselect);
handles.main.clstfile = uicontrol(handles.main.fig,'units','pixels','Position',[175 180 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
handles.main.clstfileselect = uicontrol(handles.main.fig,'units','pixels','Position',[247 180 43 16],'String','Select','BackgroundColor',color,'Callback',@clstfileselect);
handles.main.pix2mu = uicontrol(handles.main.fig,'units','pixels','Position',[175 160 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
handles.main.firstframe = uicontrol(handles.main.fig,'units','pixels','Position',[175 140 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
handles.main.dt = uicontrol(handles.main.fig,'units','pixels','Position',[175 120 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
handles.main.minframes = uicontrol(handles.main.fig,'units','pixels','Position',[175 100 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
handles.main.spotsfield = uicontrol(handles.main.fig,'units','pixels','Position',[175 80 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
handles.main.maxlinklength = uicontrol(handles.main.fig,'units','pixels','Position',[175 60 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
handles.main.ifolderselect = uicontrol(handles.main.fig,'units','pixels','Position',[50 20 200 26],'String','Start','BackgroundColor',color,'Callback',@run);
setcontrols

    function ifolderselect(hObject, eventdata)
        if get(handles.main.ifilecheck,'Value')
            if bformats
                [filename,pathname] = uigetfile('*.*','Select file with signal images',params.ifolder);
            else
                [filename,pathname] = uigetfile({'*.tif';'*.tiff'},'Select file with signal images',params.ifolder);
            end
            if isempty(filename)||isequal(filename,0), return, end
            params.ifolder = fullfile2(pathname,filename);
            set(handles.main.ifolder,'String',params.ifolder)
        else
            if ~isdir(params.ifolder) && isdir(fileparts(params.ifolder)), params.ifolder = fileparts(params.ifolder); end
            folder = uigetdir(params.ifolder,'Select folder with signal images');
            if isempty(folder)||isequal(folder,0), return; end
            params.ifolder = folder;
            set(handles.main.ifolder,'String',params.ifolder)
        end
    end
    function clstfileselect(hObject, eventdata)
        [FileName,PathName] = uigetfile('*.mat','Select file with signal meshes',params.clstfile);
        if isempty(FileName)||isequal(FileName,0), return; else params.clstfile=[PathName '/' FileName]; end
        set(handles.main.clstfile,'String',params.clstfile)
    end
    function setcontrols
        set(handles.main.ifolder,'String',params.ifolder)
        set(handles.main.clstfile,'String',params.clstfile)
        set(handles.main.pix2mu,'String',num2str(params.pix2mu))
        set(handles.main.firstframe,'String',num2str(params.firstframe))
        set(handles.main.dt,'String',num2str(params.dt))
        set(handles.main.minframes,'String',num2str(params.minframes))
        set(handles.main.spotsfield,'String',params.spotsfield)
        set(handles.main.maxlinklength,'String',num2str(params.maxlinklength))
    end
    function getcontrols
        params.ifolder = get(handles.main.ifolder,'String');
        params.clstfile = get(handles.main.clstfile,'String');
        params.pix2mu = str2num(get(handles.main.pix2mu,'String'));
        params.firstframe = str2num(get(handles.main.firstframe,'String'));
        params.dt = str2num(get(handles.main.dt,'String'));
        params.minframes = str2num(get(handles.main.minframes,'String'));
        params.spotsfield = get(handles.main.spotsfield,'String');
        params.maxlinklength = str2num(get(handles.main.maxlinklength,'String'));
    end

    function run(hObject, eventdata)
        % load data and assign parameter values
        getcontrols
        if get(handles.main.ifilecheck,'Value') && exist(params.ifolder,'file')==2
            [~,images] = loadimagestack(3,params.ifolder,1,0);
        elseif ~get(handles.main.ifilecheck,'Value') && exist(params.ifolder,'file')==7
            images = loadimageseries(params.ifolder,1);
        else
            disp('Error: no images found at the indicated path or file check is wrong')
            return
        end
        if isempty(images), disp('Error: problem loading images'); return; end
        if exist(params.clstfile,'file')==2
            lst = load(params.clstfile);
        else
            disp('Error: no meshes file at the indicated path');
            return
        end
        if ~isfield(lst,'cellList'), disp('Error: problem loading meshes'); return; end
        delete(handles.main.fig)
        disp('Runnint Spot Joining Tool')
        disp(['Loaded images from folder: ' params.ifolder])
        disp(['Loaded cellList from file: ' params.clstfile])
        disp('Parameters:')
        disp(['Pixel size in microns: ' num2str(params.pix2mu)])
        disp(['First frame: ' num2str(params.firstframe)])
        disp(['Time interval between frames: ' num2str(params.dt)])
        disp(['Spots field name: ' params.spotsfield])
        disp(['Max link length: ' num2str(params.maxlinklength)])
        
        cellList = lst.cellList;
        
        % set initial values
        cell = 1;
        frame = 1;
        handles.disp.fig = -1;
        maxframe = min(size(images,3),length(cellList));
        maxcell = 0; for qframe=1:length(cellList), maxcell=max(maxcell,length(cellList{qframe})); end
        
        % call the initial display function
        dispnewcell
        
    end

    function changeframe(hObject, eventdata)
        if hObject==handles.disp.fig
            key = eventdata.Key;
            if strcmp(key,'rightarrow')
                dir = 1;
                flag = true;
            elseif strcmp(key,'leftarrow')
                dir = -1;
                flag = true;
            elseif strcmp(key,'uparrow')
                dir = 1;
                flag = false;
            elseif strcmp(key,'downarrow')
                dir = -1;
                flag = false;
            else
                return
            end
        elseif hObject==handles.disp.nextframe
            dir = 1;
            flag = true;
        elseif hObject==handles.disp.prevframe
            dir = -1;
            flag = true;
        elseif hObject==handles.disp.nextcell
            dir = 1;
            flag = false;
        elseif hObject==handles.disp.prevcell
            dir = -1;
            flag = false;
        else
            return
        end
        if flag
            tframe = frame;
            while true
                tframe = max(tframe+dir,1);
                if tframe>maxframe || tframe<1
                    break
                elseif cell<=length(cellList{tframe}) && ~isempty(cellList{tframe}{cell}) && length(cellList{tframe}{cell}.mesh)>1
                    frame = tframe;
                    break
                end
            end
            displayimage
        else
            tcell = cell;
            while true
                tcell = max(tcell+dir,1);
                if tcell>maxcell || tcell<1
                    break
                else
                    bflag = false;
                    for tframe=[frame:-1:1 frame+1:maxframe]
                        if cell<=length(cellList{tframe}) && ~isempty(cellList{tframe}{tcell}) && length(cellList{tframe}{tcell}.mesh)>1
                            cell = tcell;
                            frame = tframe;
                            bflag = true;
                            break
                        end
                    end
                    if bflag, break; end
                end
            end
            dispnewcell
        end
    end

    function displayimage
        % display image
        if cell>length(cellList{frame}) || isempty(cellList{frame}{cell}) || length(cellList{frame}{cell}.mesh)<=1, return; end
        box = cellList{frame}{cell}.box;
        img0 = imcrop(images(:,:,frame),box);
        set(handles.disp.fig,'Name',['Spot joining tool: frame ' num2str(frame) ' cell ' num2str(cell)])
        pause(0.1);
        set(handles.disp.image,'NextPlot','replace')
        imshow(img0,[],'parent',handles.disp.image)
        set(handles.disp.image,'NextPlot','add')
        mesh = cellList{frame}{cell}.mesh;
        plot(handles.disp.image,[mesh(:,1);flipud(mesh(:,3))]-box(1)+1,[mesh(:,2);flipud(mesh(:,4))]-box(2)+1,'Color',[0 0.7 0])
        if isfield(cellList{frame}{cell},params.spotsfield)
            x = cellList{frame}{cell}.(params.spotsfield).x - box(1)+1;
            y = cellList{frame}{cell}.(params.spotsfield).y - box(2)+1;
            plot(handles.disp.image,x,y,'.','Color',[1 0 0]);
            for q=1:length(x)
                text(x(q),y(q)+1.5,num2str(q),'Color',[1 0 0],'Parent',handles.disp.image)
            end
        end
        set(handles.disp.image,'NextPlot','replace')
        
        % display box
        if isfield(handles.disp,'currentbox') && ishandle(handles.disp.currentbox)
            delete(handles.disp.currentbox);
            delete(handles.disp.currentboxnumbers);
        end
        hold(handles.disp.diagram,'on')
        xb = [frame-0.4 frame-0.4 frame+0.4 frame+0.4 frame-0.4]*params.dt;
        yb = [0 1 1 0 0];
        handles.disp.currentbox = plot(handles.disp.diagram,xb,yb,'-g');
        handles.disp.currentboxnumbers = [];
        xc = frame*params.dt;
        for spot = 1:length(cellList{frame}{cell}.(params.spotsfield).l)
            relpos = getrelpos(cellList{frame}{cell},spot);
            yc = relpos-0.02;
            handles.disp.currentboxnumbers = [handles.disp.currentboxnumbers ...
                text(xc,yc,num2str(spot),'Color',[1 0 0],'Parent',handles.disp.diagram)];
        end
        hold(handles.disp.diagram,'off')
    end

    function export(hObject, eventdata)
        [spotList,spotList2] = getSpotList(cellList,params.spotsfield);
        assignin('base','spotList',spotList)
        assignin('base','spotList2',spotList2)
        assignin('base','cellList',cellList)
    end

    function savecbk(hObject, eventdata)
        [spotList,spotList2] = getSpotList(cellList,params.spotsfield);
        lst.cellList = cellList;
        lst.spotList2 = spotList2;
        lst.spotList = spotList;
        [FileName,PathName] = uiputfile('*.mat','Select file with signal meshes',params.clstfile);
        if isempty(FileName)||isequal(FileName,0), return; else outfile=[PathName '/' FileName]; end
        save(outfile,'-struct','lst')
    end

    function dispnewcell
        % Creates one plot with a tree of connected spots
        if ~ishandle(handles.disp.fig)
            handles.disp.fig = figure('WindowKeyPressFcn',@changeframe,'pos',[50,40,900,900],'NumberTitle','off','IntegerHandle','off','WindowButtonDownFcn',@selectclick);
            handles.disp.diagram = axes('units','pixels','pos',[70 50 800 400]);
            handles.disp.image = axes('units','pixels','pos',[40 470 500 400]);
            
            handles.disp.autotrack = uicontrol(handles.disp.fig,'units','pixels','Position',[560 800 270 30],'String','Autotrack','backgroundcolor',color,'callback',@autotrack);
            handles.disp.nextcell = uicontrol(handles.disp.fig,'units','pixels','Position',[640 720 100 30],'String','Next cell','backgroundcolor',color,'callback',@changeframe);
            handles.disp.prevcell = uicontrol(handles.disp.fig,'units','pixels','Position',[640 640 100 30],'String','Prev cell','backgroundcolor',color,'callback',@changeframe);
            handles.disp.nextframe = uicontrol(handles.disp.fig,'units','pixels','Position',[705 680 100 30],'String','Next frame','backgroundcolor',color,'callback',@changeframe);
            handles.disp.prevframe = uicontrol(handles.disp.fig,'units','pixels','Position',[585 680 100 30],'String','Prev frame','backgroundcolor',color,'callback',@changeframe);
            handles.disp.dellinks = uicontrol(handles.disp.fig,'style','togglebutton','units','pixels','Position',[560 550 85 30],'String','Delete links','backgroundcolor',color);
            handles.disp.delnodes = uicontrol(handles.disp.fig,'style','togglebutton','units','pixels','Position',[651 550 86 30],'String','Delete spots','backgroundcolor',color);
            handles.disp.delbranches = uicontrol(handles.disp.fig,'style','togglebutton','units','pixels','Position',[742 550 85 30],'String','Delete branches','backgroundcolor',color);
            handles.disp.save = uicontrol(handles.disp.fig,'units','pixels','Position',[560 500 130 30],'String','Save','backgroundcolor',color,'callback',@savecbk);
            handles.disp.export = uicontrol(handles.disp.fig,'units','pixels','Position',[700 500 130 30],'String','Export','backgroundcolor',color,'callback',@export);
        end
        
        % display the diagram
        delete(get(handles.disp.diagram,'children'));
        handles.disp.spots = [];
        hold(handles.disp.diagram,'on')
        xmax = 0;
        for cframe=1:length(cellList)
            if cell<=length(cellList{cframe}) && ~isempty(cellList{cframe}{cell}) && isfield(cellList{cframe}{cell},params.spotsfield)
                for spot = 1:length(cellList{cframe}{cell}.(params.spotsfield).l)
                    relpos = getrelpos(cellList{cframe}{cell},spot);
                    x0 = cframe*params.dt;
                    y0 = relpos;
                    xmax = max(xmax,x0);
                    handles.disp.spots{cframe}{spot} = plot(handles.disp.diagram,x0,y0,'.','MarkerSize',params.markersize);
                    if isfield(cellList{cframe}{cell}.(params.spotsfield),'parentframe') && ...
                            ~isempty(cellList{cframe}{cell}.(params.spotsfield).parentframe{spot})
                        parentframe = cellList{cframe}{cell}.(params.spotsfield).parentframe{spot};
                        parentnum = cellList{cframe}{cell}.(params.spotsfield).parentnum{spot};
                        abspos2 = cellList{parentframe}{cell}.(params.spotsfield).l(parentnum);
                        celllng2 = cellList{parentframe}{cell}.length;
                        x2 = parentframe*params.dt;
                        y2 = abspos2/celllng2;
                        handles.disp.links{cframe}{spot} = plot(handles.disp.diagram,[x0 x2],[y0 y2],'-');
                    end
                end
            end
        end
        hold(handles.disp.diagram,'off')
        xlim(handles.disp.diagram,[0 xmax+0.5*params.dt]);
        ylim(handles.disp.diagram,[0 1])
        xlabel(handles.disp.diagram,'Time','FontSize',12)
        ylabel(handles.disp.diagram,'Relative spot position','FontSize',12)
        set(handles.disp.diagram,'FontSize',12,'box','on')

        % display the image
        displayimage
        
        % reset the active status
        activenode = [];
    end

    function [relpos,abspos,celllng] = getrelpos(str,spot)
        if isempty(spot)
            abspos = str.(params.spotsfield).l;
        else
            abspos = str.(params.spotsfield).l(spot);
        end
        celllng = str.length;
        relpos = abspos/celllng;
    end

    function autotrack(hObject, eventdata)
        for cframe=params.firstframe:length(cellList)
            if length(cellList{cframe})>=cell && ~isempty(cellList{cframe}{cell}) && ...
                    isfield(cellList{cframe}{cell},params.spotsfield) && ~isempty(cellList{cframe}{cell}.(params.spotsfield).l)
                % collect spot positions
                spotpos = getrelpos(cellList{cframe}{cell},[]);
                
                % collect leaves positions (end nodes of the existing tree)
                leafframe = [];
                leafnum = [];
                leafpos = [];
                for lframe=max(1,cframe-params.maxlinklength):min((cframe-1),length(cellList))
                    if ~isempty(cellList{lframe}{cell}) && isfield(cellList{lframe}{cell},params.spotsfield) && ...
                            ~isempty(cellList{lframe}{cell}.(params.spotsfield).l) &&  ...
                            isfield(cellList{lframe}{cell}.(params.spotsfield),'childrenframe')
                        for lspot = 1:length(cellList{lframe}{cell}.(params.spotsfield).l)
                            if isempty(cellList{lframe}{cell}.(params.spotsfield).childrenframe{lspot})
                                leafframe = [leafframe lframe];
                                leafnum = [leafnum lspot];
                                leafpos = [leafpos getrelpos(cellList{lframe}{cell},lspot)];
                            end
                        end
                    end
                end
                if isempty(leafpos)
                    for i=1:length(spotpos)
                        cellList{cframe}{cell}.(params.spotsfield).parentframe{i} = [];
                        cellList{cframe}{cell}.(params.spotsfield).parentnum{i}   = [];
                        cellList{cframe}{cell}.(params.spotsfield).childrenframe{i} = [];
                        cellList{cframe}{cell}.(params.spotsfield).childrennum{i} = [];
                    end
                    continue
                end
                [leafpos,ind] = sort(leafpos);
                leafframe = leafframe(ind);
                leafnum = leafnum(ind);
                
                % match spots to leaves
                % first passage - assign each spot to a leaf
                leafchld = repmat({[]},1,length(leafpos));
                spotprnt = repmat({[]},1,length(spotpos));
                for i=1:length(spotpos)
                    [m,k]=min(abs(leafpos-spotpos(i)));
                    leafchld{k} = [leafchld{k} i];
                    spotprnt{i} = [spotprnt{i} k];
                end
                % second passage - find candidates for unconnected leaves
                for k=1:length(leafpos)
                    if isempty(leafchld{k})
                        [m,i]=min(abs(leafpos(k)-spotpos));
                        spotprnt{i} = [spotprnt{i} k];
                        leafchld{k} = [0 i]; % "secondary assigned" leaves are laveled with zeros as the first candidate
                    end
                end
                % third passage - confirn reassignment
                fspotprnt = repmat({[]},1,length(spotpos));
                fleafchld = repmat({[]},1,length(leafpos));
                for k=1:length(leafpos)
                    if leafchld{k}(1)~=0
                        if length(leafchld{k})==1 % assign spots to leaves with only 1 candidate
                            fspotprnt{leafchld{k}} = k;
                            spotprnt{leafchld{k}} = [];
                            fleafchld{k} = leafchld{k};
                        else
                            f = false;
                            for i=1:length(leafchld{k}) % assign spots that are only claimed by 1 leaf
                                if length(spotprnt{leafchld{k}(i)})==1
                                    fspotprnt{leafchld{k}(i)} = k;
                                    spotprnt{leafchld{k}(i)} = [];
                                    fleafchld{k} = [fleafchld{k} leafchld{k}(i)];
                                    f = true;
                                end
                            end
                            if ~f % if nothing was assigned, assign the closest one
                                [m,i]=min(abs(leafpos(k)-spotpos(leafchld{k})));
                                fspotprnt{leafchld{k}(i)} = k;
                                spotprnt{leafchld{k}(i)} = [];
                                fleafchld{k} = [fleafchld{k} leafchld{k}(i)];
                            end
                        end
                    end
                end
                for i=1:length(spotprnt) % assign the remaining spots to the first unconnected leaf
                    if ~isempty(spotprnt{i})
                        d = [];
                        for j=1:length(spotprnt{i})
                            if isempty(fleafchld{spotprnt{i}(j)})
                                d = [d abs(leafpos(spotprnt{i}(j))-spotpos(i))];
                            else
                                d = [d Inf];
                            end
                        end
                        [m,j] = min(d);
                        fspotprnt{i} = spotprnt{i}(j);
                        fleafchld{spotprnt{i}(j)} = i;
                        spotprnt{i} = [];
                    end
                end
                for i=1:length(spotprnt) % assign the remaining spots to the first leaf
                    if ~isempty(spotprnt{i})
                        fspotprnt{i} = spotprnt{i}(1);
                    end
                end
                for i=1:length(fspotprnt)
                    k = fspotprnt{i};
                    cellList{cframe}{cell}.(params.spotsfield).parentframe{i} = leafframe(k);
                    cellList{cframe}{cell}.(params.spotsfield).parentnum{i} = leafnum(k);
                    cellList{cframe}{cell}.(params.spotsfield).childrenframe{i} = [];
                    cellList{cframe}{cell}.(params.spotsfield).childrennum{i} = [];
                    
                    frm = [cellList{leafframe(k)}{cell}.(params.spotsfield).childrenframe{leafnum(k)} cframe];
                    frm = frm(frm~=0);
                    cellList{leafframe(k)}{cell}.(params.spotsfield).childrenframe{leafnum(k)} = frm;
                    num = [cellList{leafframe(k)}{cell}.(params.spotsfield).childrennum{leafnum(k)} i];
                    num = num(num~=0);
                    cellList{leafframe(k)}{cell}.(params.spotsfield).childrennum{leafnum(k)} = num;
                end
            end
        end
        dispnewcell
    end
    
    function selectclick(hObject, eventdata)
        ps1 = get(handles.disp.diagram,'CurrentPoint');
        xlim1 = get(handles.disp.diagram,'XLim');
        ylim1 = get(handles.disp.diagram,'YLim');
        if ps1(1,1)>xlim1(1) && ps1(1,1)<xlim1(2) && ps1(1,2)>ylim1(1) && ps1(1,2)<ylim1(2)
            clickpos = ps1(1,1:2);
        else
            return
        end
        dstmintime = 1;
        dstminspace = 0.1;
        chklst = [];
        for cframe=1:length(cellList)
            if cell<=length(cellList{cframe}) && ~isempty(cellList{cframe}{cell}) && isfield(cellList{cframe}{cell},params.spotsfield)
                for spot = 1:length(cellList{cframe}{cell}.(params.spotsfield).l)
                    relpos = getrelpos(cellList{cframe}{cell},spot);
                    x0 = cframe*params.dt;
                    y0 = relpos;
                    tdst = (abs(clickpos(1)-x0))/dstmintime/params.dt;
                    sdst = (abs(clickpos(2)-y0))/dstminspace;
                    if tdst<1 && sdst<1
                        chklst = [chklst;[tdst^2+sdst^2 cframe spot]];
                    end
                end
            end
        end
        if size(chklst,1)>=1
            [m,i] = min(chklst(:,1));
            chklst = chklst(i,:);
        else
            return
        end
        cframe = chklst(2);
        cspot = chklst(3);
        if strcmp(get(handles.disp.fig,'SelectionType'),'extend') || get(handles.disp.dellinks,'Value')
            deleteonelink(cframe,cspot)
        elseif strcmp(get(handles.disp.fig,'SelectionType'),'alt') || get(handles.disp.delnodes,'Value')
            deleteonenode(cframe,cspot)
        elseif strcmp(get(handles.disp.fig,'SelectionType'),'open') || get(handles.disp.delbranches,'Value')
            deletebranch(cframe,cspot)
            displayimage
        elseif isempty(activenode) % activate node for linking
            activatenode(cframe,cspot)
        else % link/deactivate active node
            if cframe==activenode(1) && cspot==activenode(2)
                deactivatenode;
            elseif cframe<activenode(1)
                relinknode(cframe,cspot)
            end
        end
        
        function relinknode(frm2,spt2)
            frm = activenode(1);
            spt = activenode(2);
            deleteonelink(frm,spt)
            cellList{frm}{cell}.(params.spotsfield).parentframe{spt} = frm2;
            cellList{frm}{cell}.(params.spotsfield).parentnum{spt}   = spt2;
            if isfield(cellList{frm2}{cell}.(params.spotsfield),'childrenframe')
                cellList{frm2}{cell}.(params.spotsfield).childrenframe = [cellList{frm2}{cell}.(params.spotsfield).childrenframe frm];
                cellList{frm2}{cell}.(params.spotsfield).childrennum   = [cellList{frm2}{cell}.(params.spotsfield).childrennum   spt];
            else
                cellList{frm2}{cell}.(params.spotsfield).childrenframe{spt2} = frm;
                cellList{frm2}{cell}.(params.spotsfield).childrennum{spt2}   = spt;
            end
            relpos1 = getrelpos(cellList{frm}{cell},spt);
            relpos2 = getrelpos(cellList{frm2}{cell},spt2);
            hold(handles.disp.diagram,'on')
            handles.disp.links{frm}{spt} = plot(handles.disp.diagram,[frm frm2]*params.dt,[relpos1 relpos2],'-');
            hold(handles.disp.diagram,'off')
            deactivatenode
        end
        function deactivatenode
            if isempty(activenode), return; end
            frm = activenode(1);
            spt = activenode(2);
            if spt<=length(handles.disp.spots{frm}) && ishandle(handles.disp.spots{frm}{spt})
                set(handles.disp.spots{frm}{spt},'color',[0 0 1]);
            end
            if isfield(handles.disp,'links') && frm<=length(handles.disp.links) && spt<=length(handles.disp.links{frm}) && ishandle(handles.disp.links{frm}{spt})
                set(handles.disp.links{frm}{spt},'color',[0 0 1]);
            end
            activenode = [];
        end
        function activatenode(frm,spt)
            if ~isempty(activenode), return; end
            activenode = [frm spt];
            if spt<=length(handles.disp.spots{frm}) && ishandle(handles.disp.spots{frm}{spt})
                set(handles.disp.spots{frm}{spt},'color',[1 0 0]);
            end
            if isfield(handles.disp,'links') && frm<=length(handles.disp.links) && spt<=length(handles.disp.links{frm}) && ishandle(handles.disp.links{frm}{spt})
                set(handles.disp.links{frm}{spt},'color',[1 0 0]);
            end
        end
        function deletebranch(frm,spt)
            if isfield(cellList{frm}{cell}.(params.spotsfield),'childrenframe') && length(cellList{frm}{cell}.(params.spotsfield).childrenframe)>=spt
                for c=length(cellList{frm}{cell}.(params.spotsfield).childrenframe{spt}):-1:1
                    deletebranch(cellList{frm}{cell}.(params.spotsfield).childrenframe{spt}(c),cellList{frm}{cell}.(params.spotsfield).childrennum{spt}(c))
                end
                deleteonenode(frm,spt)
            end
        end
        function deleteonenode(frm,spt)
            if isfield(cellList{frm}{cell}.(params.spotsfield),'childrenframe')
                %r=testconsistency(cellList,cell);
                L = cellList{frm}{cell}.(params.spotsfield).l<Inf;
                if length(L)<spt, return; end
                L(spt)=0;
                for c=length(cellList{frm}{cell}.(params.spotsfield).childrenframe{spt}):-1:1
                    deleteonelink(cellList{frm}{cell}.(params.spotsfield).childrenframe{spt}(c),cellList{frm}{cell}.(params.spotsfield).childrennum{spt}(c))
                end
                deleteonelink(frm,spt)
                %r=testconsistency(cellList,cell);
                nspots = length(cellList{frm}{cell}.(params.spotsfield).l);
                for spt2=spt+1:nspots % relink other spots
                    parentframe2 = cellList{frm}{cell}.(params.spotsfield).parentframe{spt2};
                    parentnum2   = cellList{frm}{cell}.(params.spotsfield).parentnum{spt2};
                    parentframe2a = cellList{parentframe2}{cell}.(params.spotsfield).childrenframe{parentnum2};
                    parentnum2a   = cellList{parentframe2}{cell}.(params.spotsfield).childrennum{parentnum2};
                    ind = parentframe2a==frm & parentnum2a==spt2;
                    parentframe2a(ind) = parentframe2a(ind);
                    parentnum2a(ind)   = parentnum2a(ind)-1;
                    cellList{parentframe2}{cell}.(params.spotsfield).childrenframe{parentnum2} = parentframe2a;
                    cellList{parentframe2}{cell}.(params.spotsfield).childrennum{parentnum2}   = parentnum2a;
                    childrenframe2 = cellList{frm}{cell}.(params.spotsfield).childrenframe{spt2};
                    childrennum2   = cellList{frm}{cell}.(params.spotsfield).childrennum{spt2};
                    for k=1:length(childrenframe2)
                        childrenframe2a = cellList{childrenframe2(k)}{cell}.(params.spotsfield).parentframe{childrennum2(k)};
                        childrennum2a   = cellList{childrenframe2(k)}{cell}.(params.spotsfield).parentnum{childrennum2(k)};
                        if childrenframe2a==frm && childrennum2a==spt2
                            cellList{childrenframe2(k)}{cell}.(params.spotsfield).parentframe{childrennum2(k)} = childrenframe2a;
                            cellList{childrenframe2(k)}{cell}.(params.spotsfield).parentnum{childrennum2(k)}   = childrennum2a-1;
                        end
                    end
                end
                % r=testconsistency(cellList,cell);
                names = fieldnames(cellList{frm}{cell}.(params.spotsfield));
                for c=1:length(names)
                    cellList{frm}{cell}.(params.spotsfield).(names{c}) = cellList{frm}{cell}.(params.spotsfield).(names{c})(L);
                end
                delete(handles.disp.spots{frm}{spt})
                for c=spt+1:nspots
                    handles.disp.spots{frm}{c-1}=handles.disp.spots{frm}{c};
                    handles.disp.links{frm}{c-1}=handles.disp.links{frm}{c};
                end
                handles.disp.spots{frm} = handles.disp.spots{frm}(1:nspots);
                handles.disp.links{frm} = handles.disp.links{frm}(1:nspots);
                %r=testconsistency(cellList,cell);
            end
        end
        function deleteonelink(frm,spt)
            if isfield(cellList{frm}{cell}.(params.spotsfield),'parentframe') && length(cellList{frm}{cell}.(params.spotsfield).parentframe)>=spt ...
                                                                              && ~isempty(cellList{frm}{cell}.(params.spotsfield).parentframe{spt})
                parentframe = cellList{frm}{cell}.(params.spotsfield).parentframe{spt};
                parentnum = cellList{frm}{cell}.(params.spotsfield).parentnum{spt};
                cellList{frm}{cell}.(params.spotsfield).parentframe{spt} = [];
                cellList{frm}{cell}.(params.spotsfield).parentnum{spt} = [];
                childrenframe = cellList{parentframe}{cell}.(params.spotsfield).childrenframe{parentnum};
                childrennum = cellList{parentframe}{cell}.(params.spotsfield).childrennum{parentnum};
                num = childrenframe==frm & childrennum==spt;
                cellList{parentframe}{cell}.(params.spotsfield).childrenframe{parentnum}(num) = [];
                cellList{parentframe}{cell}.(params.spotsfield).childrennum{parentnum}(num) = [];
                delete(handles.disp.links{frm}{spt})
                handles.disp.links{frm}{spt} = [];
            end
        end
        
    end
end

function [spotList,spotList2] = getSpotList(cellList,field)
    spotList = {};
    for frame=1:length(cellList)
        for cell=1:length(cellList{frame})
            if cell<=length(cellList{frame}) && ~isempty(cellList{frame}{cell}) && isfield(cellList{frame}{cell},field)
                for spot=1:length(cellList{frame}{cell}.(field).l)
                    if ~isfield(cellList{frame}{cell}.(field),'parentframe') || isempty(cellList{frame}{cell}.(field).parentframe{spot})
                        spotList = [spotList trackonespot(frame,spot)];
                        % disp([frame cell spot])
                    end
                end
            end
        end
        spotList2 = {};
        for q=1:length(spotList)
            if length(spotList{q}.relpos)>1
                spotList2 = [spotList2 spotList{q}];
            end
        end
    end
    function s = trackonespot(frame,spot)
        s{1}.relpos = [];
        s{1}.abspos = [];
        s{1}.reld = [];
        s{1}.absd = [];
        s{1}.frame = [];
        s{1}.cell = [];
        s{1}.spot = [];
        s{1}.celllength = [];
        while true
            abspos = cellList{frame}{cell}.(field).l(spot);
            celllength = cellList{frame}{cell}.length;
            relpos = abspos/celllength;
            absd = cellList{frame}{cell}.(field).d(spot);
            mesh = cellList{frame}{cell}.mesh;
            maxd = sqrt(max((mesh(:,1)-mesh(:,3)).^2+(mesh(:,2)-mesh(:,4)).^2));
            reld = absd/maxd;
            s{1}.relpos = [s{1}.relpos relpos];
            s{1}.abspos = [s{1}.abspos abspos.*params.pix2mu];
            s{1}.reld = [s{1}.reld reld];
            s{1}.absd = [s{1}.absd absd.*params.pix2mu];
            s{1}.frame = [s{1}.frame frame];
            s{1}.cell = [s{1}.cell cell];
            s{1}.spot = [s{1}.spot spot];
            s{1}.celllength = [s{1}.celllength celllength];
            if isfield(cellList{frame}{cell}.(field),'childrenframe') && length(cellList{frame}{cell}.(field).childrenframe{spot})==1
                frame2 = cellList{frame}{cell}.(field).childrenframe{spot}(1);
                spot2 = cellList{frame}{cell}.(field).childrennum{spot}(1);
                frame = frame2;
                spot = spot2;
            else
                if isfield(cellList{frame}{cell}.(field),'childrenframe') && length(cellList{frame}{cell}.(field).childrenframe{spot})>1
                    newframe = cellList{frame}{cell}.(field).childrenframe{spot}(2:end);
                    newspot  = cellList{frame}{cell}.(field).childrennum{spot}(2:end);
                    for i=1:length(newframe)
                        s2 = trackonespot(newframe(i),newspot(i));
                        s = [s s2];
                    end
                end
                break
            end
        end
    end
end