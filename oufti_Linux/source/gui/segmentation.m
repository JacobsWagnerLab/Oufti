function p = segmentation (maxRawPhaseDataValue,inputImage,sobelInput,processregion,p)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function p = segmentation (maxRawPhaseDataValue,inputImage,sobelInput,processregion,p)
%oufti.v0.2.9
%@author:  Ahmad J Paintdakhi
%@date:    March 05 2013
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%p:  updated parameter structure
%**********Input********:
%maxRawPhaseDataValue:    value used to invert an input image.
%inputImage:              input image to be filtered
%sobelInput:              sobel matrix used for filtereing
%processregion:           a box comprising only a part of an image to be
%                         filtered.
%p:                       parameter structure
%=========================================================================
% PURPOSE:
% This function portrays an interactive gui that is used for segmenation
% purposes.  The number of algorithms (edgemode) for segmenatation
% available are 4. 1-log  2-valley 3-logvalley  4-crossvalley
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

global handles;
warning('off','MATLAB:hg:uicontrol:ParameterValuesMustBeValid');
segmentedImage = [];
if ~isempty(inputImage), imageSize = size(inputImage); else disp('no images loaded'); return; end
scrSize = get(0,'ScreenSize');
handles.segmentation = figure('Position',[100 scrSize(4)/7 scrSize(4)+10 scrSize(4)-340],'units','pixels',...
                            'ButtonDownFcn',@mainkeypress,'CloseRequestFcn',@closeSegmentation,'Interruptible','off','Name','Segmentation',...
                            'Toolbar','none','Menubar','none','NumberTitle','off','IntegerHandle',...
                            'off','uicontextmenu',[],'DockControls','off','Resize','off');
zoom on   

handles.segmentationPanel = uipanel('units','pixels','pos',[1 1 scrSize(4)+10 scrSize(4)-340],'BorderType','none');                        
handles.segmentationImagePanel = uipanel('units','pixels','pos',[5 5 scrSize(4)-250 scrSize(4)-345],'BorderType','etchedout',...
                                         'BackgroundColor',[1 1 1],'BorderWidth',1,'SelectionHighlight','on','ShadowColor',[0 0 1]);   
%********************************************************************************************************
%----- edgeMode Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-380 75 16],...
          'Style','text','String','EdgeMode','HorizontalAlignment','left');
handles.SegEdgeMode = uibuttongroup(handles.segmentationPanel,'units','pixels','Visible','off',...
                      'Position',[scrSize(4)-170 scrSize(4)-380 190 20]);
u1 = uicontrol('units','pixels','Position',[1 1 50 16],...
                         'Style','Radio','string','LOG','parent',handles.SegEdgeMode,'HandleVisibility','on','Tooltipstring',...
                         'Laplacian of Gaussian (LOG) method:  The algorithm applies a Gaussian filter (smoothes an image) followed by a Laplacian filter');
u2 = uicontrol('units','pixels','Position',[55 1 60 16],...
                         'Style','Radio','string','Valley','parent',handles.SegEdgeMode,'HandleVisibility','on');
% % % u3 = uicontrol('units','pixels','Position',[60 1 25 16],...
% % %                          'Style','Radio','string','3','parent',handles.SegEdgeMode,'HandleVisibility','on');
u4 = uicontrol('units','pixels','Position',[110 1 70 16],...
                         'Style','Radio','string','Cross','parent',handles.SegEdgeMode,'HandleVisibility','on',...
                         'Tooltipstring',['Combines LOG and valley detection algorithms.  Valley' ...
                         'detection algorithm first applies a Gaussian smoothing filter followed by finding a local minima with the second derivative above a threshold']);
% Initialize radionbuttons
set(handles.SegEdgeMode,'BorderType','none');
set(handles.SegEdgeMode,'SelectionChangeFcn',@edgeMode_cbk); % callback function upon selection
set(handles.SegEdgeMode,'Visible','on'); % make visible

%********************************************************************************************************

%********************************************************************************************************
%----- erodeNum Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-405 75 16],...
          'Style','text','String','Dilate','HorizontalAlignment','left',...
          'TooltipString',['The number of pixels to dilate an image by.  Increase '...
                       'if cells are detected smaller or poles are missing']);
handles.SegErodeNum = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-170 scrSize(4)-405 35 16],'Style','edit','String','1',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left','Callback',@erodeNum_cbk);
if isfield(p,'erodenum') || isfield(p,'erodeNum')
    set(handles.SegErodeNum,'string',p.erodeNum);
end
%********************************************************************************************************
                                     
%********************************************************************************************************
%----- openNum Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-430 75 16],...
          'Style','text','String','openNum','HorizontalAlignment','left',...
          'TooltipString',['Erosion followed by dilation.  This parameter helps drop noise'...
                      ' especially when small objects are detected by segmentation']);
handles.SegOpenNum = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-170 scrSize(4)-430 35 16],'Style','edit','String','1',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left','Callback',@openNum_cbk); 
if isfield(p,'openNum') || isfield(p,'opennum')
    if isfield(p,'openNum')
        set(handles.SegOpenNum,'string',p.openNum);
    else
        set(handles.SegOpenNum,'string',p.opennum);
    end
end
%********************************************************************************************************  

%********************************************************************************************************
%----- invertImage Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-455 75 16],...
          'Style','text','String','InvertImage','HorizontalAlignment','left',...
          'TooltipString',['indicates that light cells are used on dark background and the image needs to be inverted'...
          '(for example, if you are using diffuse GFP instead of phase contrast microscopy)']);
handles.SegInvertImage = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-170 scrSize(4)-455 35 16],'Style','edit','String','0',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left','Callback',@invertImage_cbk);
if isfield(p,'invertimage')
    set(handles.SegInvertImage,'string',num2str(p.invertimage));
end
%******************************************************************************************************** 

%********************************************************************************************************
%----- min max label -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-150 scrSize(4)-480  75 16],...
          'Style','text','String','Min','HorizontalAlignment','left','ForegroundColor','r');
      
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-95 scrSize(4)-480  75 16],...
          'Style','text','String','Max','HorizontalAlignment','left','ForegroundColor','r');
%********************************************************************************************************



%********************************************************************************************************
%----- threshFactorM Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-505  100 16],...
          'Style','text','String','ThreshFactorM','HorizontalAlignment','left',...
          'tooltipstring',['image intensity (considering white is 0 and black is 1) threshold factor, ' ...
                           'used in morphological operations. The value of 1 implies using the automatically ' ...
                           'detected threshold. The range of the value is from 0 to 1.']);
handles.SegThreshFactorM = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-150 scrSize(4)-505 75 16],'Style','slider', 'Min',0.0015,...
                      'Max',1.5,'Value',0.985,'SliderStep',[0.005 0.01],'BackgroundColor',[1 1 1],...
                      'HorizontalAlignment','left','callback',@threshFactorM_cbk); 
%this call not supported in Matlab2014b
%hListenerSegThreshFactorM = handle.listener(handles.SegThreshFactorM,'ActionEvent',@threshFactorM_cbk);
handles.SegThreshFactorMValueBox = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-60 scrSize(4)-505 50 16],'Style','edit',...
                      'String','0.985','BackgroundColor',[1 1 1],'HorizontalAlignment','left',...
                      'Callback',@threshFactorM_cbk);

if isfield(p,'thresFactorM')
    set(handles.SegThreshFactorM,'value',p.thresFactorM);
    set(handles.SegThreshFactorMValueBox,'string',p.thresFactorM);
end
%********************************************************************************************************

%********************************************************************************************************
%----- threshMinLevel Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-530 100 16],...
          'Style','text','String','ThreshMinLevel','HorizontalAlignment','left',...
          'tooltipstring',['an alternative to thresFactorM; this factor tells the program '...
                           'the fraction of the brightest pixels to exclude from threshold calculation. To '...
                           'eliminate the effect of bright dust particles which may appear in the field of '...
                           'view. Default: 0, typical values: 0.05-0.1)']);
handles.SegThreshMinLevel = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-150 scrSize(4)-530 75 16],'Style','slider', 'Min',0,...
                      'Max',1,'Value',0.015,'SliderStep',[0.005 0.02],'BackgroundColor',[1 1 1],...
                      'HorizontalAlignment','left','callback',@threshMinLevel_cbk); 
%this call not supported in Matlab2014b
%hListenerSegThreshMinLevel = handle.listener(handles.SegThreshMinLevel,'ActionEvent',@threshMinLevel_cbk);

handles.SegThreshMinLevelValueBox = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-60 scrSize(4)-530 50 16],'Style','edit',...
                      'String','0.015','BackgroundColor',[1 1 1],'HorizontalAlignment','left',...
                      'callback',@threshMinLevel_cbk);
if isfield(p,'threshminlevel')
    set(handles.SegThreshMinLevel,'value',p.threshminlevel);
    set(handles.SegThreshMinLevelValueBox,'string',p.threshminlevel);
end
%********************************************************************************************************

%********************************************************************************************************
%----- edgeSigmaL Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-555 100 16],...
          'Style','text','String','EdgeSigmaL ','HorizontalAlignment','left',...
          'tooltipstring','sigma parameter of Gaussian smoothing for the LoG edge detection algorithm.');
handles.SegEdgeSigmaL = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-150 scrSize(4)-555 75 16],'Style','slider', 'Min',0.0002,...
                      'Max',7,'Value',1,'SliderStep',[0.01 0.1],'BackgroundColor',[1 1 1],...
                      'HorizontalAlignment','left','Enable','off','callback',@edgeSigmaL_cbk);
%this call not supported in Matlab2014b
                  %hListenerSegEdgeSigmaL = handle.listener(handles.SegEdgeSigmaL,'ActionEvent',@edgeSigmaL_cbk);

handles.SegEdgeSigmaLValueBox = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-60 scrSize(4)-555 50 16],'Style','edit',...
                      'String',' ','BackgroundColor',[1 1 1],'HorizontalAlignment','left',...
                      'callback',@edgeSigmaL_cbk);
if isfield(p,'edgeSigmaL')
    set(handles.SegEdgeSigmaL,'value',p.edgeSigmaL);
    set(handles.SegEdgeSigmaLValueBox,'string',p.edgeSigmaL);
end
%********************************************************************************************************

%********************************************************************************************************
%----- edgeSigmaV Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-580 100 16],...
          'Style','text','String','EdgeSigmaV ','HorizontalAlignment','left',...
          'tooltipstring','sigma parameter of Gaussian smoothing for the Valley detection algorithm');
handles.SegEdgeSigmaV = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-150 scrSize(4)-580 75 16],'Style','slider', 'Min',0.00001,...
                      'Max',7,'Value',0.5,'SliderStep',[0.01 0.1],'BackgroundColor',[1 1 1],...
                      'HorizontalAlignment','left','Enable','off','callback',@edgeSigmaV_cbk);
%this call not supported in Matlab2014b
                  %hListenerSegEdgeSigmaV = handle.listener(handles.SegEdgeSigmaV,'ActionEvent',@edgeSigmaV_cbk);
handles.SegEdgeSigmaVValueBox = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-60 scrSize(4)-580 50 16],'Style','edit',...
                      'String',' ','BackgroundColor',[1 1 1],'HorizontalAlignment','left',...
                      'callback',@edgeSigmaV_cbk);
if isfield(p,'edgeSigmaV')
    set(handles.SegEdgeSigmaV,'value',p.edgeSigmaV);
    set(handles.SegEdgeSigmaVValueBox,'string',p.edgeSigmaV);
end
%********************************************************************************************************

%********************************************************************************************************
%----- valleyThresh1 Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-605 100 16],...
          'Style','text','String','ValleyThresh1 ','HorizontalAlignment','left',...
          'tooltipstring',' weak threshold for the Valley detection algorithm. Must be smaller than valleythresh2');
handles.SegValleyThresh1 = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-150 scrSize(4)-605 75 16],'Style','slider', 'Min',0,...
                      'Max',1,'Value',0.0001,'SliderStep',[0.001 0.002],'BackgroundColor',[1 1 1],...
                      'HorizontalAlignment','left','Enable','off','callback',@valleyThresh1_cbk);
%this call not supported in Matlab2014b
                  %hListenerSegValleyThresh1 = handle.listener(handles.SegValleyThresh1,'ActionEvent',@valleyThresh1_cbk);

handles.SegValleyThresh1ValueBox = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-60 scrSize(4)-605 50 16],'Style','edit',...
                      'String',' ','BackgroundColor',[1 1 1],'HorizontalAlignment','left',...
                      'callback',@valleyThresh1_cbk);
if isfield(p,'valleythresh1')
    set(handles.SegValleyThresh1,'value',p.valleythresh1);
    set(handles.SegValleyThresh1ValueBox,'string',p.valleythresh1);

end
%********************************************************************************************************

%********************************************************************************************************
%----- valleyThresh2 Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-630 100 16],...
          'Style','text','String','ValleyThresh2 ','HorizontalAlignment','left',...
          'tooltipstring',' strong threshold for the Valley detection algorithm');
handles.SegValleyThresh2 = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-150 scrSize(4)-630 75 16],'Style','slider', 'Min',0.000001,...
                      'Max',1,'Value',0.01,'SliderStep',[0.01 0.02],'BackgroundColor',[1 1 1],...
                      'HorizontalAlignment','left','Enable','off','callback',@valleyThresh2_cbk);
%this call not supported in Matlab2014b
                  %hListenerSegValleyThresh2 = handle.listener(handles.SegValleyThresh2,'ActionEvent',@valleyThresh2_cbk);
handles.SegValleyThresh2ValueBox = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-60 scrSize(4)-630 50 16],'Style','edit',...
                      'String',' ','BackgroundColor',[1 1 1],'HorizontalAlignment','left',...
                      'callback',@valleyThresh2_cbk);
if isfield(p,'valleythresh2')
    set(handles.SegValleyThresh2,'value',p.valleythresh2);
    set(handles.SegValleyThresh2ValueBox,'string',p.valleythresh2);

end
%********************************************************************************************************

%********************************************************************************************************
%----- logThresh Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-655 100 16],...
          'Style','text','String','LogThresh ','HorizontalAlignment','left',...
          'tooltipstring','threshold for the LoG edge detection algorithm. Typical values: ~0.1-0.4 (in the range -1 to 1)');
handles.SegLogThresh = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-150 scrSize(4)-655 75 16],'Style','slider', 'Min',-1.0,...
                      'Max',1,'Value',0,'SliderStep',[0.01 0.02],'BackgroundColor',[1 1 1],...
                      'HorizontalAlignment','left','Enable','off','callback',@logThresh_cbk);
%this call not supported in Matlab2014b
                  %hListenerSegLogThresh = handle.listener(handles.SegLogThresh,'ActionEvent',@logThresh_cbk);

handles.SegLogThreshValueBox = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-60 scrSize(4)-655 50 16],'Style','edit',...
                      'String',' ','BackgroundColor',[1 1 1],'HorizontalAlignment','left',...
                      'callback',@logThresh_cbk);
if isfield(p,'logthresh')
    set(handles.SegLogThresh,'value',p.logthresh);
    set(handles.SegLogThreshValueBox,'string',p.logthresh);
end
%********************************************************************************************************

%********************************************************************************************************
%----- crossThresh Parameter -------------
uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-240 scrSize(4)-680 100 16],...
          'Style','text','String','CrossThresh ','HorizontalAlignment','left',...
          'tooltipstring','cross-detection threshold between the LoG and valley algorithms. Default: 0. Typical values: ~0.1-0.4 (in the range 0 to 1)');
handles.SegCrossThresh = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-150 scrSize(4)-680 75 16],'Style','slider', 'Min',0.1,...
                      'Max',1,'Value',0.25,'SliderStep',[0.01 0.02],'BackgroundColor',[1 1 1],...
                      'HorizontalAlignment','left','Enable','off','callback',@crossThresh_cbk);
%this call not supported in Matlab2014b
                  %hListenerSegCrossThresh = handle.listener(handles.SegCrossThresh,'ActionEvent',@crossThresh_cbk);

handles.SegCrossThreshValueBox = uicontrol(handles.segmentationPanel,'units','pixels',...
                      'Position',[scrSize(4)-60 scrSize(4)-680 50 16],'Style','edit',...
                      'String',' ','BackgroundColor',[1 1 1],'HorizontalAlignment','left',...
                      'callback',@crossThresh_cbk);
if isfield(p,'crossthresh')
    set(handles.SegCrossThresh,'value',p.crossthresh);
    set(handles.SegCrossThreshValueBox,'string',p.crossthresh);

end
%********************************************************************************************************

if isfield(p,'edgemode')
    switch p.edgemode
        case 1
            set(u1,'value',1);
            set(handles.SegEdgeSigmaL,'Enable','on');    
            set(handles.SegValleyThresh1,'Enable','off'); 
            set(handles.SegValleyThresh2,'Enable','off'); 
            set(handles.SegLogThresh,'Enable','on'); 
        case 2
            set(u2,'value',1);
            set(u1,'value',0);
            set(handles.SegValleyThresh2,'Enable','on');  
            set(handles.SegEdgeSigmaV,'Enable','on');     
            set(handles.SegValleyThresh1,'Enable','on');  
        case 3
            set(u3,'value',1);
            set(u1,'value',0);
            set(handles.SegCrossThresh,'Enable','on');   
            set(handles.SegValleyThresh1,'Enable','on');
            set(handles.SegValleyThresh2,'Enable','on');
            set(handles.SegEdgeSigmaV,'Enable','on');   
            set(handles.SegEdgeSigmaL,'Enable','on');   
        case 4
            set(u4,'value',1);
            set(u1,'value',0);
            set(handles.SegCrossThresh,'Enable','on');   
            set(handles.SegValleyThresh1,'Enable','on'); 
            set(handles.SegValleyThresh2,'Enable','on');
            set(handles.SegEdgeSigmaV,'Enable','on');    
            set(handles.SegEdgeSigmaL,'Enable','on');   
    end
else
    set(handles.SegEdgeMode,'SelectedObject',[]); % no selection

end

uicontrol(handles.segmentationPanel,'units','pixels','Position',[scrSize(4)-175 scrSize(4)-765 100 40],...
          'Style','pushbutton','String','Ok ','HorizontalAlignment','left','Callback','uiresume(gcbf)');
%********************************************************************************************************


function edgeMode_cbk(~, eventdata) 
    set(handles.SegThreshFactorMValueBox,'string',num2str(get(handles.SegThreshFactorM,'value'),4));
    set(handles.SegThreshMinLevelValueBox,'string',num2str(get(handles.SegThreshMinLevel,'value'),4));
    
    switch get(eventdata.NewValue,'string')
        case 'LOG'
            segmentedImage = getSegmentation(inputImage,sobelInput);
            if ~isempty(processregion)
                crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
                segmentedImage = segmentedImage*0;
                segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
                segmentedImage = bwlabel(segmentedImage>0,4);
            end
            handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
            set(handles.SegValleyThresh2,'Enable','off');set(handles.SegValleyThresh2ValueBox,'string',' ');
            set(handles.SegEdgeSigmaV,'Enable','off');   set(handles.SegEdgeSigmaVValueBox,'string',' ');
            set(handles.SegCrossThresh,'Enable','off');  set(handles.SegCrossThreshValueBox,'string',' ');
            set(handles.SegEdgeSigmaL,'Enable','on');    set(handles.SegEdgeSigmaLValueBox,'string',num2str(get(handles.SegEdgeSigmaL,'value'),4));
            set(handles.SegValleyThresh1,'Enable','off'); set(handles.SegValleyThresh1ValueBox,'string',' ');
            set(handles.SegLogThresh,'Enable','on');     set(handles.SegLogThreshValueBox,'string',num2str(get(handles.SegLogThresh,'value'),4));
            
        case 'Valley'
            segmentedImage = getSegmentation(inputImage,sobelInput);
            if ~isempty(processregion)
                crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
                segmentedImage = segmentedImage*0;
                segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
                segmentedImage = bwlabel(segmentedImage>0,4);
            end
            handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
            set(handles.SegEdgeSigmaL,'Enable','off');    set(handles.SegEdgeSigmaLValueBox,'string',' ');
            set(handles.SegCrossThresh,'Enable','off');   set(handles.SegCrossThreshValueBox,'string',' ');
            set(handles.SegLogThresh,'Enable','off');     set(handles.SegLogThreshValueBox,'string',' ');
            set(handles.SegValleyThresh2,'Enable','on');  set(handles.SegValleyThresh2ValueBox,'string',num2str(get(handles.SegValleyThresh2,'value'),4));
            set(handles.SegEdgeSigmaV,'Enable','on');     set(handles.SegEdgeSigmaVValueBox,'string',num2str(get(handles.SegEdgeSigmaV,'value'),4));
            set(handles.SegValleyThresh1,'Enable','on');  set(handles.SegValleyThresh1ValueBox,'string',num2str(get(handles.SegValleyThresh1,'value'),4));
           
     
        case 3
            segmentedImage = getSegmentation(inputImage,sobelInput);
            if ~isempty(processregion)
                crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
                segmentedImage = segmentedImage*0;
                segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
                segmentedImage = bwlabel(segmentedImage>0,4);
            end
            handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
            set(handles.SegValleyThresh2,'Enable','off');set(handles.SegValleyThresh2ValueBox,'string',' ');
            set(handles.SegEdgeSigmaV,'Enable','off');   set(handles.SegEdgeSigmaVValueBox,'string',' ');
            set(handles.SegLogThresh,'Enable','off');    set(handles.SegLogThreshValueBox,'string',' ');
            set(handles.SegCrossThresh,'Enable','on');   set(handles.SegCrossThreshValueBox,'string',num2str(get(handles.SegCrossThresh,'value'),4));
            set(handles.SegValleyThresh1,'Enable','on'); set(handles.SegValleyThresh1ValueBox,'string',num2str(get(handles.SegValleyThresh1,'value'),4));
            set(handles.SegValleyThresh2,'Enable','on'); set(handles.SegValleyThresh2ValueBox,'string',num2str(get(handles.SegValleyThresh2,'value'),4));
            set(handles.SegEdgeSigmaV,'Enable','on');    set(handles.SegEdgeSigmaVValueBox,'string',num2str(get(handles.SegEdgeSigmaV,'value'),4));
            set(handles.SegEdgeSigmaL,'Enable','on');    set(handles.SegEdgeSigmaLValueBox,'string',num2str(get(handles.SegEdgeSigmaL,'value'),4));
            
        case 'Cross'
            segmentedImage = getSegmentation(inputImage,sobelInput);
            if ~isempty(processregion)
                crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
                segmentedImage = segmentedImage*0;
                segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
                segmentedImage = bwlabel(segmentedImage>0,4);
            end
            handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
            set(handles.SegValleyThresh2,'Enable','on');set(handles.SegValleyThresh2ValueBox,'string',' ');
            set(handles.SegEdgeSigmaV,'Enable','on');   set(handles.SegEdgeSigmaVValueBox,'string',' ');
            set(handles.SegLogThresh,'Enable','off');    set(handles.SegLogThreshValueBox,'string',' ');
            set(handles.SegCrossThresh,'Enable','on');   set(handles.SegCrossThreshValueBox,'string',num2str(get(handles.SegCrossThresh,'value'),4));
            set(handles.SegValleyThresh1,'Enable','on'); set(handles.SegValleyThresh1ValueBox,'string',num2str(get(handles.SegValleyThresh1,'value'),4));
            set(handles.SegValleyThresh2,'Enable','on'); set(handles.SegValleyThresh2ValueBox,'string',num2str(get(handles.SegValleyThresh2,'value'),4));
            set(handles.SegEdgeSigmaV,'Enable','on');    set(handles.SegEdgeSigmaVValueBox,'string',num2str(get(handles.SegEdgeSigmaV,'value'),4));
            set(handles.SegEdgeSigmaL,'Enable','on');    set(handles.SegEdgeSigmaLValueBox,'string',num2str(get(handles.SegEdgeSigmaL,'value'),4));
      
        otherwise
            set(handles.SegValleyThresh2,'Enable','off');set(handles.SegValleyThresh2ValueBox,'string',' ');
            set(handles.SegEdgeSigmaV,'Enable','off');   set(handles.SegEdgeSigmaVValueBox,'string',' ');
            set(handles.SegCrossThresh,'Enable','off');  set(handles.SegCrossThreshValueBox,'string',' ');
            set(handles.SegEdgeSigmaL,'Enable','off');    set(handles.SegEdgeSigmaLValueBox,'string',' ');
            set(handles.SegValleyThresh1,'Enable','off'); set(handles.SegValleyThresh1ValueBox,'string',' ');
            set(handles.SegLogThresh,'Enable','off');    set(handles.SegLogThreshValueBox,'string',' ');
          
            
    end
    
end

function erodeNum_cbk(hObject, eventdata)%#ok<INUSD>
    
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
end

function openNum_cbk(hObject, eventdata)%#ok<INUSD>
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
end

function invertImage_cbk(hObject, eventdata)%#ok<INUSD>
    if str2double(handles.SegInvertImage.String) == 1
        inputImage = maxRawPhaseDataValue - inputImage;
    end
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
end

function threshFactorM_cbk(hObject, eventdata)%#ok<INUSD>
    if hObject == handles.SegThreshFactorM
       tempValue = get(handles.SegThreshFactorM,'value');
       set(handles.SegThreshFactorMValueBox,'string',num2str(tempValue,4));
    else
        tempValue = get(handles.SegThreshFactorMValueBox,'string');
        tempValue = min(max(str2double(tempValue),0.0015),1.5);
        set(handles.SegThreshFactorM,'value',tempValue);
        set(handles.SegThreshFactorMValueBox,'string',num2str(tempValue,4));
    end
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
end

function threshMinLevel_cbk(hObject, eventdata)%#ok<INUSD>
   if hObject == handles.SegThreshMinLevel
        tempValue = get(handles.SegThreshMinLevel,'value');
       set(handles.SegThreshMinLevelValueBox,'string',num2str(tempValue,4));
    else
        tempValue = get(handles.SegThreshMinLevelValueBox,'string');
        tempValue = min(max(str2double(tempValue),1e-14),1);
        set(handles.SegThreshMinLevel,'value',tempValue);
        set(handles.SegThreshMinLevelValueBox,'string',num2str(tempValue,4));
    end
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
    
end

function edgeSigmaL_cbk(hObject, eventdata)%#ok<INUSD>
    if hObject == handles.SegEdgeSigmaL
        tempValue = get(handles.SegEdgeSigmaL,'value');
        set(handles.SegEdgeSigmaLValueBox,'string',num2str(tempValue,4));
    else
        tempValue = get(handles.SegEdgeSigmaLValueBox,'string');
        tempValue = min(max(str2double(tempValue),1e-14),7);
        set(handles.SegEdgeSigmaL,'value',tempValue);
        set(handles.SegEdgeSigmaLValueBox,'string',num2str(tempValue,4));
    end
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
end

function edgeSigmaV_cbk(hObject, eventdata)%#ok<INUSD>
    if hObject == handles.SegEdgeSigmaV
        tempValue = get(handles.SegEdgeSigmaV,'value');
        set(handles.SegEdgeSigmaVValueBox,'string',num2str(tempValue,4));
    else
        tempValue = get(handles.SegEdgeSigmaVValueBox,'string');
        tempValue = min(max(str2double(tempValue),1e-14),7);
        set(handles.SegEdgeSigmaV,'value',tempValue);
        set(handles.SegEdgeSigmaVValueBox,'string',num2str(tempValue,4));
    end
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
   
    
end

function valleyThresh1_cbk(hObject, eventdata)%#ok<INUSD>
    if hObject == handles.SegValleyThresh1
        tempValue = get(handles.SegValleyThresh1,'value');
        set(handles.SegValleyThresh1ValueBox,'string',num2str(tempValue,4));
    else
        tempValue = get(handles.SegValleyThresh1ValueBox,'string');
        tempValue = min(max(str2double(tempValue),0),1);
        set(handles.SegValleyThresh1,'value',tempValue);
        set(handles.SegValleyThresh1ValueBox,'string',num2str(tempValue,4));
    end
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
     
    
end

function valleyThresh2_cbk(hObject, eventdata)%#ok<INUSD>
    if hObject == handles.SegValleyThresh2
        tempValue = get(handles.SegValleyThresh2,'value');
        set(handles.SegValleyThresh2ValueBox,'string',num2str(tempValue,4));
    else
        tempValue = get(handles.SegValleyThresh2ValueBox,'string');
        tempValue = min(max(str2double(tempValue),0.000001),1);
        set(handles.SegValleyThresh2,'value',tempValue);
        set(handles.SegValleyThresh2ValueBox,'string',num2str(tempValue,4));
    end
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
     
    
end


function logThresh_cbk(hObject, eventdata)%#ok<INUSD>
    if hObject == handles.SegLogThresh
        tempValue = get(handles.SegLogThresh,'value');
        set(handles.SegLogThreshValueBox,'string',num2str(tempValue,4));
    else
        tempValue = get(handles.SegLogThreshValueBox,'string');
        tempValue = min(max(str2double(tempValue),-1),1);
        set(handles.SegLogThresh,'value',tempValue);
        set(handles.SegLogThreshValueBox,'string',num2str(tempValue,4));
    end
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
     
    
end

function crossThresh_cbk(hObject, eventdata)%#ok<INUSD>
    if hObject == handles.SegCrossThresh
        tempValue = get(handles.SegCrossThresh,'value');
        set(handles.SegCrossThreshValueBox,'string',num2str(tempValue,4));
    else
        tempValue = get(handles.SegCrossThreshValueBox,'string');
        tempValue = min(max(str2double(tempValue),0.1),1);
        set(handles.SegCrossThresh,'value',tempValue);
        set(handles.SegCrossThreshValueBox,'string',num2str(tempValue,4));
    end
    segmentedImage = getSegmentation(inputImage,sobelInput);
    if ~isempty(processregion)
        crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
        segmentedImage = segmentedImage*0;
        segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
        segmentedImage = bwlabel(segmentedImage>0,4);
    end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
    
    
end


%*****************************************************************************************
% ----- main processing function ---------------------
try
iniMagnification = min(100,floor(75*min(scrSize(4)/imageSize(1),scrSize(3)/imageSize(2))));
ax = axes('Units','pixels','Position',[1 1 scrSize(4)-250 scrSize(4)-240],'parent',handles.segmentationImagePanel);
drawnow(); pause(0.005);
warning('off','images:initSize:adjustingMag') % ('off','backtrace');
if get(u1,'value') == 1 || get(u2,'value') == 1 || get(u4,'value') == 1
    if str2num(get(handles.SegInvertImage,'string')) == 1, inputImage = maxRawPhaseDataValue - inputImage;end
    segmentedImage = getSegmentation(inputImage,sobelInput);
        if ~isempty(processregion)
            crp = segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
            segmentedImage = segmentedImage*0;
            segmentedImage(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
         segmentedImage = bwlabel(segmentedImage>0,4);
        end
    handles.segmentationImagePanel = imshow(segmentedImage>0,[],'parent',ax);
    drawnow(); pause(0.005);
    uiwait(handles.segmentation);
else
    handles.segmentationImagePanel = imshow(inputImage,[],'parent',ax,'ini',iniMagnification);                                
    drawnow(); pause(0.005);
    uiwait(handles.segmentation);
end

switch get(get(handles.SegEdgeMode,'SelectedObject'),'string')
        case 'LOG'
            p.edgemode       = 1;
            p.erodeNum       = str2double(get(handles.SegErodeNum,'string'));
            p.openNum        = str2double(get(handles.SegOpenNum,'string'));
            p.invertimage     = str2double(get(handles.SegInvertImage,'string'));
            p.thresFactorM   = get(handles.SegThreshFactorM,'value');
            p.thresFactorF   = p.thresFactorM;
            p.threshminlevel = get(handles.SegThreshMinLevel,'value');
            p.edgeSigmaL     = get(handles.SegEdgeSigmaL,'value');
            p.valleythresh1  = get(handles.SegValleyThresh1,'value');
            p.logthresh      = get(handles.SegLogThresh,'value');
            %-----------------------------------------------------------------------------
            %add parameters to the global params handle
            paramString = get(handles.params,'string');
            isTrueSegParam = find(strcmp('%parameters added after Segmentation Module',paramString)==1);
            if ~isempty(isTrueSegParam),paramString(isTrueSegParam:end) = [];end
            lengthParamString = find(cellfun(@isempty,paramString)==0,1,'last');
            paramString(lengthParamString+3) = {'%parameters added after Segmentation Module'};
            paramString(lengthParamString+4) = {'edgemode = 1'};
            paramString(lengthParamString+5) = {['erodeNum = ' num2str(p.erodeNum)]};
            paramString(lengthParamString+6) = {['openNum = ' num2str(p.openNum)]};
            paramString(lengthParamString+7) = {['invertimage = ' num2str(p.invertimage)]};
            paramString(lengthParamString+8) = {['thresFactorM = ' num2str(p.thresFactorM)]};
            paramString(lengthParamString+9) = {['thresFactorF = ' num2str(p.thresFactorF)]};
            paramString(lengthParamString+10) = {['threshminlevel = ' num2str(p.threshminlevel)]};
            paramString(lengthParamString+11) = {['edgeSigmaL = ' num2str(p.edgeSigmaL)]};
            paramString(lengthParamString+12) = {['valleythresh1 = ' num2str(p.valleythresh1)]};
            paramString(lengthParamString+13) = {['logthresh = ' num2str(p.logthresh)]};
            set(handles.params,'string',paramString);
            %-----------------------------------------------------------------------------
        case 'Valley'
            p.edgemode       = 2;
            p.erodeNum       = str2double(get(handles.SegErodeNum,'string'));
            p.openNum        = str2double(get(handles.SegOpenNum,'string'));
            p.invertimage     = str2double(get(handles.SegInvertImage,'string'));
            p.thresFactorM   = get(handles.SegThreshFactorM,'value');
            p.thresFactorF   = p.thresFactorM;
            p.threshminlevel = get(handles.SegThreshMinLevel,'value');
            p.valleythresh2  = get(handles.SegValleyThresh2,'value');
            p.edgeSigmaV     = get(handles.SegEdgeSigmaV,'value');
            p.valleythresh1  = get(handles.SegValleyThresh1,'value'); 
            %-----------------------------------------------------------------------------
            %add parameters to the global params handle
            paramString = get(handles.params,'string');
            isTrueSegParam = find(strcmp('%parameters added after Segmentation Module',paramString)==1);
            if ~isempty(isTrueSegParam),paramString(isTrueSegParam:end) = [];end
            lengthParamString = find(cellfun(@isempty,paramString)==0,1,'last');
            paramString(lengthParamString+3) = {'%parameters added after Segmentation Module'};
            paramString(lengthParamString+4) = {'edgemode = 2'};
            paramString(lengthParamString+5) = {['erodeNum = ' num2str(p.erodeNum)]};
            paramString(lengthParamString+6) = {['openNum = ' num2str(p.openNum)]};
            paramString(lengthParamString+7) = {['invertimage = ' num2str(p.invertimage)]};
            paramString(lengthParamString+8) = {['thresFactorM = ' num2str(p.thresFactorM)]};
            paramString(lengthParamString+9) = {['thresFactorF = ' num2str(p.thresFactorF)]};
            paramString(lengthParamString+10) = {['threshminlevel = ' num2str(p.threshminlevel)]};
            paramString(lengthParamString+11) = {['valleythresh2 = ' num2str(p.valleythresh2)]};
            paramString(lengthParamString+12) = {['edgeSigmaV = ' num2str(p.edgeSigmaV)]};
            paramString(lengthParamString+13) = {['valleythresh1 = ' num2str(p.valleythresh1)]};
            set(handles.params,'string',paramString);
            %-----------------------------------------------------------------------------
        case 3
            p.edgemode       = 3;
            p.erodeNum       = str2double(get(handles.SegErodeNum,'string'));
            p.openNum        = str2double(get(handles.SegOpenNum,'string'));
            p.invertimage     = str2double(get(handles.SegInvertImage,'string'));
            p.thresFactorM   = get(handles.SegThreshFactorM,'value');
            p.thresFactorF   = p.thresFactorM;
            p.threshminlevel = get(handles.SegThreshMinLevel,'value');
            p.crossthresh    = get(handles.SegCrossThresh,'value');
            p.valleythresh1  = get(handles.SegValleyThresh1,'value');
            p.valleythresh2  = get(handles.SegValleyThresh2,'value');
            p.edgeSigmaV     = get(handles.SegEdgeSigmaV,'value');
            p.edgeSigmaL     = get(handles.SegEdgeSigmaL,'value');
            %-----------------------------------------------------------------------------
            %add parameters to the global params handle
            paramString = get(handles.params,'string');
            isTrueSegParam = find(strcmp('%parameters added after Segmentation Module',paramString)==1);
            if ~isempty(isTrueSegParam),paramString(isTrueSegParam:end) = [];end
            lengthParamString = find(cellfun(@isempty,paramString)==0,1,'last');
            paramString(lengthParamString+3) = {'%parameters added after Segmentation Module'};
            paramString(lengthParamString+4) = {'edgemode = 3'};
            paramString(lengthParamString+5) = {['erodeNum = ' num2str(p.erodeNum)]};
            paramString(lengthParamString+6) = {['openNum = ' num2str(p.openNum)]};
            paramString(lengthParamString+7) = {['invertimage = ' num2str(p.invertimage)]};
            paramString(lengthParamString+8) = {['thresFactorM = ' num2str(p.thresFactorM)]};
            paramString(lengthParamString+9) = {['thresFactorF = ' num2str(p.thresFactorF)]};
            paramString(lengthParamString+10) = {['threshminlevel = ' num2str(p.threshminlevel)]};
            paramString(lengthParamString+11) = {['edgeSigmaL = ' num2str(p.edgeSigmaL)]};
            paramString(lengthParamString+12) = {['valleythresh1 = ' num2str(p.valleythresh1)]};
            paramString(lengthParamString+13) = {['valleythresh2 = ' num2str(p.valleythresh2)]};
            paramString(lengthParamString+14) = {['edgeSigmaV = ' num2str(p.edgeSigmaV)]};
            paramString(lengthParamString+15) = {['crossthresh = ' num2str(p.crossthresh)]};
            set(handles.params,'string',paramString);
            %-----------------------------------------------------------------------------
        case 'Cross'
            p.edgemode       = 4;
            p.erodeNum       = str2double(get(handles.SegErodeNum,'string'));
            p.openNum        = str2double(get(handles.SegOpenNum,'string'));
            p.invertimage     = str2double(get(handles.SegInvertImage,'string'));
            p.thresFactorM   = get(handles.SegThreshFactorM,'value');
            p.thresFactorF   = p.thresFactorM;
            p.threshminlevel = get(handles.SegThreshMinLevel,'value');
            p.crossthresh    = get(handles.SegCrossThresh,'value');
            p.valleythresh1  = get(handles.SegValleyThresh1,'value');
            p.valleythresh2  = get(handles.SegValleyThresh2,'value');
            p.edgeSigmaV     = get(handles.SegEdgeSigmaV,'value');
            p.edgeSigmaL     = get(handles.SegEdgeSigmaL,'value');
            %-----------------------------------------------------------------------------
            %add parameters to the global params handle
            paramString = get(handles.params,'string');
            isTrueSegParam = find(strcmp('%parameters added after Segmentation Module',paramString)==1);
            if ~isempty(isTrueSegParam),paramString(isTrueSegParam:end) = [];end
            lengthParamString = find(cellfun(@isempty,paramString)==0,1,'last');
            paramString(lengthParamString+3) = {'%parameters added after Segmentation Module'};
            paramString(lengthParamString+4) = {'edgemode = 4'};
            paramString(lengthParamString+5) = {['erodeNum = ' num2str(p.erodeNum)]};
            paramString(lengthParamString+6) = {['openNum = ' num2str(p.openNum)]};
            paramString(lengthParamString+7) = {['invertimage = ' num2str(p.invertimage)]};
            paramString(lengthParamString+8) = {['thresFactorM = ' num2str(p.thresFactorM)]};
            paramString(lengthParamString+9) = {['thresFactorF = ' num2str(p.thresFactorF)]};
            paramString(lengthParamString+10) = {['threshminlevel = ' num2str(p.threshminlevel)]};
            paramString(lengthParamString+11) = {['edgeSigmaL = ' num2str(p.edgeSigmaL)]};
            paramString(lengthParamString+12) = {['valleythresh1 = ' num2str(p.valleythresh1)]};
            paramString(lengthParamString+13) = {['valleythresh2 = ' num2str(p.valleythresh2)]};
            paramString(lengthParamString+14) = {['edgeSigmaV = ' num2str(p.edgeSigmaV)]};
            paramString(lengthParamString+15) = {['crossthresh = ' num2str(p.crossthresh)]};
            set(handles.params,'string',paramString);
            %-----------------------------------------------------------------------------
    otherwise
end
close(handles.segmentation);
catch
    return;
end
function mainkeypress(hObject, eventdata)%#ok<INUSD>
  
end

function closeSegmentation(hObject, eventdata)%#ok<INUSD>
    try
         delete(handles.segmentation);
    catch
         delete(gcf);
    end
         
         
end
end %segmentation