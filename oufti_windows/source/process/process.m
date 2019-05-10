
function process(range,mode,lst,addsig,addas,savefile,fsave,saveselect,processregion,shiftfluo,tmpFileName,isHighThroughput)
% Main processing function, decides on which frames and what type of
% cell detection or cell analysis to do, to be called by "Detection &
% analysis" buttons or from eacher variant of the batch mode
% 
% "range" - range of frames to run, can be []-all frames
% "mode" - 1-tlapse, 2-1st ind, 3-all ind, 4-reuse
% "lst" - list of cells on the frame previous to range(1)
% "addsig" - [0 0 0 0]=[0 0 0]=[0 0]=0=[]-no signal, 1st one phase, etc. 
% "addas" - default {}={0,-,1,2}, if numeric X, creates signalX, else - X
% "savefile" - filename to save to
% "fsave" - frequance of saving, n-once per n frames, 0-never, []-end  
global p cellList imsizes  cellListN coefPCA mCell paramString handles shiftframes rawPhaseData imageForce
%     global handles initModel

%--------------------------------------------------------------------------
%pragma instructs the compiler to include functions for deployment.
%#function truncateFile.pl truncateFile
%--------------------------------------------------------------------------
%pragma instructs the compiler to include functions for deployment.
initModel();
if ~isfield(cellList,'meshData')
    cellList = oufti_makeNewCellListFromOld(cellList);
end
cellListN = cellfun(@length,cellList.meshData);
%     set(handles.maingui,'Name',savefile);
%     if ~isempty(tmpFileName), tmpFileName = fileparts(tmpFileName); cd (tmpFileName);end
%     set(handles.saveFile,'String',tmpFileName);
if isempty(p) || ~isfield(p,'algorithm'), disp('Error: parameters not initialized.'); return; end
    nFrames = oufti_getLengthOfCellList(cellList);  
if mode==4 && ~isempty(range) &&(nFrames<range(1)), disp('Processing error: selected frame out of range'); return; end
if mode==4 && isempty(range) && oufti_isFrameEmpty(1, cellList), disp('Processing error: for all frames, the 1st frame must not be empty'); return; end
if mode~=4 && ~isempty(lst) && (isempty(range) || range(1)==1), disp('Processing error: selected cells regime does not work on the 1st frame'); return; end
    
if ~isempty(fsave) && (fsave==0 || isempty(savefile)), savemode = 0; % never save
elseif isempty(fsave), savemode = 2; % save at the end
elseif fsave == 1, savemode = 1;
else savemode = 3; % save on some steps
end
if length(range)==1, range = [range range]; end
if isempty(range), range = [1 imsizes(end,3)]; end	
    
time1 = clock;
fid = -1;
listtorun = lst; % cellstructure array containing all cell info

if mode==3 && p.runSerial~=1
   try
   frameList = range(1):range(2);
   processIndependentFrames(frameList,0,processregion,savefile);
   cellList.cellId{1} = single(cellList.cellId{1});
   cellListN = cellfun(@length,cellList.meshData);
   try
       if length(find(addsig)) >= 1
           addSignalToFrameParallel(range,addsig,addas,listtorun,p.sgnResize,...
                                 p.approxSignal,shiftfluo); 
        end
   catch  err
        disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
        disp(err.message)
        savemesh(savefile,lst,saveselect,[]);
        return;
    end
% %     savemesh(savefile,lst,saveselect,[]); this is not needed.
% %     return;
   catch err
       disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
       disp(err.message)
       savemesh(savefile,lst,saveselect,[]);
       return;
    end
       
else
        if isHighThroughput && p.outCsvFormat
            if strcmpi(savefile(end-7:end),'.out.mat')
                savefile = savefile(1:end-4);
            elseif strcmpi(savefile(end-3:end),'.mat')
                savefile(end-3:end) = '.out';
            else
                savefile = [savefile '.out'];
            end
            if ~exist(savefile,'file')
                fopen(savefile,'w+');
            end
            textFile = fopen(savefile,'r+');
            fieldNamesCellList = {'ancestors'
                                  'birthframe'
                                  'box'
                                  'descendants'
                                  'divisions'
                                  'mesh'
                                  'length'
                                  'area'
                                  'polarity'
                                  'signal0'
                                  };
        end
       
    for frame=range(1):range(2)
    try 
        try
            imageForce(frame-1).forceX = [];
            imageForce(frame-1).forceY = [];
        catch
        end
        
        if mode ==4 && length(find(addsig)) >=1 
        disp(['Adding Signals to frames: ' num2str(range(1)) ':' num2str(range(2))])
        break;
        end
         if isempty(lst) && mode~=4, cellList = oufti_addFrame(frame, [], [], cellList); end%cellList{frame}={}; end
         if mode==3 || (mode~=4 && frame==1) || (mode==2 && frame==range(1)) %|| oufti_isFrameEmpty(1, cellList) ||...
                %(frame>=2 &&(length(cellList)<frame-1||(isempty(cellList{frame-1})))&&mode~=4)
            if p.algorithm==1 
               processFrameOld(frame,[],false,processregion);
            elseif ismember(p.algorithm,[2 3 4])
               processFrameI(frame,ismember(mode,1),processregion);
               if imsizes(1,1) < 1600 || imsizes(1,2) < 1600
                    joincells(frame,[]);
               end
               cellList.cellId{1} = single(cellList.cellId{1});
			   cellListN = cellfun(@length,cellList.meshData);
            end
         elseif mode==1 || mode==2
                shiftmeshes(frame,1,listtorun);
                if isempty(lst), listtorun=[]; end
                if p.algorithm==1
                    warndlg('Time-lapse analysis is not supported with Pixel based operation');
                    listtorun = processFrameOld(frame,listtorun,true,[]);
                end
                if ismember(p.algorithm,[2 3 4])
                    
                    [listtorun,fid] = processFrameGreaterThanOne(frame,listtorun,savefile,fid,isHighThroughput);
                    if isempty(listtorun),disp(['%%%%% Analysis failed in frame ' num2str(frame) ' Check parameters %%%%%']);return;end
				    cellListN = cellfun(@length,cellList.meshData);  
                    
                    if isHighThroughput && p.outCsvFormat && textFile ~= -1 && (frame - 1) == 1  
                        dateAndTimeDataProcessed = clock();
                        frewind(textFile);
                        fprintf(textFile,'%s','%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
                        fprintf(textFile,'\n\n');
                        fprintf(textFile,'%s',['High-throughput ".out" file named ' char(savefile) ' processed on ---> ' num2str(dateAndTimeDataProcessed(2)) ...
                                                  '/' num2str(dateAndTimeDataProcessed(3)) '/' num2str(dateAndTimeDataProcessed(1)) ' at ' ...
                                                  num2str(dateAndTimeDataProcessed(4)) ':' num2str(dateAndTimeDataProcessed(5))]);
                        fprintf(textFile,'\n\n');
                        fprintf(textFile,'%s','%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
                        fprintf(textFile,'\n\n');
                        fprintf(textFile,'$ cellListN');fprintf(textFile,'% d',cellListN);
                        fprintf(textFile,'\n');
                        fprintf(textFile,'$ coefPCA');fprintf(textFile,'% d',coefPCA);	
                        fprintf(textFile,'\n');
                        fprintf(textFile,'$ mCell');fprintf(textFile,'% d',mCell);	
                        fprintf(textFile,'\n');
                        fprintf(textFile,'$ shiftfluo');fprintf(textFile,'% d',shiftfluo);	
                        fprintf(textFile,'\n');
                        if ~isempty(whos('global','shiftframes'))
                            if isstruct(shiftframes)
                                tempShiftFrames = (struct2cell(shiftframes))';
                                fprintf(textFile,'$ shiftframes');
                                fprintf(textFile,'% g',tempShiftFrames{1});
                                fprintf(textFile,';');fprintf(textFile,'% g',tempShiftFrames{2});
                            else
                                fprintf(textFile,'$ shiftframes');fprintf(textFile,'% g',shiftframes);
                            end
                        end
                        fprintf(textFile,'\n');
                        if ~iscell(whos('paramString'))
                            paramString = get(handles.params,'string');
                            for z=1:size(paramString,1)
                                for s=1:size(paramString,2)
                                var = eval('paramString{z,s}');
                                if size(var,1) == 0
                                    var = '';
                                end
                                if isnumeric(var) == 1
                                var = num2str(var);
                                end
                                fprintf(textFile,'# % s\n',var);
                                end
                            end
                            fprintf(textFile,'\n');
                        end
                        fprintf(textFile,'\n');
                        fprintf(textFile,'\n');        
                        fprintf(textFile,'%% parameter values\n');
                        fprintf(textFile,'frameNumber,');
                        for ii = 1:length(fieldNamesCellList)
                            var = eval('fieldNamesCellList{ii}');
                            fprintf(textFile,'%s',var);
                            if ii < length(fieldNamesCellList),fprintf(textFile,',');end   
                        end
                        fprintf(textFile,',cellId,\n');
                        for cells = 1:length(cellList.meshData{frame-1})
                            fprintf(textFile,'#%d,',frame-1);
                            for ii = 1:length(fieldNamesCellList)
                                switch fieldNamesCellList{ii}
                                    case 'ancestors'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'ancestors') || isempty(cellList.meshData{frame-1}{cells}.ancestors)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.ancestors) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.ancestors(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.ancestors(end));
                                        end
				
                                    case 'birthframe'
                                       if ~isfield(cellList.meshData{frame-1}{cells},'birthframe') || isempty(cellList.meshData{frame-1}{cells}.birthframe)
                                            fprintf(textFile,' ,');
                                       else
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.birthframe(end));
                                       end
				
                                    case 'box'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'box') || isempty(cellList.meshData{frame-1}{cells}.box)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.box) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.box(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.box(end));
                                        end
				
                                    case 'descendants'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'descendants') || isempty(cellList.meshData{frame-1}{cells}.descendants)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.descendants) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.descendants(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.descendants(end));
                                        end

                                    case 'divisions'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'divisions') || isempty(cellList.meshData{frame-1}{cells}.divisions)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.divisions) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.divisions(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.divisions(end));
                                        end

                                    case 'mesh'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'mesh') || isempty(cellList.meshData{frame-1}{cells}.mesh)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:size(cellList.meshData{frame-1}{cells}.mesh,2) - 1
                                                fprintf(textFile,'%g ',cellList.meshData{frame-1}{cells}.mesh(:,jj));
                                                fprintf(textFile,';');
                                            end
                                            fprintf(textFile,'% g',cellList.meshData{frame-1}{cells}.mesh(:,end));
                                            fprintf(textFile,',');
                                        end

                                    case 'length' 
                                           
                                          fprintf(textFile,' ,');

                                    case 'area'
                                          fprintf(textFile,' ,');
                                            
                                     case 'polarity'
                                            if ~isfield(cellList.meshData{frame-1}{cells},'polarity') 
                                               fprintf(textFile,' ,');
                                            else  
                                               fprintf(textFile,'% g',cellList.meshData{frame-1}{cells}.polarity);
                                               fprintf(textFile,',');
                                            end
                                        
                                    case 'signal0'
                                         fprintf(textFile,' ,');     
                                end
                            end
                            fprintf(textFile,'%g,\n',cellList.cellId{frame-1}(cells));
                        end
                    elseif isHighThroughput && p.outCsvFormat && textFile ~= -1 && p.csvFileEdit
                        try
                            disp(['Truncating ' savefile ' file ........']);
                            tempFile = fopen(savefile,'r');
                            tempData = fread(tempFile,'uchar=>char')';
                            fclose(tempFile);
                            frameValue = ['#' num2str(frame - 1)];
                            fileLocation = strfind(tempData,frameValue);
                            fseek(textFile,fileLocation(1)-1,'bof');
                            perl('truncateFile.pl',savefile,num2str(fileLocation(1)-1));
                            p.csvFileEdit = 0;
                        catch
                            warndlg('[Make sure the .out file contains the frames you want to truncate.  Check the .out output file and re-run the analysis]');
                            return;
                        end
                        for cells = 1:length(cellList.meshData{frame-1})
                            fprintf(textFile,'#%d,',frame-1);
                            for ii = 1:length(fieldNamesCellList)
                                switch fieldNamesCellList{ii}
                                    case 'ancestors'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'ancestors') || isempty(cellList.meshData{frame-1}{cells}.ancestors)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.ancestors) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.ancestors(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.ancestors(end));
                                        end
				
                                    case 'birthframe'
                                       if ~isfield(cellList.meshData{frame-1}{cells},'birthframe') || isempty(cellList.meshData{frame-1}{cells}.birthframe)
                                            fprintf(textFile,' ,');
                                       else
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.birthframe(end));
                                       end
				
                                    case 'box'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'box') || isempty(cellList.meshData{frame-1}{cells}.box)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.box) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.box(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.box(end));
                                        end
				
                                   case 'descendants'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'descendants') || isempty(cellList.meshData{frame-1}{cells}.descendants)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.descendants) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.descendants(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.descendants(end));
                                        end
				
                                 case 'divisions'
                                     if ~isfield(cellList.meshData{frame-1}{cells},'divisions') || isempty(cellList.meshData{frame-1}{cells}.divisions)
                                        fprintf(textFile,' ,');
                                     else
                                        for jj = 1:length(cellList.meshData{frame-1}{cells}.divisions) - 1
                                            fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.divisions(jj));
                                        end
                                        fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.divisions(end));
                                     end
				
                                case 'mesh'
                                    if ~isfield(cellList.meshData{frame-1}{cells},'mesh') || isempty(cellList.meshData{frame-1}{cells}.mesh)
                                        fprintf(textFile,' ,');
                                    else
                                        for jj = 1:size(cellList.meshData{frame-1}{cells}.mesh,2) - 1
                                            fprintf(textFile,'%g ',cellList.meshData{frame-1}{cells}.mesh(:,jj));
                                            fprintf(textFile,';');
                                        end
                                        fprintf(textFile,'% g',cellList.meshData{frame-1}{cells}.mesh(:,end));
                                        fprintf(textFile,',');
                                    end
                                   case 'length' 
                                         fprintf(textFile,' ,');
                                          
                                    case 'area'
                                          fprintf(textFile,' ,');
                                           
                                    case 'polarity'
                                            if ~isfield(cellList.meshData{frame-1}{cells},'polarity') 
                                               fprintf(textFile,' ,');
                                            else  
                                               fprintf(textFile,'% g',cellList.meshData{frame-1}{cells}.polarity);
                                               fprintf(textFile,',');
                                           end
                                        
                                    case 'signal0'
                                         fprintf(textFile,' ,');
                                        
                                end
                            end
                            fprintf(textFile,'%g,\n',cellList.cellId{frame-1}(cells));
                        end
                    elseif isHighThroughput && p.outCsvFormat && textFile ~= -1 && ~p.csvFileEdit
                        
                        for cells = 1:length(cellList.meshData{frame-1})
                            fprintf(textFile,'#%d,',frame-1);
                            for ii = 1:length(fieldNamesCellList)
                                switch fieldNamesCellList{ii}
                                    case 'ancestors'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'ancestors') || isempty(cellList.meshData{frame-1}{cells}.ancestors)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.ancestors) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.ancestors(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.ancestors(end));
                                        end
				
                                    case 'birthframe'
                                       if ~isfield(cellList.meshData{frame-1}{cells},'birthframe') || isempty(cellList.meshData{frame-1}{cells}.birthframe)
                                            fprintf(textFile,' ,');
                                       else
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.birthframe(end));
                                       end
				
                                    case 'box'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'box') || isempty(cellList.meshData{frame-1}{cells}.box)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.box) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.box(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.box(end));
                                        end
				
                                   case 'descendants'
                                        if ~isfield(cellList.meshData{frame-1}{cells},'descendants') || isempty(cellList.meshData{frame-1}{cells}.descendants)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame-1}{cells}.descendants) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.descendants(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.descendants(end));
                                        end
				
                                 case 'divisions'
                                     if ~isfield(cellList.meshData{frame-1}{cells},'divisions') || isempty(cellList.meshData{frame-1}{cells}.divisions)
                                        fprintf(textFile,' ,');
                                     else
                                        for jj = 1:length(cellList.meshData{frame-1}{cells}.divisions) - 1
                                            fprintf(textFile,'%g;',cellList.meshData{frame-1}{cells}.divisions(jj));
                                        end
                                        fprintf(textFile,'%g,',cellList.meshData{frame-1}{cells}.divisions(end));
                                     end
				
                                case 'mesh'
                                    if ~isfield(cellList.meshData{frame-1}{cells},'mesh') || isempty(cellList.meshData{frame-1}{cells}.mesh)
                                        fprintf(textFile,' ,');
                                    else
                                        for jj = 1:size(cellList.meshData{frame-1}{cells}.mesh,2) - 1
                                            fprintf(textFile,'%g ',cellList.meshData{frame-1}{cells}.mesh(:,jj));
                                            fprintf(textFile,';');
                                        end
                                        fprintf(textFile,'% g',cellList.meshData{frame-1}{cells}.mesh(:,end));
                                        fprintf(textFile,',');
                                    end
                                    case 'length' 
                                               fprintf(textFile,' ,');
                                           

                                    case 'area'
                                               fprintf(textFile,' ,');
                                           
                                    case 'polarity'
                                            if ~isfield(cellList.meshData{frame-1}{cells},'polarity') 
                                               fprintf(textFile,' ,');
                                            else  
                                               fprintf(textFile,'% g',cellList.meshData{frame-1}{cells}.polarity);
                                               fprintf(textFile,',');
                                           end
                                        
                                     case 'signal0'
                                               fprintf(textFile,' ,');
                                        
                                end
                            end
                            fprintf(textFile,'%g,\n',cellList.cellId{frame-1}(cells));
                        end
                    end
                end
            if isHighThroughput && p.outCsvFormat && textFile ~= -1 && frame == range(2)
                   for cells = 1:length(cellList.meshData{frame})
                       fprintf(textFile,'#%d,',frame);
                            for ii = 1:length(fieldNamesCellList)
                                switch fieldNamesCellList{ii}
                                    case 'ancestors'
                                        if ~isfield(cellList.meshData{frame}{cells},'ancestors') || isempty(cellList.meshData{frame}{cells}.ancestors)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame}{cells}.ancestors) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame}{cells}.ancestors(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame}{cells}.ancestors(end));
                                        end
                                    case 'birthframe'
                                       if ~isfield(cellList.meshData{frame}{cells},'birthframe') || isempty(cellList.meshData{frame}{cells}.birthframe)
                                            fprintf(textFile,' ,');
                                       else
                                            fprintf(textFile,'%g,',cellList.meshData{frame}{cells}.birthframe(end));
                                       end
                                    case 'box'
                                        if ~isfield(cellList.meshData{frame}{cells},'box') || isempty(cellList.meshData{frame}{cells}.box)
                                            fprintf(textFile,' ,');
                                        else
                                            for jj = 1:length(cellList.meshData{frame}{cells}.box) - 1
                                                fprintf(textFile,'%g;',cellList.meshData{frame}{cells}.box(jj));
                                            end
                                            fprintf(textFile,'%g,',cellList.meshData{frame}{cells}.box(end));
                                        end
                                  case 'descendants'
                                      if ~isfield(cellList.meshData{frame}{cells},'descendants') || isempty(cellList.meshData{frame}{cells}.descendants)
                                          fprintf(textFile,' ,');
                                      else
                                          for jj = 1:length(cellList.meshData{frame}{cells}.descendants) - 1
                                              fprintf(textFile,'%g;',cellList.meshData{frame}{cells}.descendants(jj));
                                          end
                                          fprintf(textFile,'%g,',cellList.meshData{frame}{cells}.descendants(end));
                                      end
                                      case 'divisions'
                                          if ~isfield(cellList.meshData{frame}{cells},'divisions') || isempty(cellList.meshData{frame}{cells}.divisions)
                                              fprintf(textFile,' ,');
                                          else
                                              for jj = 1:length(cellList.meshData{frame}{cells}.divisions) - 1
                                                  fprintf(textFile,'%g;',cellList.meshData{frame}{cells}.divisions(jj));
                                              end
                                              fprintf(textFile,'%g,',cellList.meshData{frame}{cells}.divisions(end));
                                          end
                                    case 'mesh'
                                          if ~isfield(cellList.meshData{frame}{cells},'mesh') || isempty(cellList.meshData{frame}{cells}.mesh)
                                              fprintf(textFile,' ,');
                                          else
                                              for jj = 1:size(cellList.meshData{frame}{cells}.mesh,2) - 1
                                                  fprintf(textFile,'%g ',cellList.meshData{frame}{cells}.mesh(:,jj));
                                                  fprintf(textFile,';');
                                              end
                                              fprintf(textFile,'% g',cellList.meshData{frame}{cells}.mesh(:,end));
                                              fprintf(textFile,',');
                                          end
                                     case 'length' 
                                               fprintf(textFile,' ,');
                                           
                                    case 'area'
                                               fprintf(textFile,' ,');
                                            
                                    case 'polarity'
                                            if ~isfield(cellList.meshData{frame}{cells},'polarity') 
                                               fprintf(textFile,' ,');
                                            else  
                                               fprintf(textFile,'% g',cellList.meshData{frame}{cells}.polarity);
                                               fprintf(textFile,',');
                                           end
                                        
                                     case 'signal0'
                                               fprintf(textFile,' ,');
                                        
                                end
                            end
                            fprintf(textFile,'%g,\n',cellList.cellId{frame}(cells));
                   end
            end
                    
         shiftmeshes(frame,-1,listtorun);
         elseif mode==4
                if isfield(p,'joinWhenReuse') && p.joinWhenReuse, 
                joincells(frame,[]); 
                end
                if frame~=range(1)
                listtorun = selNewFrame(listtorun,frame-1,frame);
                end
         end 
    if isempty(lst), listtorun=[]; end
%  for i=1:length(addsig)
%     if addsig(i)
%        if length(addas)<i, addas0 = max(i-2,0); else addas0 = addas{i}; end
%           addSignalToFrame(frame,i,addas0,listtorun,p.sgnResize,p.approxSignal,shiftfluo);
%     end
%  end
  
        try
            time2 = clock;
            if mode~=4
            disp(['frame ' num2str(frame) ' finished, elapsed time ' num2str(etime(time2,time1)) ' s']);
            disp(' ');
            end
            if savemode==1 && mod(frame,fsave)==0 && p.outCsvFormat==0
               savemesh(savefile,selNewFrame(lst,frame,1),saveselect,[]);
            end
        catch err
            disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
            disp(err.message)
            savemesh(savefile,selNewFrame(lst,frame,1),saveselect,[]);
        end
        
        if p.stopButton == 1 || p.pauseButton == 1
            if p.stopButton == 1
                error('all tasks aborted and data being saved')
            else
                f = figure('OuterPosition',[600,700,300,100],'MenuBar','none','Name','','NumberTitle','off',...
                           'DockControls','off');
                h = uicontrol('Position',[40 10 200 40],'String','Continue',...
                              'Callback','uiresume(gcbf)');
                uiwait(gcf);
                close(f);
                p.pauseButton = 0;
            end
        end
    
    catch err
        if p.stopButton ~= 1
            disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
            disp(err.message)
            savemesh(savefile, selNewFrame(lst,frame,1),saveselect,[]);
            fclose('all');
            return;
% % %         elseif isHighThroughput && p.outCsvFormat && textFile ~= -1
% % %             fprintf(textFile,'$ cellId\n');
% % %             for ii = 1:length(cellList.cellId)
% % %                 fprintf(textFile,'% d',cellList.cellId{ii});
% % %                 fprintf(textFile,',');fprintf(textFile,'\n');
% % %             end
% % %             return;
        else
            p.stopButton = 0;
            fclose('all');
            return;
        end
    end
    end
% % %     if isHighThroughput && p.outCsvFormat && textFile ~= -1
% % %        fprintf(textFile,'$ cellId\n');
% % %        for ii = 1:length(cellList.cellId)
% % %        fprintf(textFile,'% d',cellList.cellId{ii});
% % %        fprintf(textFile,',');fprintf(textFile,'\n');
% % %        end
% % %     end
fclose('all');
    
       
 %-------------------------------------------------------------------------
 %addSignalToFrameParallel is used instead of addSignalToFrame update June
 %8 2012.
 try
    if range(2) < range(1), msgbox('Number of images are less than requested frames'); return; end
    if ~isHighThroughput
        if length(find(addsig)) >=1 && p.runSerial == 0
            addSignalToFrameParallel(range,addsig,addas,listtorun,...
                             p.sgnResize,p.approxSignal,shiftfluo); 
        else
            for ii = range(1):range(2)
            for i=1:length(addsig)
            if addsig(i)
            if length(addas)<i, addas0 = max(i-2,0); else addas0 = addas{i}; end
            addSignalToFrame(ii,i,addas0,listtorun,p.sgnResize,p.approxSignal,shiftfluo);
            end
            end
            end
        end
    end
    if length(find(addsig)) >=1 && savemode==3 && ~isHighThroughput,savemesh(savefile,lst,saveselect,[]); end;
 catch err
     disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
     disp(err.message)
     if p.outCsvFormat==0
        savemesh(savefile,lst,saveselect,[]);
     end
     return;
 end
 
end
%-------------------------------------------------------------------------
try
     
     if ((savemode == 1 && mode == 3) || savemode==2 || (savemode==3 && mod(frame,fsave)~=0))
         if ~isHighThroughput && p.outCsvFormat==1
             warndlg('Data was not saved:  set outCsvFormat parameter to 0.  You can manually save the data with "Save analysis" button');
             return;
         else
             savemesh(savefile,lst,saveselect,[]);
         end
      end

    return;
catch
    if savemode==2 || savemode==3  && p.outCsvFormat==0
        savemesh(savefile,lst,saveselect,[]);
    end

    return;
end

end


function d=edist(x1,y1,x2,y2)
    % complementary for "getextradata", computes the length between 2 points
    d=sqrt((x2-x1).^2+(y2-y1).^2);
end


