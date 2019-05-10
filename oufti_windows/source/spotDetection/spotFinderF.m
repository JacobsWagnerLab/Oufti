function spotFinderF
% A version of SpotFinder, which works with spots without cells
% Currently it does not perform training, though it uses most of the
% parameters of SpotFinderZ
% 
% Version 0.2 of 09/08/2011
% 
% Changes compared to version 0.1:
% - Added 'min filtered height' and 'shift limit' and parameters
% - Corrected bug switching x and y (which previously created error ~1px)
%
% Updated on 06/20/2013 by Ivan:
% - to fix incorrect definition of SpotWidth (squared value was used
% instead of SW) leading to miscalculation of SpotItensity
% - removed additional  "hidden" filtering of the potential spots before
% fitting with hmin value


% clear oufti data from old sessions, if any
global handles
if ~isempty(who('handles')) && isfield(handles,'maingui') && ishandle(handles.maingui)
    choice = questdlg('Another MicrobeTracker or SpotFinder session is running. Close it and continue?','Question','Close & continue','Keep & exit','Close & continue');
    if strcmp(choice,'Keep & exit')
        return
    else
        if ~isempty(who('handles')) && isstruct(handles)
            fields = fieldnames(handles);
            for q1=1:length(fields)
                cfield = [];
                eval(['cfield = handles.' fields{q1} ';'])
                if ishandle(cfield)
                    delete(cfield);
                elseif isstruct(cfield)
                    fields2 = fieldnames(cfield);
                    for q2=1:length(fields2)
                        eval(['if ishandle(cfield.' fields2{q2} '), delete(cfield.' fields2{q2} '); end'])
                    end
                end
            end
        end
    end
end

% detect if Bioformats is installedcurrentdir = fileparts(mfilename('fullpath'));
bformats = checkbformats(1);
global handles %#ok<REDEF>

panelshift=0;
handles.maingui = figure('pos',[250 250 280 165+panelshift],'Toolbar','none','Menubar','none','Name','SpotFinderF 0.2','NumberTitle','off','IntegerHandle','off','Resize','off','KeyPressFcn',@mainkeypress);
handles.normpanel = uibuttongroup('units','pixels','pos',[145 59+panelshift 130 99],'SelectionChangeFcn',@checkchange_cbk);
handles.outputpanel = uipanel('units','pixels','pos',[8 44+panelshift 130 85]);
set(handles.maingui,'Color',get(handles.normpanel,'BackgroundColor'));

uicontrol(handles.normpanel,'units','pixels','Position',[5 80 118 16],'Style','text','String','Normalization','FontWeight','bold','HorizontalAlignment','center');
uicontrol(handles.normpanel,'units','pixels','Position',[5 66 118 16],'Style','text','String','(requires subt. bgrnd)','HorizontalAlignment','center');
handles.norm1 = uicontrol(handles.normpanel,'units','pixels','Position',[5 48 120 16],'Style','radiobutton','String','No normalization','KeyPressFcn',@mainkeypress);
handles.norm2 = uicontrol(handles.normpanel,'units','pixels','Position',[5 28 120 16],'Style','radiobutton','String','Frame','KeyPressFcn',@mainkeypress);
handles.norm3 = uicontrol(handles.normpanel,'units','pixels','Position',[5 8 120 16],'Style','radiobutton','String','Stack','KeyPressFcn',@mainkeypress);

uicontrol(handles.outputpanel,'units','pixels','Position',[6 62 120 16],'Style','text','String','Output','FontWeight','bold','HorizontalAlignment','center');
handles.outspots = uicontrol(handles.outputpanel,'units','pixels','Position',[5 46 120 16],'Style','checkbox','String','Spots','Callback',@checkchange_cbk,'KeyPressFcn',@mainkeypress);
handles.outfile = uicontrol(handles.outputpanel,'units','pixels','Position',[35 27 90 16],'Style','checkbox','String','File','Enable','off','KeyPressFcn',@mainkeypress);
handles.outscreen = uicontrol(handles.outputpanel,'units','pixels','Position',[35 8 90 16],'Style','checkbox','String','Screen','Enable','off','KeyPressFcn',@mainkeypress);

handles.helpbtn = uicontrol(handles.maingui,'units','pixels','Position',[10 138+panelshift 125 20],'String','Help','Callback',@help_cbk,'Enable','on','KeyPressFcn',@mainkeypress);
handles.loadstack = uicontrol(handles.maingui,'units','pixels','Position',[151 41+panelshift 130 14],'Style','checkbox','String','Use stack files','Enable','on','KeyPressFcn',@mainkeypress);

handles.parambtn = uicontrol(handles.maingui,'units','pixels','Position',[13 13+panelshift 121 22],'String','Params','Callback',@params_cbk,'KeyPressFcn',@mainkeypress);
handles.run = uicontrol(handles.maingui,'units','pixels','Position',[147 13+panelshift 121 22],'String','Run','Callback',@run_cbk,'KeyPressFcn',@mainkeypress);
handles.calculate = [];
drawnow

se{1} = strel('arbitrary',[0 0 0 0 0; 0 0 0 0 0; 1 1 1 1 1; 0 0 0 0 0; 0 0 0 0 0]);
se{2} = strel('arbitrary',[1 0 0 0 0; 0 1 0 0 0; 0 0 1 0 0; 0 0 0 1 0; 0 0 0 0 1]);
se{3} = strel('arbitrary',[0 0 1 0 0; 0 0 1 0 0; 0 0 1 0 0; 0 0 1 0 0; 0 0 1 0 0]);
se{4} = strel('arbitrary',[0 0 0 0 1; 0 0 0 1 0; 0 0 1 0 0; 0 1 0 0 0; 1 0 0 0 0]);

params.loCutoff = 1;
params.hiCutoff = 3;
params.minprefilterh = 0;
params.shiftlim = 0.01;
params.dmax = 6;
params.resize = 1;
params.ridges = 1;
params.wmax = 20; % max width in pixels
params.wmin = 4; % min width in pixels
params.hmin = 0.001; % min height
params.ef2max = 30; % max relative squared error
params.vmax = 1; % max ratio of the variance to squared spot height
params.fmin = 0.01; % min ratio of the filtered to fitted spot (takes into account size and shape)
saveparamsFileName = '';

spotList = [];
FirstFolder = '';
spotFinderMImageFile = '';
spotFinderMFCFile = '';
targetSpotsFileName = '';
w = [];


    function mainkeypress(hObject, eventdata)
        c = get(handles.maingui,'CurrentCharacter');
        if isempty(c)
            return;
        elseif double(c)==28 % left arrow - go to previous cell
            set(handles.maingui,'UserData',-1);
        elseif double(c)==29 % right arrow - go to next cell
            set(handles.maingui,'UserData',1);
        elseif double(c)==27 % ESC - stop
            set(handles.maingui,'UserData',0);
            stoprun;
        end
    end

    function params_cbk(hObject, eventdata)
        handles.params = figure('pos',[270 300 240 325],'Toolbar','none','Menubar','none','Name','spotFinder params','NumberTitle','off','IntegerHandle','off','Resize','off','CloseRequestFcn',@paramsclosereq,'Color',get(handles.outputpanel,'BackgroundColor'));
        uicontrol(handles.params,'units','pixels','Position',[5 300 140 16],'Style','text','String','Low cutoff, px','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 280 140 16],'Style','text','String','High cutoff, px','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 260 140 16],'Style','text','String','Min filtered height, i.u.','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 240 140 16],'Style','text','String','Shift limit','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 220 140 16],'Style','text','String','Fit area size, px','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 200 140 16],'Style','text','String','Resize, times','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 180 140 16],'Style','text','String','Remove ridges','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 160 140 16],'Style','text','String','Max width squared, px^2','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 140 140 16],'Style','text','String','Min width squared, px^2','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 120 140 16],'Style','text','String','Min height, i.u.','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 100 140 16],'Style','text','String','Max rel. sq. error','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 80 140 16],'Style','text','String','Max var/sq. height ratio','HorizontalAlignment','right');
        uicontrol(handles.params,'units','pixels','Position',[5 60 140 16],'Style','text','String','Min filtered/fitted ratio','HorizontalAlignment','right');
        
        handles.OK1 = uicontrol(handles.params,'units','pixels','Position',[6 6 230 18],'String','OK','Callback',@paramsclosereq);
        handles.OK2 = uicontrol(handles.params,'units','pixels','Position',[6 30 110 18],'String','Save','Callback',@saveparams);
        handles.OK3 = uicontrol(handles.params,'units','pixels','Position',[126 30 110 18],'String','Load','Callback',@loadparams);
        handles.loCutoff = uicontrol(handles.params,'units','pixels','Position',[155 300 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.hiCutoff = uicontrol(handles.params,'units','pixels','Position',[155 280 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.minprefilterh = uicontrol(handles.params,'units','pixels','Position',[155 260 51 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.minprefilterhchk = uicontrol(handles.params,'units','pixels','Position',[207 260 30 17],'String','Test','Callback',@minprefilterhchk_cbk);
        handles.shiftlim = uicontrol(handles.params,'units','pixels','Position',[155 240 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.dmax = uicontrol(handles.params,'units','pixels','Position',[155 220 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.resize = uicontrol(handles.params,'units','pixels','Position',[155 200 70 17],'Style','edit','String','','BackgroundColor',[1 1 1],'Enable','on'); % TODO: test before enabling
        handles.ridges = uicontrol(handles.params,'units','pixels','Position',[182 180 70 17],'Style','checkbox','String','');
        handles.wmax = uicontrol(handles.params,'units','pixels','Position',[155 160 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.wmin = uicontrol(handles.params,'units','pixels','Position',[155 140 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.hmin = uicontrol(handles.params,'units','pixels','Position',[155 120 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.ef2max = uicontrol(handles.params,'units','pixels','Position',[155 100 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.vmax = uicontrol(handles.params,'units','pixels','Position',[155 80 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        handles.fmin = uicontrol(handles.params,'units','pixels','Position',[155 60 70 17],'Style','edit','String','','BackgroundColor',[1 1 1]);
        setparams
    end
    function setparams
        set(handles.loCutoff,'String',num2str(params.loCutoff));
        set(handles.hiCutoff,'String',num2str(params.hiCutoff));
        set(handles.minprefilterh,'String',num2str(params.minprefilterh));
        set(handles.shiftlim,'String',num2str(params.shiftlim));
        set(handles.dmax,'String',num2str(params.dmax));
        set(handles.resize,'String',num2str(params.resize));
        set(handles.ridges,'Value',params.ridges);
        set(handles.wmax,'String',num2str(params.wmax));
        set(handles.wmin,'String',num2str(params.wmin));
        set(handles.hmin,'String',num2str(params.hmin));
        set(handles.ef2max,'String',num2str(params.ef2max));
        set(handles.vmax,'String',num2str(params.vmax));
        set(handles.fmin,'String',num2str(params.fmin));
    end

    function saveparams(hObject, eventdata)
        [FileName,pathname] = uiputfile('*.sfp', 'Select file to put parameters to',saveparamsFileName);
        if(FileName==0), stoprun; return; end;
        saveparamsFileName = fullfile(pathname,FileName);
        getparams
        save(saveparamsFileName,'params')
    end

    function loadparams(hObject, eventdata)
        [FileName,pathname] = uigetfile('*.sfp', 'Select file to get parameters from',saveparamsFileName);
        if(FileName==0), stoprun; return; end;
        saveparamsFileName = fullfile(pathname,FileName);
        l = load('-mat',saveparamsFileName,'params');
        if isfield(l,'params')
            params = l.params;
        else
            disp('Wrong file type')
        end
        setparams
    end

    function paramsclosereq(hObject, eventdata)
        getparams
        delete(handles.params);
    end

    function getparams
        params.loCutoff = str2num(get(handles.loCutoff,'String'));
        params.hiCutoff = str2num(get(handles.hiCutoff,'String'));
        params.minprefilterh = str2num(get(handles.minprefilterh,'String'));
        params.shiftlim = str2num(get(handles.shiftlim,'String'));
        params.dmax = str2num(get(handles.dmax,'String'));
        params.resize = str2num(get(handles.resize,'String'));
        params.ridges = get(handles.ridges,'Value');
        params.wmax = str2num(get(handles.wmax,'String'));
        params.wmin = str2num(get(handles.wmin,'String'));
        params.hmin = str2num(get(handles.hmin,'String'));
        params.ef2max = str2num(get(handles.ef2max,'String'));
        params.vmax = str2num(get(handles.vmax,'String'));
        params.fmin = str2num(get(handles.fmin,'String'));
    end

    function minprefilterhchk_cbk(hObject, eventdata)
        [filename,pathname] = uigetfile('*.*','Select image file to test',spotFinderMFCFile);
        if isequal(filename,0), return; end
        spotFinderMFCFile = fullfile(pathname,filename);
        getparams
        img = imread(spotFinderMFCFile);
        cimage0 = im2double(img);
        cimage0 = imresize(cimage0,params.resize);
        cimageF = filterimage(cimage0);
        if params.minprefilterh>0
            cimageF = cimageF.*(cimageF>params.minprefilterh);
        end
        figure('Name',['Filtered image, min height ' num2str(params.minprefilterh)])
        imshow(cimageF,[])
        colormap jet
        set(gca,'pos',[0 0 1 1])
    end

    function checkchange_cbk(hObject, eventdata)
        if hObject==handles.outspots && get(handles.outspots,'Value')==1
            set(handles.outscreen,'Enable','on')
            set(handles.outfile,'Enable','on')
        elseif hObject==handles.outspots && get(handles.outspots,'Value')==0
            set(handles.outscreen,'Enable','off')
            set(handles.outfile,'Enable','off')
        end

        if hObject==handles.outspots && get(handles.outspots,'Value')==1 && get(handles.outfile,'Value')==0
            set(handles.outscreen,'Value',1)
        elseif hObject==handles.outfile && get(handles.outscreen,'Value')==0 && get(handles.outfile,'Value')==0
            set(handles.outfile,'Value',1)
        end

    end

    function stoprun(hObject, eventdata)
        set(handles.parambtn,'Style','pushbutton','String','Params','Callback',@params_cbk);
        set(handles.run,'Style','pushbutton','Position',[147 13+panelshift 121 22],'String','Run','Callback',@run_cbk);
        if ishandle(handles.calculate), delete(handles.calculate); end
        if ~isempty(w) && ishandle(w), close(w); end
        if isfield(handles,'fig')&&ishandle(handles.fig), delete(handles.fig); end
    end

    function help_cbk(hObject, eventdata)
        folder = fileparts(which('spotFinderZ.m'));
        w = fullfile2(folder,'help','helpSpotFinderS.htm');
        if ~isempty(w)
            web(w);
        end
    end

    function run_cbk(hObject, eventdata)
        normType = get(handles.norm1,'Value') + 2*get(handles.norm2,'Value') + 3*get(handles.norm3,'Value');
        outfile = get(handles.outfile,'Value') && get(handles.outspots,'Value');
        outscreen = get(handles.outscreen,'Value') && get(handles.outspots,'Value');
        
%% Ask to input images
        disp(' ')
        if get(handles.loadstack,'Value')
            if bformats
                [filename,pathname] = uigetfile('*.*','Select file with signal images',spotFinderMImageFile);
            else
                [filename,pathname] = uigetfile({'*.tif';'*.tiff'},'Select file with signal images',spotFinderMImageFile);
            end
            if isempty(filename)||isequal(filename,0), stoprun; return, end
            spotFinderMImageFile = fullfile2(pathname,filename);
            [~,images] = loadimagestack(3,spotFinderMImageFile,1,0);
        else
            folder = uigetdir(FirstFolder,'Select folder with signal images');
            if isempty(folder)||isequal(folder,0), stoprun; return, end
            images = loadimageseries(folder,1);
            FirstFolder = folder;
        end
        L1 = size(images,3);
        pause(0.1);
        
%% Ask for the output file name
        if outfile
            [FileName,PathName] = uiputfile('*.mat', 'Enter a filename to save the data to',targetSpotsFileName);
            targetSpotsFileName = fullfile2(PathName,FileName);
        end
        
%% Get frame range
        range1 = 1;
        range2 = L1;
        framerange = range1:range2;
        if isempty(framerange), return; end
        
%% Obtaining normalization data
        normarray = ones(1,max(framerange));
        if ismember(normType,[2 3])
            for frame=framerange
                cimage = im2double(images(:,:,frame));
                normarray(frame) = mean(mean(cimage))/params.resize^2;
            end
            if normType==3
                normarray = ones(1,max(framerange))*mean(normarray);
            end
        end
                        
        
%% Filtering and integrating images
        Nspotstotal1 = 0; % Raw spots count
        Ispotstotal1 = 0; % Raw spots total intensity
        Nspotstotal2 = 0; % Good spots count
        Ispotstotal2 = 0; % Good spots total intensity
        msize = 1.5; % Prefilter range, must be >0
        x = repmat(1:ceil(msize)*2+1,ceil(msize)*2+1,1);
        y = repmat((1:ceil(msize)*2+1)',1,ceil(msize)*2+1);
        prefilter = exp(-((ceil(msize)+1-x).^2 + (ceil(msize)+1-y).^2) / msize^2);
        prefilter = prefilter/sum(sum(prefilter));
        x2 = [];
        y2 = [];
        g0 = makeg(params.dmax);
        
        spotList = {};
        w = waitbarN(0, 'Filtering / integrating images');
        for frame=framerange
            dmax = round(params.dmax);

            cimage0 = im2double(images(:,:,frame))/normarray(frame);
            cimage0 = imresize(cimage0,params.resize);
            cimageF = filterimage(cimage0);
            if params.minprefilterh>0
                cimageF = cimageF.*(cimageF>params.minprefilterh);
            end
            cimage = imfilter(cimage0,prefilter,'replicate');

            Ispotstotal1 = Ispotstotal1 + sum(sum(cimageF));
            Nspotstotal1 = Nspotstotal1 + sum(sum(cimageF>0));

            [ya,xa,va] = find(cimageF(dmax+1:end-dmax,dmax+1:end-dmax));
             % these 2 lines were in original Oleksii's code (Ivan)
             %xa = xa(va>params.hmin)+dmax;
             %ya = ya(va>params.hmin)+dmax;
             % changed to these 2 lines
            xa = xa+dmax;
            ya = ya+dmax;

            lxa = length(xa);
            ind2 = 0;
            for ind=1:lxa
                box = [xa(ind)-dmax ya(ind)-dmax dmax*2 dmax*2];
                imR = imcrop(cimage,box);
                imF = imcrop(cimageF,box);
                istr = analizeonespot(imR,imF,box,g0,params);
                if ~isempty(istr), ind2=ind2+1; spotList{frame}{ind2} = in2outstr(istr); end
                waitbar((frame-1+ind/lxa)/L1,w,['Processing spot ' num2str(ind) ' (of ' num2str(lxa) ') on frame ' num2str(frame) ' (of ' num2str(length(framerange)) ')']);
            end
            
            Nspotstotal2 = Nspotstotal2 + ind2; 
        end
        disp(['Filtering/integration finished, processed ' num2str(L1) ' images']);
        delta = 1E-10;
        disp(['Identified ' num2str(Nspotstotal1) ' raw spots of mean intensity ' num2str(Ispotstotal1/Nspotstotal1+delta)]);
        disp(['Identified ' num2str(Nspotstotal2) ' good spots of mean intensity ' num2str(Ispotstotal2/Nspotstotal2+delta)]);
        close(w);
        
%% Finding all spots regardless of the cells
        % if outimpos
        %     assignin('base','positions',positions);
        % end

%% Saving data
        if outscreen, assignin('base','spotList',spotList); disp('Data was written to cellList array'); end
        if outfile
            if isempty(dir(targetSpotsFileName))
                save(targetSpotsFileName,'params','spotList')
            else
                save(targetSpotsFileName,'params','spotList','-append')
            end
        end
% End of run_cbk function code
    end

    function res = filterimage(img)
        img2 = img;% im2double(imread(['C:\Documents and Settings\Oleksii\Desktop\Audrey''s mRNA\gfps\0' num2str(k,'%02.2d') '.tif']));
        img2a = bpass(img2,params.loCutoff,params.hiCutoff);
        img2b = img2a;
        img2c = repmat(img2b,[1 1 4]);
        if params.ridges
            for j=1:4, img2c(:,:,j) = img2b-imopen(img2b,se{j}); end
            img2b = min(img2c,[],3);
            img2b = bpass(img2b,params.loCutoff,params.hiCutoff);
        end
        res = img2b.*(imdilate(img2b,strel('arbitrary',[1 1 1; 1 1 1; 1 1 1]))==img2b).*(imerode(img2b,strel('disk',1))<img2b);
    end
end

%% Global functions

function res = bpass(image_array,lnoise,lobject)
    % Code 'bpass.pro' by John C. Crocker and David G. Grier (1997).
    % All comments are removed, see separate file version for details

    normalize = @(x) x/sum(x);

    image_array = double(image_array);
    r = -round(lobject):round(lobject);
    gaussian_kernel = normalize(exp(-(r/(2*lnoise)).^2));
    boxcar_kernel = normalize(ones(1,length(r)));

    gconv = conv2(image_array',gaussian_kernel','same');
    gconv = conv2(gconv',gaussian_kernel','same');

    bconv = conv2(image_array',boxcar_kernel','same');
    bconv = conv2(bconv',boxcar_kernel','same');

    filtered = gconv - bconv;

    filtered(1:(round(lobject)),:) = 0;
    filtered((end - lobject + 1):end,:) = 0;
    filtered(:,1:(round(lobject))) = 0;
    filtered(:,(end - lobject + 1):end) = 0;

    res = max(filtered,0);
end

function w=waitbarN(n,s)
    w = waitbar(n,s);
    p = rand^2;
    q = sin(rand*2*pi);
    color = [p (1-p)*q^2 (1-p)*(1-q^2)];
    set(findobj(w,'Type','patch'),'FaceColor',color,'EdgeColor',color)
    set(findobj(w,'Type','axes'),'Children',get(findobj(w,'Type','axes'),'Children'))
end

function g = makeg(dmax)
    g.x0 = dmax;
    g.dst2 = repmat(reshape(-dmax:dmax,1,[]),2*dmax+1,1).^2 +...
             repmat(reshape(-dmax:dmax,[],1),1,2*dmax+1).^2;
    g.msk = g.dst2<dmax^2;
    g.mskp = bwperim(g.msk);
    
    g.mr = 2*dmax+1;
    g.nr = 2*dmax+1;
    g.Ix2 = repmat((1:g.mr)',[1 g.nr]);
    g.Iy2 = repmat(1:g.nr,[g.mr 1]);
    
    g.options = optimset('Display','off','MaxIter',300);
end

function outstr = analizeonespot(imR,imF,box,g,params)
    imR2 = imR.*g.msk;
    
    imR2a = imR2(g.msk);
    bgr0 = mean(imR2a(imR2a<median(imR2a)));
    dat1 = [bgr0 sqrt(params.wmin*params.wmax) max(0,imR(g.x0+1,g.x0+1)-bgr0)];
    [dat2,fval,exitflag] = fminsearch(@gfit,dat1,g.options);
    
    %a1 = checkifcorrect(dat2,params);
    
    dat2 = [dat2 g.x0 g.x0];
    [dat3,fval,exitflag] = fminsearch(@gfitpos,dat2,g.options);
    
    a2 = checkifcorrect(dat2,params);
    if ~a2, outstr=[]; return; end
    
    outstr.b = dat3(1); % background
    %this how it was in original Olkesii's code, changed to following line (Ivan):
    % outstr.w = dat3(2); % spot width,
    outstr.w = sqrt(dat3(2)); % spot width, in orginal  
    outstr.h = dat3(3); % hight
    outstr.rse = gfit(dat3)/(dat3(3)^2); % rel. sq. error
    outstr.pmv = var(imR(g.mskp))/(dat3(3)^2); % perimeter variance
    outstr.fur = imF(g.x0,g.x0)/dat3(3); % filtered/fitted ratio
    outstr.e = exitflag; % exit -1 / 0 / 1
    outstr.x = dat3(5)+box(1)-1;
    outstr.y = dat3(4)+box(2)-1;
    
    function lst = checkifcorrect(dat,params)
        spotlist(1,1) = dat(1); % background
        spotlist(1,2) = dat(2); % squared width of the spots
        spotlist(1,3) = dat(3); % hight
        spotlist(1,4) = gfit(dat)/(dat(3)^2); % rel. sq. error
        spotlist(1,5) = var(imR(g.msk))/(dat(3)^2); % perimeter variance
        spotlist(1,6) = imF(g.x0+1,g.x0+1)/dat(3); % filtered/fitted ratio
        spotlist(1,7) = exitflag; % exit -1 / 0 / 1
        spotlist(1,8) = g.x0+1;
        spotlist(1,9) = g.x0+1;

        wmax = params.wmax; % max width in pixels
        wmin = params.wmin;
        hmin = params.hmin; % min height
        ef2max = params.ef2max; % max relative squared error
        vmax = params.vmax; % max ratio of the variance to squared spot height
        fmin = params.fmin; % min ratio of the filtered to fitted spot (takes into account size and shape)

        lst = spotlist(:,2)<wmax & spotlist(:,2)>wmin & spotlist(:,3)>hmin ...
            & spotlist(:,4)<ef2max ...
            & (spotlist(:,5)<vmax | spotlist(:,5)==0) ... % OK if zero
            & spotlist(:,6)>fmin ...
            & spotlist(:,7)==1;
    end
    
    function res = gfit(in)
        b = in(1);
        wv = in(2);
        hv = in(3);
        M = b + exp(-g.dst2/wv)*hv;
        R = (g.msk.*(M - imR)).^2;
        res = sum(sum(R));
        if b<0, res=res+(b/hv)^2; end
    end
    function res = gfitpos(in)
        b = in(1);
        wv = in(2);
        hv = in(3);
        xv = in(4);
        yv = in(5);
        Xm = repmat(xv,g.mr,g.nr);
        Ym = repmat(yv,g.mr,g.nr);
        D2 = (Xm-g.Ix2).^2 + (Ym-g.Iy2).^2;
        M = b + exp(-D2/wv)*hv;
        R = (g.msk.*(M - imR)).^2;
        
        if ~isfield(params,'shiftlim')||isempty(params.shiftlim)||params.shiftlim<0, params.shiftlim = 0.01; end
        res = sum(sum(R))*(1+params.shiftlim*((g.x0-xv)^2+(g.x0-yv)^2))*(1+max(0,wv/params.wmax-1)^2);
        if b<0, res=res+(b/hv)^2; end
    end
end

function outstr = in2outstr(instr)
    outstr.h = instr.h;
    outstr.w = instr.w;
    outstr.b = instr.b;
    outstr.x = instr.x;
    outstr.y = instr.y;
    outstr.m = pi*instr.h*instr.w^2;
end

function res = fullfile2(varargin)
    % This function replaces standard fullfile function in order to correct
    % a MATLAB bug that appears under Mac OS X
    % It produces results identical to fullfile under any other OS
    arg = '';
    for i=1:length(varargin)
        if ~strcmp(varargin{i},'\') && ~strcmp(varargin{i},'/')
            if i>1, arg = [arg ',']; end
            arg = [arg '''' varargin{i} ''''];
        end
    end
    eval(['res = fullfile(' arg ');']);
end