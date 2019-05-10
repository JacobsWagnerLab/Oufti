function oufti
%mcc -m -C oufti.m -R '-startmsg,"Launching Oufti application"' -a C:\projects\oufti\microFluidic\truncateFile.pl -a C:\projects\oufti\helpers\loci_tools.jar 
% License (GNU GPL v.3)
% 
% The program suite Oufti outlines bacterial cells in microscope
% images, analyzes fluorescence data and performs statistical analysis of
% the cells. The suite has been developed by Oleksii Sliusarenko with
% contribution of Therry Emonet, Michael Sneddon, and Whitman Schofield,
% members of the Emonet lab and the Jacobs-Wagner lab, Yale University, New
% Haven, CT.
% 
% Copyright (c) 2007-2012, the Emonet lab and the Jacbos-Wagner lab, Yale
% University.
%
% This program is free software: you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation, either version 3 of the License, or (at your
% option) any later version.
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along
% with this program. If not, see <http://www.gnu.org/licenses/>.
% 
% Additional information about the program suite can be obtained from its
% website <http://Oufti.org/>.

% -----------------------------------
% Compilation instructions:
% -----------------------------------
% Include:
% checkbformats.m
% logvalley.m
% edgeforce.m
% interp2a.m
% isContourClockwise.m
% loadimageseries.m
% projectCurve.m
% expandpoly.m
% aip.cpp (not aip.c!)
% intxy2C.c/cpp
% intxyMiltiC.c/cpp
% intxySelfC.c/cpp

% clear oufti data from old sessions, if any
versionNumber = 'Oufti - compiled:  August 25, 2015';
 %-------------------------------------------------------------------------
 %pragma function needed to include files for deployment
 %#function [createCellMovie intxySelfC intxyMultiC intxy2C aip truncateFile.pl gmdistribution VideoWriter]
 %#function [cellLengthFcn cellListFilterFcn cellMaxWidthFcn cellMeanWidthFcn cellStatFcn curvatureHistFcn curveGraph]
 %#function [demograph demographFcn dispcellAllFcn exportCellListFcn getLLoCurves growthCurvesFcn dispcellFcn dispcellAllFcn]
 %#function [spotViewer growthFitbyOD importCsvFcn intensityHistFcn intensityProfileFcn kymographFcn meanIntensityHistFcn]
 
 %-------------------------------------------------------------------------
global handles  
if exist('handles','var') && isfield(handles,'maingui') && ishandle(handles.maingui)
    choice = questdlg('Another Oufti session is running. Close it and continue?','Question','Close & continue','Keep & exit','Close & continue');
    if strcmp(choice,'Keep & exit'), return; end
end
cleardata();
% % % try
% % % sched = findResource('scheduler', 'type', 'local');
% % % all_jobs = get(sched, 'Jobs');
% % % destroy(all_jobs);
% % % catch err
% % %     disp('no jobs to clear from memory');
% % % end

%-------------------------------------------------------------------------------------
%checkbformats checks for Bio-Formats Viewer library.  This library provides a useful
%function that loads stack images that are not tif.
bformats = checkbformats(1);
%-------------------------------------------------------------------------------------

% define/redefine globals
global hFig rmask cellList cellListN selectedList imsizes handles imageFolders imageLimits logcheckw regionSelectionRect shiftframes shiftfluo %#ok<REDEF>

%% GUI
handles.textMode = 0;
handles.maingui = figure('pos',[100 100 800 800],'WindowButtonMotionFcn',@mousemove,'windowButtonUpFcn',...
                         @dragbutonup,'windowButtonDownFcn',@selectclick,'KeyPressFcn',@mainkeypress,...
                         'WindowKeyPressFcn',@wndmainkeypress,'WindowKeyReleaseFcn',@wndmainkeyrelease,...
                         'CloseRequestFcn',@mainguiclosereq,'Toolbar','none','Menubar','none','Name',...
                         num2str(versionNumber),'Visible','off','NumberTitle','off','IntegerHandle','off','ResizeFcn',@resizefcn,'uicontextmenu',[],'DockControls','off');
%----------------------------------------------------------------------------------------
hFig = handle(handles.maingui);
%menus for Oufti, spotFinder or alignment functions
%#function ouftiVisibility spotFinderVisibility objectDetection

handles.allGui = uimenu('Parent',handles.maingui,'Label','cellDetection','Callback',...
                        'ouftiVisibility');

handles.spotGui = uimenu('Parent',handles.maingui,'Label','spotDetection','Callback',...
                         'spotFinderVisibility');
                     
handles.objectGui = uimenu('Parent',handles.maingui,'Label','objectDetection','Callback',...
                           'objectDetection');
%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
%This menu item is for extra tools such generation of movie file for a
%given cell in timelapse study
handles.tools = uimenu('Parent',handles.maingui,'Label','Tools');
                uimenu(handles.tools,'Label','cellCycleViewer','Callback','createCellMovie',...
                        'separator','on','Accelerator','M');

%This menu item is to display spots structures array gathered  using spot
%detection utility or the spotFinderF utility.
                uimenu(handles.tools,'Label','spotViewer','Callback','spotViewer',...
                        'separator','on','Accelerator','S');
handles.cellStat = uimenu(handles.tools,'Label','cell statistics');
                uimenu(handles.cellStat,'Label','cell stat','Callback','cellStatFcn');
                uimenu(handles.cellStat,'Label','curvature hist','Callback','curvatureHistFcn');
                uimenu(handles.cellStat,'Label','length hist','Callback','cellLengthFcn');
                uimenu(handles.cellStat,'Label','mean width hist','Callback','cellMeanWidthFcn');
% % %                 uimenu(handles.cellStat,'Label','max width hist','Callback','cellMaxWidthFcn');
                
handles.signalStat = uimenu(handles.tools,'Label','signal statistics');
                uimenu(handles.signalStat,'Label','intensity hist','Callback','intensityHistFcn');
                uimenu(handles.signalStat,'Label','mean intensity hist','Callback','meanIntensityHistFcn');
                uimenu(handles.signalStat,'Label','intensity profile','Callback','intensityProfileFcn');
                uimenu(handles.signalStat,'Label','kymograph','Callback','kymographFcn');
                uimenu(handles.signalStat,'Label','demograph','Callback','demographFcn');
%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

                uimenu(handles.tools,'Label','display cell','Callback','dispcellFcn');
                
                uimenu(handles.tools,'Label','display all cells','Callback','dispcellAllFcn');
                
                uimenu(handles.tools,'Label','growth curves','Callback','growthCurvesFcn');
                uimenu(handles.tools,'Label','cellList filter','Callback','cellListFilterFcn');
                uimenu(handles.tools,'Label','export cellList to csv','Callback','exportCellListFcn');
                uimenu(handles.tools,'Label','import csv to cellList','Callback','importCsvFcn');

%----------------------------------------------------------------------------------------

                     %Image loading and displaying
handles.impanel = uipanel('units','pixels','pos',[17 170 700 600],'BorderType','none');
handles.operationButtonsPanel = uipanel('Parent',handles.maingui,'units','pixels','Position',[795 770 190 29],'BorderType','none');
handles.pauseButton = uicontrol('Style','pushbutton','Parent',handles.operationButtonsPanel,'String','Pause',...
                                'Position',[30 2 80 25],'callback',@operationButtons,'FontUnits','pixels',...
                               'FontName','Helvetica','FontSize',10); 
handles.stopButton = uicontrol('Style','pushbutton','Parent',handles.operationButtonsPanel,'units','pixels','Position',[110 2 80 25],...
                               'String','Stop','callback',@operationButtons,'FontUnits','pixels',...
                               'FontName','Helvetica','FontSize',10);                                                 
handles.imslider = uicontrol('Style','slider','units','pixels','Position',[2 170 15 600],...
                         'SliderStep',[1 5],'min',1,'max',2,'value',1,'Enable','off',...
                         'callback',@imslider);
%-----------------------------------------------------------------------------------------
%update v0.2.10
%date: March 6, 2013.  by:  Ahmad.p
%hScrollbarImSlider = handle.listener(handles.imslider,'ActionEvent',@imslider);
handles.loadpanel = uipanel('units','pixels','pos',[3 772 770 29],'BorderType','none');
handles.helpbtn = uicontrol(handles.loadpanel,'units','pixels','Position',[1 2 60 25],'String','Help',...
                    'ForegroundColor',[0.8 0 0],'callback',@help_cbk,'FontUnits','pixels','FontSize',13);
handles.loadphase = uicontrol(handles.loadpanel,'units','pixels','Position',[78 2 80 25],...
                              'String','Load phase','callback',@loadstack,'FontUnits','pixels',...
                              'FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeyprese);
handles.loads1 = uicontrol(handles.loadpanel,'units','pixels','Position',[163 2 80 25],'String','Load signal 1','callback',@loadstack,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.loads2 = uicontrol(handles.loadpanel,'units','pixels','Position',[247 2 80 25],'String','Load signal 2','callback',@loadstack,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.loadcheck = uicontrol(handles.loadpanel,'units','pixels','pos',[331 2 60 25],'style','checkbox','String','stack','FontUnits','pixels','FontName','Helvetica','FontSize',10,'Value',1,'KeyPressFcn',@mainkeypress);
handles.highThroughput = uicontrol(handles.loadpanel,'units','pixels','pos',[380 2 100 25],'style','checkbox','String','High-throughput','FontUnits','pixels','FontName','Helvetica','FontSize',10,'Value',0,'KeyPressFcn',@mainkeypress);

uicontrol(handles.loadpanel,'units','pixels','Position',[480 6 70 15],'Style','text','String','Align frames:','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.alignframes = uicontrol(handles.loadpanel,'units','pixels','Position',[550 2 41 25],'String','Align','callback',@alignphaseframes,'Enable','off','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.loadalignment = uicontrol(handles.loadpanel,'units','pixels','Position',[595 2 41 25],'String','Load','callback',@alignphaseframes,'Enable','off','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.savealignment = uicontrol(handles.loadpanel,'units','pixels','Position',[640 2 41 25],'String','Save','callback',@alignphaseframes,'Enable','off','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.shiftframes = uicontrol(handles.loadpanel,'units','pixels','Position',[685 2 41 25],'String','Shift','callback',@alignphaseframes,'Enable','off','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.resetshift = uicontrol(handles.loadpanel,'units','pixels','Position',[730 2 41 25],'String','Reset','callback',@alignphaseframes,'Enable','off','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);

% Zoom panel
handles.zoompanel = uipanel('units','pixels','pos',[180 75 160 91]);
handles.zoomin = uicontrol(handles.zoompanel,'units','pixels','pos',[120 63 20 20],'String','+','callback',@zoominout,'Enable','off','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.zoomout = uicontrol(handles.zoompanel,'units','pixels','pos',[20 63 20 20],'String','-','callback',@zoominout,'Enable','off','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.zoomcheck = uicontrol(handles.zoompanel,'units','pixels','pos',[10 43 140 20],'style','checkbox','String','Display zoomed image','callback',@zoomcheck,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
%handles.logcheck = uicontrol(handles.zoompanel,'units','pixels','pos',[10 26 140 20],'style','checkbox','String','Log window /','callback',@logcheck,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
%handles.logcheckw = uicontrol(handles.zoompanel,'units','pixels','pos',[100 26 50 20],'style','checkbox','String','WS','callback',@logcheck,'Value',1,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.contrast = uicontrol(handles.zoompanel,'units','pixels','pos',[5 5 48 20],'String','Contrast','callback',@contrast_cbk,'Enable','on','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.clonefigure = uicontrol(handles.zoompanel,'units','pixels','pos',[55 5 48 20],'String','Clone','callback',@clonefigure,'Enable','on','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.exportbtn = uicontrol(handles.zoompanel,'units','pixels','pos',[105 5 48 20],'String','Export','callback',@export_cbk,'Enable','on','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);

% Frame and cell data
handles.datapanel = uipanel('units','pixels','pos',[5 5 170 161]);
uicontrol(handles.datapanel,'units','pixels','Position',[1 142 75 15],'Style','text','String','Image:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.currentimage = uicontrol(handles.datapanel,'units','pixels','Position',[80 142 85 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 128 75 15],'Style','text','String','Current frame:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.currentframe = uicontrol(handles.datapanel,'units','pixels','Position',[80 128 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.currentcellsT = uicontrol(handles.datapanel,'units','pixels','Position',[1 114 75 15],'Style','text','String','Selected cell:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.currentcells = uicontrol(handles.datapanel,'units','pixels','Position',[80 114 85 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 100 75 15],'Style','text','String','Ancestors:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.ancestors = uicontrol(handles.datapanel,'units','pixels','Position',[80 100 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 86 75 15],'Style','text','String','Descendants:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.descendants = uicontrol(handles.datapanel,'units','pixels','Position',[80 86 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 72 75 15],'Style','text','String','Divisions:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 58 75 15],'Style','text','String','Stage:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.stage = uicontrol(handles.datapanel,'units','pixels','Position',[80 58 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.divisions = uicontrol(handles.datapanel,'units','pixels','Position',[80 72 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 58 75 15],'Style','text','String','Length:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.celldata.length = uicontrol(handles.datapanel,'units','pixels','Position',[80 58 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 44 75 15],'Style','text','String','Width:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.celldata.width = uicontrol(handles.datapanel,'units','pixels','Position',[80 44 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 30 75 15],'Style','text','String','Area:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.celldata.area = uicontrol(handles.datapanel,'units','pixels','Position',[80 30 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 16 75 15],'Style','text','String','Volume:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.celldata.volume = uicontrol(handles.datapanel,'units','pixels','Position',[80 16 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.datapanel,'units','pixels','Position',[1 1 75 15],'Style','text','String','Cursor:','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.celldata.coursor = uicontrol(handles.datapanel,'units','pixels','Position',[80 1 80 15],'Style','text','String','','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);

% Display controls
handles.dcpanel = uipanel('units','pixels','pos',[345 75 322 91]);

handles.dispmesh = uibuttongroup(handles.dcpanel,'units','pixels','Position',[5 60 310 20],'BorderType','none','SelectionChangeFcn',@dispmeshcontrol,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.dispmesh,'units','pixels','Position',[2 2 100 14],'Style','text','String','Show mesh as:','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.mesh0 = uicontrol(handles.dispmesh,'units','pixels','Position',[79 2 75 16],'Style','radiobutton','String','None','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.mesh1 = uicontrol(handles.dispmesh,'units','pixels','Position',[136 2 75 16],'Style','radiobutton','String','Contour','HorizontalAlignment','left','Value',1,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.mesh2 = uicontrol(handles.dispmesh,'units','pixels','Position',[193 2 65 16],'Style','radiobutton','String','Number','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.mesh3 = uicontrol(handles.dispmesh,'units','pixels','Position',[250 2 55 16],'Style','radiobutton','String','Mesh','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);

handles.dispcolor = uibuttongroup(handles.dcpanel,'units','pixels','Position',[5 35 310 20],'BorderType','none','SelectionChangeFcn',@dispcolorcontrol,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.dispcolor,'units','pixels','Position',[2 2 100 14],'Style','text','String','Mesh color:','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.color1 = uicontrol(handles.dispcolor,'units','pixels','Position',[79 2 65 16],'Style','radiobutton','String','White','HorizontalAlignment','left','Value',1,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.color2 = uicontrol(handles.dispcolor,'units','pixels','Position',[136 2 62 16],'Style','radiobutton','String','Black','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.color3 = uicontrol(handles.dispcolor,'units','pixels','Position',[193 2 62 16],'Style','radiobutton','String','Green','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.color4 = uicontrol(handles.dispcolor,'units','pixels','Position',[250 2 62 16],'Style','radiobutton','String','Yellow','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);

handles.dispimg = uibuttongroup(handles.dcpanel,'units','pixels','Position',[5 10 310 20],'BorderType','none','SelectionChangeFcn',@dispimgcontrol,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.dispimg,'units','pixels','Position',[2 2 100 14],'Style','text','String','Display image:','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.dispph = uicontrol(handles.dispimg,'units','pixels','Position',[79 2 62 16],'Style','radiobutton','String','Phase','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
% handles.dispfm = uicontrol(handles.dispimg,'units','pixels','Position',[136 2 62 16],'Style','radiobutton','String','Extra','HorizontalAlignment','left','Visible','off','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.disps1 = uicontrol(handles.dispimg,'units','pixels','Position',[136 2 62 16],'Style','radiobutton','String','Signal 1','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.disps2 = uicontrol(handles.dispimg,'units','pixels','Position',[193 2 62 16],'Style','radiobutton','String','Signal 2','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);

% Background subtraction
handles.bgr = uipanel('units','pixels','pos',[672 75 105 91]);
handles.subtbgr = uicontrol(handles.bgr,'units','pixels','Position',[5 55 91 20],'String','Subtract bgrnd','callback',@subtbgrcbk,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.subtbgrtype = uibuttongroup(handles.bgr,'units','pixels','Position',[5 27 91 20],'BorderType','none','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.subtbgrvis = uicontrol(handles.subtbgrtype,'units','pixels','Position',[1 2 55 16],'Style','radiobutton','String','Visible','HorizontalAlignment','left','Value',1,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.subtbgrall = uicontrol(handles.subtbgrtype,'units','pixels','Position',[56 2 35 16],'Style','radiobutton','String','All','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.savebgr = uicontrol(handles.bgr,'units','pixels','Position',[5 5 91 20],'String','Save vis. signal','callback',@subtbgrcbk,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);

% Training
% % % handles.trn = uipanel('units','pixels','pos',[672 5 103 87]);
% % % handles.train = uicontrol(handles.trn,'units','pixels','Position',[5 61 91 20],'String','Train','callback',@train_cbk,'Tooltipstring','Train the program for a new cell type (alg. 2 and 3)','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
% % % uicontrol(handles.trn,'units','pixels','Position',[5 39 55 16],'Style','text','String','# of points','FontUnits','pixels','FontName','Helvetica','FontSize',10);
% % % handles.trainN = uicontrol(handles.trn,'units','pixels','Position',[62 40 31 19],'String','','Style','edit','Max',1,'BackgroundColor',[1 1 1],'FontUnits','pixels','FontName','Helvetica','FontSize',10);
% % % handles.trainMult = uicontrol(handles.trn,'units','pixels','Position',[5 20 91 20],'String','Mult. folders','style','checkbox','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
% % % uicontrol(handles.trn,'units','pixels','Position',[5 1 55 16],'Style','text','String','Algorithm','FontUnits','pixels','FontName','Helvetica','FontSize',10);
% % % handles.trainAlg = uicontrol(handles.trn,'units','pixels','Position',[62 2 31 19],'String','2','Style','edit','Max',1,'BackgroundColor',[1 1 1],'FontUnits','pixels','FontName','Helvetica','FontSize',10);

% Detection buttons
bhght = 316;
handles.btnspanel = uipanel('units','pixels','pos',[750 480 216 bhght]);
uicontrol(handles.btnspanel,'units','pixels','Position',[7 bhght-26 200 18],'Style','text','String','Detection & analysis','FontWeight','bold','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.runframeAll = uicontrol(handles.btnspanel,'units','pixels','Position',[7 bhght-45 95 21],'String','All frames','Enable','off','callback',@run_cbk,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.runframeThis = uicontrol(handles.btnspanel,'units','pixels','Position',[112 bhght-45 95 21],'String','This frame','Enable','off','callback',@run_cbk,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.runframeRange = uicontrol(handles.btnspanel,'units','pixels','Position',[7 bhght-69 95 21],'String','Range:','Enable','off','callback',@run_cbk,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.btnspanel,'units','pixels','Position',[105 bhght-67 23 14],'Style','text','String','from','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.runframeStart = uicontrol(handles.btnspanel,'units','pixels','Position',[131 bhght-69 27 19],'Style','edit','Min',1,'Max',1,'BackgroundColor',[1 1 1],'FontUnits','pixels','FontName','Helvetica','FontSize',10);
uicontrol(handles.btnspanel,'units','pixels','Position',[162 bhght-67 12 14],'Style','text','String','to','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.runframeEnd = uicontrol(handles.btnspanel,'units','pixels','Position',[176 bhght-69 27 19],'Style','edit','Min',1,'Max',1,'BackgroundColor',[1 1 1],'FontUnits','pixels','FontName','Helvetica','FontSize',10);

handles.runmode     = uibuttongroup(handles.btnspanel,'units','pixels','Position',[7 bhght-149 135 80],'BorderType','none','FontUnits','pixels','FontName','Helvetica','FontSize',10,'SelectionChangeFcn',@modeSelection);
handles.runmode1    = uicontrol(handles.runmode,'units','pixels','Position',[2 41 130 16],'Style','radiobutton','String','Time lapse','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.runmode3    = uicontrol(handles.runmode,'units','pixels','Position',[2 21 130 16],'Style','radiobutton','String','Independent frames','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.runmode4    = uicontrol(handles.runmode,'units','pixels','Position',[2 1 130 16],'Style','radiobutton','String','Reuse meshes','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.runselected = uicontrol(handles.btnspanel,'units','pixels','Position',[8 bhght-169 120 16],'Style','checkbox','String','Selected cells only','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.selectarea  = uicontrol(handles.btnspanel,'units','pixels','Position',[123 bhght-169 90 16],'Style','checkbox','String','Selected area','Callback',@selectarea,'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);

handles.includePhase     = uicontrol(handles.btnspanel,'units','pixels','Position',[8 bhght-199 160 16],'Style','checkbox','String','Compute phase profile as','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.includePhaseAs   = uicontrol(handles.btnspanel,'units','pixels','Position',[170 bhght-200 40 19],'Style','edit','String','0','BackgroundColor',[1 1 1],'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.includeSignal1   = uicontrol(handles.btnspanel,'units','pixels','Position',[8 bhght-219 160 16],'Style','checkbox','String','Compute signal 1 profile as','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.includeSignal1As = uicontrol(handles.btnspanel,'units','pixels','Position',[170 bhght-220 40 19],'Style','edit','String','1','BackgroundColor',[1 1 1],'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.includeSignal2   = uicontrol(handles.btnspanel,'units','pixels','Position',[8 bhght-239 160 16],'Style','checkbox','String','Compute signal 2 profile as','FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);
handles.includeSignal2As = uicontrol(handles.btnspanel,'units','pixels','Position',[170 bhght-240 40 19],'Style','edit','String','2','BackgroundColor',[1 1 1],'FontUnits','pixels','FontName','Helvetica','FontSize',10,'KeyPressFcn',@mainkeypress);

handles.saveEachFrame   = uicontrol(handles.btnspanel,'units','pixels','Position',[8 bhght-269 125 16],'Style','checkbox','String','Save on each frame /','Callback',@saveWhileProcessing_cbk,'Value',0,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.saveWhenDone    = uicontrol(handles.btnspanel,'units','pixels','Position',[133 bhght-269 80 16],'Style','checkbox','String','when done','Callback',@saveWhileProcessing_cbk,'Value',1,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.saveFileControl = uicontrol(handles.btnspanel,'units','pixels','Position',[7 bhght-289 50 17],'String','File','callback',{@saveFileControl},'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.saveFile        = uicontrol(handles.btnspanel,'units','pixels','Position',[62 bhght-289 151 15],'Style','text','String','','HorizontalAlignment','left','KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);

handles.runBatch = uicontrol(handles.btnspanel,'units','pixels','Position',[41 bhght-311 132 20],'String','Batch Processing','callback',@runBatch,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);

% Saving meshes
handles.savemeshpanel       = uipanel('units','pixels','pos',[780 404 216 72]);
uicontrol(handles.savemeshpanel,'units','pixels','Position',[7 47 200 18],'Style','text','String','Saving analysis','FontWeight','bold','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.savemesh            = uicontrol(handles.savemeshpanel,'units','pixels','Position',[7 27 95 20],'String','Save analysis','callback',@saveLoadMesh_cbk,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.saveselected        = uicontrol(handles.savemeshpanel,'units','pixels','Position',[112 27 95 20],'Style','checkbox','String','Selection only','KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.loadmesh            = uicontrol(handles.savemeshpanel,'units','pixels','Position',[7 5 95 20],'String','Load analysis','callback',@saveLoadMesh_cbk,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.loadparamwithmesh   = uicontrol(handles.savemeshpanel,'units','pixels','Position',[112 5 95 20],'Style','checkbox','String','Load params','Value',1,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);

% Selection
handles.selectpanel     = uipanel('units','pixels','pos',[180 5 228 66]);
uicontrol(handles.selectpanel,'units','pixels','Position',[5 46 220 15],'Style','text','String','Selection','FontWeight','bold','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.selectall       = uicontrol(handles.selectpanel,'units','pixels','Position',[5 27 73 20],'String','Select all','callback',@selectall,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.selectgroup     = uicontrol(handles.selectpanel,'units','pixels','Position',[118 27 35 20],'String','Cell(s)','callback',@selectgroup,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.selectFrame     = uicontrol(handles.selectpanel,'units','pixels','Position',[80 27 35 20],'String','Frame','callback',@selectFrame,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.selectgroupedit = uicontrol(handles.selectpanel,'units','pixels','Position',[156 27 65 19],'Style','edit','String','','BackgroundColor',[1 1 1],'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.invselection    = uicontrol(handles.selectpanel,'units','pixels','Position',[5 5 73 20],'String','Invert','callback',@invselection,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.delselected     = uicontrol(handles.selectpanel,'units','pixels','Position',[80 5 73 20],'String','Delete','callback',@delselected,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.deleteselframe  = uicontrol(handles.selectpanel,'units','pixels','Position',[154 5 71 20],'Style','checkbox','String','This frame','KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);

% Changing polarity
handles.polaritypanel   = uipanel('units','pixels','pos',[413 5 86 66]);
uicontrol(handles.polaritypanel,'units','pixels','Position',[5 46 74 15],'Style','text','String','Polarity','FontWeight','bold','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.setpolarity     = uicontrol(handles.polaritypanel,'units','pixels','Position',[5 27 74 20],'Style','togglebutton','String','Set','callback',@polarity_cbk,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.removepolarity  = uicontrol(handles.polaritypanel,'units','pixels','Position',[5 5 74 20],'Style','togglebutton','String','Remove','callback',@polarity_cbk,'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);

% % % % Manual operations
% % % handles.specialpanel = uipanel('units','pixels','pos',[504 5 163 66]);
% % % uicontrol(handles.specialpanel,'units','pixels','Position',[5 46 154 15],'Style','text','String','Manual','FontWeight','bold','FontUnits','pixels','FontName','Helvetica','FontSize',10);
% % % handles.join = uicontrol(handles.specialpanel,'units','pixels','Position',[5 27 74 20],'Style','pushbutton','String','Join','callback',@manual_cbk,'KeyPressFcn',@mainkeypress,'Tooltipstring','Force join two or more cells','FontUnits','pixels','FontName','Helvetica','FontSize',10);
% % % handles.split = uicontrol(handles.specialpanel,'units','pixels','Position',[5 5 74 20],'Style','pushbutton','String','Split','callback',@manual_cbk,'KeyPressFcn',@mainkeypress,'Tooltipstring','Force split a cell','FontUnits','pixels','FontName','Helvetica','FontSize',10);
% % % handles.refine = uicontrol(handles.specialpanel,'units','pixels','Position',[82 27 74 20],'Style','pushbutton','String','Refine','callback',@manual_cbk,'KeyPressFcn',@mainkeypress,'Tooltipstring','Refine the cell outline under the current parameters','FontUnits','pixels','FontName','Helvetica','FontSize',10);
% % % handles.addcell = uicontrol(handles.specialpanel,'units','pixels','Position',[82 5 74 20],'Style','togglebutton','String','Add','callback',@manual_cbk,'KeyPressFcn',@mainkeypress,'Tooltipstring','Add a cell by clicking its outline (alg. 1) or centerline (alg. 4), doubleclick or press Enter to select, Esc to cancel','FontUnits','pixels','FontName','Helvetica','FontSize',10);
% % % 

% Manual operations
handles.specialpanel    = uipanel('units','pixels','pos',[504 5 163 66]);
uicontrol(handles.specialpanel,'units','pixels','Position',[5 46 154 15],'Style','text','String','Manual','FontWeight','bold','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.join            = uicontrol(handles.specialpanel,'units','pixels','Position',[5 27 45 20],'Style','pushbutton','String','Join','callback',@manual_cbk,'KeyPressFcn',@mainkeypress,'Tooltipstring','Force join two or more cells','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.split           = uicontrol(handles.specialpanel,'units','pixels','Position',[55 27 55 20],'Style','pushbutton','String','Split','callback',@manual_cbk,'KeyPressFcn',@mainkeypress,'Tooltipstring','Force split a cell','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.addcell         = uicontrol(handles.specialpanel,'units','pixels','Position',[114 27 45 20],'Style','togglebutton','String','Add','callback',@manual_cbk,'KeyPressFcn',@mainkeypress,'Tooltipstring',...
                            'Add a cell by clicking its outline (alg. 1) or centerline (alg. 4), doubleclick or press Enter to select, Esc to cancel','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.refine          = uicontrol(handles.specialpanel,'units','pixels','Position',[5 5 45 20],'Style','pushbutton','String','Refine','callback',@manual_cbk,'KeyPressFcn',@mainkeypress,'Tooltipstring','Refine the cell outline under the current parameters','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.refineAll       = uicontrol(handles.specialpanel,'units','pixels','Position',[55 5 55 20],'Style','pushbutton','String','Refine All','callback',@manual_cbk,'KeyPressFcn',@mainkeypress,'Tooltipstring',...
                            'Refine all the cells that are selected or just went under drag mode using cell outline under the current parameters','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.drag            = uicontrol(handles.specialpanel,'units','pixels','Position',[114 5 45 20],'Style','togglebutton','String','Drag','FontUnits','pixels','FontName','Helvetica','FontSize',10,'callback',@manual_cbk,'KeyPressFcn',@selectclick);


% Parameters
handles.parampanel  = uipanel('units','pixels','pos',[780 10 216 20]);
handles.paramtitle  = uicontrol(handles.parampanel,'units','pixels','Position',[7 318 200 20],'Style','text','String','Parameters','FontWeight','bold','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.params      = uicontrol(handles.parampanel,'units','pixels','Position',[7 31 200 290],'Style','edit','Min',1,'Max',50,'BackgroundColor',[1 1 1],'HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.saveparam   = uicontrol(handles.parampanel,'units','pixels','Position',[7 6 95 20],'String','Save parameters','callback',{@saveparam_cbk},'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.loadparam   = uicontrol(handles.parampanel,'units','pixels','Position',[112 6 95 20],'String','Load parameters','callback',{@loadparam_cbk},'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);

% Parameters test modes
handles.testpanel   = uipanel('units','pixels','pos',[780 5 216 48]);
handles.testtitle   = uicontrol(handles.testpanel,'units','pixels','Position',[7 23 200 20],'Style','text','String','Parameter test mode','FontWeight','bold','FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.segmenttest = uicontrol(handles.testpanel,'units','pixels','Position',[7 6 95 20],'String','Segmentation','callback',{@run_cbk},'KeyPressFcn',@mainkeypress,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
handles.aligntest   = uicontrol(handles.testpanel,'units','pixels','Position',[112 6 95 20],'String','Alignment','callback',{@run_cbk},'KeyPressFcn',@mainkeypress,'Style','togglebutton','FontUnits','pixels','FontName','Helvetica','FontSize',10);

% Other objects
screenSize = get(0,'ScreenSize');
%-----------------------------------------
%
if screenSize(4)<=840, pos = [screenSize(1:2) screenSize(3:4)-40]; set(hFig,'position', [pos(1) pos(2)-50 pos(3) 700]); end
if screenSize(4)<=740, pos = [screenSize(1:2) screenSize(3:4)-40]; set(hFig,'position', [pos(1) pos(2)-100 pos(3) 600]); end
handles.hfig = figure('Toolbar','none','Menubar','none','Name','Zoomed image','NumberTitle','off','IntegerHandle','off',...
                'Visible','off','CloseRequestFcn',@hfigclosereq,'windowButtonDownFcn',@selectclick,...
                'windowButtonUpFcn',@dragbutonup,'WindowButtonMotionFcn',@dragmouse,...
                'WindowScrollWheelFcn',@zoominout,'KeyPressFcn',@mainkeypress,'uicontextmenu',[]);

set(handles.maingui,'Color',get(handles.imslider,'BackgroundColor'));
handles.cells = {};
handles.selectedCells = {};
handles.hpanel = -1;

% Variables intialization
initP; % Initialize parameters structure and some global variables
%cellList = {{}}; % list to store fitted cells
cellList = oufti_initializeCellList();
cellListN = [];
saveFile = 'tempresults.mat'; set(handles.saveFile,'String',saveFile);
paramFile = fileparts(which('Oufti.m'));
selectedList = [];
imsizes = zeros(5,3);
meshDispMode = 1;
imageDispMode = 1;
dispMeshColor = [1 1 1];
dispSelColor = [1 0 0];
frame = 1;
prevframe = 1;
magnification = 1;
zoomlocation = [];
iniMagnification = 100;
clear('pos');
selDispList = [];
handles.cells = {};
dragMode = false;
groupSelectionMode = false;
regionSelectionMode = false;
cellDrawPositions = [];
cellDrawObjects = [];
groupSelectionPosition = [];
groupSelectionRectH = [];
regionSelectionRect = [];
dragPosition = [];
shiftframes = [];
batchstruct = [];
imageFolders = {'','','',''};
imageFiles = {'','','',''};
batchTextFile = '';
imageActive = false(1,4); % indicates whether the last image was loaded from file
meshFile = '';
selectFile = '';
logcheckw = true;
imageLimits = {[0 1],[0 1],[0 1],[0 1]};
undo = [];
isShiftPressed = 0;
splitSelectionMode = false;
shiftfluo = [0 0; 0 0];
shiftfluoFile = '';
displayImage();
rmask{1} = strel('arbitrary',[0 0 0 0 0; 0 0 0 0 0; 1 1 0 1 1; 0 0 0 0 0; 0 0 0 0 0]);
rmask{2} = strel('arbitrary',[1 0 0 0 0; 0 1 0 0 0; 0 0 0 0 0; 0 0 0 1 0; 0 0 0 0 1]);
rmask{3} = strel('arbitrary',[0 0 1 0 0; 0 0 1 0 0; 0 0 0 0 0; 0 0 1 0 0; 0 0 1 0 0]);
rmask{4} = strel('arbitrary',[0 0 0 0 1; 0 0 0 1 0; 0 0 0 0 0; 0 1 0 0 0; 1 0 0 0 0]);
ouftiLocation = [];


%change directory to the last used dir
changeDir

 % Make figure visible after adding components
% handles.maingui.Visible = 'on';
set(handles.maingui,'visible','on');
% End of main function code GUI

%%

function changeDir()

    %find where oufti exists, modify that folder
    ouftiLocation = which('oufti');
    ix = strfind(ouftiLocation,'/');
    ouftiLocation(ix(end):end) = [];
    
    if exist([ouftiLocation,'/lastDir.mat'],'file')
        load([ouftiLocation,'/lastDir.mat'],'lastDir')
		try
			cd(lastDir)
		catch
		end
    end    
    
end

function help_cbk(hObject, eventdata)%#ok<INUSD>

web('http://www.oufti.org/quickstart.htm');
end

% --- Aligning nested functions ---

function subtbgrcbk(hObject, eventdata)%#ok<INUSD>
    global rawPhaseData rawS1Data rawS2Data p
    edit2p
    if hObject==handles.subtbgr
        channels = [];
        if get(handles.subtbgrvis,'Value')==1
            if imageDispMode==3, channels = 3;
            elseif imageDispMode==4, channels = 4;
            elseif  imageDispMode==1, displayImage, return
            end
        elseif get(handles.subtbgrall,'Value')==1
            if ~isempty(who('rawS1Data')) && ~isempty(rawS1Data), channels=3; end
            if ~isempty(who('rawS2Data')) && ~isempty(rawS2Data), channels=[channels 4]; end
        end
        subtractbgr(channels,[],p.invertimage)
        displayImage();
        displayCells();
    elseif hObject==handles.savebgr
        if imageDispMode==1 && (isempty(who('rawPhaseData')) || isempty(rawPhaseData)), return; end
        % if imageDispMode==2 && (isempty(who('rawFMData')) || isempty(rawFMData)), return; end
        if imageDispMode==3 && (isempty(who('rawS1Data')) || isempty(rawS1Data)), return; end
        if imageDispMode==4 && (isempty(who('rawS2Data')) || isempty(rawS2Data)), return; end
        % if imageDispMode~=3 && imageDispMode~=4, return; end
        [filename,pathname] = uiputfile('*.tif', 'Enter a filename for the first image');
        if(filename==0), return; end;
        if length(filename)>4 && strcmp(filename(end-3:end),'.tif'), filename = filename(1:end-4); end
        lng = imsizes(imageDispMode,3);
        ndig = ceil(log10(lng+1));
        istart = 1;
        for k=1:ndig
            if length(filename)>=k && ~isempty(str2num(filename(end-k+1:end)))
                istart = str2num(filename(end-k+1:end));
            else
                k=k-1;
                break
            end
        end
        if lng==1, k=0; end
        filename = fullfile2(pathname,filename(1:end-k));
        for i=1:lng;
            fnum=i+istart-1;
            if lng>1
                cfilename = [filename num2str(fnum,['%.' num2str(ndig) 'd']) '.tif'];
            else
                cfilename = [filename '.tif'];
            end
            if imageDispMode==1
                imwrite(rawPhaseData(:,:,i),cfilename,'tif','Compression','none');
            elseif imageDispMode==3
                imwrite(rawS1Data(:,:,i),cfilename,'tif','Compression','none');
            elseif imageDispMode==4
                imwrite(rawS2Data(:,:,i),cfilename,'tif','Compression','none');
            end
        end
    end
end
    

function alignphaseframes(hObject, eventdata)%#ok<INUSD>
    
    global rawPhaseData rawS1Data rawS2Data filenametmp % rawPhaseDataT cellListT shiftframesT
    
    if hObject==handles.alignframes
        edit2p
        alignfrm
        if ~isempty(shiftframes)
            set(handles.resetshift,'Enable','on');
            set(handles.shiftframes,'Enable','on');
            set(handles.savealignment,'Enable','on');
        end
    elseif hObject==handles.savealignment
        if isempty(shiftframes), return; end
        [filename,pathname] = uiputfile('*.mat', 'Enter a filename to save alignment data to',filenametmp);
        if(filename==0), return; end;
        if length(filename)<5, filename = [filename '.mat']; end
        if ~strcmp(filename(end-3:end),'.mat'), filename = [filename '.mat']; end
        filename = fullfile2(pathname,filename);
        savealign(filename)
    elseif hObject==handles.loadalignment
        [filename,pathname] = uigetfile('*.mat', 'Enter a filename to save alignment data to',filenametmp);
        if(filename==0), return; end;
        filename = fullfile2(pathname,filename);
        loadalign(filename)
        set(handles.resetshift,'Enable','on');
        set(handles.shiftframes,'Enable','on');
        set(handles.savealignment,'Enable','on');
    elseif hObject==handles.shiftframes
        if ~isempty(who('shiftframes')) && ~isempty(shiftframes)
            if ~isempty(who('rawPhaseData')) && ~isempty(rawPhaseData), rawPhaseData = shiftstack(rawPhaseData,shiftframes); end
            % if ~isempty(who('rawFMData')) && ~isempty(rawFMData), rawFMData = shiftstack(rawFMData,shiftframes); end
            if ~isempty(who('rawS1Data')) && ~isempty(rawS1Data), rawS1Data = shiftstack(rawS1Data,shiftframes); end
            if ~isempty(who('rawS2Data')) && ~isempty(rawS2Data), rawS2Data = shiftstack(rawS2Data,shiftframes); end
            if ~isempty(who('cellList')) && ~isempty(cellList), cellList = shiftstack(cellList,shiftframes); end
            shiftframes = [];
            set(handles.resetshift,'Enable','off');
            set(handles.shiftframes,'Enable','off');
            set(handles.savealignment,'Enable','off');
            displayImage
            displayCells
            disp('Images shifted')
        end
    elseif hObject==handles.resetshift
        shiftframes = [];
        set(handles.resetshift,'Enable','off');
        set(handles.shiftframes,'Enable','off');
        set(handles.savealignment,'Enable','off');
    end
end 

% --- End of aligning nested functions ---

% --- Batch processing nested functions ---

function runBatch(hObject, eventdata)%#ok<INUSD>
    if isfield(handles,'batchcontrol') && ishandle(handles.batchcontrol), figure(handles.batchcontrol); return; end % do not create second window
    handles.batchcontrol = figure('pos',[screenSize(3)/2-625 screenSize(4)/2-234 1250 470],'Toolbar','none','Menubar','none','Name','Batch Processing','NumberTitle','off','IntegerHandle','off','Resize','off','Color',get(handles.imslider,'BackgroundColor'),'CloseRequestFcn',@mainguiclosereqB);
    handles.batccpanel = uipanel('units','pixels','pos',[5 385 1240 25],'BorderType','none');
    handles.batchrun = uicontrol(handles.batccpanel,'units','pixels','Position',[5 2 90 20],'String','Run batch','callback',@batchcontrol,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchsave = uicontrol(handles.batccpanel,'units','pixels','Position',[105 2 90 20],'String','Save batch','callback',@batchcontrol,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchload = uicontrol(handles.batccpanel,'units','pixels','Position',[205 2 90 20],'String','Load batch','callback',@batchcontrol,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchrunsaved = uicontrol(handles.batccpanel,'units','pixels','Position',[305 2 90 20],'String','Run saved','callback',@batchcontrol,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchtext = uicontrol(handles.batccpanel,'units','pixels','Position',[945 2 90 20],'String','Text mode','callback',@batchtext,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchadd = uicontrol(handles.batccpanel,'units','pixels','Position',[1045 2 90 20],'String','Add job','callback',@batchcontrol,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchrem = uicontrol(handles.batccpanel,'units','pixels','Position',[1145 2 90 20],'String','Remove job','callback',@batchcontrol,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    handles.batchtitle = uipanel('units','pixels','pos',[10 442 1230 26]);
    
    uicontrol(handles.batchtitle,'units','pixels','Position',[25 14 80 10],'Style','text','String','Load phase','HorizontalAlignment','left','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[19 1 30 11],'Style','text','String','stack','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[159 14 80 10],'Style','text','String','Load signal 1','HorizontalAlignment','left','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[153 1 30 11],'Style','text','String','stack','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[293 14 80 10],'Style','text','String','Load signal 2','HorizontalAlignment','left','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[285 1 30 11],'Style','text','String','stack','FontSize',7);
  
    uicontrol(handles.batchtitle,'units','pixels','Position',[427 3 80 15],'Style','text','String','Load mesh','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.batchtitle,'units','pixels','Position',[561 3 85 15],'Style','text','String','Load parameters','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    uicontrol(handles.batchtitle,'units','pixels','Position',[696 14 60 10],'Style','text','String','Subtract bgr','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[696 1 30 11],'Style','text','String','sig 1','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[726 1 30 11],'Style','text','String','sig 2','FontSize',7);
    
    uicontrol(handles.batchtitle,'units','pixels','Position',[766 14 120 10],'Style','text','String','Time mode','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[796 1 30 11],'Style','text','String','tlapse','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[826 1 30 11],'Style','text','String','all-ind','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[856 1 30 11],'Style','text','String','reuse','FontSize',7);
    
    uicontrol(handles.batchtitle,'units','pixels','Position',[901 3 40 15],'Style','text','String','Range');
    
    uicontrol(handles.batchtitle,'units','pixels','Position',[956 14 90 10],'Style','text','String','Include','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[956 1 30 11],'Style','text','String','phase','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[986 1 30 11],'Style','text','String','sig 1','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[1016 1 30 11],'Style','text','String','sig 2','FontSize',7);
    
    uicontrol(handles.batchtitle,'units','pixels','Position',[1041 12 40 11],'Style','text','String','+ prev','FontSize',7);
    uicontrol(handles.batchtitle,'units','pixels','Position',[1043 1 40 11],'Style','text','String','frame','FontSize',7);
    
    uicontrol(handles.batchtitle,'units','pixels','Position',[1086 3 80 15],'Style','text','String','Save mesh','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    handles.batch = [];
    batchstruct = [];
    addBatchPanel
end

function batchtext(hObject, eventdata)%#ok<INUSD>
    close(handles.batchcontrol)
    handles.batchtextcontrol = figure('pos',[screenSize(3)/2-400 screenSize(4)/2-300 800 600],'Toolbar','none','Menubar','none','Name','Batch Processing: Text Mode','NumberTitle','off','IntegerHandle','off','Resize','off','Color',get(handles.imslider,'BackgroundColor'),'CloseRequestFcn',@batchGuiClose);
    uicontrol(handles.batchtextcontrol,'units','pixels','Position',[5 583 790 16],'Style','text','String','List of Oufti-specific functions which can be used in bach processing:','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    helpstr = {'','[loadedData, filenames, dirName] = loadimageseries(pathToFolder,varargin) -- loads a series of TIFF images from <folder> to <channel>, which is 1 for phase, 3 for signal 1, 4 for signal 2',...
               '[~,data] = loadimagestack(channel,filename,1,0) -- loads a stack of images from <file> to <channel> channel:   1 - rawPhaseData, 3 - rawSignal1, 4 - rawSignal2',...
               'loadaram(file) -- load a set of saved parameters from <file>',...
               'param = loadmesh(filename) -- loads mesh from <filename> (<filename> should be a full path or a name in the current folder)',...
               'parseparameters(param) -- initializes the parameter set with the string <param> from loadmesh command',...
               'process(range,mode,lst,addsig,addas,savefile,fsave,saveselect,region,shiftfluo,isOufti) -- main processing function, here <range> = [<start> <end>] - range of frames;',...
               '    <mode> - 1-tlapse, 2-1st indep., 3-all indep., 4-reuse meshes; <lst> - list of cells on the first frame in the range; <addsig> - array of 4 1''s/0''s',...
               '    <addas> - cell array of names to add signal, '' to use default, <savefile> - file to save on each step, '''' - do not save;'...
               '    <fsave> - number of frames per one saving; <saveselect> - if 0 or 1=save selected cells only, <region> - region to process, [] for the whole',...
               '    <shiftfluo> - array [x1 y1;y1 y2] of shifts of fluorescence images (for signals 1 and 2) relative to phase',...
               'savemesh(filename,list,mode,range) -- save the mesh, <list> - list of selected cells, <mode> = true - save selected, false - save all, <range> - frame range',...
               '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%',...
               '-------------Add extra fields to cellList-------------',...
               'global cellList',...
               'for frame = 1:length(cellList.meshData)' 'for cells = 1:length(cellList.meshData{frame})',...
               'cellList.meshData{frame}{cells} = getextradata(cellList.meshData{frame}{cells});',...
               'end' 'end',...
               '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'};
    handles.batchtexttext = uicontrol(handles.batchtextcontrol,'Max',10,'units','pixels','Position',[5 364 790 218],'Style','edit','String',helpstr,'Horizontalalignment','left','callback',@batchtexttext,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    function batchtexttext(hObject, eventdata)%#ok<INUSD>
        set(handles.batchtexttext,'Position',[5 364 790 218]);
    end
    handles.batchtextedit = uicontrol(handles.batchtextcontrol,'Max',200,'units','pixels','Position',[5 30 790 330],'Style','edit','String',{},'Horizontalalignment','left','Backgroundcolor',[1 1 1],'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchtextsave = uicontrol(handles.batchtextcontrol,'units','pixels','Position',[505 5 90 20],'String','Save','callback',@batchtextsaveload,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchtextload = uicontrol(handles.batchtextcontrol,'units','pixels','Position',[605 5 90 20],'String','Load','callback',@batchtextsaveload,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchtextrun = uicontrol(handles.batchtextcontrol,'units','pixels','Position',[705 5 90 20],'String','Run','callback',@batchtextrun,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
end

function batchtextsaveload(hObject, eventdata)%#ok<INUSD>
    if hObject==handles.batchtextsave
        str = get(handles.batchtextedit,'String');
        [filename,pathname] = uiputfile('*.txt','Enter a filename to save the batch file to',batchTextFile);
        if isequal(filename,0), return; end
        if isempty(strfind(filename,'.')), filename=[filename','.txt']; end
        filename = fullfile2(pathname,filename);
        batchTextFile = filename;
        for i=1:length(str)
            if i==1
                dlmwrite(filename,str{i},'delimiter', '');
            else
                dlmwrite(filename,str{i},'-append','delimiter', '');
            end
        end
    elseif hObject==handles.batchtextload
        disp('Loading text batch file...');
        [filename,pathname] = uigetfile('*.txt','Select a text file to load batch from (.txt)',batchTextFile);
        if isequal(filename,0), return; end
        filename = fullfile2(pathname,filename);
        batchTextFile = filename;
        res = readtextfile(filename);
        set(handles.batchtextedit,'String',res);
    end
end

function batchtextrun(hObject, eventdata)%#ok<INUSD>
    % processes the text-based version of the batch mode
    % The actual text is being run in the global space outside the main
    % function, this function prepares the text and displays the results.
    s=get(handles.batchtextedit,'String');
    s2='';
    if iscell(s)
        for ind=1:size(s,1)
            strlng = regexp(s{ind},'%');
            if isempty(strlng), str=s{ind}; else str=s{ind}(1:strlng-1); end
            s2=[s2 str ', '];%#ok<AGROW>
        end
    else
        for ind=1:size(s,1)
            strlng = regexp(s(ind,:),'%');
            if isempty(strlng), str=s(ind,:); else str=s(ind,1:strlng-1); end
            s2=[s2 str ', '];%#ok<AGROW>
        end
    end
    batchtextrun_glb(s2);
    updateslider
    displayImage
    displayCells
    selDispList = [];
    displaySelectedCells
    enableDetectionControls
end


function mainguiclosereqB(hObject, eventdata)%#ok<INUSD>
    % close callback for the batch window
    n = length(handles.batch);
    for i=1:n
        delete(handles.batchc(i).batchpanel)
    end
    handles.batch = [];
    handles.textMode = [];
    delete(handles.batchcontrol)
end

function batchGuiClose(hObject, eventdata)%#ok<INUSD>
if handles.textMode == 1, handles.textMode = 0;end
    delete(handles.batchtextcontrol);
    
end

function addBatchPanel
    % adds a task line (panel) to the GUI-based version of the batch mode
    n = length(handles.batch)+1;
    if n>32, disp('Too many jobs, cannot add another one.'); return; end
    if n>15
        pos = get(handles.batchcontrol,'pos');
        pos = [pos(1) pos(2)-27 pos(3) pos(4)+27];
        set(handles.batchcontrol,'pos',pos);
        for i=1:(n-1)
            set(handles.batchc(i).batchpanel,'pos',get(handles.batchc(i).batchpanel,'pos')+[0 27 0 0]);
        end
    end
    handles.batchc(n).batchpanel = uipanel('units','pixels','pos',[10 415-27*(n-1)+max(0,n-15)*27 1230 25]);
    uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[2 3 20 15],'Style','text','String',num2str(n),'FontWeight','bold','FontUnits','pixels','FontName','Helvetica','FontSize',10);

    handles.batch(n).bloadsgn1chk = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[25 4 32 16],'Style','checkbox','String','','Callback',@batchloadfile,'Tooltipstring','Select to load images from stack files','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchc(n).bloadsgn1 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[42 4 32 16],'String','folder','Callback',@batchloadfile,'Tooltipstring','Select folder with phase contrast images in TIFF format','FontSize',7);
    handles.batch(n).bloadsgn1 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[74 3 93 15],'Style','text','String','','Value',1,'hor','left','HorizontalAlignment','left','Enable','inactive','ButtonDownFcn',@batchloadfile,'FontSize',7);

    handles.batch(n).bloadsgn3chk = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[159 4 32 16],'Style','checkbox','String','','Callback',@batchloadfile,'Tooltipstring','Select to load images from stack files','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchc(n).bloadsgn3 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[176 4 32 16],'String','folder','Callback',@batchloadfile,'Tooltipstring','Select folder with signal 1 images in TIFF format','FontSize',7);
    handles.batch(n).bloadsgn3 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[209 3 93 15],'Style','text','String','','Value',1,'hor','left','HorizontalAlignment','left','Enable','inactive','ButtonDownFcn',@batchloadfile,'FontSize',7);

    handles.batch(n).bloadsgn4chk = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[293 4 32 16],'Style','checkbox','String','','Callback',@batchloadfile,'Tooltipstring','Select to load images from stack files','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batchc(n).bloadsgn4 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[310 4 32 16],'String','folder','Callback',@batchloadfile,'Tooltipstring','Select folder with signal 2 images in TIFF format','FontSize',7);
    handles.batch(n).bloadsgn4 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[344 3 93 15],'Style','text','String','','Value',1,'hor','left','HorizontalAlignment','left','Enable','inactive','ButtonDownFcn',@batchloadfile,'FontSize',7);
    
    handles.batchc(n).bloadmesh = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[428 4 32 16],'String','file','Callback',@batchloadfile,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).bloadmesh = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[463 3 107 15],'Style','text','String','','Value',1,'hor','left','HorizontalAlignment','left','Enable','inactive','ButtonDownFcn',@batchloadfile,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
      
    handles.batchc(n).bloadparam = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[562 4 32 16],'String','file','Callback',@batchloadfile,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).bloadparam = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[594 3 107 15],'Style','text','String','','Value',1,'hor','left','HorizontalAlignment','left','Enable','inactive','ButtonDownFcn',@batchloadfile,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
      
    handles.batch(n).bsubtr3 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[706 2 40 20],'Style','checkbox','String','','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).bsubtr4 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[736 2 40 20],'Style','checkbox','String','','FontUnits','pixels','FontName','Helvetica','FontSize',10);

    handles.batchc(n).mode = uibuttongroup(handles.batchc(n).batchpanel,'units','pixels','Position',[776 2 120 20],'BorderType','none');
    handles.batch(n).mode(1) = uicontrol(handles.batchc(n).mode,'units','pixels','Position',[30 1 20 20],'Style','radiobutton','String','','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).mode(3) = uicontrol(handles.batchc(n).mode,'units','pixels','Position',[60 1 20 20],'Style','radiobutton','String','','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).mode(4) = uicontrol(handles.batchc(n).mode,'units','pixels','Position',[90 1 20 20],'Style','radiobutton','String','','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    handles.batch(n).bstart = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[901 2 20 19],'Style','edit','Max',1,'BackgroundColor',[1 1 1],'HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).bend = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[925 2 20 19],'Style','edit','Max',1,'BackgroundColor',[1 1 1],'HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    handles.batch(n).badd1 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[966 2 50 20],'Style','checkbox','String','','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).badd3 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[996 2 50 20],'Style','checkbox','String','','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).badd4 = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[1026 2 50 20],'Style','checkbox','String','','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).baddprev = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[1056 2 50 20],'Style','checkbox','String','','Value',1,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    handles.batchc(n).bsavemesh = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[1086 4 32 16],'String','file','Callback',@batchloadfile,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.batch(n).bsavemesh = uicontrol(handles.batchc(n).batchpanel,'units','pixels','Position',[1121 3 106 15],'Style','text','String','','Value',1,'HorizontalAlignment','left','Enable','inactive','ButtonDownFcn',@batchloadfile,'FontUnits','pixels','FontName','Helvetica','FontSize',10);

    pos = get(handles.batchcontrol,'pos');
    set(handles.batchtitle,'position',[10 pos(4)-470+442 1230 26])
    set(handles.batccpanel,'position',[5 385-27*(n-1)+max(0,n-15)*27 1250 25])
end

function remBatchPanel
    % removes a task line (panel) to the GUI-based version of the batch mode
    delete(handles.batchc(end).batchpanel)
    handles.batchc=handles.batchc(1:end-1);
    handles.batch=handles.batch(1:end-1);
    n = length(handles.batch);
    set(handles.batccpanel,'position',[5 385-27*(n-1)+max(0,n-15)*27 1220 25])
    if n>=15
        pos = get(handles.batchcontrol,'pos');
        set(handles.batchcontrol,'pos',[pos(1) pos(2)+27 pos(3) pos(4)-27]);
        for i=1:n
            set(handles.batchc(i).batchpanel,'pos',get(handles.batchc(i).batchpanel,'pos')-[0 27 0 0]);
        end
    end
    pos = get(handles.batchcontrol,'pos');
    set(handles.batchtitle,'position',[10 pos(4)-470+442 1230 26])
end

function batchcontrol(hObject, eventdata)%#ok<INUSD>
    % callback for the control buttons in the GUI-based batch mode
    % (adding/removing panels, saving/loading batch sequences, running)
    
    if hObject==handles.batchadd, addBatchPanel; return;
    elseif hObject==handles.batchrem && length(handles.batch)>1, remBatchPanel; return;
    elseif hObject==handles.batchsave
        [filename,pathname] = uiputfile('*.btc', 'Enter a filename to save batch to');
        if(filename==0), return; end;
        if length(filename)<4, filename = [filename '.btc']; end
        if ~strcmp(filename(end-3:end),'.btc'), filename = [filename '.btc']; end
        filename = fullfile2(pathname,filename);
        batchstructupdate(true)
        for j=1:length(handles.batch)
            if j==1
                dlmwrite(filename,['job = ' num2str(j)],'delimiter', '');
            else
                dlmwrite(filename,' ','-append','delimiter', '');
                dlmwrite(filename,['job = ' num2str(j)],'-append','delimiter', '');
            end
            batchfields = fieldnames(handles.batch(j));
            for i=1:length(batchfields)
                if isfield(batchstruct(j),batchfields{i}) && ~isempty(eval(['batchstruct(j).' batchfields{i}]))
                    dlmwrite(filename,[batchfields{i} ' = ' num2str(eval(['batchstruct(j).' batchfields{i}]))],'-append','delimiter', '');
                end
            end
        end
    elseif hObject==handles.batchload
        runstruct = batchload;
        if ~isempty(runstruct), batchstruct = runstruct; end
        batchstructupdate(false)
    elseif hObject==handles.batchrunsaved
        runstruct = batchload;
        batchrun(runstruct)
    elseif hObject==handles.batchrun
        edit2p
        
        batchstructupdate(true)
        batchrun(batchstruct)
    end
    
end

function runstruct = batchload
    % loads saved batch sequence into the GUI-based batch window
    [filename,pathname] = uigetfile('*.btc', 'Enter a filename to get batch from');
    if(filename==0), runstruct = []; return; end;
    batchfields = fieldnames(handles.batch(1));
    for i=1:length(batchfields)
        eval(['runstruct(1).' batchfields{i} '='''';']);
    end
    fid = fopen(fullfile2(pathname,filename));
    try
        res = textscan(fid, '%s%s', 'commentstyle', '%','delimiter','=');
        cnt = 0;
        for i=1:length(res{1})
            if length(res{1}{i})>=3 && strcmp(res{1}{i}(1:3),'job')
                cnt = cnt+1;
            else
                if ~isempty(str2num(res{2}{i}))
                    eval(['runstruct(' num2str(cnt) ').' res{1}{i} '=[' res{2}{i} '];']);
                else
                    eval(['runstruct(' num2str(cnt) ').' res{1}{i} '=[' char(39) res{2}{i} char(39) '];']);
                end
            end
        end
    catch
        runstruct = [];
        errordlg('Problems reading batch file');
        return;
    end
    fclose(fid);
end

function batchrun(runstruct)
    % runs the GUI-based batch sequence, takes "runstruct" - an array, each
    % element of which is a structure, containing a single task, each task
    % includes running detection in a given range with specified parameters
    global filenametmp
    n = length(runstruct);
    
    for job=1:n
        try
        % Parameters are only loaded from screen, not from file
        % No FM4-64 / extra data can be used (TODO: implement)
        cellListN = [];
        cellList = oufti_initializeCellList();
        savefile='';
        % load TIFF images
        if ~isempty(runstruct(job).bloadsgn1) && isdir(runstruct(job).bloadsgn1)
            folder = runstruct(job).bloadsgn1;
            loadimages(1,folder)
        end
        % if ~isempty(runstruct(job).bloadsgn2) && isdir(runstruct(job).bloadsgn2)
        %     folder = runstruct(job).bloadsgn2;
        %     loadimages(2,folder)
        % end
        if ~isempty(runstruct(job).bloadsgn3) && isdir(runstruct(job).bloadsgn3)
            folder = runstruct(job).bloadsgn3;
            loadimages(3,folder)
        end
        if ~isempty(runstruct(job).bloadsgn4) && isdir(runstruct(job).bloadsgn4)
            folder = runstruct(job).bloadsgn4;
            loadimages(4,folder)
        end
        % load images from stack files
        if ~isempty(runstruct(job).bloadsgn1)
            d = dir(runstruct(job).bloadsgn1);
            if ~isempty(d) && length(d)==1 && ~d.isdir
                loadstackdisp(1,runstruct(job).bloadsgn1);
            end
        end
        % if ~isempty(runstruct(job).bloadsgn2)
        %     d = dir(runstruct(job).bloadsgn2);
        %     if ~isempty(d) && length(d)==1 && ~d.isdir
        %         loadstackdisp(2,runstruct(job).bloadsgn2);
        %     end
        % end
        if ~isempty(runstruct(job).bloadsgn3)
            d = dir(runstruct(job).bloadsgn3);
            if ~isempty(d) && length(d)==1 && ~d.isdir
                loadstackdisp(3,runstruct(job).bloadsgn3);
            end
        end
        if ~isempty(runstruct(job).bloadsgn4)
            d = dir(runstruct(job).bloadsgn4);
            if ~isempty(d) && length(d)==1 && ~d.isdir
                loadstackdisp(4,runstruct(job).bloadsgn4);
            end
        end
        % load the rest of the data (meshes, parameters)
        if ~isempty(runstruct(job).bloadmesh)
            filename = runstruct(job).bloadmesh;
            loadmesh(filename);
        end
        if ~isempty(runstruct(job).bloadparam)
            filename = runstruct(job).bloadparam;
            loadparam(filename); % normally outputs the text read
        end
        if ~isempty(runstruct(job).bsavemesh)
            savefile = runstruct(job).bsavemesh;
        else
            for i=1:1000
                if isempty(dir(['tempCellListFile' num2str(i,'%.3d') '.mat']))
                    savefile = ['tempCellListFile' num2str(i,'%.3d') '.mat'];
                    break
                end
            end
        end
       
        imsizes = updateimsizes(imsizes);
        range = [1 imsizes(end,3)]; % range of frames
        if isfield(runstruct(job),'bstart') && ~isempty(runstruct(job).bstart), range(1)=runstruct(job).bstart; end
        if isfield(runstruct(job),'bend') && ~isempty(runstruct(job).bend), range(2)=runstruct(job).bend; end

        if isfield(runstruct(job),'bsubtr3') && ~isempty(runstruct(job).bsubtr3) && runstruct(job).bsubtr3
            subtractbgr(3,range)
        end
        if isfield(runstruct(job),'bsubtr4') && ~isempty(runstruct(job).bsubtr4) && runstruct(job).bsubtr4
            subtractbgr(4,range)
        end        
        
        mode = runstruct(job).mode; % 1-tlapse, 2-1st indep, 3-all indep, 4-reuse
        lst = []; % sorry, no running on a list of cells in graphical batch mode
        addsig=[runstruct(job).badd1 0 runstruct(job).badd3 runstruct(job).badd4];
        addas = []; % sorry, only standard signal names in graphical batch mode
        fsave = []; % saving either on each frame or never
        
        if runstruct(job).baddprev && range(1)>1 && oufti_getLengthOfCellList(cellList)>=range(1)-1 && oufti_doesFrameExist(range(1)-1, cellList)
            process(range(1)-1,4,lst,addsig,addas,'',0,get(handles.saveselected,'Value'),regionSelectionRect,shiftfluo,filenametmp,get(handles.highThroughput,'Value'));
        end
        
        process(range,mode,lst,addsig,addas,savefile,fsave,get(handles.saveselected,'Value'),regionSelectionRect,shiftfluo,filenametmp,get(handles.highThroughput,'Value'));
        % Main processing function
        % 
        % "range" - range of frames to run, can be []-all frames
        % "mode" - 1-tlapse, 2-1st ind, 3-all ind, 4-reuse
        % "lst" - list of cells on the frame previous to range(1)
        % "addsig" - [0 0 0 0]=[0 0 0]=[0 0]=0=[]-no signal, 1st one phase, etc. 
        % "addas" - default {}={0,-,1,2}, if numeric X, creates signalX, else - X
        % "savefile" - filename to save to
        % "fsave" - frequance of saving, n-once per n frames, 0-never, []-end
        catch err
        disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
        disp(err.message)
        continue;
        end
        
    end
    updateslider
    displayImage
    displayCells
    selDispList = [];
    displaySelectedCells
    enableDetectionControls
end



function batchstructupdate(gui2str)
    % if gui2str==true, updates "batchstruct" based on "handles.batch"
    % states, otherwise updates "handles.batch" states based on "batchstruct"
    if gui2str
        batchfields = fieldnames(handles.batch(1));
        for i=1:length(batchfields)
            eval(['if isempty(batchstruct) || ~isfield(batchstruct(1),''' batchfields{i} '''), batchstruct(1).' batchfields{i} '=''''; end']);
        end
        for k=1:length(handles.batch)
            batchstruct(k).bloadsgn1chk = get(handles.batch(k).bloadsgn1chk,'Value');
            batchstruct(k).bloadsgn3chk = get(handles.batch(k).bloadsgn3chk,'Value');
            batchstruct(k).bloadsgn4chk = get(handles.batch(k).bloadsgn4chk,'Value');
            batchstruct(k).bsubtr3 = get(handles.batch(k).bsubtr3,'Value');
            batchstruct(k).bsubtr4 = get(handles.batch(k).bsubtr4,'Value');
            batchstruct(k).mode = get(handles.batch(k).mode(1),'Value') + ...
                3*get(handles.batch(k).mode(3),'Value') + 4*get(handles.batch(k).mode(4),'Value');
            batchstruct(k).bstart = str2num(get(handles.batch(k).bstart,'String'));
            batchstruct(k).bend = str2num(get(handles.batch(k).bend,'String'));
            batchstruct(k).badd1 = get(handles.batch(k).badd1,'Value');
            batchstruct(k).badd3 = get(handles.batch(k).badd3,'Value');
            batchstruct(k).badd4 = get(handles.batch(k).badd4,'Value');
            batchstruct(k).baddprev = get(handles.batch(k).baddprev,'Value');
        end
    else
        d = length(batchstruct)-length(handles.batch);
        if d>0, for k=1:d, addBatchPanel; end; end
        if d<0, for k=1:-d, remBatchPanel; end; end
        for k=1:length(batchstruct)
            set(handles.batch(k).bloadsgn1,'String',slashsplit(batchstruct(k).bloadsgn1));
            % set(handles.batch(k).bloadsgn2,'String',slashsplit(batchstruct(k).bloadsgn2));
            set(handles.batch(k).bloadsgn3,'String',slashsplit(batchstruct(k).bloadsgn3));
            set(handles.batch(k).bloadsgn4,'String',slashsplit(batchstruct(k).bloadsgn4));
            set(handles.batch(k).bloadmesh,'String',slashsplit(batchstruct(k).bloadmesh));
            set(handles.batch(k).bloadparam,'String',slashsplit(batchstruct(k).bloadparam));
            set(handles.batch(k).bsavemesh,'String',slashsplit(batchstruct(k).bsavemesh));
            if ~isempty(batchstruct(k).bsubtr3), set(handles.batch(k).bsubtr3,'Value',batchstruct(k).bsubtr3); end
            if ~isempty(batchstruct(k).bsubtr4), set(handles.batch(k).bsubtr4,'Value',batchstruct(k).bsubtr4); end
            set(handles.batch(k).mode(batchstruct(k).mode),'Value',1);
            set(handles.batch(k).bstart,'String',batchstruct(k).bstart);
            set(handles.batch(k).bend,'String',batchstruct(k).bend);
            if ~isempty(batchstruct(k).badd1), set(handles.batch(k).badd1,'Value',batchstruct(k).badd1); end
            if ~isempty(batchstruct(k).badd3), set(handles.batch(k).badd3,'Value',batchstruct(k).badd3); end
            if ~isempty(batchstruct(k).badd4), set(handles.batch(k).badd4,'Value',batchstruct(k).badd4); end
            if ~isempty(batchstruct(k).baddprev), set(handles.batch(k).baddprev,'Value',batchstruct(k).baddprev); end
            if isfield(batchstruct(k),'bloadsgn1chk') && ~isempty(batchstruct(k).bloadsgn1chk) && batchstruct(k).bloadsgn1chk
                set(handles.batch(k).bloadsgn1chk,'Value',1);
                set(handles.batchc(k).bloadsgn1,'String','file','Tooltipstring','Select stack file with phase contrast images');
            else
                set(handles.batch(k).bloadsgn1chk,'Value',0);
                set(handles.batchc(k).bloadsgn1,'String','folder','Tooltipstring','Select folder with phase contrast images in TIFF format');
            end
            if isfield(batchstruct(k),'bloadsgn3chk') && ~isempty(batchstruct(k).bloadsgn3chk) && batchstruct(k).bloadsgn3chk
                set(handles.batch(k).bloadsgn3chk,'Value',1);
                set(handles.batchc(k).bloadsgn3,'String','file','Tooltipstring','Select stack file with signal 1 images');
            else
                set(handles.batch(k).bloadsgn3chk,'Value',0);
                set(handles.batchc(k).bloadsgn3,'String','folder','Tooltipstring','Select folder with signal 1 images in TIFF format');
            end
            if isfield(batchstruct(k),'bloadsgn4chk') && ~isempty(batchstruct(k).bloadsgn4chk) && batchstruct(k).bloadsgn4chk
                set(handles.batch(k).bloadsgn4chk,'Value',1);
                set(handles.batchc(k).bloadsgn4,'String','file','Tooltipstring','Select stack file with signal 2 images');
            else
                set(handles.batch(k).bloadsgn4chk,'Value',0);
                set(handles.batchc(k).bloadsgn4,'String','folder','Tooltipstring','Select folder with signal 2 images in TIFF format');
            end
        end
    end
end

function batchloadfile(hObject, eventdata)%#ok<INUSD>
    % callback to select files/folders in each panel of the batch mode
    n = length(handles.batch);
    for k=1:n
        % selecting folders / files
        if hObject==handles.batchc(k).bloadsgn1 && ~get(handles.batch(k).bloadsgn1chk,'Value')
            signalFolder = uigetdir(imageFolders{1},'Select Directory with Phase Images...');
            if(signalFolder==0), return; end;
            imageFolders{1} = signalFolder;
            batchstruct(k).bloadsgn1 = signalFolder;
            set(handles.batch(k).bloadsgn1,'String',slashsplit(signalFolder))
        end
        % if hObject==handles.batchc(k).bloadsgn2
        %     signalFolder = uigetdir(imageFolders{2},'Select Directory with Extra Images...');
        %     if(signalFolder==0), return; end;
        %     imageFolders{2} = signalFolder;
        %     batchstruct(k).bloadsgn2 = signalFolder;
        %     set(handles.batch(k).bloadsgn2,'String',slashsplit(signalFolder))
        % end
        if hObject==handles.batchc(k).bloadsgn3 && ~get(handles.batch(k).bloadsgn3chk,'Value')
            signalFolder = uigetdir(imageFolders{3},'Select Directory with Signal 1 Images...');
            if(signalFolder==0), return; end;
            imageFolders{3} = signalFolder;
            batchstruct(k).bloadsgn3 = signalFolder;
            set(handles.batch(k).bloadsgn3,'String',slashsplit(signalFolder))
        end
        if hObject==handles.batchc(k).bloadsgn4 && ~get(handles.batch(k).bloadsgn4chk,'Value')
            signalFolder = uigetdir(imageFolders{4},'Select Directory with Signal 2 Images...');
            if(signalFolder==0), return; end;
            imageFolders{4} = signalFolder;
            batchstruct(k).bloadsgn4 = signalFolder;
            set(handles.batch(k).bloadsgn4,'String',slashsplit(signalFolder))
        end
        if hObject==handles.batchc(k).bloadmesh
            [filename,pathname] = uigetfile('*.mat', 'Enter a filename to get meshes from');
            if(filename==0), return; end;
            filename = fullfile2(pathname,filename);
            batchstruct(k).bloadmesh = filename;
            set(handles.batch(k).bloadmesh,'String',slashsplit(filename))
        end
        if hObject==handles.batchc(k).bloadparam
            [filename,pathname] = uigetfile({'*.set';'*.mat'}, 'Enter a filename to get parameters from',paramFile);
            if(filename==0), return; end;
            filename = fullfile2(pathname,filename);
            paramFile = filename;
            batchstruct(k).bloadparam = filename;
            set(handles.batch(k).bloadparam,'String',slashsplit(filename))
        end
        if hObject==handles.batchc(k).bsavemesh
            [filename,pathname] = uiputfile('*.mat', 'Enter a filename to save the result (mesh) to',meshFile);
            if(filename==0), return; end;
            filename = fullfile2(pathname,filename);
            meshFile = filename;
            batchstruct(k).bsavemesh = filename;
            set(handles.batch(k).bsavemesh,'String',slashsplit(filename))
        end
        % selecting stack files
        if hObject==handles.batchc(k).bloadsgn1 && get(handles.batch(k).bloadsgn1chk,'Value')
            [filename,pathname] = uigetfile('*.*','Select Stack File with Phase Images...',fileparts(imageFiles{1}));
            if isequal(filename,0), return; end;
            fullfilename = fullfile(pathname,filename);
            imageFiles{1} = fullfilename;
            batchstruct(k).bloadsgn1 = fullfilename;
            set(handles.batch(k).bloadsgn1,'String',filename)
        elseif hObject==handles.batchc(k).bloadsgn3 && get(handles.batch(k).bloadsgn3chk,'Value')
            [filename,pathname] = uigetfile('*.*','Select Stack File with Signal 1 Images...',fileparts(imageFiles{3}));
            if isequal(filename,0), return; end;
            fullfilename = fullfile(pathname,filename);
            imageFiles{3} = fullfilename;
            batchstruct(k).bloadsgn3 = fullfilename;
            set(handles.batch(k).bloadsgn3,'String',filename)
        elseif hObject==handles.batchc(k).bloadsgn4 && get(handles.batch(k).bloadsgn4chk,'Value')
            [filename,pathname] = uigetfile('*.*','Select Stack File with Signal 2 Images...',fileparts(imageFiles{4}));
            if isequal(filename,0), return; end;
            fullfilename = fullfile(pathname,filename);
            imageFiles{4} = fullfilename;
            batchstruct(k).bloadsgn4 = fullfilename;
            set(handles.batch(k).bloadsgn4,'String',filename)
        end
        % removing selected folders / files by clicking on them
        if hObject==handles.batch(k).bloadsgn1
            batchstruct(k).bloadsgn1 = '';
            set(handles.batch(k).bloadsgn1,'String','')
        end
        % if hObject==handles.batch(k).bloadsgn2
        %     batchstruct(k).bloadsgn2 = '';
        %     set(handles.batch(k).bloadsgn2,'String','')
        % end
        if hObject==handles.batch(k).bloadsgn3
            batchstruct(k).bloadsgn3 = '';
            set(handles.batch(k).bloadsgn3,'String','')
        end
        if hObject==handles.batch(k).bloadsgn4
            batchstruct(k).bloadsgn4 = '';
            set(handles.batch(k).bloadsgn4,'String','')
        end
        if hObject==handles.batch(k).bloadmesh
            batchstruct(k).bloadmesh = '';
            set(handles.batch(k).bloadmesh,'String','')
        end
        if hObject==handles.batch(k).bloadparam
            batchstruct(k).bloadparam = '';
            set(handles.batch(k).bloadparam,'String','')
        end
        if hObject==handles.batch(k).bsavemesh
            batchstruct(k).bsavemesh = '';
            set(handles.batch(k).bsavemesh,'String','')
        end
        % modifying TIFF / stack loading bottons depending on checkboxes
        if hObject==handles.batch(k).bloadsgn1chk && get(handles.batch(k).bloadsgn1chk,'Value')
            set(handles.batchc(k).bloadsgn1,'String','file','Tooltipstring','Select stack file with phase contrast images');
            batchstruct(k).bloadsgn1 = '';
            set(handles.batch(k).bloadsgn1,'String','')
        elseif hObject==handles.batch(k).bloadsgn1chk && ~get(handles.batch(k).bloadsgn1chk,'Value')
            set(handles.batchc(k).bloadsgn1,'String','folder','Tooltipstring','Select folder with phase contrast images in TIFF format');
            batchstruct(k).bloadsgn1 = '';
            set(handles.batch(k).bloadsgn1,'String','')
        elseif hObject==handles.batch(k).bloadsgn3chk && get(handles.batch(k).bloadsgn3chk,'Value')
            set(handles.batchc(k).bloadsgn3,'String','file','Tooltipstring','Select stack file with signal 1 images');
            batchstruct(k).bloadsgn3 = '';
            set(handles.batch(k).bloadsgn3,'String','')
        elseif hObject==handles.batch(k).bloadsgn3chk && ~get(handles.batch(k).bloadsgn3chk,'Value')
            set(handles.batchc(k).bloadsgn3,'String','folder','Tooltipstring','Select folder with signal 1 images in TIFF format');
            batchstruct(k).bloadsgn3 = '';
            set(handles.batch(k).bloadsgn3,'String','')
        elseif hObject==handles.batch(k).bloadsgn4chk && get(handles.batch(k).bloadsgn4chk,'Value')
            set(handles.batchc(k).bloadsgn4,'String','file','Tooltipstring','Select stack file with signal 2 images');
            batchstruct(k).bloadsgn4 = '';
            set(handles.batch(k).bloadsgn4,'String','')
        elseif hObject==handles.batch(k).bloadsgn4chk && ~get(handles.batch(k).bloadsgn4chk,'Value')
            set(handles.batchc(k).bloadsgn4,'String','folder','Tooltipstring','Select folder with signal 2 images in TIFF format');
            batchstruct(k).bloadsgn4 = '';
            set(handles.batch(k).bloadsgn4,'String','')
        end
    end
end

% --- End of batch processing nested functions ---

% --- GUI zoom and display nested functions ---

function resizefcn(hObject, eventdata)%#ok<INUSD>
    % resizes the main program window
    global handles1
    screenSize = get(0,'ScreenSize');
    pos = get(hFig,'position');
    %pos = get(hObject,'position');
    pos = [max(pos(1),1) max(1,min(pos(2),screenSize(4)-20-max(pos(4),600))) max(pos(3:4),[1000 600])];
    %hFig.pos = pos;
    set(hObject,'position',pos);
    set(handles.loadpanel,'pos', [3 pos(4)-800+772 770 29]);
    set(handles.operationButtonsPanel,'pos' , [pos(3)-1000+795 pos(4)-800+770 190 29]);
    set(handles.savemeshpanel,'pos' , [pos(3)-1000+780 pos(4)-800+365 216 72]);
    set(handles.btnspanel,'pos',[pos(3)-1000+780 pos(4)-800+445 216 bhght]);
    if isfield(handles1,'spotFinderPanel')
        set(handles1.spotFinderPanel,'pos',[pos(3)-1000+725 pos(4)-800+485 272 250]);    
    end
    if isfield(handles1,'objectDetectionPanel')
        set(handles1.objectDetectionPanel,'pos',[pos(3)-1000+725 pos(4)-840+485 272 290]);
    end
    set(handles.impanel,'pos' , [17 170 pos(3)-1000+700 pos(4)-800+600]);
    set(handles.imslider,'pos' , [2 170 15 pos(4)-800+600]);

    if pos(4)>=800
        set(handles.parampanel,'pos' , [pos(3)-1000+780 pos(4)-800+57 216 280]);
        set(handles.testpanel,'pos' ,[pos(3)-1000+780 pos(4)-800+5 216 55]);
        set(handles.paramtitle,'pos' , [7 280 200 20]);
        set(handles.params,'pos' , [7 31 200 240]);
    else
        set(handles.parampanel,'pos' , [pos(3)-1000+780 57 216 pos(4)-800+280]);
        set(handles.testpanel,'pos' , [pos(3)-1000+780 5 216 55]);
        set(handles.paramtitle,'pos' , [7 pos(4)-800+280 200 20]);
        set(handles.params,'pos' ,[7 31 200 pos(4)-800+240]);
    end
    
end

function dispcolorcontrol(hObject, eventdata)%#ok<INUSD>
    % changes meshes color variable depending on the selection
    if get(handles.color1,'value') == 1, dispMeshColor= [1 1 1]; end
    if get(handles.color2,'value') == 1, dispMeshColor= [0 0 0]; end
    if get(handles.color3,'value') == 1, dispMeshColor=[0 1 0]; end
    if get(handles.color4,'value') == 1, dispMeshColor=[1 1 0]; end
    for i=1:length(handles.cells)
        if isempty(find(i-selectedList==0,1)) && length(handles.cells)>=i && ~isempty(handles.cells{i})
            set(handles.cells{i},'color',dispMeshColor)
        end
    end
end

function dispmeshcontrol(hObject, eventdata)%#ok<INUSD>
    if get(handles.mesh0,'value')       == 1, meshDispMode=0; end
    if get(handles.mesh1,'value')       == 1, meshDispMode=1; end
    if get(handles.mesh2,'value')       == 1, meshDispMode=2; end
    if get(handles.mesh3,'value')       == 1, meshDispMode=3; end
    selDispList = [];
    displayCells();
    displaySelectedCells();
end

function dispimgcontrol(hObject, eventdata)%#ok<INUSD>
    
    if get(handles.dispph,'Value')==1, imageDispMode=1; end
    % if get(handles.dispfm,'Value')==1, imageDispMode=2; end
    if get(handles.disps1,'Value')==1, imageDispMode=3; end
    if get(handles.disps2,'Value')==1, imageDispMode=4; end
    displayImage();
    selDispList = [];
    displayCells();
    displaySelectedCells();
end

function zoomcheck(hObject, eventdata)%#ok<INUSD>
    if ishandle(handles.hfig)
        if get(handles.zoomcheck,'Value')==1
            showhfig
        else
            hidehfig
        end
    end
end

function hfigclosereq(hObject, eventdata)%#ok<INUSD>
    set(handles.zoomcheck,'Value',0);
    hidehfig();
end

function zoominout(hObject, eventdata)
    if hObject == handles.zoomin
        magnification = magnification*1.5;
    elseif hObject == handles.zoomout
        magnification = max(iniMagnification/100,magnification/1.5);
    elseif hObject == handles.hfig
        if eventdata.VerticalScrollCount>0
            magnification = magnification*1.5;
        else
            magnification = max(1,magnification/1.5);
        end
    end
    apiMB = iptgetapi(handles.hMagBox);
    apiMB.setMagnification(magnification);
    apiSP = iptgetapi(handles.hpanel);
    apiSP.setMagnification(magnification);
end

function hidehfig
    set(handles.hfig,'Visible','off');
    magnification = sscanf(get(handles.hMagBox,'String'),'%d')/100;
    apiMB = iptgetapi(handles.hMagBox);
    apiMB.setMagnification(0.1);
    apiSP = iptgetapi(handles.hpanel);
    zoomlocation = apiSP.getVisibleLocation();
    apiSP.setMagnification(0.1);
    set(handles.hMagBox,'Enable','off');
    set(handles.zoomin,'Enable','off');
    set(handles.zoomout,'Enable','off');
end

function showhfig
    set(handles.hfig,'Visible','on');
    apiMB = iptgetapi(handles.hMagBox);
    apiMB.setMagnification(magnification);
    apiSP = iptgetapi(handles.hpanel);
    apiSP.setMagnification(magnification);
    if ~isempty(zoomlocation), apiSP.setVisibleLocation(zoomlocation); end
    set(handles.hMagBox,'Enable','on');
    set(handles.zoomin,'Enable','on');
    set(handles.zoomout,'Enable','on');
end


function resizelogfcn(hObject, eventdata)%#ok<INUSD>
    figuresize = get(handles.gdispfig,'pos');
    set(handles.wnd,'pos',[1 1 figuresize(3:4)]);
end

function closelogreq(hObject, eventdata)%#ok<INUSD>
    set(handles.gdispfig,'visible','off')
    set(handles.logcheck,'Value',0);
end

% --- End of GUI zoom and display nested functions ---

function displayImage
    global rawPhaseData rawS1Data rawS2Data
    img = [];
    imsizes = updateimsizes(imsizes);
    %if max(imsizeMAX)<1, return; end
    if frame<1, frame=1; end
    switch imageDispMode
     case 1
         
         if ~isempty(who('rawPhaseData'))
             if ~isempty(rawPhaseData)
                 if frame<=imsizes(1,3)
                    img = rawPhaseData(:,:,frame);
                 end
             end
         end
    %  case 2
    %      if ~isempty(who('rawFMData'))
    %          if ~isempty(rawFMData)
    %              if frame<=imsizes(2,3)
    %                  img = rawFMData(:,:,frame);
    %              end
    %          end
    %      end
     case 3
         
         if ~isempty(who('rawS1Data'))
             if ~isempty(rawS1Data)
                 if frame<=imsizes(3,3)
                    img = rawS1Data(:,:,frame);
                 end
             end
         end
     case 4
        
         if ~isempty(who('rawS2Data'))
             if ~isempty(rawS2Data)
                 if frame<=imsizes(4,3)
                    img = rawS2Data(:,:,frame);
                 end
             end
         end
     otherwise
        %gdisp('No image loaded')
        %return
    end
    if isempty(img), img = ones(imsizes(end,1:2)); end
    %figure(handles.maingui);
    dellist = [];
    if ishandle(handles.hpanel)
        apiSP = iptgetapi(handles.hpanel);
        %magnification = apiSP.getMagnification();
        zoomlocation = apiSP.getVisibleLocation();
        dellist{1} = handles.hMagBox;
        dellist = [dellist {get(handles.hfig,'Children')}];
        dellist = [dellist {get(handles.impanel,'Children')}];
    end
    if strcmp(get(handles.zoomin,'Enable'),'off')
        set(handles.zoomcheck,'Enable','on');
        set(handles.zoomin,'Enable','on');
        set(handles.zoomout,'Enable','on');
    end
    if get(handles.zoomcheck,'Value')==0 && strcmp(get(handles.hfig,'Visible'),'on')
        set(handles.hfig,'Visible','off');
    elseif get(handles.zoomcheck,'Value')==1 && strcmp(get(handles.hfig,'Visible'),'off')
        set(handles.hfig,'Visible','on');
    end
    if ~isempty(dellist),
        for i=1:length(dellist)
            if ishandle(dellist{i})
                delete(dellist{i})
            end
        end
    else
        %screenSize = get(0,'ScreenSize');
        iniMagnification = 100;
        if size(img,2)<0.75*screenSize(4) || size(img,1)<0.75*screenSize(3)
            iniMagnification = min(100,floor(75*min(screenSize(4)/size(img,1),screenSize(3)/size(img,2))));
        end
        magnification = iniMagnification/100;
    end
    ax = axes('parent',handles.hfig);
    %drawnow(); pause(0.005);%java.lang.Thread.sleep(100);
    if ~ishandle(ax), ax = axes('parent',handles.hfig); disp('Error creating axes'); end
    if ~ishandle(ax), disp('Image display terminated: cannot create axes'); return; end
    pos = get(handles.hfig,'pos');
    warning('off','images:initSize:adjustingMag') % ('off','backtrace');
    handles.himage = imshow(img,imageLimits{imageDispMode},'parent',ax,'ini',iniMagnification);
    %drawnow(); pause(0.005);%java.lang.Thread.sleep(10);
    if ~ishandle(handles.himage), disp('Image display terminated: cannot create h-image'); return; end
    %warning on % ('on','backtrace');
    set(handles.hfig,'pos',pos);
    handles.hpanel = imscrollpanel(handles.hfig,handles.himage);
    %drawnow(); pause(0.005);%java.lang.Thread.sleep(10);
    if ~ishandle(handles.hpanel), disp('Image display terminated: cannot create h-panel'); return; end
    set(handles.hpanel,'Units','normalized','Position',[0 0 1 1]);
    handles.hMagBox = immagbox(handles.zoompanel,handles.himage);
    set(handles.hMagBox,'Position',[50 63 60 20]);
    handles.hovervw = imoverviewpanel(handles.impanel,handles.himage);
    %set(get(get(hh,'UIContextMenu'),'Children'),'Visible','off') 
    %drawnow(); %pause(0.005);%java.lang.Thread.sleep(10);
    apiMB = iptgetapi(handles.hMagBox);
    apiSP = iptgetapi(handles.hpanel);
    if get(handles.zoomcheck,'Value')==0, 
        set(handles.hMagBox,'Enable','off');
        set(handles.zoomin,'Enable','off');
        set(handles.zoomout,'Enable','off');
        apiMB.setMagnification(0.1);
        apiSP.setMagnification(0.1);
    else
        apiMB.setMagnification(magnification);
        apiSP.setMagnification(magnification);
        if ~isempty(zoomlocation), apiSP.setVisibleLocation(zoomlocation); end
    end
    imstring1 = {'ph','fm','s1','s2'};
    if imageActive(imageDispMode)==false
        fname = slashsplit2(imageFolders{imageDispMode});
    else
        fname = slashsplit2(imageFiles{imageDispMode});
    end
    set(handles.currentimage,'String',[fname ' (' imstring1{imageDispMode} ')']);
    if ishandle(groupSelectionRectH), delete(groupSelectionRectH); end;
    tmp = get(get(handles.impanel,'children'),'children');

    if iscell(tmp), tmp=tmp{1}; end
    ax(2) = tmp;
    if regionSelectionMode && ~isempty(regionSelectionRect)
        groupSelectionRectH = [];
        for i=1:2
            groupSelectionRectH = [groupSelectionRectH rectangle('Parent',ax(i),'Position', ...
                        regionSelectionRect,'EdgeColor',[1 0 0],'LineStyle','-')];%#ok<AGROW>
        end
    else
        groupSelectionRectH = [];  groupSelectionPosition = [];
    end
end
        
function imslider(hObject, EventType)%#ok<INUSD>
    
    try
        prevframe = frame;
        %pause(0.05);
        %pause(0.1);
        tmpFrame = imsizes(end,3)+1-round(get(hObject,'value'));
        frame = tmpFrame;
        displayImage();
        set(handles.currentframe,'String',[num2str(frame) ' of ' num2str(imsizes(end,3))]);
        displayCells();
        selectedList = selNewFrame(selectedList,prevframe,frame);
        selDispList = [];
        displaySelectedCells();
        showCellData();
    catch
        return;
    end
end

function updateslider
    
    imsizes = updateimsizes(imsizes);
    s = imsizes(end,3);
    frame = max(min(frame,s),1);
    if s>1 
        set(handles.imslider,'min',1,'max',s,'Value',s+1-frame,'SliderStep',[1/(s-1) 1/(s-1)],'Enable','on');
        set(handles.currentframe,'String',[num2str(frame) ' of ' num2str(s)]);
    else
        set(handles.imslider,'min',1,'max',s,'Value',s+1-frame,'SliderStep',[0 1],'Enable','on');
        set(handles.currentframe,'String',[num2str(frame) ' of ' num2str(s)]);
    end
end

function displayCells

    if ~isfield(handles,'himage'), disp('Cells display terminated: no image handle'); return; end
    if ~ishandle(handles.himage), disp('Cells display terminated: wrong image handle'); return; end
    if ~isempty(handles.cells)
        for i=1:length(handles.cells)
            if ishandle(handles.cells{i})
                delete(handles.cells{i});
            end
        end
        handles.cells = {};
    end
    if meshDispMode==0, return; end
    if ~oufti_doesFrameExist(frame, cellList), return; end
    if min(imsizes(end,:))<1, return; end
    if ~ishandle(handles.hfig), return; end
    ax = get(get(handles.impanel,'children'),'children');
    ah = ~ishandle(ax);
    if ah(1) && ~iscell(ax), disp('Cells display terminated: cannot create axes'); return; end
    if iscell(ax), ax = ax{1}; end;
    ax(2) = get(handles.himage,'parent');
    handles.cells = [];
    col = dispMeshColor;
    % k=1 is main window,
    % k=2 is zoomed image
    [cells, displaycellList] = oufti_getFrame(frame, cellList);
   
    set(ax(1),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add');
    set(ax(2),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add');
    for ii = 1:length(nonzeros(displaycellList))
        celln = displaycellList(ii);
        idPos = oufti_cellId2PositionInFrame(celln, frame, cellList);
        cell = cells{ii};
        if oufti_doesCellStructureHaveMesh(celln,frame,cellList)
            mesh = double(cell.mesh);
             if get(handles.disps1,'Value')==1, mesh(:,[1 3])=mesh(:,[1 3])+shiftfluo(1,1); mesh(:,[2 4])=mesh(:,[2 4])+shiftfluo(1,2); end
             if get(handles.disps2,'Value')==1, mesh(:,[1 3])=mesh(:,[1 3])+shiftfluo(2,1); mesh(:,[2 4])=mesh(:,[2 4])+shiftfluo(2,2); end
            if meshDispMode==3
                plt2k1 = plot(ax(1),mesh(:,[1 3])',mesh(:,[2 4])','color',col); %[0.5 0.5 1]
                plt2k2 = plot(ax(2),mesh(:,[1 3])',mesh(:,[2 4])','color',col); %[0.5 0.5 1]
            elseif meshDispMode==2
                e = round(size(mesh,1)/2);
                plt2k1 = text(round(mean([mesh(e,1);mesh(e,3)])),...
                    round(mean([mesh(e,2);mesh(e,4)])),...
                    num2str(celln),'HorizontalAlignment','center','FontSize',7,'color',col ...
                    ,'parent',ax(1));
                plt2k2 = text(round(mean([mesh(e,1);mesh(e,3)])),...
                    round(mean([mesh(e,2);mesh(e,4)])),...
                    num2str(celln),'HorizontalAlignment','center','FontSize',7,'color',col ...
                    ,'parent',ax(2));
            elseif meshDispMode==1
                plt2k1 = [];
                plt2k2 = [];
            end
            plt1k1 = plot(ax(1),mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4),'color',col);
            plt1k2 = plot(ax(2),mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4),'color',col);
            if ~isfield(cell,'polarity'), cell.polarity=0; end
            if ~isfield(cell,'timelapse'), cell.timelapse=0; end
            if cell.polarity && cell.timelapse
                plt3k1 = plot(ax(1),[mesh(1,1) 7*mesh(1,1)-3*mesh(3,1)-3*mesh(3,3)],[mesh(1,2) 7*mesh(1,2)-3*mesh(3,2)-3*mesh(3,4)],'color',col);
                plt3k2 = plot(ax(2),[mesh(1,1) 7*mesh(1,1)-3*mesh(3,1)-3*mesh(3,3)],[mesh(1,2) 7*mesh(1,2)-3*mesh(3,2)-3*mesh(3,4)],'color',col);
            else
                plt3k1 = [];
                plt3k2 = [];
            end
            
            handles.cells{idPos} = [plt1k1;plt2k1;plt3k1];
            handles.cells{idPos} = [handles.cells{idPos};plt1k2;plt2k2;plt3k2];
            

        elseif isfield(cell,'contour') || isfield(cell,'model') && size(cell.model,1)>1
            if meshDispMode==1 || meshDispMode==2 || meshDispMode==3
                try
                    ctrx = cell.contour(:,1);
                    ctry = cell.contour(:,2);
                catch
                    ctrx = cell.model(:,1);
                    ctry = cell.model(:,2);
                end
                pltk1 = plot(ax(1),ctrx,ctry,'color',col);
                pltk2 = plot(ax(2),ctrx,ctry,'color',col);
            else
                continue
            end
            if meshDispMode==2
                cntx = mean(ctrx);
                cnty = mean(ctry);
                plt2k1 = text(double(cntx),double(cnty),num2str(celln),'HorizontalAlignment','center','FontSize',7,'color',col...
                    ,'parent',ax(1));
                plt2k2 = text(double(cntx),double(cnty),num2str(celln),'HorizontalAlignment','center','FontSize',7,'color',col...
                    ,'parent',ax(2));
                pltk1 = [pltk1;plt2k1]; %#ok<AGROW>
                pltk2 = [pltk2;plt2k2]; %#ok<AGROW>
            end

            handles.cells{idPos} = pltk1;
            handles.cells{idPos} = [handles.cells{idPos};pltk2];
        end
        try
            if isfield(cellList.meshData{frame}{ii},'objects') && ~isempty(cellList.meshData{frame}{ii}.objects) && ...
                    isfield(cellList.meshData{frame}{ii}.objects,'outlines') && ~isempty(cellList.meshData{frame}{ii}.objects.outlines) 
                for outlines = 1:numel(cellList.meshData{frame}{ii}.objects.outlines)
                      plot(ax(1),cellList.meshData{frame}{ii}.objects.outlines{outlines}(:,1),cellList.meshData{frame}{ii}.objects.outlines{outlines}(:,2),'color','m');
                      plot(ax(2),cellList.meshData{frame}{ii}.objects.outlines{outlines}(:,1),cellList.meshData{frame}{ii}.objects.outlines{outlines}(:,2),'color','m');
                end
            end
        catch
           
        end
    end;
    xlim(ax(1),[0 imsizes(end,2)]);
    ylim(ax(2),[0 imsizes(end,1)]);
    xlim(ax(1),[0 imsizes(end,2)]);
    ylim(ax(2),[0 imsizes(end,1)]);
  
    if isempty(handles.cells), handles.cells = {}; end
    if isfield(cellList,'objectData')
        try
            displayObjects(frame);
        catch
            return;
        end
    end
end

function displayCellsForDrag(celln)
    if ~isfield(handles,'himage'), disp('Cells display terminated: no image handle'); return; end
    if ~ishandle(handles.himage), disp('Cells display terminated: wrong image handle'); return; end
    if ~isempty(handles.cells)
        for i=1:length(handles.cells)
            if ishandle(handles.cells{i})
                delete(handles.cells{i});
            end
        end
        handles.cells = {};
    end
    if meshDispMode==0, return; end
    if ~oufti_doesFrameExist(frame, cellList), return; end
    if min(imsizes(end,:))<1, return; end
    if ~ishandle(handles.hfig), return; end
    ax = get(get(handles.impanel,'children'),'children');
    ah = ~ishandle(ax);
    if ah(1) && ~iscell(ax), disp('Cells display terminated: cannot create axes'); return; end
    if iscell(ax), ax = ax{1}; end;
    ax(2) = get(handles.himage,'parent');
    handles.cells = [];
    col = dispMeshColor;
    % k=1 is main window,
    % k=2 is zoomed image

    for k=1:2
        set(ax(k),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add');
            
            idPos = oufti_cellId2PositionInFrame(celln, frame, cellList);
            cell = cellList.meshData{frame}{idPos};
            if isfield(cell,'mesh') && size(cell.mesh,1)>1
                mesh = double(cell.mesh);
                if meshDispMode==3
                    plt2 = plot(ax(k),mesh(:,[1 3])',mesh(:,[2 4])','color',col);
                elseif meshDispMode==2
                    e = round(size(mesh,1)/2);
                    plt2 = text(round(mean([mesh(e,1);mesh(e,3)])),...
                        round(mean([mesh(e,2);mesh(e,4)])),...
                        num2str(celln),'HorizontalAlignment','center','FontSize',7,'color',col...
                        ,'parent',ax(k));
                elseif meshDispMode==1
                    plt2 = [];
                end
                plt1 = plot(ax(k),mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4),'color',col);
                if ~isfield(cell,'polarity'), cell.polarity=0; end
                if cell.polarity
                    plt3 = plot(ax(k),[mesh(1,1) 7*mesh(1,1)-3*mesh(3,1)-3*mesh(3,3)],[mesh(1,2) 7*mesh(1,2)-3*mesh(3,2)-3*mesh(3,4)],'color',col);
                else
                    plt3 = [];
                end
                if k==1
                    handles.cells{idPos} = [plt1;plt2;plt3];
                else
                    handles.cells{idPos} = [handles.cells{idPos};plt1;plt2;plt3];
                end

            elseif isfield(cell,'model') && size(cell.model,1)>1
                if meshDispMode==1 || meshDispMode==2 || meshDispMode==3
                    ctrx = cell.model(:,1);
                    ctry = cell.model(:,2);
                    plt = plot(ax(k),ctrx,ctry,'color',col);
                else
                    continue
                end
                if meshDispMode==2
                    cntx = mean(ctrx);
                    cnty = mean(ctry);
                    plt2 = text(cntx,cnty,num2str(celln),'HorizontalAlignment','center','FontSize',7,'color',col...
                        ,'parent',ax(k));
                    plt = [plt;plt2]; %#ok<AGROW>
                end

                if k==1
                    handles.cells{idPos} = plt;
                else
                    handles.cells{idPos} = [handles.cells{idPos};plt];
                end
            end
        
        xlim(ax(k),[0 imsizes(end,2)]);
        ylim(ax(k),[0 imsizes(end,1)]);
    end
    if isempty(handles.cells), handles.cells = {}; end
end

function updateorientation(celln)
   % this function redraws a cell
    idPos = oufti_cellId2PositionInFrame(celln, frame, cellList);
    if ~oufti_doesCellExist(celln, frame, cellList)
        if idPos <= length(handles.cells) && max(ishandle(handles.cells{idPos})==1), delete(handles.cells{idPos}); end
        return
    end   
    if ~ishandle(handles.hfig), return; end
    ax = get(get(handles.impanel,'children'),'children');
    if iscell(ax), ax = ax{1}; end;
    ax(2) = get(handles.himage,'parent');
    if length(handles.cells)>=idPos, delete(handles.cells{idPos}); end
    if meshDispMode==0, return; end
    if ismember(celln,selDispList)
        meshcolor = dispSelColor;
    else
        meshcolor = dispMeshColor;
    end
    cell = oufti_getCellStructure(celln, frame, cellList);
    if isfield(cell,'mesh') && size(cell.mesh,1)>4
        mesh = double(cell.mesh);
        for k=1:2
            set(ax(k),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add');
            if meshDispMode==3
                plt2 = plot(ax(k),mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4),mesh(:,[1 3])',mesh(:,[2 4])','LineWidth', 3, 'color',meshcolor);
            elseif meshDispMode==2
                e = round(size(mesh,1)/2);
                plt2 = text(round(mean([mesh(e,1);mesh(e,3)])),round(mean([mesh(e,2);mesh(e,4)])),...
                    num2str(celln),'HorizontalAlignment','center','FontSize',7,'color',meshcolor,'parent',ax(k));
            elseif meshDispMode==1
                plt2 = [];
            end
            plt1 = plot(ax(k),mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4),'color',meshcolor);
            if ~isfield(cell,'polarity'), cell.polarity=0; end
            if cell.polarity
                plt3 = plot(ax(k),[mesh(1,1) 7*mesh(1,1)-3*mesh(3,1)-3*mesh(3,3)],[mesh(1,2) 7*mesh(1,2)-3*mesh(3,2)-3*mesh(3,4)],'color',meshcolor);
            else
                plt3 = [];
            end
            if k==1
                handles.cells{idPos} = [plt1;plt2;plt3];
            else
                handles.cells{idPos} = [handles.cells{idPos};plt1;plt2;plt3];
            end
            xlim(ax(k),[0 imsizes(end,2)]);
            ylim(ax(k),[0 imsizes(end,1)]);
        end
    elseif isfield(cell,'model') && size(cell.model,1)>1
        ctrx = cell.model(:,1);
        ctry = cell.model(:,2);
        for k=1:2
            if meshDispMode==1 || meshDispMode==2 || meshDispMode==3
                plt = plot(ax(k),ctrx,ctry,'color',meshcolor);
            else
                return
            end
            if meshDispMode==2
                cntx = mean(ctrx);
                cnty = mean(ctry);
                plt2 = text(double(cntx),double(cnty),num2str(celln),'HorizontalAlignment','center','FontSize',7,'LineWidth',3, 'color',meshcolor,'parent',ax(k));
                plt = [plt;plt2]; %#ok<AGROW>
            end
            if k==1
                handles.cells{idPos} = plt;
            else
                handles.cells{idPos} = [handles.cells{idPos};plt];
            end
            xlim(ax(k),[0 imsizes(end,2)]);
            ylim(ax(k),[0 imsizes(end,1)]);
        end
    end
end
function displaySelectedCells
    % remove cells from selDispList that are not displayed any more
    i=1;
    while i<=length(selDispList)
        iNr = selDispList(i);
        idPos = oufti_cellId2PositionInFrame(iNr, frame, cellList);
        if isempty(selectedList) || length(selectedList)==1 ||...
                isempty(find((selectedList-iNr)==0,1))
            if ~isempty(idPos) && length(handles.cells)>=idPos && ~isempty(handles.cells{idPos})
                set(handles.cells{idPos},'color',dispMeshColor);
                selDispList = selDispList([1:i-1 i+1:end]);
            else
                selDispList = selDispList([1:i-1 i+1:end]);
            end    
        else
            i=i+1;
        end
    end
    % add newly selected cells
    addlist = [];
    
    for i=1:length(selectedList)
        iNr = selectedList(i);
        idPos = oufti_cellId2PositionInFrame(iNr, frame, cellList);
        if isempty(idPos), continue; end
        if isempty(find((selDispList-iNr)==0,1))
            %isroot = 0;
            addlist = [addlist iNr];%#ok<AGROW>
            if length(handles.cells)>=idPos && ~isempty(handles.cells{idPos})
                set(handles.cells{idPos},'color',dispSelColor);
            end
        end
    end
    selDispList = [selDispList addlist];
 
end

function showCellData
    % this function displays statistics on the selected cell(s)
    slist = selectedList;
    selectedList = [];
    for i=1:length(slist)
        if oufti_doesCellExist(slist(i), frame, cellList)
            selectedList = [selectedList slist(i)];%#ok<AGROW>
        end
    end
    
    if isempty(selectedList) || ~oufti_doesFrameExist(frame, cellList)
        set(handles.currentcellsT,'String','Selected cell:');
        set(handles.currentcells,'String','No cells selected');
        set(handles.ancestors,'String','');
        set(handles.descendants,'String','');
        set(handles.divisions,'String','');
        set(handles.stage,'String','');
        set(handles.celldata.length,'String','');
        set(handles.celldata.area,'String','');
        set(handles.celldata.volume,'String','');
        set(handles.celldata.width,'String','');
    elseif length(selectedList)==1
        set(handles.currentcellsT,'String','Selected cell:');
        celldata = oufti_getCellStructure(selectedList, frame, cellList);
        celldata = getextradata(celldata);
        set(handles.currentcells,'String',[num2str(selectedList) ' of ' num2str(oufti_getFrameLength(frame, cellList))]);
        if isempty(celldata.ancestors), d='No ancestors'; else d=num2str(celldata.ancestors); end; set(handles.ancestors,'String',d);
        if isempty(celldata.descendants), d='No descendants'; else d=num2str(celldata.descendants); end; set(handles.descendants,'String',d);
        if isempty(celldata.divisions), d='No divisions'; else d=num2str(celldata.divisions); end; set(handles.divisions,'String',d);
        %set(handles.stage,'String',num2str(celldata.stage));
        if isfield(celldata,'area') && isfield(celldata,'length'), if isempty(celldata.area) || isempty(celldata.length), d=''; else d=num2str(celldata.area/celldata.length,'%.2f'); end; else d='No data'; end; set(handles.celldata.width,'String',d);
        if isfield(celldata,'length'), if isempty(celldata.length), d=''; else d=num2str(celldata.length,'%.2f'); end; else d='No data'; end; set(handles.celldata.length,'String',d);
        if isfield(celldata,'area'), if isempty(celldata.area), d=''; else d=num2str(celldata.area,'%.1f'); end; else d='No data'; end; set(handles.celldata.area,'String',d);
        if isfield(celldata,'volume'), if isempty(celldata.volume), d=''; else d=num2str(celldata.volume,'%.1f'); end; else d='No data'; end; set(handles.celldata.volume,'String',d);
    else
        set(handles.currentcellsT,'String','Selected cells:');
        set(handles.currentcells,'String',[num2str(length(selectedList)) ' cells']);
        set(handles.ancestors,'String','');
        set(handles.descendants,'String','');
        set(handles.divisions,'String','');
        meanwidth = [];
        meanlength = [];
        meanarea = [];
        meanvolume = [];
        for i=1:length(selectedList)
            cell = selectedList(i);
            celldata = oufti_getCellStructure(cell, frame, cellList);
            celldata = getextradata(celldata);
            if isfield(celldata,'area') && isfield(celldata,'length') && ~isempty(celldata.area) && ~isempty(celldata.length), meanwidth=[meanwidth celldata.area/celldata.length]; end%#ok<AGROW>
            if isfield(celldata,'length') && ~isempty(celldata.length), meanlength=[meanlength celldata.length]; end%#ok<AGROW>
            if isfield(celldata,'area') && ~isempty(celldata.area), meanarea=[meanarea celldata.area]; end%#ok<AGROW>
            if isfield(celldata,'volume') && ~isempty(celldata.volume), meanvolume=[meanvolume celldata.volume]; end%#ok<AGROW>
        end
        if ~isempty(meanwidth), d=[num2str(mean(meanwidth),'%.2f') ' (mean)']; else d=''; end; set(handles.celldata.width,'String',d);
        if ~isempty(meanlength), d=[num2str(mean(meanlength),'%.2f') ' (mean)']; else d=''; end; set(handles.celldata.length,'String',d);
        if ~isempty(meanarea), d=[num2str(mean(meanarea),'%.2f') ' (mean)']; else d=''; end; set(handles.celldata.area,'String',d);
        if ~isempty(meanvolume), d=[num2str(mean(meanvolume),'%.2f') ' (mean)']; else d=''; end; set(handles.celldata.volume,'String',d);
    end
end

function wndmainkeyrelease(hObject,eventdata)%#ok<INUSD>
    if ~isempty(eventdata.Key)
        if strcmp(eventdata.Key,'shift')
            isShiftPressed = 0;
        end
    end
end

function wndmainkeypress(hObject, eventdata)%#ok<INUSD>
    isShiftPressed = 0;
    if ~isempty(eventdata.Modifier)
        for i=1:length(eventdata.Modifier)
            if strcmp(eventdata.Modifier{i},'shift')
                isShiftPressed = 1;
            end
        end
    end
end
function modeSelection(hObject,eventdata)
    if strcmpi(hObject.SelectedObject.String,'Independent frames')
        set(handles.saveEachFrame,'Enable','off');
    elseif strcmpi(hObject.SelectedObject.String,'Time lapse')
        set(handles.saveEachFrame,'Enable','on');
    elseif strcmpi(hObject.SelectedObject.String,'Reuse meshes')
        set(handles.saveEachFrame,'Enable','off');
    end
    
    
    
end
function mainkeypress(hObject, eventdata)
    % key press callback
    if hObject==handles.hfig
        c = get(handles.hfig,'CurrentCharacter');
    else
        c = hFig.CurrentCharacter;
    end
    
    if isempty(c), return; end
    if double(c)==127 && hObject~=handles.selectgroupedit % delete key - deletes selected cells
        delselected(hObject, eventdata)
    elseif strcmp(c,'i') || double(c)==9
        invselection(hObject, eventdata)
    elseif strcmp(c,'a') || double(c)==1
        selectall(hObject, eventdata)
    elseif strcmp(c,'g') || double(c)==7
        selectgroup(hObject, eventdata)
    elseif strcmp(c,'q') || double(c)==113
        saveloadselection(0) % save selected cells
    elseif strcmp(c,'w') || double(c)==119
        saveloadselection(1) % save as selected cells
    elseif strcmp(c,'e') || double(c)==101
        saveloadselection(2) % load selected cells
    elseif double(c)==30 % up key - moves to the previous frame
        set(handles.imslider,'value',min(imsizes(end,3),get(handles.imslider,'value')+1));
        imslider(handles.imslider, eventdata)
    elseif double(c)==31 % down key - moves to the next frame
        set(handles.imslider,'value',max(1,get(handles.imslider,'value')-1));
        imslider(handles.imslider, eventdata)
    elseif strcmp(c,'s') || double(c)==19
        saveLoadMesh_cbk(handles.savemesh,eventdata)
    elseif strcmp(c,'l') || double(c)==12
        saveLoadMesh_cbk(handles.loadmesh,eventdata)
    elseif double(c)==13 && size(cellDrawPositions,1)>=2 % Enter - finish manually adding a cell
        saveundo;
        makeCellFromPoints(isShiftPressed);
    elseif double(c)==27 && ~isempty(cellDrawPositions) % Escape - terminate manually adding a cell
        cellDrawPositions = [];
        if ishandle(cellDrawObjects), delete(cellDrawObjects); end
        cellDrawObjects = [];
    elseif double(c)==27 && splitSelectionMode % Escape - terminate splitting regime if no cell has been selected
        splitSelectionMode = false;
        disp('Manual splitting regime terminated');
    elseif double(c)==26 % Control+Z - undo a manual operation
        doundo;
    elseif strcmp(c,'f') || double(c)==102
        shiftfluomfn % set/change shiftfluo
    elseif strcmp(c,'r') || double(c)==114
        saveloadshiftfluo(2) % save shiftfluo
    elseif strcmp(c,'t') || double(c)==116
        saveloadshiftfluo(2) % save as shiftfluo
    elseif strcmp(c,'y') || double(c)==121
        saveloadshiftfluo(2) % load shiftfluo
    end
end

function shiftfluomfn
    if get(handles.dispph,'Value')==1 || isempty(cellList.meshData) || isempty(cellList.meshData{1}), return; end
    if get(handles.disps1,'Value')==1, xy=shiftfluo(1,:); else xy=shiftfluo(2,:); end
    handles.shift.menu = figure('pos',[screenSize(3)/2-100 screenSize(4)/2-200 250 150],'Toolbar','none','Menubar','none','Name','Shift meshes','NumberTitle','off','IntegerHandle','off','Resize','off','Color',get(handles.imslider,'BackgroundColor'));
    uicontrol(handles.shift.menu,'units','pixels','Position',[5 120 240 15],'Style','text','String','Select shift size for fluorescence images','FontWeight','bold','HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.shift.menu,'units','pixels','Position',[25 90 11 15],'Style','text','String','x:','FontWeight','bold','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.shift.x = uicontrol(handles.shift.menu,'units','pixels','Position',[40 90 80 19],'Style','edit','String',num2str(xy(1)),'BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.shift.menu,'units','pixels','Position',[130 90 11 15],'Style','text','String','y:','FontWeight','bold','HorizontalAlignment','right','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.shift.y = uicontrol(handles.shift.menu,'units','pixels','Position',[145 90 80 19],'Style','edit','String',num2str(xy(2)),'BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.shift.menu,'units','pixels','Position',[56 40 140 25],'Style','pushbutton','String','Shift','FontWeight','bold','HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10,'callback',@shiftfluofn);
end
function shiftfluofn(hObject, eventdata)%#ok<INUSD>
    x = str2num(get(handles.shift.x,'string'));
    y = str2num(get(handles.shift.y,'string'));
    if isempty(x) || isempty(y), return; end
    if get(handles.disps1,'Value')==1
        shiftfluo(1,:) = [x y];
    end
    if get(handles.disps2,'Value')==1
        shiftfluo(2,:) = [x y];
    end
    displayCells
    displaySelectedCells
end

function saveloadselection(mode)
    if mode==0 && ~isempty(selectFile) % save
        save(selectFile,'selectedList')
        if isempty(selectedList)
            disp('Empty list of selected cells saved to file')
        else
            disp('The list of selected cells saved to file')
        end
    end
    if mode==1 || (mode==0 && isempty(selectFile)) % save as
        [filename,pathname] = uiputfile2('*.mat', 'Enter a filename to save the list of selected cells to',selectFile);
        if isequal(filename,0), return; end;
        if length(filename)<=4
            filename = [filename '.mat'];
        elseif ~strcmp(filename(end-3:end),'.mat')
            filename = [filename '.mat'];
        end
        selectFile = fullfile2(pathname,filename);
        save(selectFile,'selectedList')
        if isempty(selectedList)
            disp('Empty list of selected cells saved to file')
        else
            disp('The list of selected cells saved to file')
        end
    elseif mode==2 % load
        [filename,pathname] = uigetfile2('*.mat', 'Enter a filename to get the list of selected cells from',selectFile);
        if(filename==0), return; end;
        selectFile = fullfile2(pathname,filename);
        l = load(selectFile,'selectedList');
        if isempty(fields(l))
            disp('No data loaded: no the list of selected cells in this file')
        else
            selectedList = l.selectedList;
            disp('List of selected cells loaded from file')
            displaySelectedCells
        end
    end
end

function saveloadshiftfluo(mode)
    if mode==0 && ~isempty(shiftfluoFile) % save
        save(shiftfluoFile,'shiftfluo')
        if sum(sum(shiftfluo.^2))==0
            disp('Signal shift data with no shift saved to file')
        else
            disp('Signal shift data saved to file')
        end
    end
    if mode==1 || (mode==0 && isempty(shiftfluoFile)) % save as
        [filename,pathname] = uiputfile2('*.mat', 'Enter a filename to save the list of selected cells to',shiftfluoFile);
        if isequal(filename,0), return; end;
        if length(filename)<=4
            filename = [filename '.mat'];
        elseif ~strcmp(filename(end-3:end),'.mat')
            filename = [filename '.mat'];
        end
        shiftfluoFile = fullfile2(pathname,filename);
        save(shiftfluoFile,'shiftfluo')
        if sum(sum(shiftfluo.^2))==0
            disp('Signal shift data with no shift saved to file')
        else
            disp('Signal shift data saved to file')
        end
    elseif mode==2 % load
        [filename,pathname] = uigetfile2('*.mat', 'Enter a filename to get the list of selected cells from',shiftfluoFile);
        if(filename==0), return; end;
        shiftfluoFile = fullfile2(pathname,filename);
        l = load(shiftfluoFile,'shiftfluo');
        if isempty(fields(l))
            disp('No data loaded: no signal shift data (shiftfluo) in this file')
        else
            shiftfluo = l.shiftfluo;
            disp('Signal shift data loaded from file')
            if get(handles.disps1,'Value')==1 || get(handles.disps2,'Value')==1, displayCells; displaySelectedCells; end
        end
    end
end

function delselected(hObject, eventdata)%#ok<INUSD>
numFrames = oufti_getLengthOfCellList(cellList);
if numFrames < 1 || isempty(selectedList)
   return;
end
saveundo;
choiceSelection = questdlg('Time Lapse?',...
                     'Study','Yes','No','No');
choiceSelection2 = '';
 switch choiceSelection
     case 'No'
            if get(handles.deleteselframe,'Value') || get(handles.runmode3,'value')
                range = frame;
            else
                disp('Select "Independent Frames" mode');
                return;
            end
     case 'Yes'
         if get(handles.runmode1,'value') && ~get(handles.deleteselframe,'Value')
                range = [1:(frame-1) (frame):numFrames frame];
                choiceSelection2 = questdlg('Delete Offspring?',...
                                            'Study','Yes','No','No');
         elseif get(handles.runmode1,'value') && get(handles.deleteselframe,'Value')
             range = frame; 
         else
             disp('Select "Time lapse" mode');
             return;
         end
     otherwise
         if ~get(handles.runmode3,'value') && ~get(handles.runmode1,'value')
            disp('Either "Time lapse" or "Independent frames" mode not selected')
            return;
         else
             return;
         end
 end            
    
for frm = range
    if oufti_isFrameNonEmpty(frm, cellList)
       for celln = selectedList;
           if oufti_doesCellExist(celln, frm, cellList)
               %---------------------------------------------------------------------------------
               %this portion of the code removes the offspring of a cell
               %being deleted if specified by the user.  This routine is
               %only for timelapse experiments.
               if strcmpi(choiceSelection2,'yes')
                   cellStructure = oufti_getCellStructure(celln,frm,cellList);
                   if ~isempty(cellStructure.descendants)
                       selectedList = [selectedList cellStructure.descendants]; %#ok<AGROW>
                       for offSpring = cellStructure.descendants 
                           cellList = oufti_removeCellStructureFromCellList(offSpring,frm,cellList);
                       end
                   end
               end
               %---------------------------------------------------------------------------------
              cellList = oufti_removeCellStructureFromCellList(celln, frm, cellList);
           end
       end
    end
end
selectedList = [];
displayCells
displaySelectedCells
showCellData
end

function invselection(hObject, eventdata)%#ok<INUSD>
if ~oufti_doesFrameExist(frame, cellList), return; end
    
lst = [];
[~, ids] = oufti_getFrame(frame, cellList);
for celln=ids
    if oufti_isCellStructureGood(celln, frame, cellList) && ...
       ~ismember(celln, selectedList)
       lst = [lst celln];%#ok<AGROW>
    end
end
selectedList = lst;
displaySelectedCells()
showCellData()
end

function selectall(hObject, eventdata)%#ok<INUSD>
if  ~oufti_doesFrameExist(frame, cellList), return; end
selectedList = [];
if ~isShiftPressed
% select all
   [~, ids] = oufti_getFrame(frame, cellList);
   for celln=ids
        if oufti_isCellStructureGood(celln, frame, cellList)
            selectedList = [selectedList, celln];%#ok<AGROW>
        end
   end
end
    displaySelectedCells
    showCellData
end

function selectgroup(hObject, eventdata)%#ok<INUSD>
    if ~oufti_doesFrameExist(frame, cellList), return; end
    range = str2num(get(handles.selectgroupedit,'String'));
    if isempty(range), disp('No cells selected: incorrect range'); return; end
        for celln=range
        % Changed '<' to '<=' below.
            if oufti_isCellStructureGood(celln, frame, cellList)
            selectedList = [selectedList celln(~ismember(celln,selectedList))];%#ok<AGROW>
            end
        end
displaySelectedCells
showCellData
end
%*****************************************************************************
%update:  Ahmad Paintdakhi July 2, 2014, this routine is for 
%browing directly to a frame specified instead of going through scrollbar,
%which is convenient for large data sets.
function selectFrame(hObject, eventdata)%#ok<INUSD>
    frame = str2double(get(handles.selectgroupedit,'String'));
    drawnow();pause(0.005);
    displayImage();
    set(handles.currentframe,'String',[num2str(frame) ' of ' num2str(imsizes(end,3))]);
    displayCells();
    selectedList = selNewFrame(selectedList,prevframe,frame);
    selDispList = [];
    displaySelectedCells();
    showCellData();
    updateslider();
end
%*****************************************************************************
function manual_cbk(hObject, eventdata)%#ok<INUSD>
    % callback for manual operations (joining, splitting, refining, adding)
%     selectedList = sort(selectedList);
    global cellsToDragHistory 
    
    listOfCells = [];
    for ii = 1:length(selectedList)
        listOfCells.erase(ii) = oufti_cellId2PositionInFrame(selectedList(ii),frame,cellList);
    end
    edit2p
    if hObject==handles.join
        if ~oufti_doesFrameExist(frame, cellList) || oufti_isFrameEmpty(frame, cellList)
            disp('Joining failed: no cells in this frame'); return
        end
        if length(selectedList)<2, disp('Joining failed: At least two cells must be selected'); return; end
        c1 = oufti_getCellStructure(selectedList(1),frame, cellList);
        c2 = oufti_getCellStructure(selectedList(2),frame, cellList);
        if ~isempty(c1.descendants) && c2.descendants(end)==selectedList(1)
            lstt=selectedList(1);
            selectedList(1)=selectedList(2);
            selectedList(2)=lstt;
        end
        outBoolean = forcejoincells(frame,selectedList);
        if outBoolean
            saveundo;
            selDispList = [];
            % updateorientation(lst(1))
            listOfCells.add = oufti_cellId2PositionInFrame(selectedList(1),frame,cellList);
            displayCellsForManualOperations(listOfCells,1);
            updateorientation(selectedList(1));
            %displayCells();
            displaySelectedCells();
            showCellData();
            return;
        end
    elseif hObject==handles.split
        if isShiftPressed % splitting position form a click
            disp('Manual splitting regime: select the splitting point by clicking on it');
            splitSelectionMode = true;
            return;
        else % finding splitting position automatically
            choiceSelection = questdlg('Time Lapse?',...
                     'Study','Yes','No','No');   
            if isempty(cellList.meshData) || length(cellList.meshData)<frame || isempty(cellList.meshData{frame})
                disp('Splitting failed: no cells in this frame'); return
            end
            if length(selectedList)~=1, disp('Splitting failed: Exactly one cell must be selected'); return; end
            [lst,cellList] = forcesplitcell(frame,selectedList,[],cellList);
            switch choiceSelection
                     case 'Yes'
                         for ii = frame+1:length(cellList.meshData)
                             cellList = oufti_removeCellStructureFromCellList(selectedList,ii,cellList);
                         end
            end
        end
        if length(lst)==2
            saveundo;            selDispList = [];
            selectedList = lst;
        end
         for ii = 1:length(selectedList)
            listOfCells.add(ii) = oufti_cellId2PositionInFrame(selectedList(ii),frame,cellList);
         end
         if length(listOfCells.add) == 2
            displayCellsForManualOperations(listOfCells,1);
         else
            displayCells();
         end
        displaySelectedCells();
    elseif hObject==handles.refine
        if isempty(cellList.meshData) || length(cellList.meshData)<frame || isempty(cellList.meshData{frame})
            disp('Refining failed: no cells in this frame'); return
        end
        if isempty(selectedList) && isempty(cellsToDragHistory), disp('Refining failed: At least one cell must be selected'); return; end
        saveundo;
        refinecell(frame,selectedList);
        displaySelectedCells();
    elseif hObject==handles.addcell && ~get(handles.addcell,'Value')
        cellDrawPositions = [];
        if ishandle(cellDrawObjects), delete(cellDrawObjects); end
        cellDrawObjects = [];
        % actual addition is done in makeCellFromPoints function
        
    elseif hObject==handles.drag && ~get(handles.drag,'value')
            if matlabpool('size') > 0, matlabpool close;end
    elseif hObject==handles.refineAll && get(handles.refineAll,'value')
        refineAllParallel(1:oufti_getLengthOfCellList(cellList),[]);
        displayCells();
    end
    for cell=selectedList, updateorientation(cell); end
% % % displayCells();
% % % displaySelectedCells();
showCellData();
end
function displayCellsForManualOperations(listOfCells,yesDraw)
    if ~isfield(handles,'himage'), disp('Cells display terminated: no image handle'); return; end
    if ~ishandle(handles.himage), disp('Cells display terminated: wrong image handle'); return; end
    plt2 = [];
    plt3 = [];
    plt1 = [];
    plt4 = [];
    if ~isempty(handles.cells)
        for i=1:length(listOfCells.erase)
            try
                    delete(handles.cells{listOfCells.erase(i)});
                     
            catch
                displayCells();
                return;
            end
        end
       
        if length(listOfCells.erase) == 2
            indexToDelete = listOfCells.erase ~= listOfCells.add;
            if ~isempty(listOfCells.erase)
                if sum(indexToDelete) == 2
                    for ii = 1:length(listOfCells.erase)
                        handles.cells{listOfCells.erase(indexToDelete(ii))} = '';
                    end
                else
                    handles.cells{listOfCells.erase(indexToDelete)} = '';
                end
            end
            indexArray = ~cellfun(@ischar,handles.cells);
            handles.cells = handles.cells(indexArray);
            if ~isempty(listOfCells.erase),handles.cells{listOfCells.add} = '';  end
        elseif sum(listOfCells.erase == listOfCells.add) == 1
            indexToDelete = listOfCells.erase == listOfCells.add;
            if ~isempty(listOfCells.erase),handles.cells{listOfCells.add(indexToDelete)} = '';  end
        else
            if ~isempty(listOfCells.erase),handles.cells{listOfCells.erase} = '';  end
            indexArray = ~cellfun(@ischar,handles.cells);
            handles.cells = handles.cells(indexArray);
        end
        
    end
    if meshDispMode==0, return; end
    if min(imsizes(end,:))<1, return; end
    if ~ishandle(handles.hfig), return; end
    ax = get(get(handles.impanel,'children'),'children');
    ah = ~ishandle(ax);
    if ah(1) && ~iscell(ax), disp('Cells display terminated: cannot create axes'); return; end
    if iscell(ax), ax = ax{1}; end;
    ax(2) = get(handles.himage,'parent');
    col = dispMeshColor;
    % k=1 is main window,
    % k=2 is zoomed image
  
    for jj = 1:length(listOfCells.add)
        try
            mesh = cellList.meshData{frame}{listOfCells.add(jj)}.mesh;
            set(ax(1),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add'); 
            set(ax(2),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add'); 
            if yesDraw
                if length(mesh) > 1
                    plt1 = plot(ax(1),mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4),'color',col);
                    plt4 = plot(ax(2),mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4),'color',col);
                end
            else
                plt1 = [];
                plt4 = [];
            end
        catch
            set(ax(1),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add'); 
            set(ax(2),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add'); 
            model = cellList.meshData{frame}{listOfCells.add(jj)}.model;
            if yesDraw
                if length(model(:,1)) > 1
                    plt1 = plot(ax(1),model(:,1),model(:,2),'color',col);
                    plt4 = plot(ax(2),model(:,1),model(:,2),'color',col);
                end
            else
                plt1 = [];
                plt4 = [];
            end
        end
        handles.cells{listOfCells.add(jj)} = [plt1;plt2;plt3];
        handles.cells{listOfCells.add(jj)} = [handles.cells{listOfCells.add(jj)};plt4;plt2;plt3];
        xlim(ax(1),[0 imsizes(end,2)]);
        ylim(ax(1),[0 imsizes(end,1)]);
        xlim(ax(2),[0 imsizes(end,2)]);
        ylim(ax(2),[0 imsizes(end,1)]);
    end

end
function forcesplitcellonclick(frame,celln,x,y)
    listOfCells = []; 
    listOfCells.erase = oufti_cellId2PositionInFrame(celln,frame,cellList);
    cell = oufti_cellId2PositionInFrame(celln,frame,cellList);
    l=projectToMesh(x,y,cellList.meshData{frame}{cell}.mesh);
    if isfield(cellList.meshData{frame}{cell},'lengthvector')
        l = sum(l>cellList.meshData{frame}{cell}.lengthvector);
    end
   
    [lst,cellList] = forcesplitcell(frame,celln,round(l),cellList);
    if length(lst)==2
        saveundo;
        selDispList = [];
        selectedList = lst;
    end
    for ii = 1:length(selectedList)
            listOfCells.add(ii) = oufti_cellId2PositionInFrame(selectedList(ii),frame,cellList);
    end
    displayCellsForManualOperations(listOfCells,1);
    if length(lst)==2
        updateorientation(lst(1))
        updateorientation(lst(2))
        displaySelectedCells
        showCellData
    else
        disp('Splitting failed');
    end
end

function saveundo
    if isfield(cellList,'meshData')
        if length(cellList.meshData)<frame, return; end
        undo.cellListFrame = cellList.meshData{frame};
        undo.cellId        = cellList.cellId{frame};
    else
        if length(cellList)<frame, return; end
        undo.cellListFrame = cellList{frame}; 
    end
    undo.selectedList = selectedList;
    undo.frame = frame;
end

function doundo
    if isempty(undo) || frame>imsizes(end,3)
        disp('Nothing to undo: no changes made')
    else
        if frame~=undo.frame
            frame = undo.frame;
            set(handles.imslider,'value',frame);
            imslider(handles.imslider, eventdata)
        end
        cellList.meshData{undo.frame} = undo.cellListFrame;
        cellList.cellId{undo.frame}   = undo.cellId;
        selectedList = undo.selectedList;
        selDispList = [];
        undo = [];
        displayCells
        displaySelectedCells
        showCellData
        disp('Meshes updated to the previous state')
    end
end

function polarity_cbk(hObject, eventdata)%#ok<INUSD>
    if hObject==handles.removepolarity && get(handles.removepolarity,'Value')
        set(handles.setpolarity,'Value',0)
    elseif hObject==handles.setpolarity && get(handles.setpolarity,'Value')
        set(handles.removepolarity,'Value',0)
    end
end

function selectclick(hObject, eventdata)%#ok<INUSD>
global p handles1 imageHandle spotlist cellsToDragHistory
     
if ~isempty(handles1) && isfield(handles1,'spotFinderPanel') && strcmp(get(handles1.spotFinderPanel,'Visible'),'on') 
   if isempty(imageHandle) || ~ishandle(imageHandle.fig) || isempty(spotlist), return; end
      ps = get(imageHandle.ax,'CurrentPoint');
      xlimit = get(imageHandle.ax,'XLim');
      ylimit = get(imageHandle.ax,'YLim');
      x = ps(1,1);
      y = ps(1,2);
      if x<xlimit(1) || x>xlimit(2) || y<ylimit(1) || y>ylimit(2), return; end
      dst = (y-spotlist(:,8)).^2+(x-spotlist(:,9)).^2;
      [mindst,minind] = min(dst);
      if mindst>mean(xlimit(2)-xlimit(1),ylimit(2)-ylimit(1))^2/10, return; end
      lst(minind) = ~lst(minind);
      handles1.spotList{handles1.frame}{handles1.cell}.lst(minind) = lst(minind);
      if lst(minind)
         set(imageHandle.spots(minind),'Color',[1 0.1 0]);
         disp('Selected spot:')
      else
         set(imageHandle.spots(minind),'Color',[0 0.8 0]);
         disp('Unselected spot:')
      end
    spotlist = handles1.spotList{handles1.frame}{handles1.cell}.spotlist;
    disp([' background: ' num2str(spotlist(minind,1))])
    disp([' squared width: ' num2str(spotlist(minind,2))])
    disp([' height: ' num2str(spotlist(minind,3))])
    disp([' relative squared error: ' num2str(spotlist(minind,4))])
    disp([' perimeter variance: ' num2str(spotlist(minind,5))])
    disp([' filtered/unfiltered ratio: ' num2str(spotlist(minind,6))])
else
     % determine whether Shift/Control/Alt has been pressed
     if hObject==handles.maingui
        ax = get(get(handles.impanel,'children'),'children');
        if iscell(ax), ax = ax{1}; end;
        extend = strcmpi(hFig.SelectionType,'extend');
        control = strcmpi(hFig.SelectionType,'alt');
        dblclick = strcmpi(hFig.SelectionType,'open');
     else
        if ~ishandle(handles.himage), return; end
        ax = get(handles.himage,'parent');
        extend = strcmpi(get(handles.hfig,'SelectionType'),'extend');
        control = strcmpi(get(handles.hfig,'SelectionType'),'alt');
        dblclick = strcmpi(get(handles.hfig,'SelectionType'),'open');
     end
     
     % update isShiftPressed
     if ~extend && ~dblclick, isShiftPressed = 0; end
     
     % determine the point clicked
     try
         ps = get(ax,'CurrentPoint');
         if ~isempty(ps)
            if ps(1,1)<0 || ps(1,1)>imsizes(end,2) || ps(1,2)<0 || ps(1,2)>imsizes(end,1), return; end;
     
             warning('off','MATLAB:warn_r14_stucture_assignment')
             pos.x = ps(1,1);
             pos.y = ps(1,2);
             %warning on
             % perform the actions
         end
     catch
     end
     flag = true;
     if oufti_doesFrameExist(frame, cellList) && ~oufti_isFrameEmpty(frame, cellList) && ~get(handles.addcell, 'Value')
    
         if ~extend && ~isempty(selectedList)
            selectedList = [];
        end
        
        if ~control
            [~, ids] = oufti_getFrame(frame, cellList);
            for celln=ids
                cell = oufti_getCellStructure(celln,frame,cellList);
                if oufti_doesCellStructureHaveMesh(celln, frame, cellList)
                    try
                   box = cell.box;
                    catch
                        return;
                    end
                    try
                    if inpolygon(pos.x,pos.y,[box(1) box(1) box(1)+box(3) box(1)+box(3)],[box(2) box(2)+box(4) box(2)+box(4) box(2)])
                        mesh = cell.mesh;
                        if inpolygon(pos.x,pos.y,[mesh(:,1);flipud(mesh(:,3))],[mesh(:,2);flipud(mesh(:,4))])
                            if get(handles.setpolarity,'Value') && ~splitSelectionMode % selecting stalk
                                flag = false;
                                mn = ceil(size(mesh,1)/2);
                                if inpolygon(pos.x,pos.y,[mesh(mn:end,1);flipud(mesh(mn:end,3))],[mesh(mn:end,2);flipud(mesh(mn:end,4))])
                                    if ~isfield(cell,'timelapse') || cell.timelapse || get(handles.runmode1,'value') % TODO correct
%                                         cellList.meshData = reorientall(cellList.meshData,celln,true);
                                          cellList = reorientall(cellList,celln,true);
                                    else
% %                                          cellList.meshData{frame}{cell} = reorient(cellList.meshData{frame}{cell});
% %                                          cellList.meshData{frame}{cell}.polarity = 1;
										cellList = oufti_addCell(celln,frame,reorient(cell),cellList);
										cellList = oufti_addFieldToCellList(celln,frame,'polarity',1,cellList);
                                    end
                                    updateorientation(celln)
                                    disp(['The orientation of cell ' num2str(celln) ' has been updated'])
                                else
                                    if ~isfield(cell,'timelapse') || cell.timelapse || get(handles.runmode1,'value')
%                                         cellList.meshData = reorientall(cellList.meshData,cell,false);
                                        cellList = reorientall(cellList,celln,false);
                                    else
%                                         cellList.meshData{frame}{cell}.polarity = 1;
										cellList = oufti_addFieldToCellList(celln,frame,'polarity',1,cellList);
                                    end
                                    updateorientation(celln)
                                    disp(['The orientation of cell ' num2str(celln) ' has been set'])
                                end
                            elseif get(handles.removepolarity,'Value') && ~splitSelectionMode % removing stalk
                                flag = false;
                                if ~isfield(cell,'timelapse') || cell.timelapse
%                                     cellList.meshData = removeorientationall(cellList.meshData,cell);
                                      cellList = removeorientationall(cellList,celln);
                                else
%                                     cellList.meshData{frame}{cell}.polarity = 0;
									cellList = oufti_addFieldToCellList(celln,frame,'polarity',0,cellList);
                                end
                                updateorientation(celln)
                                disp(['The orientation of cell ' num2str(celln) ' has been removed'])
                            elseif splitSelectionMode % selecting manual split position
                                splitSelectionMode = false;
                                forcesplitcellonclick(frame,celln,pos.x,pos.y)
                                return
                            else % selecting cell
                                flag = false;
                                if isempty(find((selectedList-celln)==0,1))
                                    % Adding a cell to selectedList
                                    selectedList = [selectedList, celln];%#ok<AGROW>
                                    if isShiftPressed == 0
                                        break;
                                    end
                                else
                                    % Removing a cell from selectedList
                                    [~,k] = find((selectedList-celln)==0,1);
                                    selectedList = selectedList([1:k-1 k+1:end]);
                                end
                            end
                        end
                    end
                    catch err
                        return;
                    end
                elseif isfield(cell,'model') && length(cell.model)>1 && ...
                        ~get(handles.setpolarity,'Value') && ~get(handles.removepolarity,'Value') % Using 'contour' instead of 'mesh'
                    box = cell.box;
                    if inpolygon(pos.x,pos.y,[box(1) box(1) box(1)+box(3) box(1)+box(3)],[box(2) box(2)+box(4) box(2)+box(4) box(2)])
                        contour = cell.model;
                        if inpolygon(pos.x,pos.y,contour(:,1),contour(:,2))
                            flag = false;
                            if p.algorithm == 1 && splitSelectionMode
                               disp('Cell with no mesh can not be splitted at this moment, deleted the cell and add the two cells manually');
                                return;
                            end
                            if isempty(find((selectedList-celln)==0,1))
                                selectedList = [selectedList, celln]; %#ok<AGROW>% Adding a cell to selectedList
                            else
                                [~,k] = find((selectedList-celln)==0,1);
                                selectedList = selectedList([1:k-1 k+1:end]); % Removing a cell from selectedList
                            end
                        end
                    end
                end
            end
        end
        displaySelectedCells();
        showCellData();
        %------------------------------------------------------------------
        %this statement checks if a drag selection is enabled upon which it
        %calls wbmcb and wbucb functions which perform drag operation of
        %cell mesh.  The dragging of cell meshes is perfromed by clicking
        %on a particular mesh and dragging to a desired position with the
        %left key of a mouse.  Once the mouse button is released then that
        %location becomed the new place of the dragged cell mesh.
        if ishandle(handles.drag) && get(handles.drag,'Value')
           cellsToDragHistory = [cellsToDragHistory selectedList];
           if strcmp(get(hObject,'SelectionType'),'normal')
              if ishandle(ax),cp = get(ax,'CurrentPoint');end
              if ishandle(handles.impanel),impanelStruct = struct(get(handles.impanel));end
              ax2 = get(impanelStruct.Children,'children');
              if iscell(ax2), ax2 = ax2{1}; end;
           
              pointHistoryX = cp(1,1);
              pointHistoryY = cp(1,2);
              set(hObject,'WindowButtonMotionFcn',@wbmcb)
              set(hObject,'WindowButtonUpFcn',@wbucb)
             
           end
        elseif ishandle(handles.drag) && ~get(handles.drag,'Value')
            cellsToDragHistory = [];
             
        else
            cellsToDragHistory = [];
        end
        %------------------------------------------------------------------
     end
     
     % terminate splitting regime if no cell has been selected
     if splitSelectionMode
         splitSelectionMode = false;
         disp('Manual splitting regime terminated');
     end
     
     % adding cells
     if get(handles.addcell,'Value') && ~dblclick && ~control && max(imsizes(1:3,1))>0
        if isempty(cellDrawPositions)
            edit2p;
            if ~isfield(p,'algorithm'), disp('Parameters not loaded or "algorithm" field missing'); return; end
            if ~ismember(p.algorithm,[1 4])
                disp('Adding cells is only inplemented for algorithms 1 and 4')
                return
            end
        end
        % adding next cell drawing point for manually adding cell
        flag = false;
        ax = get(get(handles.impanel,'children'),'children');
        ah = ~ishandle(ax);
        if ah(1) && ~iscell(ax), disp('Could not add point: cannot find axes'); return; end
        if iscell(ax), ax = ax{1}; end;
        ax(2) = get(handles.himage,'parent');
        cellDrawPositions = [cellDrawPositions;ps(1,1:2)];
        if ishandle(cellDrawObjects), delete(cellDrawObjects); end
        cellDrawObjects = [];
        for k=1:2
            set(ax(k),'NextPlot','add');
            cellDrawObjects = [cellDrawObjects plot(ax(k),cellDrawPositions(:,1),cellDrawPositions(:,2),'.-r')];%#ok<AGROW>
        end
        return
    end
    
    % finishing manually adding cell: adding last point
    if get(handles.addcell,'Value') && size(cellDrawPositions,2)>1 && dblclick && ~control
        flag = false;
        saveundo;
        makeCellFromPoints(isShiftPressed);
        return
    end
    
    % start selecting a group of cells
    if flag && (control || extend)
        groupSelectionMode = true;
        groupSelectionPosition = ps(1,1:2);
    end
    
    % start moving the field
    if flag && hObject==handles.hfig && ~extend && ~control
        dragMode = true;
        dragPosition = getmousepos;
    end
    
    if ishandle(groupSelectionRectH), delete(groupSelectionRectH); end
    groupSelectionRectH = [];
    regionSelectionRect = [];
end


%##########################################################################
function wbmcb(hObject,eventData) %#ok<INUSD>
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function wbmcb(hObject,eventData) %#ok<INUSD>
%Oufti.v0.3.1
%@modified: Ahmad J Paintdakhi July 15, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%
%**********Input********:
%
%purpose:  The function finds the current location of the mesh during drag
%process and updates the cell mesh and box values.         
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
if ishandle(ax),cp = get(ax,'CurrentPoint');end
if ishandle(ax2), cp2 = get(ax2,'CurrentPoint');end
if (cp2(1,1)> 0 && cp2(1,2)> 0 && cp2(1,2) < imsizes(end,1) && cp2(1,1) < imsizes(end,2) )
    pointHistoryX = [pointHistoryX cp(1,1)];
    pointHistoryY = [pointHistoryY cp(1,2)];
    xValue = pointHistoryX(end-1) - cp(1,1);
    yValue = pointHistoryY(end-1) - cp(1,2);
    if ~isempty(selectedList) && oufti_doesCellStructureHaveMesh(selectedList,frame,cellList)
        cellList.meshData{frame}{oufti_cellId2PositionInFrame...
            (selectedList,frame,cellList)}.mesh(:,[2 4]) = ...
            cellList.meshData{frame}{oufti_cellId2PositionInFrame...
            (selectedList,frame,cellList)}.mesh(:,[2 4]) - yValue;
        cellList.meshData{frame}{oufti_cellId2PositionInFrame...
                (selectedList,frame,cellList)}.mesh(:,[1 3]) = ...
                cellList.meshData{frame}{oufti_cellId2PositionInFrame...
                (selectedList,frame,cellList)}.mesh(:,[1 3]) - xValue;
        cellList.meshData{frame}{oufti_cellId2PositionInFrame...
                (selectedList,frame,cellList)}.box(1) = ...
                cellList.meshData{frame}{oufti_cellId2PositionInFrame...
                (selectedList,frame,cellList)}.box(1) - xValue;
        cellList.meshData{frame}{oufti_cellId2PositionInFrame...
                (selectedList,frame,cellList)}.box(2) = ...
                cellList.meshData{frame}{oufti_cellId2PositionInFrame...
                (selectedList,frame,cellList)}.box(2) - yValue;
        displayCellsForDrag(selectedList);
        displaySelectedCells();
    end
   
end
end
%##########################################################################


%##########################################################################
function wbucb(hObject,eventData) %#ok<INUSD>
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function wbucb(hObject,eventData) %#ok<INUSD>
%Oufti.v0.3.1
%@modified: Ahmad J Paintdakhi July 15, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%
%**********Input********:
%
%purpose:  The function finds the current location of the mesh during drag
%process and updates the cell mesh and box values.         
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
if strcmp(get(hObject,'SelectionType'),'normal')
   set(hObject,'Pointer','arrow')
   set(hObject,'WindowButtonMotionFcn',@mousemove)
   set(hObject,'WindowButtonUpFcn',@dragbutonup)
   displayCells();
else
   return
end

end
%##########################################################################

end%function selectclick

function makeCellFromPoints(askfornumber)
    % creating a cell from a series of points
    % for manual addition of cells
    global p %cellListN
    ctr = cellDrawPositions;
    cellDrawPositions = []; % clear used up data
    if ishandle(cellDrawObjects), delete(cellDrawObjects); end
    cellDrawObjects = [];
    if size(ctr,1)<2, return; end
        if p.getmesh, step = p.meshStep; else step = 1; end
        % the BACKBONE is defined by ctr coordinates
        width = p.cellwidth;
        d=diff(ctr,1,1);
        l=cumsum([0;sqrt((d.*d)*[1 ;1])]);
        [l,i]=unique(l);
        if length(l)<=1, return; end
        ctr0=interp1(l,ctr(i,:),linspace(0,l(end),floor(l(end)/step+1)));
        tolerance = 1;
        while true
            %p.meshStep,p.meshTolerance,p.meshWidth
            ctr0(end,:) = ctr(end,:);
            d = diff(ctr0,1,1);
            l = cumsum([0;sqrt((d.*d)*[1 ;1])]);
            ctr0 = spsmooth(l',ctr0',tolerance,linspace(0,l(end),floor(l(end)/step+1)))';
            ctrd = ctr0(1:end-2,:)/2+ctr0(3:end,:)/2-ctr0(2:end-1,:);
            if step^2/sqrt(max(sum(ctrd.^2,2)))>width*3 % ???
                H = ceil(width*pi/2/step/2);
                HA = H+1:-1:1;
                HA = pi*HA/(2*sum(HA)-HA(1));
                alpha = HA(H+1);
                x=zeros(1,H+1);
                y=zeros(1,H+1);
                for i=H:-1:1
                    x(i) = x(i+1) - step*cos(alpha);
                    y(i) = y(i+1) + step*sin(alpha);
                    alpha = HA(i) + alpha;
                end
                y = -(y-y(1))*width/y(1);
                x = x-x(1);
                d = diff(ctr0,1,1);
                l = cumsum([0;sqrt((d.*d)*[1 ;1])]);
                if l(end)/2<x(end)
                    q = x<l(end)/2;
                    y = [y(q) fliplr(y(q))];
                    x = [x(q) fliplr(l(end)-x(q))];
                else
                    y = [y(1:end-1) ones(1,floor(l(end)-2*x(end)+1))*width fliplr(y(1:end-1))];
                    x = [x(1:end-1) linspace(x(end),l(end)-x(end),floor(l(end)-2*x(end)+1)) l(end)-fliplr(x(1:end-1))];
                end
                ctr0 = interp1(l,ctr0,x);
                if size(ctr0,1)<3, disp('Cell too short'); return; end
                d2 = [[0 0]; ctr0(3:end,:)-ctr0(1:end-2,:); [0 0]];
                d2l = sqrt(sum(d2.^2,2))+1E-10;
                d3 = [d2(:,2)./d2l -d2(:,1)./d2l];
                ctr2 = [ctr0+d3.*[y' y']/2;flipud(ctr0(1:end-1,:)-d3(1:end-1,:).*[y(1:end-1)' y(1:end-1)']/2)];
                d = diff(ctr2,1,1);
                l = cumsum([0;sqrt((d.*d)*[1 ;1])]);
                cCell = interp1(l,ctr2,linspace(0,l(end),floor(l(end)/step+1)));
                break
            else
                tolerance=tolerance/5;
            end
        end
    % Generate the strusture to record
    if p.getmesh
        if size(cCell,1)<3, disp('Cell addition failed: error defining shape'); return; end
        mesh = model2MeshForRefine(cCell,p.meshStep,p.meshTolerance,p.meshWidth);
        if isempty(mesh), disp('Cell addition failed: error getting mesh'); return; end
        cellStructure.mesh = single(mesh);
        cellStructure.model = single(cCell);
    else
        cellStructure.contour = single(cCell);
        cellStructure.model = single(cCell);
    end
    tlapse = false; % determine the timelapse mode
%     if length(cellList)>frame;
%         for cell=1:length(cellList{frame})
%             if cell<=length(cellList{frame}) && ~isempty(cellList{frame}{cell}) && isfield(cellList{frame}{cell},'timelapse')
%                 if cellList{frame}{cell}.timelapse
%                     tlapse = true;
%                 else
%                     tlapse = false;
%                 end
%                 break
%             end
%         end
%     end
    for celln=1:oufti_getFrameLength(frame, cellList);
        %~isempty(cellList{frame}{celln}) && isfield(cellList{frame}{celln},'timelapse')
        if oufti_doesCellExist(celln, frame, cellList)
            cell = oufti_getCellStructure(celln, frame, cellList);
            if  isfield(cell,'timelapse') && cell.timelapse
                tlapse = true;
            else
                tlapse = false;
            end
            break
        end
    end
    if isempty(tlapse)
        if get(handles.runmode1,'value')
            tlapse = true;
        else
            tlapse = false;
        end
    end
    % Determine the cell number
    if ~askfornumber
%         if length(cellList)>=frame;
%             for cell=1:length(cellList{frame})+1
%                 if cell<=length(cellList{frame}) && (isempty(cellList{frame}{cell}) ...
%                         || ~isfield(cellList{frame}{cell},'mesh') || length(cellList{frame}{cell}.mesh)<=1)
%                     break
%                 end
%             end
%         else
%             cell=1;
%         end
        
        celln = getDaughterNum();
        if isempty(celln) && sum(~cellfun(@isempty,(cellList.cellId))) == 0, celln = 1;end
        %cellList = oufti_addCell(celln, frame, cellStructure, cellList);
    else
        while true
            dlg = inputdlg('Enter cell number','Adding cell dialog',1,{''});
            if isempty(dlg) || isempty(str2num(dlg{1})), disp('Adding cell terminated by the user'); return; end
            cell = str2num(dlg{1});
            if mod(cell,1)~=0 || cell<=0
                disp('Cell number must be a positive integer');
            else
                numallowed = true;
                for cframe=frame:oufti_getLengthOfCellList(cellList) %length(cellList)
                    if oufti_doesCellStructureHaveMesh(celln, frame, cellList)
                        numallowed = false;
                        disp(['Cell number ' num2str(celln) ' is not allowed: such cell already exists'])
                        break
                    end
                end
                if numallowed
                    break
                end
            end
        end
    end
    % create the output structure
    cellStructure.birthframe = frame;
    cellStructure.divisions = [];
    cellStructure.ancestors = [];
    cellStructure.descendants = [];
    % determine whether the cell will be considered as newborn or must be
    % linked to the previousely existing one
    if tlapse && ~p.forceindframes && frame>1
        for cframe=frame-1:-1:1
            if celln<=length(cellList.meshData{cframe}) && ~isempty(cellList.meshData{cframe}{celln})
                cellStructure.birthframe = cellList.meshData{cframe}{celln}.birthframe;
                cellStructure.divisions = cellList.meshData{cframe}{celln}.divisions;
                cellStructure.ancestors = cellList.meshData{cframe}{celln}.ancestors;
                cellStructure.descendants = cellList.meshData{cframe}{celln}.descendants;
                daughter = getDaughterNum();%getdaughter(celln,length(cellStructure.divisions),max(cellList.cellId{frame})+1);
                if ~isempty(cellList.meshData{frame}{oufti_cellId2PositionInFrame(daughter,frame,cellList)})
                    cellStructure.divisions = [cellStructure.divisions frame];
                    cellStructure.descendants = [cellStructure.descendants daughter];
                end
                break
            end
        end
    end
    
    cellStructure.timelapse = tlapse;
    cellStructure.algorithm = p.algorithm;
    cellStructure.polarity = 0;
    cellStructure.stage = 1;
    box = [max(floor(min(cCell)+1-p.roiBorder),1) min(ceil(max(cCell)-1+p.roiBorder),imsizes(end,2:-1:1))];
    cellStructure.box = [box(1:2) box(3:4)-box(1:2)+1];
%     cellList.meshData{frame}{celln} = cellStructure;
	cellList = oufti_addCell(celln, frame, cellStructure, cellList);
    cellListN(frame) = oufti_getFrameLength(frame, cellList); %length(cellList{frame});
    selectedList = celln;
    disp(['Adding a cell succeeded: cell ' num2str(celln) ' added'])
    if tlapse && ~p.forceindframes
        updatelineage(celln,frame)
    end
    listOfCells.add = oufti_cellId2PositionInFrame(celln,frame,cellList);
    listOfCells.erase = [];
    displayCellsForManualOperations(listOfCells,0);
    updateorientation(celln);
    displaySelectedCells();
    showCellData();
end

function dragbutonup(hObject, eventdata)%#ok<INUSD>
   
    try
    dragMode = false;
    if groupSelectionMode
        if hObject==handles.maingui
            ax = get(get(handles.impanel,'children'),'children');
            if ishandle(handles.himage), ax(2) = get(handles.himage,'parent'); end
            if iscell(ax), ax = ax{1}; end;
            extend = strcmpi(hFig.SelectionType,'extend');
        else
            ax = get(handles.himage,'parent');
            ax(2) = get(get(handles.impanel,'children'),'children');
            extend = strcmpi(get(handles.hfig,'SelectionType'),'extend');
        end
        if ishandle(groupSelectionRectH), delete(groupSelectionRectH); end; groupSelectionRectH = [];
        ps = get(ax(1),'CurrentPoint');
        pos = ps(1,1:2);
        pos1 = max(min(pos,groupSelectionPosition),1);
        pos2 = min(max(pos,groupSelectionPosition),imsizes(end,2:-1:1));
        pos3 = max([1,1],pos2-pos1);
        % groupSelectionRectH = rectangle('Position',[pos1,pos3],'EdgeColor',[1 1 1],'LineStyle',':');
        if regionSelectionMode
            groupSelectionRectH = [];
            for i=1:2
                groupSelectionRectH(i) = rectangle('Parent',ax(i),'Position',[pos1,pos3],'EdgeColor',[1 0 0],'LineStyle','-');
            end
            regionSelectionRect = [ceil(pos1),floor(pos3)];
            if isfield(handles,'export') && isfield(handles.export,'figure') && ishandle(handles.export.figure)
                set(handles.export.region(1),'String',num2str(regionSelectionRect(1)+1));
                set(handles.export.region(2),'String',num2str(regionSelectionRect(2)+1));
                set(handles.export.region(3),'String',num2str(regionSelectionRect(3)-2));
                set(handles.export.region(4),'String',num2str(regionSelectionRect(4)-2));
            end
        else
            if ~extend && ~isempty(selectedList)
                selectedList = [];
            end
            numCells = oufti_getFrameLength(frame, cellList);
            for celln = 1:numCells
                if oufti_doesCellStructureHaveMesh(celln, frame, cellList)
                    cell = oufti_getCellStructure(celln,frame,cellList);
                    box = cell.box;
                    mbox = box(1:2)+box(3:4)/2-1/2;
                    if pos1(1)<=mbox(1) && pos1(2)<=mbox(2) && pos2(1)>=mbox(1) && pos2(2)>=mbox(2)
                        mesh = cell.mesh;
                        mesh1 = min(min(mesh(:,1:2)),min(mesh(:,3:4)));
                        mesh2 = max(max(mesh(:,1:2)),max(mesh(:,3:4)));
                        if pos1(1)<=mesh1(1) && pos1(2)<=mesh1(2) && pos2(1)>=mesh2(1) && pos2(2)>=mesh2(2)
                            if isempty(find((selectedList-celln)==0,1))
                                % Adding a cell to selectedList
                                selectedList = [selectedList, celln];%#ok<AGROW>
                            else
                                % Removing a cell from selectedList
                                [n,k] = find((selectedList-celln)==0,1);
                                selectedList = selectedList([1:k-1 k+1:end]);
                            end
                        end
                    end
                elseif oufti_doesCellHaveContour(celln, frame, cellList)
                    cell = oufti_getCellStructure(celln, frame, cellList);
                    box = cell.box;
                    mbox = box(1:2)+box(3:4)/2-1/2;
                    if pos1(1)<=mbox(1) && pos1(2)<=mbox(2) && pos2(1)>=mbox(1) && pos2(2)>=mbox(2)
                        contour = cell.model;
                        limx = [min(contour(:,1)) max(contour(:,1))];
                        limy = [min(contour(:,2)) max(contour(:,2))];
                        if pos1(1)<=limx(1) && pos1(2)<=limy(2) && pos2(1)>=limx(1) && pos2(2)>=limy(2)
                            if isempty(find((selectedList-celln)==0,1))
                                % Adding a cell to selectedList
                                selectedList = [selectedList, celln];%#ok<AGROW>
                            else
                                % Removing a cell from selectedList
                                [~,k] = find((selectedList-celln)==0,1);
                                selectedList = selectedList([1:k-1 k+1:end]);
                            end
                        end
                    end
                end
            end
            displaySelectedCells();
            showCellData();
            if ishandle(groupSelectionRectH), delete(groupSelectionRectH); end; groupSelectionRectH = [];
            groupSelectionRectH = [];
        end
        groupSelectionMode = false;
    end
    catch err
        if ishandle(groupSelectionRectH), delete(groupSelectionRectH); end; groupSelectionRectH = [];
        groupSelectionRectH = [];
        return;
    end
  
    
    
end

function pos = getmousepos
    himageStruct = struct(get(handles.himage));
% % %     ax = himageStruct.Parent;
% % %     ax = get(handles.himage,'parent');
    ps = get(himageStruct.Parent,'CurrentPoint');
    pos.x = ps(1,1);
    pos.y = ps(1,2);
    if ps(1,1)<0 || ps(1,1)>imsizes(end,2) || ps(1,2)<0 || ps(1,2)>imsizes(end,1), pos = []; end;
end

function mousemove(hObject, eventdata)%#ok<INUSD>
    global handles1 imageHandle
    try
    if ~isempty(handles1) && strcmp(get(handles1.spotFinderPanel,'Visible'),'on')
        return;
    end
    if ishandle(imageHandle),delete(imageHandle.fig);end
    if hObject==handles.maingui
        ax = get(get(handles.impanel,'Children'),'Children');
        if iscell(ax), ax = ax{1}; end;
        extend = strcmp(hFig.SelectionType,'extend');
    else
        if ~ishandle(handles.himage), return; end
        himageStruct = get(handles.himage);
        ax = himageStruct.Parent;
        extend = strcmp(get(handles.hfig,'SelectionType'),'extend');
    end
    if isempty(ax), return; end
    pt = get(ax,'CurrentPoint');
    if isempty(pt), return; end
    hFig.Pointer = 'arrow'; % TODO: create more proper cursor control
    pt = round(pt(1,1:2));
    if pt(1)>0 && pt(2)>0 && pt(1)<imsizes(end,2) && pt(2)<imsizes(end,1)
        set(handles.celldata.coursor,'String',['x=' num2str(pt(1)) ', y=' num2str(pt(2))]);
    else
        set(handles.celldata.coursor,'String','');
    end
    if groupSelectionMode
        % selecting a group of cells: draw rectangle
        ps = get(ax,'CurrentPoint');
        pos = ps(1,1:2);
        if ishandle(groupSelectionRectH), delete(groupSelectionRectH); end;
        if regionSelectionMode
            groupSelectionRectH = rectangle('Position',[min(pos,groupSelectionPosition),max([1,1],abs(pos-groupSelectionPosition))],...
                'EdgeColor',[1 0 0],'LineStyle',':');
        else
            groupSelectionRectH = rectangle('Position',[min(pos,groupSelectionPosition),max([1,1],abs(pos-groupSelectionPosition))],...
                'EdgeColor',[1 1 1],'LineStyle',':');
        end
    end
    % if gdisp % Awkward patch to make the behavior of log window same as zoom window
    %     set(handles.logcheck,'Value',1)
    % else
    %     set(handles.logcheck,'Value',0)
    % end
    catch err
        if ishandle(groupSelectionRectH), delete(groupSelectionRectH); end;
    end
end

function dragmouse(hObject, eventdata)
    mousemove(hObject, eventdata);
    if dragMode
        dragPositionNew = getmousepos;
        if isempty(dragPositionNew), dragMode=false; return; end
        apiHP = iptgetapi(handles.hpanel);
        pos = apiHP.getVisibleLocation();
        rect = apiHP.getVisibleImageRect();
        apiHP.setVisibleLocation(min(imsizes(end,2)-rect(3),max(0,pos(1)+dragPosition.x-dragPositionNew.x)),...
            min(imsizes(end,1)-rect(4),max(0,pos(2)+dragPosition.y-dragPositionNew.y)));
    end
end


% --- Other GUI nested functions ---

function selectarea(hObject, eventdata)%#ok<INUSD>
    if get(handles.selectarea,'value')
        regionSelectionMode = true;
    else
        regionSelectionMode = false;
        if ishandle(groupSelectionRectH), delete(groupSelectionRectH); end
        groupSelectionRectH = [];
        regionSelectionRect = [];
    end
end

function mainguiclosereq(hObject, eventdata)%#ok<INUSD>
    if strcmp(get(hObject,'Name'),versionNumber)
        quitMessage();
    else
        return;
    end
end

function contrast_cbk(hObject, eventdata)%#ok<INUSD>
    if ~ishandle(handles.hpanel), return; end
    if ~ishandle(handles.hfig), return; end
    ax = get(get(handles.impanel,'children'),'children');
    if iscell(ax), ax = ax{1}; end;
    imgh = findall(ax,'Type','image');
    img = get(imgh,'CData');
    if strcmp(class(img),'double')
        set(imgh,'CData',im2uint16(get(imgh,'CData')));
        set(ax,'CLim',get(ax,'CLim')*2^16);
    end
    clim = get(ax,'CLim');
    if clim(1)<min(min(img)), clim=double(min(min(img)))+[0 clim(2)-clim(1)] ; end
    if clim(2)>max(max(img)), clim(1)= max(double(max(max(img)))+(-clim(2)+clim(1)),double(min(min(img)))); clim(2)=double(max(max(img))); end
    if clim(2)<=clim(1), clim(1)=clim(2)-1; end
    set(ax,'CLim',clim);
    handles.ctrfigure = imcontrast(ax);
    set(handles.ctrfigure,'CloseRequestFcn',@ctrclosereq)
end

function export_cbk(hObject, eventdata)%#ok<INUSD>
    choice = questdlg('Do you want entire image or Region of interest (ROI)?  ROI uses sub-pixel alignment.','Video construction','Entire Image','Region of interest (ROI)','Cancel');
    if strcmp(choice,'Region of interest (ROI)'),exportSubPixel(); return;end
    if isfield(handles,'export') && isfield(handles.export,'figure') && ~isempty(handles.export.figure) && ishandle(handles.export.figure), figure(handles.export.figure); return; end % do not create second window
    
    handles.export.figure = figure('pos',[25 screenSize(4)-250 380 225],'Toolbar','none','Menubar','none','Name','Export images','NumberTitle','off','IntegerHandle','off','Resize','off','Color',get(handles.imslider,'BackgroundColor'));

    uicontrol(handles.export.figure,'units','pixels','Position',[5 200 370 15],'Style','text','String','Export frames to images / movies','FontWeight','bold','HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    uicontrol(handles.export.figure,'units','pixels','Position',[5 175 150 15],'Style','text','String','Export images from frame','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.startframe = uicontrol(handles.export.figure,'units','pixels','Position',[157 174 25 19],'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.export.figure,'units','pixels','Position',[183 175 20 15],'Style','text','String','to','FontWeight','bold','HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.endframe = uicontrol(handles.export.figure,'units','pixels','Position',[205 174 25 19],'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    uicontrol(handles.export.figure,'units','pixels','Position',[5 150 80 15],'Style','text','String','Output format','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.format = uicontrol(handles.export.figure,'units','pixels','Position',[88 151 50 19],'Style','popupmenu','String',{'.avi' '.tif' '.jpg' '.mp4'},'Callback',@formatSelection,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    bg = uibuttongroup(handles.export.figure,'Visible','off','units','pixels','Position',[150 151 200 19],'SelectionChangedFcn',@bselection);
    handles.export.p     = uicontrol(bg,'units','pixels','Position',[1 1 60 15],'Style','radiobutton','String','phase','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'HandleVisibility','off');
    handles.export.sOne     = uicontrol(bg,'units','pixels','Position',[65 1 60 15],'Style','radiobutton','String','signal1','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'HandleVisibility','off');
    handles.export.sTwo     = uicontrol(bg,'units','pixels','Position',[130 1 60 15],'Style','radiobutton','String','signal2','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10,'HandleVisibility','off');
    bg.Visible = 'on';
    handles.signal = [1,0,0];
    uicontrol(handles.export.figure,'units','pixels','Position',[5 125 120 15],'Style','text','String','Region to export, left:','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.region(1) = uicontrol(handles.export.figure,'units','pixels','Position',[128 124 30 19],'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.export.figure,'units','pixels','Position',[158 125 30 15],'Style','text','String','top:','FontWeight','bold','HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.region(2) = uicontrol(handles.export.figure,'units','pixels','Position',[191 124 30 19],'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.export.figure,'units','pixels','Position',[223 125 40 15],'Style','text','String','width:','FontWeight','bold','HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.region(3) = uicontrol(handles.export.figure,'units','pixels','Position',[266 124 30 19],'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.export.figure,'units','pixels','Position',[298 125 40 15],'Style','text','String','height:','FontWeight','bold','HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.region(4) = uicontrol(handles.export.figure,'units','pixels','Position',[341 124 30 19],'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    uicontrol(handles.export.figure,'units','pixels','Position',[5 100 70 15],'Style','text','String','Image zoom','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.zoom = uicontrol(handles.export.figure,'units','pixels','Position',[78 99 45 19],'Style','edit','String','1','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    handles.export.resText = uicontrol(handles.export.figure,'units','pixels','Position',[128 100 85 15],'Style','text','String','Quality(0-100)','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.resolution = uicontrol(handles.export.figure,'units','pixels','Position',[210 99 45 19],'Style','edit','String','100','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    uicontrol(handles.export.figure,'units','pixels','Position',[5 75 55 15],'Style','text','String','Movie fps','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.fps = uicontrol(handles.export.figure,'units','pixels','Position',[63 74 45 19],'Style','edit','String','30','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    %----------------------------------------------------------------------
    %this addition adds an option to skip # of frame in the movie making
    %process
    uicontrol(handles.export.figure,'units','pixels','Position',[120 75 70 15],'Style','text','String','Skip every ','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.frames2Skip = uicontrol(handles.export.figure,'units','pixels','Position',[185 75 45 19],'Style','edit','String','1','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.export.figure,'units','pixels','Position',[240 75 40 15],'Style','text','String','frames ','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    %----------------------------------------------------------------------
    
    uicontrol(handles.export.figure,'units','pixels','Position',[5 50 92 15],'Style','text','String','Time stamp at x:','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.xtime = uicontrol(handles.export.figure,'units','pixels','Position',[100 49 45 19],'Style','edit','String','','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.export.figure,'units','pixels','Position',[150 50 10 15],'Style','text','String','y:','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.ytime = uicontrol(handles.export.figure,'units','pixels','Position',[163 49 45 19],'Style','edit','String','','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.export.figure,'units','pixels','Position',[213 50 60 15],'Style','text','String','step:','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.stime = uicontrol(handles.export.figure,'units','pixels','Position',[245 49 45 19],'Style','edit','String','','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    uicontrol(handles.export.figure,'units','pixels','Position',[295 50 60 15],'Style','text','String','font:','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.export.ftime = uicontrol(handles.export.figure,'units','pixels','Position',[324 49 45 19],'Style','edit','String','10','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    handles.export.export = uicontrol(handles.export.figure,'units','pixels','Position',[10 10 360 20],'String','Export','callback',@export_fn,'FontUnits','pixels','FontName','Helvetica','FontSize',10);
    
    if ~isempty(regionSelectionRect)
        set(handles.export.region(1),'string',num2str(regionSelectionRect(1)+1));
        set(handles.export.region(2),'string',num2str(regionSelectionRect(2)+1));
        set(handles.export.region(3),'string',num2str(regionSelectionRect(3)-2));
        set(handles.export.region(4),'string',num2str(regionSelectionRect(4)-2));
    end
    function bselection (~,eventData)
        if strcmpi(eventData.NewValue.String,'phase')
            handles.signal = [1 0 0];
        elseif strcmpi(eventData.NewValue.String,'signal1')
            handles.signal = [0 1 0];
        elseif strcmpi(eventData.NewValue.String,'signal2')
            handles.signal = [0 0 1];
        end
    end
    
    function formatSelection(hObject,~)
        if get(hObject, 'value') == 4 || get(hObject, 'value') == 1
           set(handles.export.resText, 'String','Quality(0-100)');
           
        else
            set(handles.export.resText, 'String','Resolution');
        end
    end
end

function export_fn(hObject, eventdata)%#ok<INUSD>
    global rawPhaseData rawS1Data rawS2Data 
    % read the data from the form fields
    range = [];
    range = [range str2num(get(handles.export.startframe,'String'))]; if length(range)<1 || range(1)<1, range(1)=1; end
    range = [range str2num(get(handles.export.endframe,'String'))]; if length(range)<2 || range(2)>imsizes(end,3), range(2)=imsizes(end,3); end
    format = get(handles.export.format,'Value');
    formatlist = get(handles.export.format,'String');
    region = [];
    region = [region str2num(get(handles.export.region(1),'String'))]; if length(region)<1 || region(1)<1, region(1)=1; end
    region = [region str2num(get(handles.export.region(2),'String'))]; if length(region)<2 || region(2)<1, region(2)=1; end
    region = [region str2num(get(handles.export.region(3),'String'))]; if length(region)<3, region(3) = Inf; end; region(3) = min(imsizes(end,2)-region(1)+1,region(3)); 
    region = [region str2num(get(handles.export.region(4),'String'))]; if length(region)<4, region(4) = Inf; end; region(4) = min(imsizes(end,1)-region(2)+1,region(4)); 
    zm = str2num(get(handles.export.zoom,'String')); if length(zm)<1 || zm<0.05 || zm>20, zm=1; end
    fps = str2num(get(handles.export.fps,'String')); if length(fps)<1 || fps<0.1 || fps>500, fps=1; end
    resolution = str2num(get(handles.export.resolution,'String')); if length(resolution)<1 || resolution<10 || resolution>1000, resolution='auto'; end
    frames2Skip = str2double(get(handles.export.frames2Skip,'String'));
    % request the output file name
    w = whos('movieFile','class');
    if isempty(w) || strcmp(w.class,'(unassigned)'), movieFile=''; end
    drawnow(); pause(0.05);
    if format==1
        [outfile,pathname] = uiputfile2('*.avi', 'Enter a filename to save the movie to',movieFile);
    elseif format==2
        [outfile,pathname] = uiputfile2('*.tif', 'Enter the name of the first image file',movieFile);
    elseif format==3
        [outfile,pathname] = uiputfile2('*.jpg', 'Enter  the name of the first image file',movieFile);
    elseif format==4
        [outfile,pathname] = uiputfile2('*.mp4', 'Enter the name of the first image file',movieFile);
    end
    if isequal(outfile,0), return; end
    if length(outfile)<=4
        outfile = [outfile formatlist{format}];
    elseif ~strcmp(outfile(end-3:end),formatlist{format})
        outfile = [outfile formatlist{format}];
    end
    if format==2 || format==3 
        if length(outfile)>4 && strcmp(outfile(end-3:end),formatlist{format}), outfile = outfile(1:end-4); end
        lng = range(2)-range(1)+1;
        ndig = ceil(log10(lng+1));
        istart = 1;
        for k=1:ndig
            if length(outfile)>=k && ~isempty(str2num(outfile(end-k+1:end)))
                istart = str2num(outfile(end-k+1:end));
            else
                k=k-1;
                break
            end
        end
        outfile=outfile(1:end-k);
    end
    outfile = fullfile2(pathname,outfile);

    % output data
    w = waitbar(0, 'Exporting images');
    handles.export.fig2 = figure('pos',[20 20 ceil(region(3)*zm) ceil(region(4)*zm)],'Toolbar','none','Visible','on','Menubar','none','Name','','NumberTitle','off','IntegerHandle','off','Resize','off');
    frametmp = frame;
    fmt = formatlist{format};
    fmt = fmt(2:end);
    if format==1
     vidObj = VideoWriter(outfile);
     vidObj.FrameRate = fps;
     vidObj.Quality = resolution;
     open(vidObj);
    elseif format==4
        try
            vidObj = VideoWriter(outfile,'MPEG-4');
            vidObj.FrameRate = fps;
            vidObj.Quality = resolution;
            open(vidObj);
        catch
            warndlg('MPEG-4 format is not supported in this version of operating system');
            return
        end
    elseif format==2
        fmt = 'tiff';
    elseif format==3
        fmt = 'jpeg';
    end
    xtime = str2num(get(handles.export.xtime,'String'));
    ytime = str2num(get(handles.export.ytime,'String'));
    ftime = str2num(get(handles.export.ftime,'String'));
    stime = str2num(get(handles.export.stime,'String'));
    try
        if handles.signal(1) == 1
            phaseIm = rawPhaseData;
        elseif handles.signal(2) == 1
            phaseIm = rawS1Data;
        elseif handles.signal(3) == 1
            phaseIm = rawS2Data;
        end
    catch
        warndlg('Make sure correct value is chosen "Phase", "Signal1", or "Signal12"');    end
    for frame=range(1):frames2Skip:range(2)
        set(hObject,'value',imsizes(end,3)+1-frame);
        %imslider(hObject, eventdata)
        img = phaseIm(:,:,frame);
        ax = axes('parent',handles.hfig);
        handles.himage = imshow(img,imageLimits{imageDispMode},'parent',ax,'ini',100);
        drawnow; pause(0.05);%java.lang.Thread.sleep(50);
        pos = get(handles.hfig,'pos');
        set(handles.hfig,'pos',pos);
        handles.hpanel = imscrollpanel(handles.hfig,handles.himage);
        drawnow; pause(0.05);%java.lang.Thread.sleep(50);
        displayCells();
        set(handles.currentframe,'String',[num2str(frame) ' of ' num2str(imsizes(end,3))]);
        if ~ishandle(handles.hpanel), return; end
        ax = findall(handles.hpanel,'type','axes');
        %pos2 = get(handles.export.fig2,'pos');
        %warning off
        delete(findobj(handles.export.fig2,'Type','axes'))
        ax2 = copyobj(ax,handles.export.fig2);
        %warning on
        set(handles.export.fig2,'pos',[25 400 imsizes(end,2) imsizes(end,1)])
        set(handles.export.fig2,'pos',[25 400 ceil(region(3)*zm) ceil(region(4)*zm)])%????????
        set(ax2,'Units','pixels','pos',[1 1 ceil(region(3)*zm) ceil(region(4)*zm)])
% % %         xlim(ax2,[region(1) region(1)+region(3)])%????????
% % %         ylim(ax2,[region(2) region(2)+region(4)])%????????
        colormap gray
        set(ax2,'nextplot','replace','Visible','on')
        if ~isempty(xtime) && ~isempty(ytime) && ~isempty(stime) && ~isempty(ftime)
            stime2 = mod(mod((frame-1)*stime,60),1);
            a=zeros(1,32);
            a(strfind(num2str(stime2,'%0.30f'),'0'))=1;
            stimelng=find(~a,1,'last')-2;
            if stimelng<=0
                tstring = [num2str(floor((frame-1)*stime/60/60),'%02.f') ':' num2str(mod(floor((frame-1)*stime/60),60),'%02.f') ':' num2str(mod((frame-1)*stime,60),'%02.f')];
            else
                tstring = [num2str(floor((frame-1)*stime/60/60),'%02.f') ':' num2str(mod(floor((frame-1)*stime/60),60),'%02.f') ':' num2str(mod((frame-1)*stime,60),['%0' num2str(3+stimelng) '.' num2str(stimelng) 'f'])];
            end
            rectangle('position',[(xtime-5)+1,(ytime-5)+1,95,25],'facecolor','white','parent',ax2,'EdgeColor','none');
            text(region(1)+xtime,region(2)+ytime+ftime/2,tstring,'Fontsize',ftime,'color','red','parent',ax2);

        end
        if format==1
            frameValue = getframe;
            writeVideo(vidObj,frameValue);   
        elseif format==2 || format==3 
            fnum=frame+istart-range(1);
            cfilename = [outfile num2str(fnum,['%.' num2str(ndig) 'd']) formatlist{format}];
            hgexport(handles.export.fig2,cfilename,hgexport('factorystyle'),'Format',...
                fmt,'Units','pixels','Width',floor(region(3)*zm),'Height',floor(region(4)*zm),'Resolution',resolution);
        elseif format==4
            writeVideo(vidObj,getframe(ax2));
        end
        waitbar(frame/(range(2)-range(1)+1),w);
        if ~isempty(shiftframes)
             for c = 1:length(cellList.meshData{frame})
                 try
                 cellList.meshData{frame}{c}.mesh(:,[1 3]) = cellList.meshData{frame}{c}.mesh(:,[1 3])-1*shiftframes.x(frame);
                 cellList.meshData{frame}{c}.mesh(:,[2 4]) = cellList.meshData{frame}{c}.mesh(:,[2 4])-1*shiftframes.y(frame);
                 if isfield(cellList.meshData{frame}{c},'objects')
                     cellList.meshData{frame}{c}.outlines(:,1) = cellList.meshData{frame}{c}.outlines(:,1)-1*shiftframes.x(frame);
                     cellList.meshData{frame}{c}.outlines(:,2) = cellList.meshData{frame}{c}.outlines(:,2)-1*shiftframes.y(frame);
                 end
                 catch
                 end
             end
        end
     end
     close(w);
    frame = frametmp;
    set(hObject,'value',imsizes(end,3)+1-frame);
    imslider(hObject, eventdata)
    if format==1
%     aviobj = close(aviobj);
    close(vidObj);
    end
    close(handles.export.fig2);
    disp('------------------ Process Successfull ----------------------')
end

function exportSubPixel(hObject,evenData)
    handles.exportSubPixel.filePhase = '';
    handles.exportSubPixel.pathPhase = '';
    handles.exportSubPixel.fileFluorOne = '';
    handles.exportSubPixel.pathFluorOne = '';
    handles.exportSubPixel.fileFluorTwo = '';
    handles.exportSubPixel.pathFluorTwo = '';
    handles.exportSubPixel.fileFluorThree = '';
    handles.exportSubPixel.pathFluorThree = '';
    screenSize = get(0,'ScreenSize');
    
    handles.exportSubPixel.figure = figure('pos',[25 screenSize(4)-400 380 300],'Toolbar','none','Menubar','none','Name','Generate sub-pixel aligned roi-based movie','NumberTitle','off','IntegerHandle','off','Resize','off','Color',get(handles.imslider,'BackgroundColor'));    
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[5 280 150 15],'Style','text','String','Export images from frames','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.frameRange = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[165 280 150 19],'Style','edit','String','[1,10]','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10,...
                                        'Tooltipstring','is the range of frames to be included in the movie. This can either be a list of frames (i.e., [3,4,6,7,9,11,12]) or two terminal frames (i.e., [1,100]). In the case that two terminal frames are provided, all intermediate frames will be included as well');
    handles.exportSubPixel.phaseFile = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[5 250 150 20],...
                                       'callback',@exportSubPixel_images,'Style','pushbutton','string','Select first phase image','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.loadStack = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[165 250 50 20],'Style','checkbox','value',0,'String','stack','Enable','on',...
                                                 'Tooltipstring','Click if images are in a stack.  To use this option, all image sets should be in stack.');
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[100 225 150 15],'Style','text','String','Optional selection','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Arial','FontSize',12);
                              
    handles.exportSubPixel.cellList = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[5 205 55 20],'Style','checkbox','value',0,'String','cellList','Enable','on',...
                                      'tooltipstring','Indicates that a cellList will be used, if this option is enabled then a cellNumber must be provided.');
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[55 200 100 20],'Style','text','String','cellNumber');
    handles.exportSubPixel.cellNumber = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[132 205 20 15],'Style','edit');
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[150 200 100 20],'Style','text','String','cellListPad');
    handles.exportSubPixel.cellListPad = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[230 205 20 15],'Style','edit','string','6');
    handles.exportSubPixel.fluorOne = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[5 180 55 20],'callback',@exportSubPixel_images,...
                                                'Style','pushbutton','string','fluor1','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.fluorTwo = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[65 180 55 20],'callback',@exportSubPixel_images,...
                                                'Style','pushbutton','string','fluor2','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.fluorThree = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[125 180 55 20],'callback',@exportSubPixel_images,...
                                                'Style','pushbutton','string','fluor3','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);

    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[265 185 80 15],'Style','text','String','upSampleFactor');
    handles.exportSubPixel.upSample = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[350 185 20 15],'Style','edit','string','20');
    
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[265 205 80 15],'Style','text','String','maxPixelShift');
    handles.exportSubPixel.maxPixelShift = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[350 205 20 15],'Style','edit','string','50');
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[100 155 200 15],'Style','text','String','Movie construction parameters','FontWeight','bold','HorizontalAlignment','left','FontUnits','pixels','FontName','Arial','FontSize',12);

    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[5 135 120 15],'Style','text','String','experimentFrameRate','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.experimentRate = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[130 135 30 15],'Style','edit','String','1');
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[210 135 120 15],'Style','text','String','scaleBarColor','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.scaleBarColor = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[300 135 50 15],'Style','edit','String','[0,0,0]');

    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[5 115 120 15],'Style','text','String','frameRate','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.frameRate = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[130 115 30 15],'Style','edit','String','20');
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[210 115 120 15],'Style','text','String','scaleBarPosition','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.scaleBarPosition = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[300 115 50 15],'Style','edit','String','[5,20]');
    
    
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[5 95 120 15],'Style','text','String','magnification','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.magnification = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[130 95 30 15],'Style','edit','string','200');
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[210 95 120 15],'Style','text','String','timeStampPosition','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.timeScalePosition = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[300 95 50 15],'Style','edit','string','[5,10]');
    
    
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[5 75 120 15],'Style','text','String','pixelSize','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.pixelSize = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[130 75 30 15],'Style','edit','string',0.064);
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[210 75 120 15],'Style','text','String','timeStampColor','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.timeScaleColor = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[300 75 50 15],'Style','edit','string','[0,0,0]');
    
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[5 50 120 15],'Style','text','String','timeUnits','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica','FontSize',10);
    handles.exportSubPixel.timeUnits = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[130 50 30 15],'Style','edit','string','sec');

    handles.exportSubPixel.saveLocation = uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[75 20 80 20],'Style','pushbutton','string','saveLocation',...
                                                   'callback',@exportSubPixel_images,'Style','pushbutton','string','saveLocation','BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);
  
    uicontrol(handles.exportSubPixel.figure,'units','pixels','Position',[200 20 80 20],'Style','pushbutton','string','Run','callback',@exportSubPixel_run,...
               'BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontUnits','pixels','FontName','Helvetica','FontSize',10);

end

function exportSubPixel_images(hObject,eventData)
    global phaseData signalData1 signalData2 signalData3


    if strcmp('Select first phase image',hObject.String)
        if handles.exportSubPixel.loadStack.Value == 1
            [file,path] = uigetfile('*.*','Select the phase stack file');
            [~,phaseData] = loadimagestack(1,[path '/' file],1,0);
        else
            handles.exportSubPixel.filePhase = '';
            handles.exportSubPixel.pathPhase = '';
            [file,path] = uigetfile('*.tif','Select the first phase image');

        end
        handles.exportSubPixel.filePhase = file;
        handles.exportSubPixel.pathPhase = path;
    elseif strcmp('fluor1',hObject.String)
        if handles.exportSubPixel.loadStack.Value == 1
            [file,path] = uigetfile('*.*','Select the first fluorescent stack file');
            [~,signalData1] = loadimagestack(1,[path '/' file],1,0);
        else
            handles.exportSubPixel.fileFluorOne = '';
            handles.exportSubPixel.pathFluorOne = '';
            [file,path] = uigetfile('*.tif','Select the first fluorescent image');

        end
        handles.exportSubPixel.fileFluorOne = file;
        handles.exportSubPixel.pathFluorOne = path;
        
    elseif strcmp('fluor2',hObject.String)
         if handles.exportSubPixel.loadStack.Value == 1
            [file,path] = uigetfile('*.*','Select the second fluorescent stack file');
            [~,signalData2] = loadimagestack(1,[path '/' file],1,0);
         else
            handles.exportSubPixel.fileFluorTwo = '';
            handles.exportSubPixel.pathFluorTwo = '';
            [file,path] = uigetfile('*.tif','Select the first fluorescent image');

        end
        handles.exportSubPixel.fileFluorTwo = file;
        handles.exportSubPixel.pathFluorTwo = path;
        
    elseif strcmp('fluor3',hObject.String)
        if handles.exportSubPixel.loadStack.Value == 1
            [file,path] = uigetfile('*.*','Select the third fluorescent stack file');
            [~,signalData3] = loadimagestack(1,[path '/' file],1,0);
        else
            handles.exportSubPixel.fileFluorThree = '';
            handles.exportSubPixel.pathFluorThree = '';
            [file,path] = uigetfile('*.tif','Select the first fluorescent image');

        end
        handles.exportSubPixel.fileFluorThree = file;
        handles.exportSubPixel.pathFluorThree = path;
    elseif strcmp('saveLocation',hObject.String)
        [file,path] = uiputfile('*.avi','Name the file to save the movie to');
        handles.exportSubPixel.pathSave = path;
        handles.exportSubPixel.fileSave = file;
    end

end

function exportSubPixel_run(hObject,eventData)
    frameRange = str2num(handles.exportSubPixel.frameRange.String);
    phsFile1 = [handles.exportSubPixel.pathPhase handles.exportSubPixel.filePhase];
    fluorFile1 = [handles.exportSubPixel.pathFluorOne handles.exportSubPixel.fileFluorOne];
    fluorFile2 = [handles.exportSubPixel.pathFluorTwo handles.exportSubPixel.fileFluorTwo];
    fluorFile3 = [handles.exportSubPixel.pathFluorThree handles.exportSubPixel.fileFluorThree];
    cellNumber = str2num(handles.exportSubPixel.cellNumber.String);
    cellListPad = str2num(handles.exportSubPixel.cellListPad.String);
    upSampleFactor = str2num(handles.exportSubPixel.upSample.String);
    maxPixelShift = str2num(handles.exportSubPixel.maxPixelShift.String);
    experimentFrameRate = str2num(handles.exportSubPixel.experimentRate.String);
    frameRate = str2num(handles.exportSubPixel.frameRate.String);
    magnification1 = str2num(handles.exportSubPixel.magnification.String);
    pixelSize = str2num(handles.exportSubPixel.pixelSize.String);
    timeUnits   = handles.exportSubPixel.timeUnits.String;
    scaleBarColor = str2num(handles.exportSubPixel.scaleBarColor.String);
    scaleBarPosition = str2num(handles.exportSubPixel.scaleBarPosition.String);
    timeScalePosition = str2num(handles.exportSubPixel.timeScalePosition.String);
    timeScaleColor = str2num(handles.exportSubPixel.timeScaleColor.String);
    try
        saveLocation = [handles.exportSubPixel.pathSave handles.exportSubPixel.fileSave(1:end)]; 
    catch
        warndlg('Choose path for the movie file to save to');
        return;
    end
    loadStackValue = handles.exportSubPixel.loadStack.Value;
    try
        if handles.exportSubPixel.cellList.Value == 0 && isempty(fluorFile1)
            if isempty(phsFile1)
                warndlg('Provide images or if images are present select the cellList box');
                return;
            end
            [alignFromSelData] = alignFromSelection(phsFile1, frameRange,loadStackValue);
        elseif ~isempty(fluorFile1) && handles.exportSubPixel.cellList.Value == 0
                [alignFromSelData] = alignFromSelection(phsFile1, frameRange,loadStackValue);
        elseif handles.exportSubPixel.cellList.Value == 1 && (~isempty(fluorFile1) || ~isempty(phsFile1))
            if ~isempty(cellList.meshData{1}{1})
                [alignFromSelData] = alignFromSelection(phsFile1, frameRange,loadStackValue,'fluorfile',fluorFile1,'cellList',cellList,'upsamplefactor',upSampleFactor,'cellnumber',cellNumber,...
                                                    'celllistpad',cellListPad,'maximumPixelShift',maxPixelShift);
           else
                warndlg('Load cellList first'); return;
            end
        else
            warndlg('Select images to make movie from');
            return;
        end
    catch err
        disp(err.message);
        return;
    end
    
    try
        if ~isempty(fluorFile1) && ~isempty(fluorFile2) && ~isempty(fluorFile3)
            [shiftedIMs] = shiftMovieImages(alignFromSelData, loadStackValue,phsFile1, fluorFile1,fluorFile2,fluorFile3);
            position{1,1} = [1, 0, 0, 0];
            position{1,2} = [0, 0, 2, 0];
            position{2,1} = [0, 3, 0, 3];
            position{2,2} = [0, 3, 2, 3];

        elseif ~isempty(fluorFile1) && ~isempty(fluorFile2)
            [shiftedIMs] = shiftMovieImages(alignFromSelData, loadStackValue, phsFile1, fluorFile1,fluorFile2);
             position{1,1} = [1, 0, 0, 0];
            position{1,2} = [0, 0, 2, 0];
            position{2,1} = [0, 3, 0, 3];
        elseif ~isempty(fluorFile1)
            [shiftedIMs] = shiftMovieImages(alignFromSelData, loadStackValue, phsFile1, fluorFile1);
             position{1,1} = [1, 0, 0, 0];
            position{1,2} = [0, 0, 2, 0];

        elseif ~isempty(phsFile1)
            [shiftedIMs] = shiftMovieImages(alignFromSelData,loadStackValue, phsFile1);
            position{1,1} = [1, 0, 0, 0];
        end
    catch err
        disp(err.message);
    end
    
    writeMovie(shiftedIMs,alignFromSelData,'positions',position,'timestampposition',timeScalePosition,'timestampcolor',timeScaleColor,...
               'scalebarposition',scaleBarPosition,'scalebarcolor',scaleBarColor,'framerate',frameRate,'timeunits',timeUnits','pixelsize',pixelSize,...
               'magnification',magnification1,'experimentframerate',experimentFrameRate,'savelocation',saveLocation);

end

function ctrclosereq(hObject, eventdata)%#ok<INUSD>
    ax = get(get(handles.impanel,'children'),'children');
    if iscell(ax), ax = ax{1}; end;
    imageLimits{imageDispMode} = get(ax,'CLim');
    delete(handles.ctrfigure)
end

function clonefigure(hObject, eventdata)%#ok<INUSD>
    % this function copies the zoom window (or main window if zoom window
    % is colsed) into an identically sized MATLAB figure so that the user
    % could save or export it
    if ~ishandle(handles.hfig)||~ishandle(handles.hpanel)||~ishandle(handles.impanel), return; end
    if get(handles.zoomcheck,'Value')==1
        pos = get(handles.hfig,'pos');
    else
        pos = get(handles.impanel,'pos');
    end
    fig = figure;
    pos2 = get(fig,'pos');
    ax = findall(handles.hpanel,'type','axes');
    apiSP = iptgetapi(handles.hpanel);
    rect = apiSP.getVisibleImageRect();
    mag2 = apiSP.getMagnification();
    apiSP.setMagnification(1);
    ax2 = copyobj(ax,fig);
    apiSP.setMagnification(mag2);
    set(fig,'pos',[pos2(1)-(pos(3)-pos2(3))/2 pos2(2)-(pos(4)-pos2(4)) pos(3) pos(4)])
    set(ax2,'pos',[1 1 pos(3:4)])
    xlim(ax2,[rect(1) rect(1)+rect(3)])
    ylim(ax2,[rect(2) rect(2)+rect(4)])
    colormap gray
end

function train_cbk(hObject, eventdata)%#ok<INUSD>
    % callback to call the training routine for algorithms 2 ans 3
    nm = ceil(str2num(get(handles.trainN,'String'))/4)*4; %#ok<ST2NM>
    if isempty(nm), disp('Number of points not entered, training function terminated'); return; end
    alg = str2num(get(handles.trainAlg,'String'));
    if isempty(alg), disp('Algorithm not selected, training function terminated'); return; end
    trainPDM(get(handles.trainMult,'Value'),nm,alg)
end

% --- End of other GUI nested functions ---

% --- Saving and loading cell data GUI nested functions ---

function saveLoadMesh_cbk(hObject, eventdata)%#ok<INUSD>
    global filenametmp 
    if hObject==handles.savemesh
        %[filename,pathname] = uiputfile('*.mat', 'Enter a filename to save meshes to','');
        [filename,pathname] = uiputfile2('*.mat', 'Enter a filename to save meshes to',meshFile);
        if isequal(filename,0), return; end;
        if length(filename)<=4
            filename = [filename '.mat'];
        elseif ~strcmp(filename(end-3:end),'.mat')
            filename = [filename '.mat'];
        end
        filename = fullfile2(pathname,filename);
        meshFile = filename;
        savemesh(filename,[],get(handles.saveselected,'Value'),[])
    elseif hObject==handles.loadmesh
        [filename,pathname] = uigetfile2({'*.mat;*.out'},...
                            'Enter a filename to get meshes from',filenametmp);
        if(filename==0), return; end;
        filename = fullfile2(pathname,filename);
        meshFile = filename;
        param = loadmesh(filename);
        if get(handles.loadparamwithmesh,'Value') && ~isempty(param)
            parseparameters(param)
            set(handles.params,'String',param);
            disp('Parameters loaded from the meshes file')
        elseif get(handles.loadparamwithmesh,'Value') && isempty(param)
            disp('The meshes file does not contain parameters')
        end
        undo = [];
        updateslider();
        displayImage();
        selDispList = [];
        displayCells();
        displaySelectedCells();
    end
end

% --- End of saving and loading cell data GUI nested functions ---

% --- Parameters GUI nested functions ---

function saveFileControl(hObject, eventdata)%#ok<INUSD>
     global filenametmp
    %Ask for a filename to save the data to
    [filename,pathname] = uiputfile('*.mat', 'Enter a filename to save settings to',filenametmp);
    if(filename==0), return; end;
    if length(filename)<5, filename = [filename '.mat']; end
    if ~strcmp(filename(end-3:end),'.mat'), filename = [filename '.mat']; end
    saveFile = fullfile2(pathname,filename);
    set(handles.saveFile,'String',filename);
end

function initP
    global se maskdx maskdy
% %     global wCell mC1 mC2 wthres wthres0
% %     A=load('cell_div_templates6.mat');
% %     wCell=A.w;
% %     mC1=A.mC1;
% %     mC2=A.mC2;
% %     wthres=A.wthres;
% %     wthres0=wthres;
    svalue = {'% Load parameters to continue';'%'};
    set(handles.params,'String',svalue);
    % edit2p;

    % Global derived parameters
    % initModel
    
    se = strel('arb',[0 1 0;1 1 1;0 1 0]); % erosion mask, can be 4 or 8 neighbors
    maskdx = fliplr(fspecial('sobel')'); %[-1 0 1; -2 0 2; -1 0 1]/2; % masks for computing x & y derivatives
    maskdy = fspecial('sobel');%[1 2 1; 0 0 0; -1 -2 -1]/2;
end

function edit2p
    str = getparamstring(handles);
    parseparameters(str)
end

function saveparam_cbk(hObject, eventdata)%#ok<INUSD>
    %Ask for a filename to save the data to
    global filenametmp
    [filename,pathname] = uiputfile2('*.set', 'Enter a filename to save settings to',filenametmp);
    if isequal(filename,0), return; end
    if length(filename)<=4
        filename = [filename '.set'];
    elseif ~strcmp(filename(end-3:end),'.set')
        filename = [filename '.set'];
    end
    filename = fullfile2(pathname,filename);
    paramFile = filename;
    %Save parameters
    str = getparamstring(handles);
    fileID = fopen(filename,'w');
    for i=1:size(str,1)
        if iscell(str)
            fprintf(fileID,[regexprep(str{i},'%','%%') char([13 10])]);
        else
            fprintf(fileID,[regexprep(strtrim(str(i,:)),'%','%%') char([13 10])]);
        end
    end
    fclose(fileID);
end

function loadparam_cbk(hObject, eventdata)%#ok<INUSD>
    global filenametmp
    disp('Loading settings...');
    [filename,pathname] = uigetfile2({'*.set';'*.mat'}, 'Load Settings file (.set)',filenametmp);
    if isequal(filename,0), return; end
    paramFile = fullfile2(pathname,filename);
    res=loadparam(paramFile);
    if iscell(res)&&length(res)==1, res=res{1}; end
    set(handles.params,'String',res);
    disp(['Parameters loaded from file ' filename]);
end

% --- End of parameters GUI nested functions ---

% --- Running processing GUI nested functions ---

function saveWhileProcessing_cbk(hObject, eventdata)%#ok<INUSD>
    if hObject==handles.saveEachFrame && get(handles.saveEachFrame,'Value')
        set(handles.saveWhenDone,'Value',0);
    elseif hObject==handles.saveWhenDone && get(handles.saveWhenDone,'Value')
        set(handles.saveEachFrame,'Value',0);
    end
end

function run_cbk(hObject, eventdata)%#ok<INUSD>
    if strcmp(num2str(saveFile),'tempresults.mat')
        warndlg('Press "File" button to select directory for analysis','!! Warning !!')
        return;
    end
    warning('off','MATLAB:warn_r14_stucture_assignment')
    global p filenametmp 
    if imsizes(end,1)==0, return; end
    edit2p();
    % range
    if hObject==handles.runframeAll
        range = [1 imsizes(end,3)];
    elseif hObject==handles.runframeThis || hObject==handles.segmenttest || hObject==handles.aligntest
        range = [frame frame];
    elseif hObject==handles.runframeRange
        range = [1 imsizes(end,3)];
        s = str2num(get(handles.runframeStart,'String'));
        if ~isempty(s), range(1) = max(s,range(1)); end
        s = str2num(get(handles.runframeEnd,'String'));
        if ~isempty(s), range(2) = min(s,range(2)); end
    end
    
    % mode
    if get(handles.runmode1,'Value'), mode=1; end
    if get(handles.runmode3,'Value'), mode=3; end
    if get(handles.runmode4,'Value'), mode=4; end
    
    % lst
    if get(handles.runselected,'Value')
        if isempty(selectedList), return; end
        lst = selNewFrame(selectedList,frame,max(range(1)-1,1));
    else
        lst = [];
    end
    
    % test mode
        if hObject==handles.segmenttest
            str = getparamstring(handles);
            parseparameters(str)
            p = testModeSegment(frame,regionSelectionRect,p); handles.segmentationRun = true; return;
        end
        if hObject == handles.aligntest
            if ~isfield(p,'algorithm') || p.algorithm==1, return; end
            p.fitDisplay = true;
            if hObject==handles.aligntest && mode==1 && frame>range(1)
                processFrameGreaterThanOne(frame,lst);
            
            elseif hObject==handles.aligntest && ismember(mode,[1 2 3])
                processFrameI(range(1),ismember(mode,[3 4]),regionSelectionRect);
            end
            return;
        end
        try
            if handles.textMode == 1 
                processTextMode(range,1,lst,[1 0 0 0],{0},'',0,0)
                return;
            end
        catch
            disp('----  If running  textMode, close textMode window for normal processing ----');
            disp('----------------------------------------------------------------------------');
            disp('----  If above statement is not true, then perform Segmentation ----');
        end
    
    % addsig
    addsig = [0 0 0 0];
    if get(handles.includePhase,'Value'), addsig(1) = 1; end
    if get(handles.includeSignal1,'Value'), addsig(3) = 1; end
    if get(handles.includeSignal2,'Value'), addsig(4) = 1; end
    
    % addas
    addas = {0,'-',1,2};
    s=get(handles.includePhaseAs,'String');   
    if ~isempty(str2num(s)), addas{1}=str2num(s); elseif ~isempty(s), addas{1}=s; end
    s=get(handles.includeSignal1As,'String'); 
    if ~isempty(str2num(s)), addas{3}=str2num(s); elseif ~isempty(s), addas{3}=s; end
    s=get(handles.includeSignal2As,'String'); 
    if ~isempty(str2num(s)), addas{4}=str2num(s); elseif ~isempty(s), addas{4}=s; end
    
    % savefile
    % main function variable 'saveFile' is used
    
    % fsave
    fsave=0;
    if get(handles.saveEachFrame,'Value'), fsave=1; end
    if get(handles.saveWhenDone,'Value'), fsave=[]; end
    
    process(range,mode,lst,addsig,addas,saveFile,fsave,get(handles.saveselected,'Value'),regionSelectionRect,shiftfluo,filenametmp,get(handles.highThroughput,'Value'));
    % Main processing function
    % 
    % range - range of frames to run, can be []-all frames
    % mode - 1-tlapse, 2-1st ind, 3-all ind, 4-reuse
    % lst - list of cells on the frame previous to range(1)
    % addsig - [0 0 0 0]=[0 0 0]=[0 0]=0=[]-no signal, 1st one phase, etc. 
    % addas - default {}={0,-,1,2}, if numeric X, creates signalX, else - X
    % savefile - filename to save to
    % fsave - frequence of saving, n-once per n frames, 0-never, []-end
    
    selDispList = [];
    displayCells
    if get(handles.runselected,'Value')
        selectedList = selNewFrame(lst,range(1),frame);
    else
        selectedList = [];
    end
    displaySelectedCells
    showCellData
end

% --- End of running processing nested functions ---

% --- Loading and saving images nested functions ---

function res = loadstackdisp(n,filename)
    [res,~] = loadimagestack(n,filename,1,1);
    global filenametmp
    filenametmp = filename;
    imsizes = updateimsizes(imsizes);
    updateslider
    displayImage
    displayCells
    selDispList = [];
    displaySelectedCells
    enableDetectionControls
end

function loadimagesdisp(n,folder)
    loadimages(n,folder)
    % updateimsizes
    updateslider
    displayImage
    displayCells
    selDispList = [];
    displaySelectedCells
    enableDetectionControls
end

function enableDetectionControls
    % Enable cell detection controls
    set(handles.runframeAll,'Enable','on');
    set(handles.runframeThis,'Enable','on');
    set(handles.runframeRange,'Enable','on');
    set(handles.alignframes,'Enable','on');
    set(handles.loadalignment,'Enable','on');
end

function loadstack(hObject, eventdata)
 
    chk = get(handles.loadcheck,'value'); % if yes, load image stack using Bioformats, otherwise load TIFFs
    global filenametmp
    if hObject==handles.loadphase
        if chk
            if bformats
                [filename,pathname] = uigetfile('*.*','Select Stack File with Phase Images...',imageFiles{1});
            else
                [filename,pathname] = uigetfile({'*.tif';'*.tiff'},'Select Stack File with Phase Images...',imageFiles{1});
            end
            if isequal(filename,0), return; end;
            
            %save this path as the lsat used path by oufti
            setLastDir(pathname);
            
            filename = fullfile(pathname,filename);
            filenametmp = imageFiles{1};
            imageFiles{1} = filename;
            res = loadstackdisp(1,filename);
            if res
                imageActive(1) = true;
            else
                imageFiles{1} = filenametmp;
            end
        else
            loadphase(hObject, eventdata)
        end
    elseif hObject==handles.loads1
        if chk
            if bformats
                [filename,pathname] = uigetfile('*.*','Select Stack File with Signal 1 Images...',filenametmp);
            else
                [filename,pathname] = uigetfile({'*.tif';'*.tiff'},'Select Stack File with Signal 1 Images...',filenametmp);
            end
            if isequal(filename,0), return; end;
            filename = fullfile(pathname,filename);
            filenametmp = imageFiles{3};
            imageFiles{3} = filename;
            res = loadstackdisp(3,filename);
            if res
                imageActive(3) = true;
            else
                imageFiles{3} = filenametmp;
            end
        else
            loads1(hObject, eventdata)
        end
    elseif hObject==handles.loads2
        if chk
            if bformats
                [filename,pathname] = uigetfile('*.*','Select Stack File with Signal 2 Images...',filenametmp);
            else
                [filename,pathname] = uigetfile({'*.tif';'*.tiff'},'Select Stack File with Signal 2 Images...',filenametmp);
            end
            if isequal(filename,0), return; end;
            filename = fullfile(pathname,filename);
            filenametmp = imageFiles{4};
            imageFiles{4} = filename;
            res = loadstackdisp(4,filename);
            if res
                imageActive(4) = true;
            else
                imageFiles{4} = filenametmp;
            end
        else
            loads2(hObject, eventdata)
        end
    end
end

function loadphase(hObject, eventdata)%#ok<INUSD>
    global rawPhaseFolder
    rawPhaseFolder = uigetdir(imageFolders{1},'Select Directory with Phase Images...');
    
    setLastDir(rawPhaseFolder);
    
    if isequal(rawPhaseFolder,0), return; end;
    imageActive(1) = false;
    loadimagesdisp(1,rawPhaseFolder)
end

function setLastDir(infolder)
    
%     [ouftiLocation,'\lastDir.mat']
    lastDir = infolder;

    try
        save([ouftiLocation,'/lastDir'],'lastDir')
    catch
        warning('Could not update last directory used')
    end

end

function loadfm(hObject, eventdata)%#ok<INUSD>
    global rawFMFolder
    rawFMFolder = uigetdir(imageFolders{2},'Select Directory with Extra Images...');
    if isequal(rawFMFolder,0), return; end;
    imageActive(2) = false;
    loadimagesdisp(2,rawFMFolder)
end

function loads1(hObject, eventdata)%#ok<INUSD>
    global rawS1Folder
    rawS1Folder = uigetdir(imageFolders{1},'Select Directory with Signal 1 Images...');
    if isequal(rawS1Folder,0), return; end;
    imageActive(3) = false;
    loadimagesdisp(3,rawS1Folder)
end

function loads2(hObject, eventdata)%#ok<INUSD>
    global rawS2Folder
    rawS2Folder = uigetdir(imageFolders{1},'Select Directory with Signal 2 Images...');
    if isequal(rawS2Folder,0), return; end;
    imageActive(4) = false;
    loadimagesdisp(4,rawS2Folder)
end

% --- End of loading and saving images nested functions ---

end % ------------------------- END MAIN FUNCTION -------------------------

% External functions: Initializations  

%%

function operationButtons(hObject, eventdata)

operationButtonsCallFunction(hObject,eventdata);

end

%% Aligning global functions

function loadalign(filename)
    global shiftframes
    % This function loads aligning data from file <filename>
    % The file must exist and be a .mat file
    % Intended use: with "alignphaseframes" callback & batch files
    loaded = load(filename,'shiftframes');
    if ~isfield(loaded,'shiftframes'), disp('This file does not contain alignment data'); return; end
    shiftframestmp = loaded.shiftframes;
    if ~isstruct(shiftframestmp), disp('This file does not contain alignment data'); return; end
    if ~isfield(shiftframestmp,'x') || ~isfield(shiftframestmp,'y'), disp('This file does not contain alignment data'); return; end
    shiftframes.x = shiftframestmp.x;
    shiftframes.y = shiftframestmp.y;
    disp('Alignment data loaded')
end

function savealign(filename)
    global shiftframes %#ok<NUSED>
    % This function saves aligning data to file <filename>
    % The file must be a .mat file
    % Intended use: with "alignphaseframes" callback & batch files
    save(filename,'shiftframes');
    disp('Alignment data saved')
end

function alignfrm
    % This function alignes phase images
    % The result is stored in "shiftframes" structure with x & y fields of the main function 
    % Intended use: with "alignphaseframes" callback & batch files
    global rawPhaseData p shiftframes
    
    if checkparam(p,'aligndepth'), disp('Images not aligned: parameter "aligndepth" not provided.'); return; end
    if isempty(rawPhaseData), disp('Images not aligned: no phase images loaded.'); return; end
%-------------------------------------------------------------------------------------------
% % %     [shiftframes.x,shiftframes.y]=alignframes(rawPhaseData,p.aligndepth);
%update: Ahmad.P Sept. 25, 2012
%alignImages function uses fast-normalized cross-correlation technique to
%find shift between images and returns data for x and y shifts stored in
%shiftframes structure.
try
    [shiftframes.x,shiftframes.y]=alignImages(rawPhaseData);
catch err
    disp('Images not aligned:  check shiftframes structure to find which images were aligned.')
    disp(err.message)
end
%-------------------------------------------------------------------------------------------
disp('Images aligned')
end

%% Initialization global functions

function cleardata
global handles1 rawPhaseData rawS1Data rawS2Data cellList cellListN selectedList shiftframes imsizes handles %#ok<NUSED>
try
if exist('handles','var') && isstruct(handles)
        fields = fieldnames(handles);
        for i=1:length(fields)
            eval(['cfield = handles.' fields{i} ';'])
            if ishandle(cfield)
                delete(cfield);
            elseif isstruct(cfield)
                fields2 = fieldnames(cfield);
                for k=1:length(cfield)
                    for j=1:length(fields2)
                        eval(['if ishandle(cfield(' num2str(k) ').' fields2{j} '), delete(cfield(' num2str(k) ').' fields2{j} '); end'])
                    end
                end
            end
        end
end
catch
     clear global rawPhaseData rawS1Data rawS2Data cellList cellListN selectedList shiftframes imsizes handles handles1
     close force gcf
end
% cleas variables
   clear global rawPhaseData rawS1Data rawS2Data cellList cellListN selectedList shiftframes imsizes handles handles1
   close force gcf
  
end

%% Batch global functions

function batchtextrun_glb(s)
%--------------------------------------------------------------------------
%pragma instructs the compiler to include functions for deployment.
%#function divisionframe1 divisionframe2 savemesh process forcesplitcell forcesplitcellSetsu 
%#function processIndividualCells interp2_ edgeforce getExtForces
%#function processFrameGreaterThanOneTextMode processTextMode
%--------------------------------------------------------------------------
 
eval(s);

end

%% Images global function

function subtractbgr(channels,range,varargin)
    % background subrtaction routine:
    % "channels" - list of channels (3-signal 1, 4-signal 2)
    % "range" - [first_frame last_frame] (empty = all frames)
    % "invert" (optional) - invert the "phase" image
    
    global rawPhaseData rawS1Data rawS2Data imsizes p
    
    if checkparam(p,'bgrErodeNum') || ~strcmp(class(p.bgrErodeNum),'double')
        disp('Background subtraction failed: parameter "bgrErodeNum" not provided.');
        return
    end
    if length(varargin)>=1
        invert = varargin{1};
    else
        invert = false;
    end
    if isempty(channels), channels = [3 4]; end
    if min(imsizes(channels,1))<2, return; end
    if isempty(rawPhaseData), disp('Background subtraction failed: no phase images loaded'); return; end
    if isempty(range), range = [1 10000]; end
    if length(range)==1, range = [range range]; end
    f = channels*0;
    for g=1:length(channels)
        if channels(g)==3
            if imsizes(3,1)<2, continue;
            else crange=[max(1,range(1)) min(imsizes(3,3),range(2))];
            end
        elseif channels(g)==4
            if imsizes(4,1)<2, continue; % isempty(who('rawS2Data')) || isempty(rawS2Data), 
            else crange=[max(1,range(1)) min(imsizes(4,3),range(2))];
            end
        else
            continue
        end
        if imsizes(1,3)==1 && crange(2)>crange(1)
            disp('Background subtraction warning: using single phase contrast image for multiple signal images');
        elseif imsizes(1,3)<crange(2)
            disp('Background subtraction error: the number of phase contrast and signal images not matching');
            continue
        end
        for i=crange(1):crange(2)
            f(g) = 1;
            if imsizes(1,3)==1
                imgP = rawPhaseData(:,:,1);
            else
                imgP = rawPhaseData(:,:,i);
            end
            if isempty(imgP), continue; end
            if channels(g)==3, signalImage = rawS1Data(:,:,i); end
            if channels(g)==4, signalImage = rawS2Data(:,:,i); end
            if size(signalImage,1)~=size(imgP,1) || size(signalImage,2)~=size(imgP,2)
                disp('Background subtraction error: the images are of different size.')
                break
            end
            if invert, imgP = max(max(imgP))-imgP; end
            %%%imgP = highPassFilter(imgP,120);
            thres = graythreshreg(imgP,p.threshminlevel);
            %%%thres = graythresh(imgP);
            %--------------------------------------------------------------
            %update Ahmad.P October 22,2012
            %create binary mask of the phase image based on 'thres' value.
            %The mask is the adjacent area around each cell/cell group.
            mask = im2bw(imgP,thres);
            %errosion is not necessary if we are to fit the gaussian curve
            %on our intensity range
            %%%for k=1:p.bgrErodeNum, mask = imerode(mask,se); end
            
            %define intensity values using mask from the signal image
            bgr = signalImage(mask);
            mu = mean(double(bgr));
            sigma = std(double(bgr));
            %find outliers in the intensity range using 1 standard
            %deviation
            outliers = (bgr-mu)>sigma;
            %erase outliers values from the intensity vector 'bgr'
            bgr(outliers) = [];
            %fit a normal distribution curve on the intensity vector 'bgr'
            %and find the mean of the fitted curve
% % %             [mu1,s1] = normfit(double(bgr));
            obj = gmdistribution.fit(double(bgr),1);
            mu1 = obj.mu;
            backgroundIntensityMean = mu1;
            %change signal image to 32-bit format
            img0 = int32(signalImage);
            %subtract 'backgroundIntensityMean from the image signal 
            img1 = img0-backgroundIntensityMean;
            %img2 = max(0,img1);
            %convert image back to 16-bit format
            %img = uint16(img1);
            img = img1;
            %--------------------------------------------------------------
            if channels(g)==3, rawS1Data(:,:,i) = img; end
            if channels(g)==4, rawS2Data(:,:,i) = img; end
            if mod(i,5)==0, disp(['Subtracting background from signal ' num2str(channels(g)-2) ', frame ' num2str(i)]); end
        end
    end
    if sum(f)>1
        disp(['Subtracting backgroung completed from ' num2str(sum(f)) ' channels']);
    elseif sum(f)==1
        disp(['Subtracting backgroung completed from signal ' num2str(channels(f)-2)]);
    end
end



function loadimages(n,folder)
    % loads TIFF (image) files into the specified channel:
    % "n" - channel (1-phase, 2-extra, 3-signal1, 4-signal2)
    % "folder" - folder name
    % for actual loading uses loadimageseries routine
    
 %-------------------------------------------------------------------------
 %pragma function needed to include files for deployment
 %#function loadimageseries 
 %-------------------------------------------------------------------------
    global cellList rawPhaseData rawS1Data rawS2Data imsizes filenametmp imageFolders imageLimits imageForce %#ok<NUSED>
    if n==1, str='rawPhaseData'; end
    % if n==2, str='rawFMData'; end
    if n==3, str='rawS1Data'; end
    if n==4, str='rawS2Data'; end
    filenames = ''; %#ok<NASGU>
    dirname = ''; %#ok<NASGU>
    imageFolders{n} = folder;
    filenametmp = folder;
    eval(['[' str ', filenames, folder] = loadimageseries(folder,1);']);
    eval(['cls = class(' str ');']);
    if strcmp(cls,'uint8'), lng=8; elseif strcmp(cls,'uint16'), lng=16; elseif strcmp(cls,'uint32'), lng=32;
        else disp('No images loaded');return; end
    eval(['imageLimits{n} = 2^' num2str(lng) '*mean(stretchlim(' str ',[0.0001 0.9999]),2);']);
    %eval(['imageLimits{n} = im2double([min(min(min(' str '))) max(max(max(' str ')))]);']);
    if(folder==-1), return; end; 
    eval(['imsizes(n,:) = [size(' str ',1) size(' str ',3) size(' str ',3)];']);
    disp(['Loaded ' num2str(imsizes(n,3)) ' files'])
    imsizes = updateimsizes(imsizes);
    imageForce = [];
    numImages = imsizes(n,3);
    for ii = 1:imsizes(n,3)
        imageForce(ii).forceX = [];
        imageForce(ii).forceY = [];
    end
    if  ~isempty(cellList.meshData{1}) && sum(cellfun(@isempty,cellList.meshData)) ~= numImages || (numel(cellList.meshData) == 1 && ~isempty(cellList.meshData{1}))
        newData = questdlg('New Dataset?','new cellList','yes','no','yes');
         switch newData
             case 'yes'
                 clear global cellList;
                 cellList = oufti_initializeCellList();
             case 'no'
                cellList = oufti_allocateCellList(cellList,1:imsizes(n,3));
         end
    else
         cellList = oufti_allocateCellList(cellList,1:imsizes(n,3));
    end
end

function imsizes =  updateimsizes(imsizes)
    % Updates the structure "imsizes" chat contains the information about 
    % the size of each images stack (phase, extra, signa1, signal2) and
    % the area occupied by the meshes. Needed for display purposes.
    global rawPhaseData rawS1Data rawS2Data cellList regionSelectionRect mode
    if ~isfield(cellList,'meshData')
        cellList = oufti_makeNewCellListFromOld(cellList);
    end
    imsizesold = imsizes;
    imsizes(1,:)=[size(rawPhaseData,1) size(rawPhaseData,2) size(rawPhaseData,3)];
    % imsizes(2,:)=[size(rawFMData,1) size(rawFMData,2) size(rawFMData,3)];
    imsizes(3,:)=[size(rawS1Data,1) size(rawS1Data,2) size(rawS1Data,3)];
    imsizes(4,:)=[size(rawS2Data,1) size(rawS2Data,2) size(rawS2Data,3)];
    imsizes(5,:)=imsizes(1,:);
    if mode ~=3
    if oufti_doesFrameExist(1, cellList) && ~oufti_isFrameEmpty(1, cellList) % ~isempty(cellList)
        xmax=0;
        ymax=0;
        frmmax = oufti_getLengthOfCellList(cellList); % length(cellList);
        for frm=1:max(1,floor(frmmax/3)):frmmax
            [~, cellId] = oufti_getFrame(frm, cellList);
            for i = cellId
                cell = oufti_getCellStructure(i, frm, cellList);
                if ~isempty(cell)
                    box = double(cell.box);
                    xmax = max(xmax,box(2)+box(4));
                    ymax = max(ymax,box(1)+box(3));
                end
            end
        end
    
        imsizes(end,:) = max([imsizes(1:end-1,:);[xmax ymax oufti_getLengthOfCellList(cellList)]]);
    else
        imsizes(end,:) = max(imsizes(1:end-1,:));
    end
    if imsizes(end,1)==0, imsizes(end,:) = [400 500 1]; end
    if ~prod((imsizesold(end,:)==imsizes(end,:))+0)
        regionSelectionRect = [];
    end
    
    else
      if ~isempty(cellList.meshData)
        xmax=0;
        ymax=0;
        frmmax = length(cellList.meshData);
        for frm=1:max(1,floor(frmmax/3)):frmmax
            for i=1:length(cellList.meshData{frm})
                if ~isempty(cellList.meshData{frm}{i}) && isfield(cellList.meshData{frm}{i},...
                        'box')
                    box = cellList.meshData{frm}{i}.box;
                    xmax = max(xmax,box(2)+box(4));
                    ymax = max(ymax,box(1)+box(3));
                end
            end
        end
        imsizes(end,:) = max([imsizes(1:end-1,:);[xmax ymax length(cellList.meshData)]]);
      else
        imsizes(end,:) = max(imsizes(1:end-1,:));
      end
    if imsizes(end,1)==0, imsizes(end,:) = [400 500 1]; end
    if ~prod((imsizesold(end,:)==imsizes(end,:))+0)
        regionSelectionRect = [];
    end
    end

   
end

%% Parameters global functions

function res = getparamstring(hndls)
    str = get(hndls.params,'String');
    if ~iscell(str) && size(str,1)==1
        res = textscan(str,'%s','delimiter','');
    elseif ~iscell(str) && size(str,1)>1
        for i=1:size(str,1)
            tmp1 = strtrim(str(i,:));
            if ~isempty(tmp1)
                tmp2 = textscan(tmp1,'%s','delimiter','');
                str2{i,1} = tmp2{1}{1};
            end
        end
        res = str2;
    else
        res = str;
    end
    if length(res)==1
        res=res{1};
    end
end

function res=loadparam(filename)
% loads parameters either from parameters file or from meshes file, in
% first case the file is a text file, in the second - a string variable
% the function sends the data to "parseparameters" function (updates the 
% global variable "p") and returns the data string to display
    if length(filename)>4 && strcmp(filename(end-3:end),'.set')
        try
            res = fileread(filename); % Saving/loading format
        catch
            errordlg(['Could not open parameters file! Make sure the file exists and'...
                ' the parameters are saved in the correct format.']);
            return;
        end;
    elseif length(filename)>4 && strcmp(filename(end-3:end),'.mat')
        res = load(filename);
        if isempty(res)
            errordlg('Could not parce parameters! No parameters saved in this file.');
            return;
        else
            try
                res = {res.paramString};
                % res = textscan(str,'%s','delimiter','');
            catch
                errordlg('Could not parse parameters! Make sure the parameters are saved in the correct format.');
                return;
            end
        end
    else
        errordlg('Could not open parameters file! File extension must be ".set" or ".mat".');
        return;
    end
    if ~iscell(res)
        res=textscan2(res);
        % res = textscan(res,'%s','delimiter','');
        % res=res{1};
    end
    parseparameters(res)
end

function res=textscan2(str)
    str = strtrim(str);
    str = regexprep(str,char([13 10]),char(10));
    str = regexprep(str,char([92 110]),char(10));
    pos = [0 sort([strfind(str,char(10)) strfind(str,'\n')]) length(str)+1];
    res = {};
    for i=1:length(pos)-1
        if pos(i)+1<=pos(i+1)-1
            res{i,1} = str(pos(i)+1:pos(i+1)-1);
        else
            res{i,1} = '';
        end
    end
end

%% Saving mesh global functions

function param = loadmesh(filename)
    % loads mesh from the specified file, updates "cellList" and
    % "cellListN" structures, sets "selectedList" to empty = no cells
    % selected, returns parameters structure (which can be used or not,
    % depending on the "Load params" checkbox)
    global cellList handles1 cellListN selectedList handles paramString rawPhaseData
    %warning off
    isHighThroughput = get(handles.highThroughput,'value');
    try
        warning('off','MATLAB:load:variableNotFound');
    catch
    end
    if strcmp('out',filename(end-2:end)) && isHighThroughput
       dataChoice = questdlg('Load all data set?',...
                        'text file','Yes','No','No');

        switch dataChoice
            case 'Yes'
                [l.cellList,l.paramString] = csv2cell(filename, ',', '#', '"','textual-usewaitbar',[]);
            case 'No'
                prompt = {'Enter frame number to load:'};
                dlg_title = 'Frame Value';
                num_lines = 1;
                frameNumber = str2double(inputdlg(prompt,dlg_title,num_lines));
                if isempty(frameNumber) || isnan(frameNumber), param = []; return;end
                [cellListTemp,l.paramString] = csv2cell(filename, ',', '#', '"','textual-usewaitbar',frameNumber);
                l.cellList = oufti_initializeCellList;
                l.cellList.meshData = cell(1,size(rawPhaseData,3));
                l.cellList.cellId   = cell(1,size(rawPhaseData,3));
                if isempty(cellListTemp)
                    param = paramString; return; 
                else 
                    l.cellList.meshData(frameNumber) = cellListTemp.meshData;
                    l.cellList.cellId{frameNumber}   = cellListTemp.cellId{:};
                end
                
            otherwise
                param = paramString;
                return;
        end
        
       
    else
        l=load(filename,'cellList','cellListN','paramString','objectParams','spotParams');
       
    end
    %warning on
	 % New or old cellList?
    if isstruct(l.cellList)
        % new
        disp('Loading cellList...')
        cellList = l.cellList;
        if ~isfield(l,'cellListN')
            cellListN = cellfun(@length,cellList.meshData);
        else
            cellListN = l.cellListN;
        end
        selectedList = [];
        if isfield(l,'objectParams')
            handles1.objectParams = l.objectParams;
        end
        if isfield(l,'spotParams')
            handles1.spotParams = l.spotParams;
        end
        if isfield(l,'paramString')
            param = l.paramString;
        else
            param = [];
        end
    else
        % old
        disp('Loading old cellList and converting to new format...')
        cellList = oufti_makeNewCellListFromOld(l.cellList);
        if ~isHighThroughput
        disp('Converting CellList to new format...')
        cellList = oufti_makeCellListSingle(cellList);
        sz = whos('cellList');
        disp (['Size is now ' num2str(sz.bytes) ' bytes'])
        end
        if isfield(l,'objectParams')
            handles1.objectParams = l.objectParams;
        end
        if isfield(l,'spotParams')
            handles1.spotParams = l.spotParams;
        end
        if ~isfield(l,'cellListN')
            cellListN = cellfun(@length,cellList.meshData);
        else
            cellListN = l.cellListN;
        end
        selectedList = [];
    
        if isfield(l,'paramString')
            param = l.paramString;
        else
            param = [];
        end
        
    end
   
    disp(['Meshes loaded from file ' filename])
end


function refinecell(frame,lst)
% this function runs the alignment again for the selected cells
% only for algorithms 2-4
global cellList cellListN p rawPhaseData se maskdx maskdy cellsToDragHistory imageForce

if length(lst) > 10
   refineAllParallel(frame,lst);
    
else


    if checkparam(p,'invertimage','algorithm','erodeNum','meshStep','meshTolerance','meshWidth')
        disp('Refining cells failed: one or more required parameters not provided.');
        return
    end
    if ~oufti_isFrameNonEmpty(frame, cellList) || (isempty(lst) && isempty(cellsToDragHistory)), return; end;
    if ~ismember(p.algorithm,[2 3 4]), disp('There is no refinement routine for algorithm 1'); return; end
    if frame>size(rawPhaseData,3), return; end
    if p.invertimage        
        img = max(max(max(rawPhaseData)))-rawPhaseData(:,:,frame);
    else
        img = rawPhaseData(:,:,frame);
    end
    imge = img2imge(img,p.erodeNum,se);
    imge16 = img2imge16(img,p.erodeNum,se);
    if gpuDeviceCount == 1
        try
            thres = graythreshreg(gpuArray(imge),p.threshminlevel);
        catch
            thres = graythreshreg(imge,p.threshminlevel);
        end
    else
        thres = graythreshreg(imge,p.threshminlevel);
    end
    if gpuDeviceCount == 1
        try
           [extDx,extDy,imageForce(frame)] = getExtForces(gpuArray(imge),gpuArray(imge16),gpuArray(maskdx),gpuArray(maskdy),p,imageForce(frame));
           extDx = gather(extDx);
           extDy = gather(extDy);
           imageForce(frame).forceX = gather(imageForce(frame).forceX);
           imageForce(frame).forceY = gather(imageForce(frame).forceY);
        catch
            [extDx,extDy,imageForce(frame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(frame));
        end
    else
        [extDx,extDy,imageForce(frame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(frame));
    end
    if isempty(extDx), disp('Refining cells failed: unable to get energy'); return; end
    n = 0;
    tempCellList1 = cellList;
    tempP = p;
    tempSe = se;
    tempMaskdx = maskdx;
    tempMaskdy = maskdy;
    tempCellListN = cellListN;
    meshData = cell(1,numel(lst));
    cellId   = cell(1,numel(lst));

    if ~isempty(cellsToDragHistory)
        disp('Refining recently dragged cells');
        lst = cellsToDragHistory;
    end
    
     for celln = 1:length(lst)
        pcCell = [];
        cCell = [];
        prevStruct = oufti_getCellStructure(lst(celln), frame, tempCellList1);
        roiBox = prevStruct.box;
        roiImg = imcrop(imge,roiBox);
        roiBox(3:4) = [size(roiImg,2) size(roiImg,1)]-1;
        roiExtDx = imcrop(extDx,roiBox);
        roiExtDy = imcrop(extDy,roiBox);
        % Now split the cell
        if isfield(prevStruct,'mesh') && size(prevStruct.mesh,1)>1
            mesh = prevStruct.mesh;
            if ismember(tempP.algorithm,[2 3])
                pcCell = splitted2model(mesh,tempP,tempSe,tempMaskdx,tempMaskdy);
                pcCell = model2box(pcCell,roiBox,tempP.algorithm);
                pcCell = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,tempP,false,roiBox,thres,[frame lst(celln)]);
                pcCell = box2model(pcCell,roiBox,tempP.algorithm);
                cCell  = double(model2geom(pcCell,tempP.algorithm));
            elseif ismember(tempP.algorithm,4)
                pcCell = align4IM(mesh,tempP);
                pcCell = model2box(pcCell,roiBox,tempP.algorithm);
                cCell = align4Manual(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,tempP,roiBox,thres,[frame lst(celln)]);
                cCell = double(box2model(cCell,roiBox,tempP.algorithm));
            end
            if isempty(cCell), disp(['Cell ' num2str(lst(celln)) ' refinement failed: error fitting shape']); continue; end
            mesh = model2MeshForRefine(cCell,tempP.meshStep,tempP.meshTolerance,tempP.meshWidth);
            if (isempty(mesh) || size(mesh,1) == 1), disp(['Cell ' num2str(lst(celln)) ' refinement failed: error getting mesh']); continue; end
            if size(pcCell,2)==1, model=cCell'; else model=cCell; end
            prevStruct.model = single(model);
            prevStruct.mesh = single(mesh);
            roiBox(1:2) = floor(max([min(min(mesh(:,[1 3]))) min(min(mesh(:,[2 4])))]-tempP.roiBorder,1));
            roiBox(3:4) = ceil(min([max(max(mesh(:,[1 3]))) max(max(mesh(:,[2 4])))]+tempP.roiBorder,[size(img,2) size(img,1)])-roiBox(1:2));
            prevStruct.box = roiBox;
            if ~isfield(prevStruct,'timelapse')
                if ismember(0,tempCellListN(1)== tempCellListN) || length(tempCellListN)<=1
                    prevStruct.timelapse = 0;
                else
                    prevStruct.timelapse = 1;
                end
            end
            %%%cellList.meshData{frame}{cell} = getextradata(prevStruct);
            meshData{celln} = prevStruct;
            cellId{celln} = lst(celln);
            n = n+1;
        end
     end
    disp(['Refinement of ' num2str(n) ' cells succeeded'])
    for ii = 1:numel(cellId)
        if ~isempty(cellId{ii})
            cellList = oufti_addCell(cellId{ii},frame,meshData{ii},cellList);
        end
    end
end
cellsToDragHistory = [];
end


function res = forcejoincells(frame,lst) 
    res = false;
    global cellList cellListN p se rawPhaseData maskdx maskdy imageForce
    cellListN = cellfun(@length,cellList.meshData);
    if checkparam(p,'invertimage','algorithm','erodeNum','roiBorder','meshStep','meshTolerance','meshWidth','joindilate')
        disp('Joining cells failed: one or more required parameters not provided.');
        res = false;
        return
    end    
    if ~ismember(p.algorithm,[2 3 4])
        cell1 = oufti_getCellStructure(lst(1),frame,cellList);
        cell2 = oufti_getCellStructure(lst(2),frame,cellList);
        cell1.model = double(cell1.model);
        cell2.model = double(cell2.model);
         % Start the joining procedire immediately without checking distance
        border = p.roiBorder;
        box = zeros(length(lst),4);
        if p.invertimage
            img = max(max(max(rawPhaseData)))-rawPhaseData(:,:,frame);
        else
            img = rawPhaseData(:,:,frame);
        end
        for i=1:length(lst)
            cell = oufti_getCellStructure(lst(i), frame, cellList);
            if isfield(cell,'mesh')
                mesh{i} = double(cell.mesh);
                box(i,:) = [min(min(mesh{i}(:,[1 3]))) min(min(mesh{i}(:,[2 4]))) (-max(max(mesh{i}(:,[1 3])))) (-max(max(mesh{i}(:,[2 4]))))];
            elseif isfield(cell,'model')
                model{i} = double(cell.model);
                box(i,:) = [min(model{i}(:,1)) min(min(model{i}(:,2))) (-max(max(model{i}(:,1)))) (-max(max(model{i}(:,2))))];
            end
        end
        roiBox = min(box);
        roiBox = [max(floor(roiBox(1:2)-border),1) min(ceil(-roiBox(3:4)+border),[size(img,2) size(img,1)])];
        roiBox = [roiBox(1:2) roiBox(3:4)-roiBox(1:2)]+1;
        mask1 = poly2mask([cell1.model(:,1);cell1.model(1,1)]-roiBox(1)+1,[cell1.model(:,2);cell1.model(1,2)]-roiBox(2)+1,roiBox(4),roiBox(3));
        mask2 = poly2mask([cell2.model(:,1);cell2.model(1,1)]-roiBox(1)+1,[cell2.model(:,2);cell2.model(1,2)]-roiBox(2)+1,roiBox(4),roiBox(3));
        mask = mask1 | mask2;
        mask = conv2(double(mask),ones(5));
        mask = imerode(mask,se);
        mask = imerode(mask,se);
        try
            maskBoundary = align4Initial(mask,p);
        catch
        end
        if size(maskBoundary,2) == 2 &&   size(maskBoundary,1) > 2 
            for i=2:length(lst)
                cellList = oufti_removeCellStructureFromCellList(lst(i), frame, cellList);
            end
            cellStructure.model(:,1) = maskBoundary(:,1) + roiBox(1)-3;  %box2model([x y],roiBox,1);
            cellStructure.model(:,2) = maskBoundary(:,2) + roiBox(2)-3;
            cCell = model2geom(cellStructure.model,1);            
            if p.getmesh
                if ~isfield(p,'meshstep') && isfield(p,'meshStep')
                    try
                        p.meshstep = p.meshStep;
                    catch
                        p.meshstep = 1;
                    end
                end
                cellStructure.mesh = model2MeshForRefine(cCell,p.meshstep,p.meshTolerance,p.meshWidth+3);
                if cellStructure.mesh == 0
                    cellStructure.mesh = model2MeshForRefine(cCell,p.meshstep,0.001,p.meshWidth+3);
                end
            else
                cellStructure.mesh = 0;
            end
            cellStructure.box = roiBox;
            cellStructure.algorithm = 1;
            cellStructure.birthframe = frame;
            cellStructure.stage = 1;
            cellStructure.polarity = 2;
            cellStructure.timelapse = 0;
            cellStructure.divisions = [];
            cellStructure.ancestors = [];
            cellStructure.descendants = [];
            cellList = oufti_addCell(lst(1), frame, cellStructure, cellList);
            disp(['Joined cells ' num2str(lst) ' - success, saved as cell ' num2str(lst(1))]);
            res = true;
        else
            disp(['Tried to join cells ' num2str(lst)]);
        end
        return; 
    
    end
    if length(lst) < 2 || ~oufti_doesCellStructureHaveMesh(lst(1), frame, cellList) || ~oufti_doesCellStructureHaveMesh(lst(2), frame, cellList)
        res = [];
        return;
    end
   
    if frame>size(rawPhaseData,3), return; end
    if p.invertimage
        img = max(max(max(rawPhaseData)))-rawPhaseData(:,:,frame);
    else
        img = rawPhaseData(:,:,frame);
    end
    imge = img2imge(img,p.erodeNum,se);
    imge16 = img2imge16(img,p.erodeNum,se);
    
    if gpuDeviceCount == 1
        try
           thres = graythreshreg(gpuArray(imge),p.threshminlevel);
           [extDx,extDy,imageForce(frame)] = getExtForces(gpuArray(imge),gpuArray(imge16),gpuArray(maskdx),gpuArray(maskdy),p,imageForce(frame));
           extDx = gather(extDx);
           extDy = gather(extDy);
           imageForce(frame).forceX = gather(imageForce(frame).forceX);
           imageForce(frame).forceY = gather(imageForce(frame).forceY);
        catch
            thres = graythreshreg(imge,p.threshminlevel);
            [extDx,extDy,imageForce(frame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(frame));
        end
    else
        thres = graythreshreg(imge,p.threshminlevel);
        [extDx,extDy,imageForce(frame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(frame));
    end

    if isempty(extDx), disp('Force joining cells failed: unable to get energy'); return; end
    
    % Start the joining procedire immediately without checking distance
    border = p.roiBorder;
    mesh = {};
    box = zeros(length(lst),4);
    for i=1:length(lst)
        cell = oufti_getCellStructure(lst(i), frame, cellList);
        mesh{i} = double(cell.mesh);
        box(i,:) = [min(min(mesh{i}(:,[1 3]))) min(min(mesh{i}(:,[2 4]))) (-max(max(mesh{i}(:,[1 3])))) (-max(max(mesh{i}(:,[2 4]))))];
    end
    roiBox = min(box);
    roiBox = [max(floor(roiBox(1:2)-border),1) min(ceil(-roiBox(3:4)+border),[size(img,2) size(img,1)])];
    roiBox = [roiBox(1:2) roiBox(3:4)-roiBox(1:2)]+1;
    
    % Create a mask
    mask = poly2mask([mesh{1}(:,1);flipud(mesh{1}(:,3))]-roiBox(1)+1,[mesh{1}(:,2);flipud(mesh{1}(:,4))]-roiBox(2)+1,roiBox(4),roiBox(3));
    if p.joindilate<0
        for j=1:-p.joindilate
            mask = imerode(mask,se);
        end
    end
    p1 = mesh{1}(1,:);
    p2 = mesh{1}(end,:);
    p1a = mesh{1}(4,:);
    p2a = mesh{1}(end-3,:);
    lst2 = 2:length(lst);
    for i=1:length(lst)-1
        dsn = [];
        ind = [];
        for j=lst2
            [dsn2,ind2] = min([dstm(p1-mesh{j}(1,:)) dstm(p1-mesh{j}(end,:)) dstm(p2-mesh{j}(1,:)) dstm(p2-mesh{j}(end,:))]);
            dsn = [dsn dsn2];%#ok<AGROW>
            ind = [ind ind2];%#ok<AGROW>
        end
        [~,ind3] = min(dsn);
        ind4 = ind(ind3);
        mesh2 = mesh{lst2(ind3)};
        lst2 = lst2(lst2~=lst2(ind3));
        if ind4==1 || ind4==2, p1b = p1a; else p1b = p2a; end
        if ind4==1 || ind4==3, p2b = mesh2(4,:); else p2b = mesh2(end-3,:); end
        mask2 = poly2mask([mesh2(:,1);flipud(mesh2(:,3))]-roiBox(1)+1,[mesh2(:,2);flipud(mesh2(:,4))]-roiBox(2)+1,roiBox(4),roiBox(3));
        mask3 = poly2mask([p1b(1) p2b(1) p2b(3) p1b(3)]-roiBox(1)+1,[p1b(2) p2b(2) p2b(4) p1b(4)]-roiBox(2)+1,roiBox(4),roiBox(3));
        mask4 = poly2mask([p1b(1) p2b(3) p2b(1) p1b(3)]-roiBox(1)+1,[p1b(2) p2b(4) p2b(2) p1b(4)]-roiBox(2)+1,roiBox(4),roiBox(3));
        if p.joindilate<0
            for j=1:-p.joindilate
                mask2 = imerode(mask2,se);
                mask3 = imerode(mask3,se);
                mask4 = imerode(mask4,se);
            end
        end
        if sum(sum(mask.*mask2))>100, mask3=0; mask4=0; end
        mask = min(1,mask+mask2+mask3+mask4);
        if ind4==1, p1 = mesh2(end,:); p1a = mesh2(end-3,:); end
        if ind4==2, p1 = mesh2(1,:); p1a = mesh2(4,:); end
        if ind4==3, p2 = mesh2(end,:); p2a = mesh2(end-3,:); end
        if ind4==4, p2 = mesh2(1,:); p2a = mesh2(4,:); end
    end
    if p.joindilate>0
        for j=1:p.joindilate
            mask = imdilate(mask,se);
        end
    end
    edg = bwperim(mask);

    pmap = 1 - edg;
    f1=true;
    while f1
        pmap1 = 1 - edg + imerode(pmap,se);
        f1 = max(max(pmap1-pmap))>0;
        pmap = pmap1;
    end;
    pmapEnergy = pmap + 0.1*pmap.^2;
    pmapDx = imfilter(pmapEnergy,maskdx); % distance forces
    pmapDy = imfilter(pmapEnergy,maskdy); 
    pmapDxyMax = 10;
    pmapDx = pmapDx/pmapDxyMax; % normalize to make the max force equal to 1
    pmapDy = pmapDy/pmapDxyMax;

    % roiBox2 = roiBox+[1 1 0 0];%[roiBox(2) roiBox(1) roiBox(4)-1 roiBox(3)-1]; % standard format
    roiImg = imcrop(imge,roiBox);
    roiExtDx = imcrop(extDx,roiBox);
    roiExtDy = imcrop(extDy,roiBox);
    roiBox(3:4) = [size(roiExtDx,2) size(roiExtDx,1)]-1; %!

    prop = regionprops(bwlabel(mask),'orientation','centroid'); % TODO: Check
    theta = prop(1).Orientation*pi/180;
    x0 = prop(1).Centroid(1);
    y0 = prop(1).Centroid(2);

    if p.algorithm==2
        pcCell0 = [theta;x0;y0;zeros(p.Nkeep+1,1)];
    elseif p.algorithm==3
        pcCell0 = [x0;y0;theta;0;zeros(p.Nkeep+1,1)];
    end
    if ismember(p.algorithm,[2 3])
        [pcCell,~] = align(mask,pmapDx,pmapDy,pmapDx*0,pcCell0,p,true,roiBox,0.5,[frame lst(1)]);
        [pcCell,~] = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,p,false,roiBox,thres,[frame lst(1)]);
    elseif p.algorithm == 4
        [ii,jj]=find(bwperim(mask),1,'first');
        %trace boundary of a cell mask in counterclockwise direction.
        tracedPoints=bwtraceboundary(mask,[ii,jj],'n',4,inf,'counterclockwise');
        %takes the fourier transform of tracedpoints.
        fourierTracedPoints = frdescp(tracedPoints);
        %takes the inverse fourier transform of fourierTracedPoints to get real values. 
        cellContourTemp = ifdescp(fourierTracedPoints,p.fsmooth);
        cellContour(:,1) = cellContourTemp(:,2);
        cellContour(:,2) = cellContourTemp(:,1);
        pcCell = makeccw(cellContour);
        fitIter = p.fitMaxIter;
        p.fitMaxIter = 2;
        [pcCell,~] = align4Manual(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,p,roiBox,thres,[frame lst(1)]);
        mesh = model2MeshForRefine(pcCell,p.fmeshstep,p.meshTolerance,p.meshWidth);
		 if length(mesh)<5
			disp(['Tried to join cells ' num2str(lst) ' - failed, increase meshWidth value.'])
			return;
		end
        pcCell = [mesh(:,1:2);flipud(mesh(2:end-1,3:4))];
        p.fitMaxIter = fitIter;
        [pcCell,~] = align4Manual(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,p,roiBox,thres,[frame lst(1)]);
    end
    pcCell = box2model(pcCell,roiBox,p.algorithm);
    cCell = model2geom(pcCell,p.algorithm);
    mesh = model2MeshForRefine(cCell,p.meshStep,p.meshTolerance,p.meshWidth);

    if length(mesh)<5
        disp(['Tried to join cells ' num2str(lst) ' - failed, increase meshWidth value.'])
        res = false;
    else
        % construct the lineage data
        cell = oufti_getCellStructure(lst(1), frame, cellList);
        cell.mesh = single(mesh);
        if size(pcCell,2)==1, model=reshape(pcCell,[],1); else model=pcCell; end
        cell.model = single(model); % TODO: check if works for alg. 2-3
        cell.box = roiBox;
        for i=2:length(lst)
            cellList = oufti_removeCellStructureFromCellList(lst(i), frame, cellList);
        end
        if numel(cell.descendants)>1
            cell.descendants=cell.descendants(1:end-1);
        else
            cell.descendants=[];
        end
        if numel(cell.divisions)>1
            cell.divisions=cell.divisions(1:end-1);
        else
            cell.divisions=[];
            cell.polarity=0;
        end
        cellList = oufti_addCell(lst(1), frame, cell, cellList);
        disp(['Joined cells ' num2str(lst) ' - success, saved as cell ' num2str(lst(1))])

        res = true; % output the number of the new cell is succeeded
    end
    
    function res = dstm(a)
        res = (a(1)+a(3))^2+(a(2)+a(4))^2;
    end
end


%% Shifting frames

function [shiftX,shiftY]= alignframes(A,depth)
    
    mrg = round(min(size(A,1),size(A,2))*0.05);
    fld = [size(A,1)-2*mrg size(A,2)-2*mrg];
    time1 = clock;
    x0=[0 1 1 0 -1 -1 -1 0 1];
    y0=[0 0 1 1 1 0 -1 -1 -1];
    nframes = size(A,3);
    %field = [size(A,1) size(A,2)];
    memory = double(A(:,:,1));
    score = zeros(1,9);
    shiftX = zeros(1,nframes);
    shiftY = zeros(1,nframes);
    for frame=2:nframes
        memory = memory*(1-1/depth) + double(A(:,:,frame-1))/depth;
        sc2memory = imresize(memory,0.5);
        sc4memory = imresize(memory,0.25);
        cframe = double(A(:,:,frame));
        sc2cframe = imresize(cframe,0.5);
        sc4cframe = imresize(cframe,0.25);
        [xF,yF] = alignoneframe(sc4cframe,sc4memory,0,0,round(mrg/4));
        [xF,yF] = alignoneframe(sc2cframe,sc2memory,2*xF,2*yF,round(mrg/2));
        [xF,yF] = alignoneframe(cframe,memory,2*xF,2*yF,mrg);
        shiftX(frame) = xF;
        shiftY(frame) = yF;
        if depth>1 && (xF~=0 || yF~=0)
            fldX = max(1,xF+1):min(fld(1),fld(1)+xF);
            fldY = max(1,yF+1):min(fld(2),fld(2)+yF);
            fldX2 = max(1,-xF+1):min(fld(1),fld(1)-xF);
            fldY2 = max(1,-yF+1):min(fld(2),fld(2)-yF);
            memory(fldX2,fldY2) = memory(fldX,fldY);
        end
        disp(['frame = ' num2str(frame) ', shift ' num2str(xF) ',' num2str(yF) ' pixels'])
    end
    shiftX = cumsum(shiftX);
    shiftY = cumsum(shiftY);
    time2 = clock;
    disp(['Finised, elapsed time ' num2str(etime(time2,time1)) ' s']);  

    function [x,y] = alignoneframe(cframe,memory,x,y,margin)
        cframetmp = cframe(margin+1:end-margin,margin+1:end-margin);
        memorytmp = memory(margin+1:end-margin,margin+1:end-margin);
        field = [size(cframe,1)-2*margin size(cframe,2)-2*margin];
        while true
            for j=1:9
                dx=x0(j);
                dy=y0(j);
                xJ = x + dx;
                yJ = y + dy;
                fieldX = max(1,xJ+1):min(field(1),field(1)+xJ);
                fieldY = max(1,yJ+1):min(field(2),field(2)+yJ);
                fieldX2 = max(1,-xJ+1):min(field(1),field(1)-xJ);
                fieldY2 = max(1,-yJ+1):min(field(2),field(2)-yJ);
                score(j) = corel(memorytmp(fieldX,fieldY),cframetmp(fieldX2,fieldY2));
            end
            [~,ind] = max(score);
            if ind==1, break; end
            x = x+x0(ind);
            y = y+y0(ind);
        end
    end
end

function B = shiftstack(A,varargin)
    if length(varargin)==1
        shift=varargin{1};
    else
        shift.x=varargin{1};
        shift.y=varargin{2};
    end
    if ~iscell(A) && ~isstruct(A)
        B = ones(size(A),class(A));
        for frame = 1:size(A,3)
            xJ = shift.x(frame);
            yJ = shift.y(frame);
            B(:,:,frame)  = shiftImage(A(:,:,frame), [yJ xJ]);
        end
    else
        B = A;
        for frame = 1:min(length(A.meshData),length(shift.x))
            xJ = shift.x(frame);
            yJ = shift.y(frame);
            if length(A.meshData)>=frame && ~isempty(A.meshData{frame})
                for cell=1:length(A.meshData{frame})
                    if ~isempty(A.meshData{frame}{cell}) && isfield(A.meshData{frame}{cell},'mesh') && length(A.meshData{frame}{cell}.mesh)>1
                        B.meshData{frame}{cell}.mesh(:,[1 3]) = A.meshData{frame}{cell}.mesh(:,[1 3])+yJ;
                        B.meshData{frame}{cell}.mesh(:,[2 4]) = A.meshData{frame}{cell}.mesh(:,[2 4])+xJ;
                    end
                end
            end
        end
    end
    
    
function [shiftedImage] = shiftImage(image, shift)
% applies the shift to image. shift contains an [x, y] vector and need not
% be integer values. If non-integer, a convolution will be used shuffle
% intensities from adjacent pixels after any requisite integer based
% operations have been performed.

if isempty(shift), shiftedImage = image; return, end
image = double(image);

mnx = min(image(:));
%split the shifting operation into integer based (s) and fractional (shiftx,
% shifty)
[s(1),shiftx]=deal(fix(shift(1)),shift(1)-fix(shift(1)));
[s(2),shifty]=deal(fix(shift(2)),shift(2)-fix(shift(2)));

if s(1)>=1
    image(:,end-s(1)+1:end)=[];
    m = repmat(mnx, [size(image,1),s(1)]);
    image = cat(2,m,image);
elseif s(1)<=-1
    image(:,1:abs(s(1))) = [];
    m = repmat(mnx,[size(image,1),abs(s(1))]);
    image = cat(2,image,m);
end
if s(2)>=1
    image(end-s(2)+1:end,:)=[];
    m = repmat(mnx,[s(2),size(image,2)]);
    image = cat(1,m,image);
elseif s(2)<=-1
    image(1:abs(s(2)),:)=[];
    m = repmat(mnx,[abs(s(2)),size(image,2)]);
    image=cat(1,image,m);
end

if shiftx ~= 0
    sx = [-shiftx,1-abs(shiftx) shiftx];
    sx(sx<0)=0;
    sx = sx / sum(sx(:));
    image=conv2(double(image),sx,'same');
end

if shifty ~= 0
    sy = [-shifty,1-abs(shifty),shifty];
    sy(sy<0)=0;
    sy = sy / sum(sy(:));
    image=conv2(double(image'),sy,'same')';   
end

shiftedImage=image;
end
end

function y=corel(X,Y)
y = mean(mean((X-mean(mean(X))).*(Y-mean(mean(Y)))));%/sqrt(mean(mean((X-mean(mean(X))).^2))/sqrt(mean(mean((Y-mean(mean(Y))).^2))));
end

%% Training

function trainPDM(mult,N,alg)
% Training function. Reads the new data format.

% mult = false; % read multiple files
% N=52; % number of points in the model

global trainPDMpathName
cellArray=[];
if ~exist('trainPDMpathName','var'), trainPDMpathName = ''; end
while true
    % Opening a mesh file
    [FileName,PathName] = uigetfile('*.mat','Select File with Mesh Data...','MultiSelect','on',[trainPDMpathName '/']);
    if isequal(FileName,0)
        if size(cellArray,1)<1; 
            return;
        else
            break;
        end
    end
    trainPDMpathName = PathName;
    if ~iscell(FileName), FileName = {FileName}; end
    for u=1:length(FileName)
        load(fullfile2(PathName,FileName{u}),'cellList');
		% this was the old format. Make new kind of cellList.
		if ~isstruct(cellList), cellList = oufti_makeNewCellListFromOld(cellList); end
        % Now building an array (cellArray) of the training set points
        for frame=1:oufti_getLengthOfCellList(cellList)
            [cells,~] = oufti_getFrame(frame, cellList);
            
            for i = 1:length(cells) %1:length(cellList{frame})
                cell = cells{i};
                % celln = ids(i);
                
                %Convert polygons to contour
                %if isempty(cellList{frame}{celln}), continue; end
                mesh=cell.mesh;
                if length(mesh)<4, continue; end
                ctr = [mesh(1:end-1,1:2);flipud(mesh(:,3:4))];
                % ctr = [reshape(plg(1,:,1:end-1),2,[])';plg(2,:,end);plg(1,:,end);plg(3,:,end);flipud(reshape(plg(4,:,1:end-1),2,[])')];
                dctr=diff(ctr,1,1);
                len=cumsum([0;sqrt((dctr.*dctr)*[1;1])]);
                l=length(ctr)-1;
                len1=linspace(0,len(l/2+1),N/2+1);
                len2=linspace(len(l/2+1),len(end),N/2+1);
                len3=[len1(1:end-1) len2];
                ctr1=interp1(len,ctr,len3);
                ctr2=ctr1(2:end,:);%The first and last points are no more the same. The end points are N/2 and N
                ctr2(:,1)=mean(ctr2(:,1))-ctr2(:,1);
                ctr2(:,2)=mean(ctr2(:,2))-ctr2(:,2);
                if len3(end)<5*sqrt(sum((ctr2(N/2,:)-ctr2(N,:)).^2,2))
                    cellArray=cat(3,cellArray,ctr2);
                end
            end
        end
    end
    if ~mult, break; end
end

        %Now building an array (cellArray) of the training set points
        % for frame=1:length(cellList)
            % for cell=1:length(cellList{frame})
                %Convert polygons to contour
                % if isempty(cellList{frame}{cell}), continue; end
                % mesh=cellList{frame}{cell}.mesh;
                % if length(mesh)<4, continue; end
                % ctr = [mesh(1:end-1,1:2);flipud(mesh(:,3:4))];
                %ctr = [reshape(plg(1,:,1:end-1),2,[])';plg(2,:,end);plg(1,:,end);plg(3,:,end);flipud(reshape(plg(4,:,1:end-1),2,[])')];
                % dctr=diff(ctr,1,1);
                % len=cumsum([0;sqrt((dctr.*dctr)*[1;1])]);
                % l=length(ctr)-1;
                % len1=linspace(0,len(l/2+1),N/2+1);
                % len2=linspace(len(l/2+1),len(end),N/2+1);
                % len3=[len1(1:end-1) len2];
                % ctr1=interp1(len,ctr,len3);
                % ctr2=ctr1(2:end,:);%The first and last points are no more the same. The end points are N/2 and N
                % ctr2(:,1)=mean(ctr2(:,1))-ctr2(:,1);
                % ctr2(:,2)=mean(ctr2(:,2))-ctr2(:,2);
                % if len3(end)<5*sqrt(sum((ctr2(N/2,:)-ctr2(N,:)).^2,2))
                    % cellArray=cat(3,cellArray,ctr2);
                % end
            % end
        % end
    % end
    % if ~mult, break; end
% end
disp('Mesh data loaded')
ncells = size(cellArray,3);

% Prealigning the set
time1 = clock;
for i=1:ncells;
    cCell = cellArray(:,:,i);
    alpha = angle(cCell(N,1)+j*cCell(N,2)-(cCell(N/2,1)+j*cCell(N/2,2)));
    cCell = M(cCell,alpha);
    cen = (cCell(ceil(N/4),1)+cCell(ceil(N*3/4),1)+j*cCell(ceil(N/4),2)+j*cCell(ceil(N*3/4),2))/2;
    alpha = angle(cCell(N/2,1)+j*cCell(N/2,2)-cen);
    if alpha>0, cCell(:,2)=-cCell(:,2); cCell=flipud(circShiftNew(cCell,1)); end
    cellArray(:,:,i) = cCell;
end
disp('Cells prealigned')

if alg==2

    cellArray2 = cellArray;
    cellArray2(:,2,:) = -cellArray2(:,2,:);
    cellArray2 = flipdim(cellArray2([N 1:N-1],:,:),1);

    cellArray = cat(3,cellArray,cellArray2);
    w=ones(N,1);
    %w2=repmat(w,[1 1 ncells]);
    mCell = cellArray(:,:,1);
    for i=1:10%:10
        %dist=sum(sum((s1-s2).^2,2).*w2,1);
        for k=1:ncells
            cCell = cellArray(:,:,k);
            tmin=fminbnd(@distM,-pi/5,pi/5);
            cellArray(:,:,k) = M(cCell,tmin);
        end
        mCell = mean(cellArray(:,:,:),3);
        w = 1./var(sum(cCell-mCell,2));
        disp(['Aligning: Step ' num2str(i)])
    end
    disp('Cells aligned')

    % principal components analysis
    data = [reshape(cellArray(:,1,:),N,[]);reshape(cellArray(:,2,:),N,[])]';
    [coefPCA,scorePCA,latPCA] = pca(data);
    disp('PCA completed')

elseif  alg==3
    
    w=ones(N,1);
    %w2=repmat(w,[1 1 ncells]);
        cellArray1 = cellArray;
        cellArray2 = cellArray;
        cellArray2(:,2,:) = -cellArray2(:,2,:);
        cellArray2 = flipdim(reshape(circShiftNew(cellArray2,1),size(cellArray)),1);
        cellArray2 = cat(3,cellArray,cellArray2);
        mCell = mean(cellArray2(:,:,:),3);
        cellParamArray = zeros(length(cellArray),5);
        cellParamArray(:,5)=1;
        % cellArray(:,:,1);
    for i=1:5
        %dist=sum(sum((s1-s2).^2,2).*w2,1);
        for k=1:ncells
            cCell = cellArray(:,:,k);
            cCell(:,1) = cCell(:,1)-mean(cCell(round([N/4 N*3/4]),1));
            cCell(:,2) = cCell(:,2)-mean(cCell(round([N/4 N*3/4]),2));
            tmin = fminsearch(@distParam2cell,cellParamArray(k,3:5));
            cellParamArray(k,3:5) = tmin;
            %cCell = param2cell(cellParamArray(k,3:5))+repmat(cellParamArray(k,1:2),size(cCell,1),1);
            % tmin=fminbnd(@distM,-pi/5,pi/5);
            % cCell = M(cCell,tmin);
            % bmin=fminbnd(@distB,-0.1,0.1);
            % cCell = Bu(cCell,bmin);
            % smin=fminbnd(@distS,0.1,10);
            % cCell = St(cCell,smin);
            cellArray1(:,:,k) = cCell;
        end
        cellArray2 = cellArray1;
        cellArray2(:,2,:) = -cellArray2(:,2,:);
        cellArray2 = flipdim(reshape(circShiftNew(cellArray2,1),size(cellArray)),1);
        cellArray2 = cat(3,cellArray1,cellArray2);
        mCell = mean(cellArray2(:,:,:),3);
        w = 1./var(sum(cCell-mCell,2));
        time2 = clock;
        disp(['Aligning: Step ' num2str(i) ', elapsed time ' num2str(etime(time2,time1)) ' s']); 
    end
    ('Cells aligned')

    % principal components analysis
    data = [reshape(cellArray2(:,1,:),N,[]);reshape(cellArray2(:,2,:),N,[])]';
    [coefPCA,scorePCA,latPCA] = princomp(data);
    disp('PCA completed')
    
end

% Saving / dislaying data
[FileName,PathName] = uiputfile('*.mat','Select File for PCA Data...');
save(fullfile2(PathName,FileName),'coefPCA','scorePCA','latPCA','mCell');

figure;
plot(mCell(:,1),mCell(:,2),'-',reshape(cellArray2([N/4 N/2 N*3/4 N],1,:),4,[]),reshape(cellArray2([N/4 N/2 N*3/4 N],2,:),4,[]),'.')

function res=distParam2cell(params) % all parameters but shift
    res=sum(sum((mCell-param2cell(params)).^2,2).*w);
    end

function res=param2cell(params) % all parameters but shift
    res=St(Bu(M(cCell,-params(1)),params(2)),params(3));
    end

function res=distM(t) % rotating
    res=sum(sum((M(cCell,t)-mCell).^2,2).*w);
    end

function res=distB(t) % unbending
    res=sum(sum((Bu(cCell,t)-mCell).^2,2).*w);
end

function res=distS(t) % stretching
    res=sum(sum((St(cCell,t)-mCell).^2,2).*w);
    end
end

%%
function b=Bu(a,t)
    % unbends a set of points (up if t>0) assuming initial radius of curvature 1/t
    if abs(t)<1/10000000, b=a; return; end
    R = sign(t)/abs(t);% sign(t)*max(1/abs(t),1.1*max(-a(:,2)));
    tmp = a(:,1) + j*(a(:,2)+R);
    b(:,1) = -(mod(angle(tmp)+sign(t)*pi/2,2*pi)-pi)*R;
    b(:,2) = sign(t)*abs(tmp)-R;
    % r = sqrt((a(:,2)+R).^2+a(:,1).^2);
    % phi = asin(a(:,1)./r);
    % b(:,1) = phi.*R;
    % b(:,2) = r-R;
end

function b=St(a,t)
    % stretches a cell in x direction
    b=a;
    b(:,1) = a(:,1)/t;
end

% The next 2 functions correct a bug in MATLAB uiputfile/uigetfile functions
function [d,e] = uigetfile2(a,b,c)
    f=true;
    while f
        try
            [d,e] = uigetfile(a,b,c);
            f=false;
        catch
            f=true;
        end
    end
end

function [d,e] = uiputfile2(a,b,c)
    f=true;
    while f
        try
            [d,e] = uiputfile(a,b,c);
            f=false;
        catch
            f=true;
        end
    end
end

function res = slashsplit(str)
    % This function returns the highest level folder name from a path
    split = splitstr('/', str);
    split = splitstr('\', split{end});
    res = split{end};
end

function res = slashsplit2(str)
    % This function truncates the path to a folder leaving the two highest
    % level folder names
    split = splitstr('/', str);
    if length(split)>1, split = [split{end-1} '/' split{end}]; else split = split{end}; end
    split = splitstr('\', split);
    if length(split)>1, split = [split{end-1} '\' split{end}]; else split = split{end}; end
    res = split;
end

function parts = splitstr(divider, str)
% This function splits a string into pieces at every occurrence of
% "divider" and returns the result as a cell array of strings. "divider"
% is not included in the output.
   splitlen = length(divider);
   parts = {};
   while 1
      k = strfind(str, divider);
      if isempty(k)
         parts{end+1} = str;
         break
      end
      parts{end+1} = str(1 : k(1)-1);
      str = str(k(1)+splitlen : end);
   end
end


function gdisp(data)
    % text display function
    % alternative to text display to screen
    % modified from stand-alone version by removing 'CLOSE','VISIBLE','HIDE' commands 

    global gdisphandles logcheckw
    
    if logcheckw
        disp(data)
    end
    
    if ~exist('gdisphandles','var') || ~isfield(gdisphandles,'gdispfig') || isempty(gdisphandles.gdispfig) || ~ishandle(gdisphandles.gdispfig)
        return
    end
    
    maxlines = 200;

    if ~isa(data,'char'), return; end

    gdisphandles.text = strvcat(gdisphandles.text,data);
    nlines = size(gdisphandles.text,1);
    if nlines>maxlines
        gdisphandles.text = gdisphandles.text(nlines-maxlines+1:nlines,:);
    end
    set(gdisphandles.wnd,'String',gdisphandles.text);
    refresh(gdisphandles.gdispfig)
% % %     pause(0.005);
    java.lang.Thread.sleep(10);  %wait one second 
    try
        gdisphandles.gdispobj.setCaretPosition(gdisphandles.gdispobj.getDocument.getLength);
    catch
    end
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


function res = readtextfile(filename)
    fid = fopen(filename);
    str = fscanf(fid,'%c');
    fclose(fid);
    newline = [0 regexp(str,'\n') length(str)];
    res = {};
    for i=2:length(newline)
        res = [res str(newline(i-1)+1:newline(i)-1)];
    end
end



