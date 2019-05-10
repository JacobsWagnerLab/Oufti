
function cellListFilterFcn
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function 
%PURPOSE:
%@author:  
%@date:    
%@copyright 2012-2015 Yale University
%==========================================================================
%**********output********:
%out1
%.
%.
%outN
%**********Input********:
%in1
%.
%.
%inN
%=========================================================================
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%pragma function needed to include files for deployment
%#function [getLLoCurves curveGraph]
global cellList dataStr dataStrTemp
screenSize = get(0,'ScreenSize');

if sum(cellfun(@numel,cellList.meshData)) == 0,warndlg('First load cell meshes'),return;end
if numel(cellList.meshData) == 1, warndlg('Data needs to be a timelapse');return;end
try
[dataStr,hdl] = getLLoCurves(cellList,0,1);
set(gcf,'name','cellList data points');
set(gcf,'NumberTitle','off');
firstFigurePosition = hdl.Position;

histFigure = figure('NumberTitle','off','name','Initial distributions','Position',...
                    [firstFigurePosition(1)+100,firstFigurePosition(2)-50,firstFigurePosition(3),firstFigurePosition(4)]);
lengthAtBirth = binNbFreedmanDiaconi(dataStr.Lbirth);
cellCycleTime = binNbFreedmanDiaconi(dataStr.cct);
growthRates   = binNbFreedmanDiaconi(dataStr.gRates);
rmse          = binNbFreedmanDiaconi(dataStr.rmseFit);
subplot(2,2,1),hist(dataStr.Lbirth,lengthAtBirth);
xlabel('Length at birth, px'); ylabel('Frequency');
subplot(2,2,2),hist(dataStr.cct,cellCycleTime);
xlabel('cell cycle time, frame'); ylabel('Frequency');
subplot(2,2,3),hist(dataStr.gRates,growthRates);
xlabel('growth rates, frame^-1');ylabel('Frequency');
subplot(2,2,4),hist(dataStr.rmseFit,rmse);
xlabel('rmse error of fit, px');ylabel('Frequency');

handles.growthParamMain = figure('pos',[100 screenSize(4)-300 300 200],'KeyPressFcn',@mainkeypress,...
                         'CloseRequestFcn',@mainguiclosereq,'Toolbar','none','Menubar','none','Name','cellList filter parameters',...
                         'NumberTitle','off','IntegerHandle','off','uicontextmenu',[],'DockControls','off','Resize','off');
handles.growthParamPanel = uipanel('units','pixels','pos',[1 1 299 199]);
handles.growthParami = uibuttongroup(handles.growthParamPanel,'units','pixels',...
                                    'Position',[10 105 299 20],'BorderType','none','SelectionChangeFcn',...
                                    @idSelection,'FontUnits','pixels','FontName','Helvetica','FontSize',12);

controls = uicontrol(handles.growthParamPanel,'units','pixels','Position',[5 80 100 80],'Style','Listbox',...
                                    'HorizontalAlignment','left','String',{'cell id';'length at birth';'cell cycle time';...
                                    'growth rates';'rmse error of fit'},'callback',@idSelection);                
controlsValue = uicontrol(handles.growthParamPanel,'units','pixels','Position',[105 110 40 15],'Style','edit',...
                                    'callback',@idSelection,'HorizontalAlignment','left');
idLess = uicontrol(handles.growthParami,'units','pixels','Position',[150 5 40 15],'Style','radiobutton','String',...
                            '<','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica',...
                             'FontSize',12,'HandleVisibility','off');
idMore = uicontrol(handles.growthParami,'units','pixels','Position',[195 5 40 15],'Style','radiobutton','String',...
                            '>','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica',...
                             'FontSize',12,'HandleVisibility','off');
idEqual = uicontrol(handles.growthParami,'units','pixels','Position',[240 5 40 15],'Style','radiobutton','String',...
                            '=','HorizontalAlignment','left','FontUnits','pixels','FontName','Helvetica',...
                             'FontSize',12,'HandleVisibility','off');
                                
%---------------------------------------------------------------------------------------------------------------------
                         
uicontrol(handles.growthParamPanel,'units','pixels','Position',[10 10 130 25],'style','pushbutton','string','save initial data',...
                                    'FontSize',12,'callback',@saveOriginalData);
uicontrol(handles.growthParamPanel,'units','pixels','Position',[150 10 130 25],'style','pushbutton','string','save filtered data',...
                                    'FontSize',12,'callback',@saveData);

handles.growthParam.Visible = 'on';
catch
end

    function idSelection(source,callbackData)
    temp = controls.Value;
    switch temp
        
        case 1
            id = num2str(controlsValue.String);
            if isempty(id),return;end
            value = handles.growthParami.SelectedObject.String;
            if strcmp(value,'=')
                value = '==';
            end
            param = ['dataStr.id' value id];
            h = curveGraph(dataStr.frames,dataStr.lengthes,eval(eval('param')));
            dataStrTemp             = dataStr;
            dataStrTemp.id          = dataStrTemp.id(eval(eval('param')));
            dataStrTemp.Lbirth      = dataStrTemp.Lbirth(eval(eval('param')));
            dataStrTemp.lengthes    = dataStrTemp.lengthes(eval(eval('param')));
            dataStrTemp.frames      = dataStrTemp.frames(eval(eval('param')));
            dataStrTemp.cct         = dataStrTemp.cct(eval(eval('param')));
            dataStrTemp.gRates      = dataStrTemp.gRates(eval(eval('param')));
            try
                dataStrTemp.rmseFit     = dataStrTemp.rmseFit(eval(eval('param')));
            catch
            end
            dataStrTemp.rmsd        = dataStrTemp.rmsd(eval(eval('param')));
            
        case 2
            id = num2str(controlsValue.String);
            if isempty(id),return;end
            value = handles.growthParami.SelectedObject.String;
            if strcmp(value,'=')
                value = '==';
            end
            param = ['dataStr.Lbirth' value id];
            h = curveGraph(dataStr.frames,dataStr.lengthes,eval(eval('param')));
            dataStrTemp             = dataStr;
            dataStrTemp.id          = dataStrTemp.id(eval(eval('param')));
            dataStrTemp.Lbirth      = dataStrTemp.Lbirth(eval(eval('param')));
            dataStrTemp.lengthes    = dataStrTemp.lengthes(eval(eval('param')));
            dataStrTemp.frames      = dataStrTemp.frames(eval(eval('param')));
            dataStrTemp.cct         = dataStrTemp.cct(eval(eval('param')));
            dataStrTemp.gRates      = dataStrTemp.gRates(eval(eval('param')));
            try
                dataStrTemp.rmseFit     = dataStrTemp.rmseFit(eval(eval('param')));
            catch
            end
            dataStrTemp.rmsd        = dataStrTemp.rmsd(eval(eval('param')));
            
        case 3
            id = num2str(controlsValue.String);
            if isempty(id),return;end
            value = handles.growthParami.SelectedObject.String;
            if strcmp(value,'=')
                value = '==';
            end
            param = ['dataStr.cct' value id];
            h = curveGraph(dataStr.frames,dataStr.lengthes,eval(eval('param')));
            dataStrTemp             = dataStr;
            dataStrTemp.id          = dataStrTemp.id(eval(eval('param')));
            dataStrTemp.Lbirth      = dataStrTemp.Lbirth(eval(eval('param')));
            dataStrTemp.lengthes    = dataStrTemp.lengthes(eval(eval('param')));
            dataStrTemp.frames      = dataStrTemp.frames(eval(eval('param')));
            dataStrTemp.cct         = dataStrTemp.cct(eval(eval('param')));
            dataStrTemp.gRates      = dataStrTemp.gRates(eval(eval('param')));
            try
                dataStrTemp.rmseFit     = dataStrTemp.rmseFit(eval(eval('param')));
            catch
            end
            dataStrTemp.rmsd        = dataStrTemp.rmsd(eval(eval('param')));
            
        case 4
            id = num2str(controlsValue.String);
            if isempty(id),return;end
            value = handles.growthParami.SelectedObject.String;
            if strcmp(value,'=')
                value = '==';
            end
            param = ['dataStr.gRates' value id];
            h = curveGraph(dataStr.frames,dataStr.lengthes,eval(eval('param')));
            dataStrTemp             = dataStr;
            dataStrTemp.id          = dataStrTemp.id(eval(eval('param')));
            dataStrTemp.Lbirth      = dataStrTemp.Lbirth(eval(eval('param')));
            dataStrTemp.lengthes    = dataStrTemp.lengthes(eval(eval('param')));
            dataStrTemp.frames      = dataStrTemp.frames(eval(eval('param')));
            dataStrTemp.cct         = dataStrTemp.cct(eval(eval('param')));
            dataStrTemp.gRates      = dataStrTemp.gRates(eval(eval('param')));
            try
                dataStrTemp.rmseFit     = dataStrTemp.rmseFit(eval(eval('param')));
            catch
            end
            dataStrTemp.rmsd        = dataStrTemp.rmsd(eval(eval('param')));
            
        case 5
            id = num2str(controlsValue.String);
            if isempty(id),return;end
            value = handles.growthParami.SelectedObject.String;
            if strcmp(value,'=')
                value = '==';
            end
            param = ['dataStr.rmseFit' value id];
            h = curveGraph(dataStr.frames,dataStr.lengthes,eval(eval('param')));
           dataStrTemp             = dataStr;
            dataStrTemp.id          = dataStrTemp.id(eval(eval('param')));
            dataStrTemp.Lbirth      = dataStrTemp.Lbirth(eval(eval('param')));
            dataStrTemp.lengthes    = dataStrTemp.lengthes(eval(eval('param')));
            dataStrTemp.frames      = dataStrTemp.frames(eval(eval('param')));
            dataStrTemp.cct         = dataStrTemp.cct(eval(eval('param')));
            dataStrTemp.gRates      = dataStrTemp.gRates(eval(eval('param')));
            try
                dataStrTemp.rmseFit     = dataStrTemp.rmseFit(eval(eval('param')));
            catch
            end
            dataStrTemp.rmsd        = dataStrTemp.rmsd(eval(eval('param')));
            
    end
        
    end
    function saveData(hObject,eventdata)
        [file,path] = uiputfile('*.mat','save file name');
        save([path file],'dataStrTemp');
    end

    function saveOriginalData(hObject,eventdata)
        [file,path] = uiputfile('*.mat','save file name');
        save([path file],'dataStr');
    end
function mainguiclosereq(hObject, eventdata)
   hObject.delete;
   eventdata.delete;
end
end