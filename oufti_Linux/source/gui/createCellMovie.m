function createCellMovie(hObject,eventData)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function createCellMovie(hObject,eventData)
%This function is for generation of a movie to observe cell cycle over time
%author:  Ahmad Paintdakhi
%@revision date:    September 23, 2014
%@copyright 2014-2015 Yale University
%==========================================================================
%********** input ********:
%hObject and eventData handles 
%********** output ********:
%
%==========================================================================
%global variables used with different function.
global cellList rawS1Data rawS2Data rawPhaseData frame prevframe  spotListValue boxValue cellListValue zoomValue hIm handles1 cellNum
scrSize = get(0,'ScreenSize');%screen size values gathered for different monitors usage.
%variable initialization
boxValue = 0;
spotListValue = 0;
cellListValue = 0;
zoomValue = 0;
hIm = [];
frame = 1;
prevframe = 1;
handles1.cellViewerImagePanel1 = [];
handles1.cellViewerImagePanel2 = [];
handles1.cellViewerImagePanel3 = [];
handles1.cellViewerImagePanel4 = [];

%main figure for the gui.
handles1.cellViewer = figure('Position',[100 scrSize(4)/7 scrSize(4)+10 scrSize(4)-240],'units','pixels',...
                            'ButtonDownFcn',@mainkeypress,'CloseRequestFcn',@closeImageViewer,'Interruptible','off','Name','cell cycle viewer',...
                            'Toolbar','none','Menubar','none','NumberTitle','off','IntegerHandle',...
                            'off','uicontextmenu',[],'DockControls','off','Resize','off');
zoom on;

%uipanel for the gui                        
handles1.imagePanel = uipanel('units','pixels','pos',[1 1 scrSize(4)+10 scrSize(4)-240],'BorderType','none');                        
%uipanel for images to be displayed
uicontrol(handles1.imagePanel,'units','pixels','Position',[75 scrSize(4)/3.3+scrSize(4)/3.3+45 250 30],...
          'Style','text','String','Cell at current frame','FontSize',16,'FontWeight','bold','HorizontalAlignment','left');
handles1.cellViewerImagePanel1 = uipanel('units','pixels','pos',[5 scrSize(4)/3.3+45 scrSize(4)/3.3 scrSize(4)/3.3],'BorderType','etchedout',...
                                         'BackgroundColor',[0.5 0.5 0.5],'BorderWidth',1,'SelectionHighlight','on','ShadowColor',[0 0 1]); 
uicontrol(handles1.imagePanel,'units','pixels','Position',[75 scrSize(4)/3.3+5 150 30],...
          'Style','text','String','Daughter 1','FontSize',16,'FontWeight','bold','HorizontalAlignment','left');
handles1.cellViewerImagePanel2 = uipanel('units','pixels','pos',[5 5 scrSize(4)/3.3 scrSize(4)/3.3],'BorderType','etchedout',...
                                         'BackgroundColor',[0.5 0.5 0.5],'BorderWidth',1,'SelectionHighlight','on','ShadowColor',[0 0 1]); 
uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)/3.3+160 scrSize(4)/3.3+scrSize(4)/3.3+45 250 30],...
          'Style','text','String','Cell at division','FontSize',16,'FontWeight','bold','HorizontalAlignment','left');
handles1.cellViewerImagePanel3 = uipanel('units','pixels','pos',[scrSize(4)/3.3+80 scrSize(4)/3.3+45 scrSize(4)/3.3 scrSize(4)/3.3],'BorderType','etchedout',...
                                         'BackgroundColor',[0.5 0.5 0.5],'BorderWidth',1,'SelectionHighlight','on','ShadowColor',[0 0 1]);
uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)/3.3+160 scrSize(4)/3.3+5 150 30],...
          'Style','text','String','Daughter 2','FontSize',16,'FontWeight','bold','HorizontalAlignment','left');
handles1.cellViewerImagePanel4 = uipanel('units','pixels','pos',[scrSize(4)/3.3+80 5 scrSize(4)/3.3 scrSize(4)/3.3],'BorderType','etchedout',...
                                         'BackgroundColor',[0.5 0.5 0.5],'BorderWidth',1,'SelectionHighlight','on','ShadowColor',[0 0 1]); 
%image slider
handles1.cellSlider = uicontrol('Style','slider','units','pixels','Position',[scrSize(4)-250+16 5 15 scrSize(4)-270],...
                         'SliderStep',[1 1],'min',1,'max',2,'value',1,'Enable','off','callback',@cellSlider);
%listner for the slider, the listner helps expedite the response time of
%the slider.
%Matlab 2014b does not support this call
%hScrollbarImSlider = handle.listener(handles1.cellSlider,'ActionEvent',@cellSlider);                        
                        

%------------------------------------------------------------------------------------------------------------------------------
%frame number visualization.
uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+45 (scrSize(4)-340-80) 50 40],...
          'Style','text','String','frame ','FontWeight','bold','HorizontalAlignment','left','FontSize',12);

handles1.currentFrame = uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+120 (scrSize(4)-340-65) 75 25],...
          'Style','text','BackgroundColor',[1 1 1],'HorizontalAlignment','left','HitTest','off','SelectionHighlight','off',...
           'FontWeight','bold','FontSize',12);
%------------------------------------------------------------------------------------------------------------------------------

%------------------------------------------------------------------------------------------------------------------------------
%frame number visualization.
uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+45 (scrSize(4)-340-120) 100 40],...
          'Style','text','String','cell ','FontWeight','bold','HorizontalAlignment','left','FontSize',12);

handles1.cellNumber = uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+120 (scrSize(4)-340-100) 75 25],...
          'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','left','HitTest','on','SelectionHighlight','on',...
          'FontWeight','bold','FontSize',12,'Callback',@resetData);
%------------------------------------------------------------------------------------------------------------------------------

%-----------------------------------------------------------------------------------------------------------
%Generate cell movie button is for displaying cell cycle
%signals.
uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+120 (scrSize(4)-340-140) 75 25],...
                'Style','pushbutton','String','Start','FontWeight','bold','HorizontalAlignment','left',...
                'FontSize',14,'BackgroundColor',[1 0 0],'ForeGroundColor',[1 1 1],'Callback',@visualizeCycle); 
%-----------------------------------------------------------------------------------------------------------

%-----------------------------------------------------------------------------------------------------------
%Generate cell movie button is for displaying cell cycle
%signals.
handles1.phaseButton = uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-340-200) 75 25],...
                'Style','togglebutton','String','Phase ','FontWeight','bold','value',1,'HorizontalAlignment','left',...
                'FontSize',14,'BackgroundColor',[0 0 0],'ForeGroundColor',[1 1 1],'Callback',@displayImages); 
%-----------------------------------------------------------------------------------------------------------  

%-----------------------------------------------------------------------------------------------------------
%Generate cell movie button is for displaying cell cycle
%signals.
handles1.signalButton = uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-340-240) 75 25],...
                'Style','togglebutton','String','Signal ','FontWeight','bold','HorizontalAlignment','left',...
                'FontSize',14,'BackgroundColor',[0 0 0],'ForeGroundColor',[1 1 1],'Callback',@displayImages); 
%----------------------------------------------------------------------------------------------------------- 

%-----------------------------------------------------------------------------------------------------------
handles1.signalValue = uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+120 (scrSize(4)-340-240) 40 25],...
          'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','left','HitTest','on','SelectionHighlight','on',...
          'FontWeight','bold','FontSize',12);
%-----------------------------------------------------------------------------------------------------------    

%-----------------------------------------------------------------------------------------------------------
%Cell Constriction information
uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-680) 200 25],...
          'Style','text','String','-----------------------------------------','HorizontalAlignment','left','FontSize',12);

uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-700) 200 25],...
          'Style','text','String','Constriction value','HorizontalAlignment','left','FontSize',12);
uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-720) 200 25],...
          'Style','text','String','**********************','HorizontalAlignment','left','FontSize',12);

uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-745) 200 25],...
          'Style','text','String','cell at current frame','HorizontalAlignment','left','FontSize',12);

handles1.cellConstrictionCell = uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+180 (scrSize(4)-740) 75 25],...
                'Style','text','String','0.00','FontWeight','bold','HorizontalAlignment','left',...
                'FontSize',14,'Callback',@displayImages); 
            
uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-765) 200 25],...
          'Style','text','String','cell at division','HorizontalAlignment','left','FontSize',12);

handles1.cellConstrictionDivision = uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+180 (scrSize(4)-760) 75 25],...
                'Style','text','String','0.00','FontWeight','bold','HorizontalAlignment','left',...
                'FontSize',14,'Callback',@displayImages); 
uicontrol(handles1.imagePanel,'units','pixels','Position',[scrSize(4)-250+30 (scrSize(4)-780) 200 20],...
          'Style','text','String','-----------------------------------------','HorizontalAlignment','left','FontSize',12);
%----------------------------------------------------------------------------------------------------------- 

%-------------------------------------------------------------
function closeImageViewer(hObject, eventdata)%#ok<INUSD>
         delete(handles1.cellViewer); 
         handles1 = [];
         return;
end
%-------------------------------------------------------------


%---------------------------------------------------------------------------------------   

%---------------------------------------------------------------------------------------
%the imslider function updates images and data with respect to scrollbar changes.   
function cellSlider(hObject, eventData)%#ok<INUSD>
   if get(handles1.phaseButton,'value') == 0 && get(handles1.signalButton,'value') == 0
       return;
   end
    prevframe = frame;
    drawnow();pause(0.005);
    tmpFrame = size(rawPhaseData,3)+1-round(get(hObject,'value'));
    frame = tmpFrame;
    set(handles1.currentFrame,'String',[num2str(frame) ' of ' num2str(size(rawPhaseData,3))]);

    visualizeCycle(hObject,eventData);
end
%---------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------
function updateSlider
   if get(handles1.phaseButton,'value') == 0 && get(handles1.signalButton,'value') == 0
       return;
   end
    s = size(rawPhaseData,3);
    frame = max(min(frame,s),1);
    if s>1
        set(handles1.cellSlider,'min',1,'max',s,'Value',s+1-frame,'SliderStep',...
           [1/(s-1) 1/(s-1)],'Enable','on');
        set(handles1.currentFrame,'String',[num2str(frame) ' of ' num2str(s)]);
    end
end
%---------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------
function resetData(hObject,eventData) %#ok<INUSD>
    if str2double(get(handles1.cellNumber,'string')) == cellNum
        return;
    else
       handles1.mother.mesh = [];
       handles1.daughter1 = [];
       handles1.daughter2 = [];
       handles1.div =[];
       return;
    end
end
%---------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------
function displayImages(hObject,eventData) %#ok<INUSD>
   if get(handles1.phaseButton,'value') == 0 && get(handles1.signalButton,'value') == 0
       return;
   end
   visualizeCycle(hObject,eventData);   
end
%---------------------------------------------------------------------------------------




%---------------------------------------------------------------------------------------
%the main function where cell cycle visualization is done
function visualizeCycle(hObject,eventData)%#ok<INUSD>
    
   if ishandle(hObject) && strcmpi(get(hObject,'String'),'Start') && get(hObject,'value') == 1
           userMessage = questdlg('Is this a timeLapse study?','Type of Study','Yes','No','No');
           if strcmpi(userMessage,'No')
                warndlg('Only timelapse study supported in this module');
                return;
           end
   end
   global ax1 ax2 ax3 ax4 axPanel1 axPanel2 axPanel3 axPanel4
   updateSlider();
   updateHandles();
   image = rawPhaseData;
   if isempty(image),warndlg('Load phase images to Oufti');return; end
   if get(handles1.phaseButton,'value') == 1
      image = rawPhaseData;      
    elseif get(handles1.signalButton,'value') == 1 
        signalValue = str2double(get(handles1.signalValue,'string'));
        if ~isempty(signalValue) && ~isnan(signalValue)
            switch signalValue
                case 1
                    signalImage = rawS1Data;
                case 2 
                    signalImage = rawS2Data;
            end
        else
            warndlg('Specifiy which signal to show');
            return;
        end
        image = signalImage;
        if isempty(image),warndlg('Load signal images to Oufti'); return; end

   end
            
   if isfield(handles1,'mother') && isfield(handles1.mother,'mesh') && frame <= length(handles1.mother.mesh)...
              && ~isempty(handles1.mother.mesh{frame}) && isfield(handles1,'daughter1') && ~isempty(handles1.daughter1)...
              && isfield(handles1,'daughter2') && ~isempty(handles1.daughter2)...
              && (isfield(handles1.mother,'signalImage') || isfield(handles1.mother,'phaseImage'))
      if get(handles1.phaseButton,'value') == 1 
          imshow(get(handles1.mother.phaseImage{frame},'cData'),[],'initialmagnification','fit','parent',ax1);
          set(handles1.cellConstrictionCell,'string',handles1.mother.DC{frame});
          set(handles1.cellConstrictionDivision,'string',handles1.mother.DC{end});
          imshow(get(handles1.mother.phaseImage{end},'cData'),[],'initialmagnification','fit','parent',ax3);
          imshow(get(handles1.daughter1.phaseImage{end},'cData'),[],'initialmagnification','fit','parent',ax2);
          imshow(get(handles1.daughter2.phaseImage{end},'cData'),[],'initialmagnification','fit','parent',ax4);
          set(ax1,'nextplot','add');
          set(ax2,'nextplot','add');
          set(ax3,'nextplot','add');
          set(ax4,'nextplot','add');
          plot(ax1,handles1.mother.mesh{frame}{1},handles1.mother.mesh{frame}{2},...
              handles1.mother.mesh{frame}{3},handles1.mother.mesh{frame}{4},'color',[1 0 0]);
          plot(ax3,handles1.mother.mesh{end}{1},handles1.mother.mesh{end}{2},...
              handles1.mother.mesh{end}{3},handles1.mother.mesh{end}{4},'color',[1 0 0]);
          plot(ax2,handles1.daughter1.mesh{end}{1},handles1.daughter1.mesh{end}{2},...
              handles1.daughter1.mesh{end}{3},handles1.daughter1.mesh{end}{4},'color',[1 0 0]);
          plot(ax4,handles1.daughter2.mesh{end}{1},handles1.daughter2.mesh{end}{2},...
              handles1.daughter2.mesh{end}{3},handles1.daughter2.mesh{end}{4},'color',[1 0 0]);
                return; 
      elseif get(handles1.signalButton,'value') == 1 && isfield(handles1.mother,'signalImage')
          imshow(get(handles1.mother.signalImage{frame},'cData'),[],'initialmagnification','fit','parent',ax1);
          imshow(get(handles1.mother.signalImage{end},'cData'),[],'initialmagnification','fit','parent',ax3);
          imshow(get(handles1.daughter1.signalImage{end},'cData'),[],'initialmagnification','fit','parent',ax2);
          imshow(get(handles1.daughter2.signalImage{end},'cData'),[],'initialmagnification','fit','parent',ax4);
          set(axPanel1,'nextplot','add');
          set(axPanel2,'nextplot','add');
          set(axPanel3,'nextplot','add');
          set(axPanel4,'nextplot','add');
          plot(axPanel1,handles1.mother.mesh{frame}{1},handles1.mother.mesh{frame}{2},...
              handles1.mother.mesh{frame}{3},handles1.mother.mesh{frame}{4},'color',[1 0 0]);
          plot(axPanel3,handles1.mother.mesh{end}{1},handles1.mother.mesh{end}{2},...
              handles1.mother.mesh{end}{3},handles1.mother.mesh{end}{4},'color',[1 0 0]);
          plot(axPanel2,handles1.daughter1.mesh{end}{1},handles1.daughter1.mesh{end}{2},...
              handles1.daughter1.mesh{end}{3},handles1.daughter1.mesh{end}{4},'color',[1 0 0]);
          plot(axPanel4,handles1.daughter2.mesh{end}{1},handles1.daughter2.mesh{end}{2},...
              handles1.daughter2.mesh{end}{3},handles1.daughter2.mesh{end}{4},'color',[1 0 0]);
                return; 
      end

   end
   cellNum = str2double(get(handles1.cellNumber,'string'));
   if ~isempty(cellNum) && ~isnan(cellNum)
       for frame = 1:length(cellList.meshData)
           if oufti_doesCellExist(cellNum,frame,cellList)
               cellStructure = oufti_getCellStructure(cellNum,frame,cellList);
               imageTemp = image(:,:,frame);
               cellImage = imcrop(imageTemp,cellStructure.box);
               if ~isfield(cellStructure,'signal0')
                   cellStructure.signal0 = getOneSignalC(double(cellStructure.mesh),double(cellStructure.box),imageTemp,1);
               end
               if ~isfield(cellStructure,'length')
                   %length
                   cellStructure.steplength = edist(cellStructure.mesh(2:end,1)+cellStructure.mesh(2:end,3),cellStructure.mesh(2:end,2)+cellStructure.mesh(2:end,4),...
                                              cellStructure.mesh(1:end-1,1)+cellStructure.mesh(1:end-1,3),cellStructure.mesh(1:end-1,2)+cellStructure.mesh(1:end-1,4))/2;
                   cellStructure.length = sum(cellStructure.steplength);
                   cellStructure.lengthvector = cumsum(cellStructure.steplength)-cellStructure.steplength/2;
               end
               [DC,Posr]=constDegree(cellStructure.signal0,cellStructure.length,cellStructure.lengthvector);
               [r,c] = size(cellImage);
               nPad = abs(c-r)/2;         %# The padding size
                 if c > r                   %# Pad rows
                  newImage = padarray(cellImage,[floor(nPad) 0],mean(mean(cellImage)),'pre');  %# Pad to'pre');
                  cellImage = padarray(newImage,[ceil(nPad) 0],mean(mean(cellImage)),'post');   %# Pad bott'post');
                elseif r > c               %# Pad columns
                  newImage = padarray(cellImage,[0 floor(nPad)],...  %# Pad left
                                                mean(mean(cellImage)),'pre');
                  cellImage = padarray(newImage,[0 ceil(nPad)],...   %# Pad right
                                      mean(mean(cellImage)),'post');
                 end
                if get(handles1.phaseButton,'value') == 1
                    handles1.mother.phaseImage{frame} = imshow(cellImage,[],'parent',ax1);
                    handles1.mother.DC{frame} = DC;
                    handles1.mother.DCPos{frame} = Posr;
                    set(handles1.cellConstrictionCell,'string',DC);

               elseif get(handles1.signalButton,'value') == 1
                    handles1.mother.signalImage{frame} = imshow(cellImage,[],'parent',ax1);
               end
               
               set(axPanel1,'nextplot','add');
               if r>c 
                   handles1.mother.mesh{frame}{1} = cellStructure.mesh(:,1)-cellStructure.box(1)+floor(nPad)+1;
                   handles1.mother.mesh{frame}{2} = cellStructure.mesh(:,2)-cellStructure.box(2)+1;
                   handles1.mother.mesh{frame}{3} = cellStructure.mesh(:,3)-cellStructure.box(1)+floor(nPad)+1;
                   handles1.mother.mesh{frame}{4} = cellStructure.mesh(:,4)-cellStructure.box(2)+1;
                   plot(axPanel1,cellStructure.mesh(:,1)-cellStructure.box(1)+floor(nPad)+1,cellStructure.mesh(:,2)-cellStructure.box(2)+1,cellStructure.mesh(:,3)-cellStructure.box(1)+floor(nPad)+1,cellStructure.mesh(:,4)-cellStructure.box(2)+1,'color',[1 0 0]);
               else
                   plot(axPanel1,cellStructure.mesh(:,1)-cellStructure.box(1)+1,cellStructure.mesh(:,2)-cellStructure.box(2)+ceil(nPad)+1,cellStructure.mesh(:,3)-cellStructure.box(1)+1,cellStructure.mesh(:,4)-cellStructure.box(2)+ceil(nPad)+1,'color',[1 0 0]);
                   handles1.mother.mesh{frame}{1} = cellStructure.mesh(:,1)-cellStructure.box(1)+1;
                   handles1.mother.mesh{frame}{2} = cellStructure.mesh(:,2)-cellStructure.box(2)+ceil(nPad)+1;
                   handles1.mother.mesh{frame}{3} = cellStructure.mesh(:,3)-cellStructure.box(1)+1;
                   handles1.mother.mesh{frame}{4} = cellStructure.mesh(:,4)-cellStructure.box(2)+ceil(nPad)+1; 
               end
           else
               continue;
           end
           if ~isempty(cellStructure.divisions) || ~isempty(cellStructure.descendants)
% % %                 ax2.XLim = ax1.XLim;ax2.YLim = ax1.YLim;
% % %                 ax4.XLim = ax1.XLim;ax4.YLim = ax1.YLim;
               daughter1 = oufti_getCellStructure(cellStructure.descendants(1),frame+1,cellList);
               daughter2 = oufti_getCellStructure(cellStructure.descendants(2),frame+1,cellList);
               imageTemp = image(:,:,frame+1);
               cellImageDaughter1 = imcrop(imageTemp,cellStructure.box);
               cellImageDaughter2 = imcrop(imageTemp,cellStructure.box);
               [r1,c1] = size(cellImageDaughter1);
               [r2,c2] = size(cellImageDaughter2);
               nPad1 = abs(c1-r1)/2;
               nPad2 = abs(c2-r2)/2;
% % %                if c1 > r1                   %# Pad rows
% % %                   newImage1 = padarray(cellImageDaughter1,[floor(nPad1) 0],mean(mean(cellImageDaughter1)),'pre');  %# Pad to'pre');
% % %                   cellImageDaughter1 = padarray(newImage1,[ceil(nPad1) 0],mean(mean(cellImageDaughter1)),'post');   %# Pad bott'post');
% % %                 elseif r1 > c1               %# Pad columns
% % %                   newImage1 = padarray(cellImageDaughter1,[0 floor(nPad1)],...  %# Pad left
% % %                                                 mean(mean(cellImageDaughter1)),'pre');
% % %                   cellImageDaughter1 = padarray(newImage1,[0 ceil(nPad1)],...   %# Pad right
% % %                                       mean(mean(cellImageDaughter1)),'post');
% % %                end
% % %                if c2 > r2                   %# Pad rows
% % %                   newImage2 = padarray(cellImageDaughter2,[floor(nPad2) 0],mean(mean(cellImageDaughter2)),'pre');  %# Pad to'pre');
% % %                   cellImageDaughter2 = padarray(newImage2,[ceil(nPad2) 0],mean(mean(cellImageDaughter2)),'post');   %# Pad bott'post');
% % %                 elseif r2 > c2               %# Pad columns
% % %                   newImage2 = padarray(cellImageDaughter2,[0 floor(nPad2)],...  %# Pad left
% % %                                                 mean(mean(cellImageDaughter2)),'pre');
% % %                   cellImageDaughter2 = padarray(newImage2,[0 ceil(nPad2)],...   %# Pad right
% % %                                       mean(mean(cellImageDaughter2)),'post');
% % %                end
               if get(handles1.phaseButton,'value') == 1
                    handles1.daughter1.phaseImage{frame} = imshow(cellImageDaughter1,[],'initialmagnification','fit','parent',ax2);
               elseif get(handles1.signalButton,'value') == 1
                   handles1.daughter1.signalImage{frame} = imshow(cellImageDaughter1,[],'initialmagnification','fit','parent',ax2);
               end
               handles1.daughter1.box{frame}  = cellStructure.box;
               set(axPanel2,'nextplot','add');
% % %                if r1>c1
try
               handles1.daughter1.mesh{frame}{1} = daughter1.mesh(:,1)-cellStructure.box(1)+1;
               handles1.daughter1.mesh{frame}{2} = daughter1.mesh(:,2)-cellStructure.box(2)+1;
               handles1.daughter1.mesh{frame}{3} = daughter1.mesh(:,3)-cellStructure.box(1)+1;
               handles1.daughter1.mesh{frame}{4} = daughter1.mesh(:,4)-cellStructure.box(2)+1;
catch
    disp('No mesh or mesh length < 2 for Daughter 1');
    return;
end
% % %                    plot(axPanel2,daughter1.mesh(:,1)-daughter1.box(1)+floor(nPad1)+1,daughter1.mesh(:,2)-daughter1.box(2)+1,daughter1.mesh(:,3)-daughter1.box(1)+floor(nPad1)+1,daughter1.mesh(:,4)-daughter1.box(2)+1,'color',[1 0 0]);
               plot(axPanel2,daughter1.mesh(:,1)-cellStructure.box(1)+1,daughter1.mesh(:,2)-cellStructure.box(2)+1,daughter1.mesh(:,3)-cellStructure.box(1)+1,daughter1.mesh(:,4)-cellStructure.box(2)+1,'color',[1 0 0]);
% % %                else
% % %                    handles1.daughter1.mesh{frame}{1} = daughter1.mesh(:,1)-daughter1.box(1)+1;
% % %                    handles1.daughter1.mesh{frame}{2} = daughter1.mesh(:,2)-daughter1.box(2)+ceil(nPad1)+1;
% % %                    handles1.daughter1.mesh{frame}{3} = daughter1.mesh(:,3)-daughter1.box(1)+1;
% % %                    handles1.daughter1.mesh{frame}{4} = daughter1.mesh(:,4)-daughter1.box(2)+ceil(nPad1)+1;
% % %                    plot(axPanel2,daughter1.mesh(:,1)-daughter1.box(1)+1,daughter1.mesh(:,2)-daughter1.box(2)+ceil(nPad1)+1,daughter1.mesh(:,3)-daughter1.box(1)+1,daughter1.mesh(:,4)-daughter1.box(2)+ceil(nPad1)+1,'color',[1 0 0]);
% % %                end 
               if get(handles1.phaseButton,'value') == 1 
                    handles1.daughter2.phaseImage{frame} = imshow(cellImageDaughter2,[],'initialMagnification','fit','parent',ax4);
               elseif get(handles1.signalButton,'value') == 1
                    handles1.daughter2.signalImage{frame} = imshow(cellImageDaughter2,[],'initialmagnification','fit','parent',ax4);
               end
              
               handles1.daughter2.box{frame}  = cellStructure.box;
               set(axPanel4,'nextplot','add');
% % %                if r1>c1 
try
               handles1.daughter2.mesh{frame}{1} = daughter2.mesh(:,1)-cellStructure.box(1)+1;
               handles1.daughter2.mesh{frame}{2} = daughter2.mesh(:,2)-cellStructure.box(2)+1;
               handles1.daughter2.mesh{frame}{3} = daughter2.mesh(:,3)-cellStructure.box(1)+1;
               handles1.daughter2.mesh{frame}{4} = daughter2.mesh(:,4)-cellStructure.box(2)+1;
catch
    disp('No mesh or mesh length < 2 for Daughter 2');
    return;
end
                plot(axPanel4,daughter2.mesh(:,1)-cellStructure.box(1)+1,daughter2.mesh(:,2)-cellStructure.box(2)+1,daughter2.mesh(:,3)-cellStructure.box(1)+1,daughter2.mesh(:,4)-cellStructure.box(2)+1,'color',[1 0 0]);
% % %                else
% % %                    handles1.daughter2.mesh{frame}{1} = daughter2.mesh(:,1)-daughter2.box(1)+1;
% % %                    handles1.daughter2.mesh{frame}{2} = daughter2.mesh(:,2)-daughter2.box(2)+ceil(nPad1)+1;
% % %                    handles1.daughter2.mesh{frame}{3} = daughter2.mesh(:,3)-daughter2.box(1)+1;
% % %                    handles1.daughter2.mesh{frame}{4} = daughter2.mesh(:,4)-daughter2.box(2)+ceil(nPad1)+1;
% % %                    plot(axPanel4,daughter2.mesh(:,1)-daughter2.box(1)+1,daughter2.mesh(:,2)-daughter2.box(2)+ceil(nPad2)+1,daughter2.mesh(:,3)-daughter2.box(1)+1,daughter2.mesh(:,4)-daughter2.box(2)+ceil(nPad2)+1,'color',[1 0 0]);
% % %                end 
% % %                
              
              if frame == 1
                  imshow(get(handles1.mother.phaseImage{frame},'cData'),[],'parent',ax3);
                  set(axPanel3,'nextplot','add');
                  plot(axPanel3,handles1.mother.mesh{frame}{1},handles1.mother.mesh{frame}{2},...
                  handles1.mother.mesh{frame}{3},handles1.mother.mesh{frame}{4},'color',[1 0 0]);
              else
                  imshow(get(handles1.mother.phaseImage{frame-1},'cData'),[],'parent',ax3);
                  set(axPanel3,'nextplot','add');
                  plot(axPanel3,handles1.mother.mesh{frame-1}{1},handles1.mother.mesh{frame-1}{2},...
                      handles1.mother.mesh{frame-1}{3},handles1.mother.mesh{frame-1}{4},'color',[1 0 0]);
              end
               updateSlider();
               break;
               
           end
           updateSlider();
       end
       set(handles1.cellConstrictionDivision,'string',DC);

   end
   
end

function updateHandles(hObject,eventData)
    global ax1 ax2 ax3 ax4 axPanel1 axPanel2 axPanel3 axPanel4
        %handles to the different position in figure window
   
   ax1 = axes('Units','pixels','Position',[0 0 scrSize(4)/3.3 scrSize(4)/3.3],'parent',handles1.cellViewerImagePanel1);
   ax2 = axes('Units','pixels','Position',[0 0 scrSize(4)/3.3 scrSize(4)/3.3],'parent',handles1.cellViewerImagePanel2);
   ax3 = axes('Units','pixels','Position',[0 0 scrSize(4)/3.3 scrSize(4)/3.3],'parent',handles1.cellViewerImagePanel3);
   ax4 = axes('Units','pixels','Position',[0 0 scrSize(4)/3.3 scrSize(4)/3.3],'parent',handles1.cellViewerImagePanel4);
% % %    ax2.XLim = ax1.XLim;ax2.YLim = ax1.YLim;
% % %    ax4.XLim = ax1.XLim;ax4.YLim = ax1.YLim;
   axPanel1 = get(handles1.cellViewerImagePanel1,'children');
   axPanel2 = get(handles1.cellViewerImagePanel2,'children');
   axPanel3 = get(handles1.cellViewerImagePanel3,'children');
   axPanel4 = get(handles1.cellViewerImagePanel4,'children');
   if size(axPanel1,1) > 1
       axPanel1 = axPanel1(1);
       axPanel2 = axPanel2(1);
       axPanel3 = axPanel3(1);
       axPanel4 = axPanel4(1);
   end
% % %    axPanel2.XLim = axPanel1.XLim;axPanel2.YLim = axPanel1.YLim;
% % %    axPanel4.XLim = axPanel1.XLim;axPanel4.YLim = axPanel1.YLim;
   
end

function d=edist(x1,y1,x2,y2)
    % complementary for "getextradata", computes the length between 2 points
    d=sqrt((x2-x1).^2+(y2-y1).^2);
end

function [DC,Posr]=constDegree(signal0,length,lengthvector)

DC=[];
Posr=[];

% get constriction profile
    prf = signal0;
    if isempty(prf),return; end
    for i=1:2
        prf = 0.5*prf + 0.25*(prf([1 1:end-1])+prf([2:end end]));
    end
    minima = [false reshape((prf(2:end-1)<prf(1:end-2))&(prf(2:end-1)<prf(3:end)),1,[]) false];
    if isempty(minima) || sum(prf)==0
        minsize=0;
        ctpos = [];
    else
        im = find(minima);
        minsize = 0;
        ctpos = 0;
        dh = [];
        dhi = [];
        hgt = [];
        for k=1:size(im,2)
            i=im(k);
            half1 = prf(1:i-1);
            half2 = prf(i+1:end);
            dh1 = max(half1)-prf(i);
            dh2 = max(half2)-prf(i);
            dh(k) = min(dh1,dh2);
            dhi(k) = mean([dh1 dh2]);
            hgt(k) = prf(i)+dhi(k);
        end
        [dhabs,i] = max(dh);
        minsizeabs = dhi(i);
        minsize = minsizeabs/hgt(i);%DC
        ctpos = im(i);
        ctposr = lengthvector(ctpos)/length;
        if isempty(minsize), minsize=0; end
    end
    DC=[DC minsize]; % degree of constriction
    if isempty(ctpos)
        ctposr = nan;
    end
    Posr = [Posr ctposr];% postion where most constricted
end

end % end of function createCellMovie