function spotViewer
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function imageViewer
%@author:  Ahmad J Paintdakhi
%@date:    June 26 2013
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%none
%**********Input********:
%none
%=========================================================================
% PURPOSE:
% The purpose of this gui is to display signals images and rectangles/boxes
% around each detected spot.  The image data could be image series, image
% stack or image data (matlab format).  The box data could be box(hoong
% format), spotList(spotFinderF) format or cellList(spotFinder) format from
% microbeTracker.  The gui also has a zoom and contrast functionality to
% help user evaluate fluorescent signals with respect to gathered data.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%global variables used with different function.
global frame prevframe images boxData spotListValue boxValue pathName cellListValue zoomValue hIm 
global cellList rawS1Data rawS2Data 
scrSize = get(0,'ScreenSize');%screen size values gathered for different monitors usage.
scrSize = [ 1 1 scrSize(3) 980];
%variable initialization
boxValue = 0;
spotListValue = 0;
cellListValue = 0;
zoomValue = 0;
hIm = [];
frame = 1;
prevframe = 1;
pathName = [];

%main figure for the gui.
handles.imageViewer = figure('Position',[100 scrSize(4)/10 scrSize(4)+10 scrSize(4)-340],'units','pixels',...
                            'ButtonDownFcn',@mainkeypress,'CloseRequestFcn',@closeImageViewer,'Interruptible','off',...
                            'WindowButtonDownFcn',@selectclick,'Name','SpotViewer',...
                            'Toolbar','none','Menubar','none','NumberTitle','off','IntegerHandle',...
                            'off','uicontextmenu',[],'DockControls','off','Resize','off');
%uipanel for the gui                        
handles.imagePanel = uipanel('units','pixels','pos',[1 1 scrSize(4)+10 scrSize(4)-340],'BorderType','none');                        
%uipanel for images to be displayed
handles.imageViewerImagePanel = uipanel('units','pixels','pos',[5 5 scrSize(4)-250 scrSize(4)-345],'BorderType','etchedout',...
                                         'BackgroundColor',[1 1 1],'BorderWidth',1,'SelectionHighlight','on','ShadowColor',[0 0 1]); 
                                     
%image slider
handles.imslider = uicontrol('Style','slider','units','pixels','Position',[scrSize(4)-250+7 5 15 scrSize(4)-345],...
                         'SliderStep',[1 1],'min',1,'max',2,'value',1,'Enable','off','callback',@imslider);
%listner for the slider, the listner helps expedite the response time of
%the slider.
%Matlab 2014b release does not support this call
%hScrollbarImSlider = handle.listener(handles.imslider,'ActionEvent',@imslider);

%--------------------------------------------  Data Panel ------------------------------------------------------------
handles.dataPanel = uipanel('units','pixels','Title','Load Data','pos',[scrSize(4)-250+30 (scrSize(4)-500) 160 75]);  
      
% % % handles.spotList = uicontrol(handles.dataPanel,'units','pixels','Position',[5 50 100 30],...
% % %                     'Style','pushbutton','String','Load Spotlist ','HorizontalAlignment','left','Callback',@loadBoxes);      
      
handles.cellList = uicontrol(handles.dataPanel,'units','pixels','Position',[5 10 100 30],...
          'Style','pushbutton','String','Load cellList ','HorizontalAlignment','left','Callback',@loadBoxes);        

%---------------------------------------------------------------------------------------------------------------------
      
      
      
%--------------------------------------------  Image Data Panel ------------------------------------------------------------
handles.imageDataPanel = uipanel('units','pixels','Title','Load Images','pos',[scrSize(4)-250+30 (scrSize(4)-670) 160 100]); 
      
uicontrol(handles.imageDataPanel,'units','pixels','Position',[5 50 100 30],...
          'Style','pushbutton','String','Load Image Stack ','HorizontalAlignment','left','Callback',@loadStack);
      
uicontrol(handles.imageDataPanel,'units','pixels','Position',[5 10 100 30],...
          'Style','pushbutton','String','Load Image series ','HorizontalAlignment','left','Callback',@loadImages);      
%------------------------------------------------------------------------------------------------------------------------------

%------------------------------------------------------------------------------------------------------------------------------
%frame number visualization.
uicontrol(handles.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-750) 50 40],...
          'Style','text','String','frame ','HorizontalAlignment','left','FontSize',12);

handles.currentframe = uicontrol(handles.imagePanel,'units','pixels','Position',[scrSize(4)-250+80 (scrSize(4)-730) 50 20],...
          'Style','edit','HorizontalAlignment','left','HitTest','off','SelectionHighlight','off','callback',@imslider);
%------------------------------------------------------------------------------------------------------------------------------

%------------------------------------------------------------------------------------------------------------------------------
%cell Number
uicontrol(handles.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-780) 50 40],...
          'Style','text','String','cell # ','HorizontalAlignment','left','FontSize',12);

handles.cellNum = uicontrol(handles.imagePanel,'units','pixels','Position',[scrSize(4)-250+80 (scrSize(4)-762) 50 20],...
          'Style','edit','HorizontalAlignment','left','background',[1 1 1],'callback',@updateHandle);
%------------------------------------------------------------------------------------------------------------------------------

%------------------------------------------------------------------------------------------------------------------------------
%Drop cell from CellList
handles.dropCell = uicontrol(handles.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-800) 50 20],...
          'Style','togglebutton','string','drop cell','HorizontalAlignment','left');
%------------------------------------------------------------------------------------------------------------------------------

%------------------------------------------------------------------------------------------------------------------------------
%Add spot to cellList
handles.addSpot = uicontrol(handles.imagePanel,'units','pixels','Position',[scrSize(4)-250+90 (scrSize(4)-800) 50 20],...
          'Style','togglebutton','string','add spot','HorizontalAlignment','left');
%------------------------------------------------------------------------------------------------------------------------------

%------------------------------------------------------------------------------------------------------------------------------
%Remove spot to cellList
handles.removeSpot = uicontrol(handles.imagePanel,'units','pixels','Position',[scrSize(4)-250+150 (scrSize(4)-800) 75 20],...
          'Style','togglebutton','string','remove spot','HorizontalAlignment','left');
%------------------------------------------------------------------------------------------------------------------------------

%------------------------------------------------------------------------------------------------------------------
%contrast button.  The contrast button pops up matlab imcontrast window
%which can be used to apply contrast to the current image.  The value of
%the image can be reset with the scrollbar.
uicontrol(handles.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-920) 75 20],...
                'Style','pushbutton','String','Contrast ','HorizontalAlignment','left','Callback',@contrast_cbk); 
%------------------------------------------------------------------------------------------------------------------

%-----------------------------------------------------------------------------------------------------------
%zoom button is used to zoom in the current image for better visualization
%of identified spots (labeled with rectangles or x) and raw fluorescent
%signals.
uicontrol(handles.imagePanel,'units','pixels','Position',[scrSize(4)-250+115 (scrSize(4)-920) 75 20],...
                'Style','pushbutton','String','Zoom ','HorizontalAlignment','left','Callback',@zoom_cbk); 
%-----------------------------------------------------------------------------------------------------------           


%---------------------------------------------------------------------------------------
%the imslider function updates images and data with respect to scrollbar changes.   
function imslider(hObject, EventType)%#ok<INUSD>
    prevframe = frame;
    drawnow();pause(0.005);
    tmpFrame = size(images,3)+1-round(get(hObject,'value'));
    if size(images,3) == 1, tmpFrame = 1;end
    frame = tmpFrame;
    box = displayImage();
    set(handles.currentframe,'String',[num2str(frame) ' of ' num2str(size(images,3))]);
    set(gcf, 'renderer', 'painters');
	displayBoxes(box);
end
%---------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------
%When a mouse is pressed on the image window one of the following
%operations are performed depending on the toggle button being selected.
function selectclick(hObject, EventType)%#ok<INUSD>
    cellNum = str2double(get(handles.cellNum,'string'));
    if get(handles.dropCell,'value') == 1
        for ii = 1:length(cellList.meshData)
            if doesCellExist(cellNum,ii,cellList)
                cellList = oufti_removeCellStructureFromCellList(cellNum,ii,cellList);
            end
        end
    elseif get(handles.addSpot,'value') == 1
        if ~isempty(cellNum) &&  ~isnan(cellNum)
            ps = get(handles.ax2,'CurrentPoint');
            xlimit = get(handles.ax2,'XLim');
            ylimit = get(handles.ax2,'YLim');
            xc = ps(1,1);
            yc = ps(1,2);
            if xc<xlimit(1) || xc>xlimit(2) || yc<ylimit(1) || yc>ylimit(2), return; end
        end
        img = images(:,:,frame);
        cellStructure = oufti_getCellStructure(cellNum,frame,cellList);
        if isfield(cellStructure,'box')
            roiImg = imcrop(img,cellStructure.box); 
        end
        try
            warning('off','MATLAB:colon:nonIntegerIndex');
            positionXY = positionEstimate(roiImg(xc-1:xc+1,yc-1:yc+1)) + [yc-1,xc-1] -1;
            positionX = positionXY(1);
            positionY = positionXY(2);
            rowPositions    = [floor(positionX)-3:floor(positionX) floor(positionX)+1:floor(positionX)+3]';
            columnPositions = [floor(positionY)-3:floor(positionY) floor(positionY)+1:floor(positionY)+3]';
            indexToPeak     = zeros(size(roiImg));
            indexToPeak(rowPositions,columnPositions) = 1;
            [rows,cols]     = size(roiImg);
            indexToPeak     = indexToPeak.*double(roiImg);
            indexToSpots    = bwconncomp(indexToPeak,8);
            indexToSpots    = indexToSpots.PixelIdxList{1};
            [~,id] = max(roiImg(indexToSpots));
            peakValueOfSpots = indexToSpots(id);
            %use g2d to get a position estimate
            rowPositions = (rem(peakValueOfSpots-1,rows)+1);
            columnPositions = ceil(peakValueOfSpots./rows);
            positionXY = positionEstimate(roiImg(rowPositions-1:rowPositions+1,columnPositions-1:columnPositions+1)) + [columnPositions-1,rowPositions-1] -1;
            positionX = positionXY(1);
            positionY = positionXY(2);
            indexPeakDistanceXY = indexToSpots;
            widthEstimate   = 2.0;
            backgroundRawImage = max(mean(mean(roiImg)),0);
            heightEstimate = (max(max(double(indexPeakDistanceXY)))-mean(mean(double(roiImg))));
            rowPositions = (rem(indexPeakDistanceXY-1,rows)+1);
            columnPositions = ceil(indexPeakDistanceXY./rows);
            gauss2dFitOptions = fitoptions('Method','NonlinearLeastSquares',...
                                   'Lower',[0,0,0],...
                                   'Upper',[Inf,Inf,Inf],'MaxIter', 600,...
                                   'Startpoint',[backgroundRawImage,heightEstimate,...
                                                 widthEstimate,positionX,positionY]);
           gauss2d = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,x,y) ...
                        backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                        /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)),...
                        'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions);

            [sfit,gof] = fit([columnPositions,rowPositions],double(roiImg(indexPeakDistanceXY)),...
                              gauss2d);
        catch
           return;
           
       end
        try
            confidenceInterval = confint(sfit);
            confidenceInterval = confidenceInterval(:,4:5);
        catch
            confidenceInterval = [];
        end
    
        xModelValue = reshape(cellStructure.box(1)-1+sfit.positionX,1,[]); 
        yModelValue = reshape(cellStructure.box(2)-1+sfit.positionY,1,[]);
        if ~isfield(cellStructure,'steplength')
           cellStructure = getextradata(cellStructure);
        end
        [l,d] = projectToMesh(cellStructure.box(1)-1+sfit.positionX,...
                         cellStructure.box(2)-1+sfit.positionY,cellStructure.mesh,cellStructure.steplength);
        I = 0;
        for kk = 1:size(cellStructure.mesh,1)-1
            pixelPeakX = [cellStructure.mesh(kk,[1 3]) cellStructure.mesh(kk+1,[3 1])] - cellStructure.box(1)+1;
            pixelPeakY = [cellStructure.mesh(kk,[2 4]) cellStructure.mesh(kk+1,[4 2])] - cellStructure.box(2)+1;
            if inpolygon(sfit.positionX,sfit.positionY,pixelPeakX,pixelPeakY)
                I = kk;
                break
            end
        end
        Q = 2*abs(pi*sfit.heightEstimate*sfit.widthEstimate^2);
        spotStructure.l = l;
% % %         spotStructure.magnitude = Q/65535;
% % %         spotStructure.w = sfit.widthEstimate*sqrt(2);
% % %         spotStructure.h = sfit.heightEstimate/65535;
% % %         spotStructure.b = sfit.backgroundRawImage/65535;
        spotStructure.d = d;
        spotStructure.x = xModelValue;
        spotStructure.y = yModelValue;
        spotStructure.positions = I;
        spotStructure.adj_Rsquared = gof.adjrsquare;
        spotStructure.confidenceInterval_x_y = confidenceInterval;
        if isfield(cellStructure,'spots') && size(cellStructure.spots,2) >= 1
            try
                cellStructure.spots.adj_Rsquared = cat(2,cellStructure.spots.adj_Rsquared,spotStructure.adj_Rsquared);
                cellStructure.spots.l = cat(2,cellStructure.spots.l,spotStructure.l);
% % %                 cellStructure.spots.magnitude = cat(2,cellStructure.spots.magnitude,spotStructure.magnitude);
% % %                 cellStructure.spots.w = cat(2,cellStructure.spots.w,spotStructure.w);
% % %                 cellStructure.spots.h = cat(2,cellStructure.spots.h,spotStructure.h);
% % %                 cellStructure.spots.b = cat(2,cellStructure.spots.b,spotStructure.b);
                cellStructure.spots.d = cat(2,cellStructure.spots.d,spotStructure.d);
                cellStructure.spots.x = cat(2,cellStructure.spots.x,spotStructure.x);
                cellStructure.spots.y = cat(2,cellStructure.spots.y,spotStructure.y);
                cellStructure.spots.confidenceInterval_x_y = cat(2,cellStructure.spots.confidenceInterval_x_y,spotStructure.confidenceInterval_x_y);
                cellStructure.spots.positions = cat(2,cellStructure.spots.positions,spotStructure.positions);           
            catch
                cellStructure.spots.adj_Rsquared = cellStructure.spots.rmse;
                cellStructure.spots = rmfield(cellStructure.spots,'rmse');
                cellStructure.spots.adj_Rsquared = cat(2,cellStructure.spots.adj_Rsquared,spotStructure.adj_Rsquared);
                cellStructure.spots.l = cat(2,cellStructure.spots.l,spotStructure.l);
% % %                 cellStructure.spots.magnitude = cat(2,cellStructure.spots.magnitude,spotStructure.magnitude);
% % %                 cellStructure.spots.w = cat(2,cellStructure.spots.w,spotStructure.w);
% % %                 cellStructure.spots.h = cat(2,cellStructure.spots.h,spotStructure.h);
% % %                 cellStructure.spots.b = cat(2,cellStructure.spots.b,spotStructure.b);
                cellStructure.spots.d = cat(2,cellStructure.spots.d,spotStructure.d);
                cellStructure.spots.x = cat(2,cellStructure.spots.x,spotStructure.x);
                cellStructure.spots.y = cat(2,cellStructure.spots.y,spotStructure.y);
                cellStructure.spots.confidenceInterval_x_y = cat(2,cellStructure.spots.confidenceInterval_x_y,spotStructure.confidenceInterval_x_y);
                cellStructure.spots.positions = cat(2,cellStructure.spots.positions,spotStructure.positions);   

            end
        else
            cellStructure.spots = spotStructure;
        end
        cellList = oufti_addCell(cellNum,frame,cellStructure,cellList);
        hold on;
        displayBoxes(cellStructure.box);
        hold off;
    elseif get(handles.removeSpot,'value') == 1
        cellStructure = oufti_getCellStructure(cellNum,frame,cellList);
        ps = get(handles.ax2,'CurrentPoint');
        xlimit = get(handles.ax2,'XLim');
        ylimit = get(handles.ax2,'YLim');
        xc = ps(1,1);
        yc = ps(1,2);
        if xc<xlimit(1) || xc>xlimit(2) || yc<ylimit(1) || yc>ylimit(2), return; end
        positionX = xc+cellStructure.box(1)-1;
        positionY = yc+cellStructure.box(2)-1;
        x = cat(1,cellStructure.spots.x);
        y = cat(1,cellStructure.spots.y);
        diffX = abs(positionX - x);
        diffY = abs(positionY - y);
        indexX = find(diffX < 0.35);
        indexY = find(diffY < 0.35);
        if size(indexX,1) < size(indexY,1)
            try
            cellStructure.spots.adj_Rsquared(indexX) = [];
            catch
                cellStructure.spots.rsquared = cellStructure.spots.rmse;
                cellStructure.spots = rmfield(cellStructure.spots,'rmse');
                cellStructure.spots.rsquared(indexX) = [];
            end
            cellStructure.spots.l(indexX) = [];
% % %             cellStructure.spots.magnitude(indexX) = [];
% % %             cellStructure.spots.w(indexX) = [];
% % %             cellStructure.spots.h(indexX) = [];
% % %             cellStructure.spots.b(indexX) = [];
            cellStructure.spots.d(indexX) = [];
            cellStructure.spots.x(indexX) = [];
            cellStructure.spots.y(indexX) = [];
            cellStructure.spots.confidenceInterval_x_y(indexX) = [];
            cellStructure.spots.positions(indexX) = []; 
        elseif size(indexX,1) > size(indexY,1)
            try
                
                cellStructure.spots.rsquared(indexY) = [];
            catch
                cellStructure.spots.rsquared = cellStructure.spots.rmse;
                cellStructure.spots = rmfield(cellStructure.spots,'rmse');
                cellStructure.spots.adj_Rsquared(indexY) = [];
            end
            cellStructure.spots.l(indexY) = [];
% % %             cellStructure.spots.magnitude(indexY) = [];
% % %             cellStructure.spots.w(indexY) = [];
% % %             cellStructure.spots.h(indexY) = [];
% % %             cellStructure.spots.b(indexY) = [];
            cellStructure.spots.d(indexY) = [];
            cellStructure.spots.x(indexY) = [];
            cellStructure.spots.y(indexY) = [];
            cellStructure.spots.confidenceInterval_x_y(indexY) = [];
            cellStructure.spots.positions(indexY) = []; 
        elseif size(indexX,1) == size(indexY,1)
            try
            cellStructure.spots.adj_Rsquared(indexX) = [];
            catch
                 cellStructure.spots.adj_Rsquared = cellStructure.spots.rmse;
                 cellStructure.spots = rmfield(cellStructure.spots,'rmse');
                 cellStructure.spots.adj_Rsquared(indexX) = [];
            end
            cellStructure.spots.l(indexX) = [];
% % %             cellStructure.spots.magnitude(indexY) = [];
% % %             cellStructure.spots.w(indexX) = [];
% % %             cellStructure.spots.h(indexX) = [];
% % %             cellStructure.spots.b(indexX) = [];
            cellStructure.spots.d(indexX) = [];
            cellStructure.spots.x(indexX) = [];
            cellStructure.spots.y(indexX) = [];
            cellStructure.spots.confidenceInterval_x_y(indexX) = [];
            cellStructure.spots.positions(indexX) = []; 
        end
        cellList = oufti_addCell(cellNum,frame,cellStructure,cellList);
        hold on;
        box = displayImage();
        displayBoxes(box);
        hold off;
        
    end
end
%---------------------------------------------------------------------------------------



%---------------------------------------------------------------------------------------
%loadBoxes function is used to load the three different types of data.  The
%data can be boxes(hoong's format), spotList(spotFinderF) format or
%cellList(spotFinder) format from microbeTracker gui.
function loadBoxes(hObject, EventType)%#ok<INUSD>
try

   if get(handles.cellList,'value')
        dataChoice = questdlg('Use current cellList?','Data','yes','no','yes');
        switch dataChoice
            case 'yes'
                if isempty(cellList.meshData) || sum(cellfun(@numel,cellList.meshData)) == 0
                    disp('cellList does not exist'); return;
                end
                cellListValue = 1;
            case 'no' 
            [fileDir,pathName] = uigetfile;
            filename = [pathName '/' fileDir];
            cellList = load(filename);
            cellList = cellList.cellList;
            cellListValue = 1;
            if ~isfield(cellList,'meshData')
                cellList = oufti_makeNewCellListFromOld(cellList);
            end
        end
   end
    h = msgbox('Data loaded successfully');
catch
    warndlg('CellList file not loaded correctly:  Try again');return;end
end
%---------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------
%loadImages function loads images that are in sequence or series in a given
%directory.
function loadImages(hObject, EventType)%#ok<INUSD>
    
 signalChoice = questdlg('Use current images?','signal value','yes','no','yes');
    switch signalChoice
        case 'yes'
            signalChoice = questdlg('Signal1 or Signal2?',...
                        'which signal?','Signal1','Signal2','Signal1');
                switch signalChoice
                    case 'Signal1'
                        signalData = rawS1Data;
                        if isempty(signalData(:,:,1)),disp('make sure Signal1 is loaded'); return;end
                        images = signalData;
                    case 'Signal2'
                        signalData = rawS2Data;
                        if isempty(signalData(:,:,1)),disp('make sure Signal2 is loaded'); return;end
                        images = signalData;
                end
                
            
        case 'no'
          if ~isempty(pathName) 
            try
              imageDir = uigetdir(pathName);
              files = dir([imageDir, '/*.tif*']);
            catch err
                return;
            end
          else
            imageDir = uigetdir;
            files = dir([imageDir '/*.tif*']);
          end
          w = waitbar(0, 'Loading image files, please wait...');
          try
            name_counter = 0;
            loadedDataTmp=[];
            for i=1:length(files)
                if files(i).isdir==1, continue; end;
                if isempty(loadedDataTmp)
                   loadedDataTmp = imread([imageDir '/' files(i).name]);
                   filenames = [];
                end
                name_counter = name_counter+1;
           end;
           [sz1,sz2,sz3] = size(loadedDataTmp);
           sz = [sz1 sz2 sz3];
           images = zeros([sz(1:2) name_counter],class(loadedDataTmp));
           name_counter = 1;
           for i=1:length(files)
                if(files(i).isdir == 1), continue; end;
                loadedDataTmp = imread([imageDir '/' files(i).name]);
                [sz1,sz2,sz3] = size(loadedDataTmp);
                if prod(([sz1,sz2,sz3]==sz)*1)
                images(:,:,name_counter) = sum(loadedDataTmp,3);
           else
               errordlg('Unable to open images: The images are of different sizes.', 'Error loading files');
               close(w);
                return;
               end
               filenames{name_counter} = files(i).name;
               name_counter = name_counter+1;
               waitbar(i/length(files), w);
           end
           catch
               images=[];
               disp('Error loading images: no images loaded');
               errordlg(['Could not open files! Make sure you selected the ', ...
                        'correct directory, all the filenames are the same length in ', ...
                        'that directory, and there are no other non-image files in ', ...
                        'that directory.'], 'Error loading files');
               close(w);
               return;
               end; 
           if isempty(images)
              errordlg('No image files to open in that directory!', 'Error loading files');
              close(w);
              return;
           end
           disp(['Images loaded from folder: ' imageDir]); close(w);
           updateSlider();
           rawS1Data = images;
           box = displayImage();
           
           displayBoxes(box);

               
    end
     
        
end
%---------------------------------------------------------------------------------------

%----------------------------------------------------------------------------------------------------
%loadStack loads images that are stored in a stack file.
function loadStack(hObject, EventType)%#ok<INUSD>
 signalChoice = questdlg('Use current images?','signal value','yes','no','yes');
    switch signalChoice
        case 'yes'
            signalChoice = questdlg('Signal1 or Signal2?',...
                        'which signal?','Signal1','Signal2','Signal1');
                switch signalChoice
                    case 'Signal1'
                        signalData = rawS1Data;
                        if isempty(signalData(:,:,1)),disp('make sure Signal1 is loaded'); return;end
                        images = signalData;
                    case 'Signal2'
                        signalData = rawS2Data;
                        if isempty(signalData(:,:,1)),disp('make sure Signal2 is loaded'); return;end
                        images = signalData;
                end
                updateSlider();
                box = displayImage();
            
        case 'no'
        [fileDir,pathName] = uigetfile({'*.tif';'*.tiff'},'Select Stack File with Phase Images...');
        filename = [pathName '/' fileDir];
        data = [];

        if (length(filename)>4 && strcmpi(filename(end-3:end),'.tif')) || ...
           (length(filename)>5 && strcmpi(filename(end-4:end),'.tiff'))
           % loading TIFF files
           try
              info = imfinfo(filename);
              numImages = numel(info);
              w = waitbar(0, 'Loading images, please wait...');
              lng = info(1).BitDepth;
              if lng==8
                 cls='uint8';
              elseif lng==16
                 cls='uint16';
              elseif lng==32
                 cls='uint32';
              else
                 disp('Error in image bitdepth loading multipage TIFF images: no images loaded');return;
              end
              data = zeros(info(1).Height,info(1).Width ,numImages, cls);
              for i = 1:numImages
                  data(:,:,i) = imread(filename,i,'Info',info);
                  waitbar(i/numImages, w);
              end
              close(w);
              disp(['Loaded ' num2str(numImages) ' images from a multipage TIFF']); 
              updateSlider();
              box = displayImage();
           catch err
               disp(err.message);
               images = [];
               close(w);
               return;

           end

        else % unsupported format of images
            disp('Error loading images: the stack must be in TIFF format for BioFormats must be loaded');
        end
        images = data;
        rawS1Data = images;
        updateSlider();
        box = displayImage();
        displayBoxes(box);
    end
     displayBoxes(box);
end
%----------------------------------------------------------------------------------------------------


%----------------------------------------------------------------------------------------------------
%loadImageData function loads images that are in .mat format.
function loadImageData(hObject, EventType)%#ok<INUSD>
if ~isempty(pathName)
    [fileDir,~] = uigetfile(pathName);
    filename = [pathName '/' fileDir];
else
    [fileDir,pathName] = uigetfile;
    filename = [pathName '/' fileDir];
end

images = load(filename);
images = images.imseries;
   updateSlider();
   box = displayImage();
   if isempty(boxData)
       disp('load boxData first')
       return;
   else
       displayBoxes(box);
   end
end
function updateSlider
   
    s = size(images,3);
    frame = max(min(frame,s),1);
    if s>1
        set(handles.imslider,'min',1,'max',s,'Value',s+1-frame,'SliderStep',[1/(s-1) 1/(s-1)],'Enable','on');
        set(handles.currentframe,'String',[num2str(frame) ' of ' num2str(s)]);
    end
end

function box = displayImage
box = [];
cellNum = str2double(get(handles.cellNum,'string'));
handles.ax2 = axes('Units','pixels','Position',[1 1 scrSize(4)-250 scrSize(4)-351],'parent',handles.imageViewerImagePanel);
handles.ax1 = axes('Units','pixels','Position',[1 1 scrSize(4)-250 scrSize(4)-351],'parent',handles.imageViewerImagePanel);

if isempty(cellNum) || isnan(cellNum)
    img = images(:,:,frame);
    handles.himage = imshow(img,[],'parent',handles.ax1);
    set(handles.ax1,'nextplot','add');
    
else
    img = images(:,:,frame);
    cellStructure = oufti_getCellStructure(cellNum,frame,cellList);
    if isfield(cellStructure,'box')
        roiImg = imcrop(img,cellStructure.box);
        bx = cellStructure.box;
    elseif isfield(cellStructure,'model')
        %use later to make sure bounding box is within image
        bxlim = [1 size(img,1) 1 size(img,2)];
        bx = [floor(min(cellStructure.model(:,2))), ceil(max(cellStructure.model(:,2))), floor(min(cellStructure.model(:,1))), ceil(max(cellStructure.model(:,1)))];
        bx([1 3]) = bx([1 3]) - ceil(N/2) - 3; %******cellPad******
        bx([2 4]) = bx([2 4]) + ceil(N/2) + 3; %******cellPad******
        %if the box is outside of the image, bring it back
        ck = (bx - bxlim).*[1 -1 1 -1];
        bx(ck < 0) = bxlim(ck < 0);
        roiImg = imcrop(img,bx);
    else
        disp('cellStructure does not contain box or model fields');
        return;
    end
    handles.ax2 = axes('Units','pixels','Position',[1 1 scrSize(4)-250 scrSize(4)-351],'parent',handles.imageViewerImagePanel);
    handles.himage = imshow(roiImg,[],'parent',handles.ax2);
    set(handles.ax2,'nextplot','add');
    box = bx;
end

end  
%----------------------------------------------------------------------------------------------------


%----------------------------------------------------------------------------------------------------
%displayBoxes function displays box or spot information that are stored in
%the data fields of either boxes(hoong format), spotList(spotFinderF
%format) or cellList(spotfinder format).
function displayBoxes(box)
    try
        if boxValue
            spotListValue = 0;
            tmpFrame = frame - 1;
            spotIndex = find(boxData(:,6) == tmpFrame);
            tempX = boxData(spotIndex,1);
            tempY = boxData(spotIndex,2);
            width = 6;
            height = 6;
            for ii = 1:length(spotIndex)
                x = tempX(ii);
                y = tempY(ii);
                pts = [x-3 y-3 width height];
                rectangle('Position',pts, 'LineWidth',1, 'EdgeColor','r');           
                % % % J = step(hshapeins, images(:,:,frame), pts);
                % % % handles.imageViewerImagePanel = imshow(J,[],'parent',ax);
            end
        elseif spotListValue
            boxValue = 0;
            width = 8;
            height = 8;
            for ii = 1:length(boxData.spotList{frame})
                x = boxData.spotList{frame}{ii}.x;
                y = boxData.spotList{frame}{ii}.y;
                pts = [x-4 y-4 width height];
                rectangle('Position',pts, 'LineWidth',1, 'EdgeColor','r');   
            end
        elseif cellListValue
            boxValue = 0;
            spotListValue = 0;
            hold on;
            if isempty(box)
                for ii = 1:length(cellList.meshData{frame})
                    if isfield(cellList.meshData{frame}{ii},'mesh')
                        plot([cellList.meshData{frame}{ii}.mesh(:,1) cellList.meshData{frame}{ii}.mesh(:,3)],...
                            [cellList.meshData{frame}{ii}.mesh(:,2) cellList.meshData{frame}{ii}.mesh(:,4)],'color','g','LineWidth',1);
                    end
                    if isfield(cellList.meshData{frame}{ii},'model')
                         cntx = mean(cellList.meshData{frame}{ii}.model(:,1));
                         cnty = mean(cellList.meshData{frame}{ii}.model(:,2));
                         text(double(cntx),double(cnty),num2str(cellList.cellId{frame}(ii)),'hittest','off','Clipping','on','HorizontalAlignment','center','FontSize',9,'color','y');
                    end
                     if isfield(cellList.meshData{frame}{ii},'spots') && ~isempty(cellList.meshData{frame}{ii}.spots)
                        for jj = 1:length(cellList.meshData{frame}{ii}.spots.x)
                            x = cellList.meshData{frame}{ii}.spots.x(jj)-1;
                            y = cellList.meshData{frame}{ii}.spots.y(jj);
                            text(double(x),double(y),'o','Color','red','FontSize',14); 
                        end
                    end
                end
            else
                xValue = size(get(handles.himage,'cData'),1);
                yValue = size(get(handles.himage,'cData'),2);
                cellNum = str2double(get(handles.cellNum,'string'));
                cellStructure = oufti_getCellStructure(cellNum,frame,cellList);
                if ~isfield(cellStructure,'model')
                    roiModel = [cellStructure.mesh(:,1:2);flipud(cellStructure.mesh(2:end-1,3:4))];
                    roiModel = model2box(roiModel,box,4);
                else
                    roiModel = model2box(cellStructure.model,box,4);
                end
                [r,c] = size(get(handles.himage,'cdata'));  %Get the image dimensions

                spotStructure = cellStructure.spots;
                if ~isempty(spotStructure.l) 
                     line([xValue*.021,yValue*.05],[xValue*.021,xValue*0.021],'LineStyle','-','LineWidth',4,'Color',[0 0.5 0]);
                     text(xValue*.07,xValue*0.021,'Adjusted Rsquared','Color',[0 0.5 0],'FontSize',12);
                     xBoxValue = reshape(spotStructure.x - cellStructure.box(1)+1,1,[]);
                     xBoxValue = xBoxValue + (size(get(handles.himage,'cdata'),2)-c)/2;
                     yBoxValue = reshape(spotStructure.y - cellStructure.box(2)+1,1,[]);
                     yBoxValue = yBoxValue + (size(get(handles.himage,'cdata'),1)-r)/2;
                     plot(xBoxValue,yBoxValue,'o','LineWidth',1.5)

                     for k = 1:length(spotStructure.l)
                        text(xValue*0.4,k*3,[num2str(k),':  '],'Color',[0,1,1],'FontSize',10);
                        text(double(xBoxValue(k))+1,double(yBoxValue(k)),num2str(k),'Color',[0,1,1],'FontSize',14);
                        try
                            text(xValue*0.45,k*3,num2str(spotStructure.adj_Rsquared(k)),'Color',[0 0.5 0],'FontSize',10);
                        catch
                            text(xValue*0.45,k*3,num2str(spotStructure.rmse(k)),'Color',[0 0.5 0],'FontSize',10);
                        end
% % %                         text(xValue*0.75,k*3,num2str(spotStructure.w(k)),'Color',[0 0.5 0.5],'FontSize',10); 
% % %                         text(xValue*0.85,k*3,num2str(spotStructure.h(k)),'Color',[0.7 0 0],'FontSize',10);
                     end
% % %                         set(imageHandle.ax,'pos',[0 0 1 1],'NextPlot','replace');
% % %                         set(imageHandle.fig,'pos',[17 170 pos(3)-1000+700 pos(4)-800+600]);
                end
                 roiModel(1,1) = roiModel(end,1);
                 roiModel(1,2) = roiModel(end,2);
                 plot(roiModel(:,1)+1,roiModel(:,2)+1,'color','g','LineWidth',2.5);
% % %                 cntx = mean(roiModel(:,1));
% % %                 cnty = mean(roiModel(:,2));
% % %                 text(cntx,cnty,num2str(cellNum),'hittest','off','Clipping','on','HorizontalAlignment','center','FontSize',9,'color','y');
% % %                 for ii = 1:size(cellStructure.spots,2)
% % %                     if isfield(cellStructure,'spots') && ~isempty(cellStructure.spots)
% % %                         x = cellStructure.spots(ii).x - box(1)+1;
% % %                         y = cellStructure.spots(ii).y - box(2)+1;
% % %                     else
% % %                         x = [];
% % %                         y = [];
% % %                     end
% % %                     plot(x,y,'.r','MarkerSize',19);
% % %                 end
            end
                    
            hold off;
        end
    catch
        warndlg('no spots to display')
        return;
    end 
end
%----------------------------------------------------------------------------------------------------

%-----------------------------------------------------------------
function contrast_cbk(hObject, eventdata)%#ok<INUSD>
%the contrast_cbk function changes contrast of an image.  The image is the
%current image on display at which point contrast button was clicked.
try
    if ~zoomValue
        handles.ctrfigure = imcontrast(handles.himage);
    else
        handles.ctrfigure = imcontrast(hIm);
    end
catch
    warndlg('No images loaded or could not create contrast');
end
        
end
%------------------------------------------------------------------

%----------------------------------------------------------------------------------------------------
%The zoom_cbk function perform zoom operation on a given set of image and
%data
function zoom_cbk (hObject, eventdata) %#ok<INUSD>
    try
        zoomValue = 1;
        hFig = figure('CloseRequestFcn',@closeContrastWindow);
        axTemp = axes('parent',hFig);
        hIm = imshow(get(handles.himage,'CData'),[],'parent',axTemp);
        hSP = imscrollpanel(hFig,hIm);
        displayBoxes([]);
        api = iptgetapi(hSP);
        api.setMagnification(5) % 2X = 200%

        imoverviewpanel(handles.imageViewerImagePanel,hIm);
    catch
        warndlg('No images available for zoom');
    end
    
end
%----------------------------------------------------------------------------------------------------


%-------------------------------------------------------------
function closeImageViewer(hObject, eventdata)%#ok<INUSD>
         delete(handles.imageViewer);     
end
%-------------------------------------------------------------

%------------------------------------------------------------
function closeContrastWindow(hObject, eventdata)%#ok<INUSD>
    zoomValue = 0;     
    delete(gcf);  
end
%------------------------------------------------------------

%------------------------------------------------------------
function updateHandle(hObject, eventdata)%#ok<INUSD>
   set(handles.ax1,'nextplot','replace');
   set(handles.ax2,'nextplot','replace');
   box = displayImage();
   displayBoxes(box);
end
%------------------------------------------------------------

end
