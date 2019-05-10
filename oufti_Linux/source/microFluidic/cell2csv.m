function cell2csv(filename,cellArray,delimiter)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function cell2csv(filename,cellArray,delimiter)
% Writes cell array content into a *.csv file.
%author:  Ahmad Paintdakhi
%@revision date:    December 19, 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%********** input ********:
%filename = Name of the file to save. [ i.e. 'text.csv' ]
%cellarray = Name of the Cell Array where the data is in
% delimiter = seperating sign, normally:',' (it's default)
%==========================================================================
global paramString cellListN shiftframes handles
screenSize = get(0,'ScreenSize');

try
    % R2010a and newer
    iconsClassName = 'com.mathworks.widgets.BusyAffordance$AffordanceSize';
    iconsSizeEnums = javaMethod('values',iconsClassName);
    SIZE_32x32 = iconsSizeEnums(2);  % (1) = 16x16,  (2) = 32x32
    jObj = com.mathworks.widgets.BusyAffordance(SIZE_32x32, 'Processing...');  % icon, label
catch
    % R2009b and earlier
    redColor   = java.awt.Color(1,0,0);
    blackColor = java.awt.Color(0,0,0);
    jObj = com.mathworks.widgets.BusyAffordance(redColor, blackColor);
end
jObj.setPaintsWhenStopped(true);  % default = false
jObj.useWhiteDots(false);         % default = false (true is good for dark backgrounds)
hh =  figure('pos',[(screenSize(3)/2)-100 (screenSize(4)/2)-100 100 100],'Toolbar','none',...
             'Menubar','none','NumberTitle','off','DockControls','off');
pause(0.05);drawnow;
pos = hh.Position;
javacomponent(jObj.getComponent, [1,1,pos(3),pos(4)],hh);
pause(0.01);drawnow;
jObj.start;
    % do some long operation...
tempCellList = cellArray;
if ~isfield(tempCellList,'meshData')
    tempCellList = oufti_makeNewCellListFromOld(tempCellList);
end


datei = fopen(filename,'w');

dateAndTimeDataProcessed = clock();
fprintf(datei,'%s','%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
fprintf(datei,'\n\n');
fprintf(datei,'%s',['MicroFluidic ".csv" file named ' char(filename) ' processed on ---> ' num2str(dateAndTimeDataProcessed(2)) ...
        '/' num2str(dateAndTimeDataProcessed(3)) '/' num2str(dateAndTimeDataProcessed(1)) ' at ' ...
        num2str(dateAndTimeDataProcessed(4)) ':' num2str(dateAndTimeDataProcessed(5))]);
fprintf(datei,'\n\n');
fprintf(datei,'%s','%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
fprintf(datei,'\n\n');
try
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

            fprintf(datei,'# % s\n',var);

        end
        end
        fprintf(datei,'\n');
    end
catch
end
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
                      'spots'
                      'objects'
                      };

if exist('cellListN'),fprintf(datei,'$ cellListN');fprintf(datei,'% d',cellListN);end
fprintf(datei,'\n');
if exist('coefPCA'),fprintf(datei,'$ coefPCA');fprintf(datei,'% d',coefPCA);end
fprintf(datei,'\n');
if exist('mCell'),fprintf(datei,'$ mCell');fprintf(datei,'% d',mCell);end
fprintf(datei,'\n');
if exist('shiftfluo'),fprintf(datei,'$ shiftfluo');fprintf(datei,'% d',shiftfluo);end
fprintf(datei,'\n');
if exist('shiftframes')
    if isstruct(shiftframes)
        tempShiftFrames = (struct2cell(shiftframes))';
        fprintf(datei,'$ shiftframes');
        fprintf(datei,'% g',tempShiftFrames{1});
        fprintf(datei,';');fprintf(datei,'% g',tempShiftFrames{2});
    else
        fprintf(datei,'$ shiftframes');fprintf(datei,'% g',shiftframes);
    end
end
fprintf(datei,'\n');
fprintf(datei,'\n');

fprintf(datei,'%% parameter values\n');
fprintf(datei,'frameNumber,');
for ii = 1:length(fieldNamesCellList)
    var = eval('fieldNamesCellList{ii}');
    fprintf(datei,'%s',var);
    if ii < length(fieldNamesCellList),fprintf(datei,',');end   
end
fprintf(datei,',cellId;\n');

for frame = 1:length(tempCellList.meshData)
    for cells = 1:length(tempCellList.meshData{frame})
        fprintf(datei,'#%d,',frame);
        for ii = 1:length(fieldNamesCellList)
		    switch fieldNamesCellList{ii}
				case 'ancestors'
                    if ~isfield(tempCellList.meshData{frame}{cells},'ancestors') || isempty(tempCellList.meshData{frame}{cells}.ancestors)
                        fprintf(datei,' ,');
                    else
                        for jj = 1:length(tempCellList.meshData{frame}{cells}.ancestors) - 1
                            fprintf(datei,'%g;',tempCellList.meshData{frame}{cells}.ancestors(jj));
                        end
                        fprintf(datei,'%g,',tempCellList.meshData{frame}{cells}.ancestors(end));
                    end
				
				case 'birthframe'
                    if ~isfield(tempCellList.meshData{frame}{cells},'birthframe') || isempty(tempCellList.meshData{frame}{cells}.birthframe)
                        fprintf(datei,' ,');
                    else
                        for jj = 1:length(tempCellList.meshData{frame}{cells}.birthframe) - 1
                            fprintf(datei,'%g;',tempCellList.meshData{frame}{cells}.birthframe(jj));
                        end
                        fprintf(datei,'%g,',tempCellList.meshData{frame}{cells}.birthframe(end));
                    end
				
				case 'box'
                    if ~isfield(tempCellList.meshData{frame}{cells},'box') || isempty(tempCellList.meshData{frame}{cells}.box)
                        fprintf(datei,' ,');
                    else
                        for jj = 1:length(tempCellList.meshData{frame}{cells}.box) - 1
                            fprintf(datei,'%g;',tempCellList.meshData{frame}{cells}.box(jj));
                        end
                        fprintf(datei,'%g,',tempCellList.meshData{frame}{cells}.box(end));
                    end
				
				case 'descendants'
                    if ~isfield(tempCellList.meshData{frame}{cells},'descendants') || isempty(tempCellList.meshData{frame}{cells}.descendants)
                        fprintf(datei,' ,');
                    else
                        for jj = 1:length(tempCellList.meshData{frame}{cells}.descendants) - 1
                            fprintf(datei,'%g;',tempCellList.meshData{frame}{cells}.descendants(jj));
                        end
                        fprintf(datei,'%g,',tempCellList.meshData{frame}{cells}.descendants(end));
                    end
				
				case 'divisions'
                    if ~isfield(tempCellList.meshData{frame}{cells},'divisions') || isempty(tempCellList.meshData{frame}{cells}.divisions)
                        fprintf(datei,' ,');
                    else
                        for jj = 1:length(tempCellList.meshData{frame}{cells}.divisions) - 1
                            fprintf(datei,'%g;',tempCellList.meshData{frame}{cells}.divisions(jj));
                        end
                        fprintf(datei,'%g,',tempCellList.meshData{frame}{cells}.divisions(end));
                    end
				
				case 'mesh'
                    if ~isfield(tempCellList.meshData{frame}{cells},'mesh') || isempty(tempCellList.meshData{frame}{cells}.mesh)
                        fprintf(datei,' ,');
                    else
                        for jj = 1:size(tempCellList.meshData{frame}{cells}.mesh,2) - 1
                            fprintf(datei,'%g ',tempCellList.meshData{frame}{cells}.mesh(:,jj));
                            fprintf(datei,';');
                        end
                        fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.mesh(:,end));
                        fprintf(datei,',');
                    end
                case 'length'
                    if ~isfield(tempCellList.meshData{frame}{cells},'length')
                        if isfield(tempCellList.meshData{frame}{cells},'mesh') || isempty(tempCellList.meshData{frame}{cells}.mesh)
                           mesh = tempCellList.meshData{frame}{cells}.mesh;
                           stepLength = edist(mesh(2:end,1)+mesh(2:end,3),mesh(2:end,2)+mesh(2:end,4),...
                                    mesh(1:end-1,1)+mesh(1:end-1,3),mesh(1:end-1,2)+mesh(1:end-1,4))/2;
                           lengthOfCell = sum(stepLength);
                           fprintf(datei,'% g',lengthOfCell);
                           fprintf(datei,' ,');
                        else
                            fprintf(datei,' ,');
                        end
                    else
                        fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.length);
                        fprintf(datei,',');
                    end

                case 'area'
                      if ~isfield(tempCellList.meshData{frame}{cells},'area') 
                          if isfield(tempCellList.meshData{frame}{cells},'mesh') || isempty(tempCellList.meshData{frame}{cells}.mesh)
                              mesh = tempCellList.meshData{frame}{cells}.mesh;
                              lng = size(mesh,1)-1;
                              steparea = zeros(lng,1);
                               for i=1:lng
                                   steparea(i,1) = polyarea([mesh(i:i+1,1);mesh(i+1:-1:i,3)],[mesh(i:i+1,2);mesh(i+1:-1:i,4)]); 
                               end
                               areaOfCell = sum(steparea);
                               fprintf(datei,'% g',areaOfCell);
                               fprintf(datei,' ,');
                          else     
                            fprintf(datei,' ,');
                          end
                      else
                        fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.area);
                        fprintf(datei,',');
                      end

                 case 'polarity'
                        if ~isfield(tempCellList.meshData{frame}{cells},'polarity') 
                           fprintf(datei,' ,');
                        else  
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.polarity);
                           fprintf(datei,',');
                        end

                case 'signal0'
                     if ~isfield(tempCellList.meshData{frame}{cells},'signal0') 
                           fprintf(datei,' ,');
                     else  
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.signal0);
                           fprintf(datei,',');
                     end
                case 'spots'
                     if ~isfield(tempCellList.meshData{frame}{cells},'spots') 
                           fprintf(datei,' ,');
                     elseif isempty(tempCellList.meshData{frame}{cells}.spots.l)
                            fprintf(datei,' ,');
                     else
                         try
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.spots.l);
                           fprintf(datei,';');
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.spots.d);
                           fprintf(datei,';');
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.spots.x);
                           fprintf(datei,';');
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.spots.y);
                           fprintf(datei,';');
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.spots.positions);
                           fprintf(datei,';');
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.spots.rsquared);
                           fprintf(datei,',');
                         catch
                         end
                     end
                case 'objects'
                     if ~isfield(tempCellList.meshData{frame}{cells},'objects') 
                           fprintf(datei,' ,');
                     elseif isempty(tempCellList.meshData{frame}{cells}.objects.outlines)
                           fprintf(datei,' ,');
                     else
                           for jj = 1:size(tempCellList.meshData{frame}{cells}.objects.outlines,2)-1
                               fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.outlines{jj}(:,1));
                               fprintf(datei,';');
                               fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.outlines{jj}(:,2));
                               fprintf(datei,';');
                               fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.pixels{jj});
                               fprintf(datei,';');
                               fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.pixelvals{jj});
                               fprintf(datei,';');
                               fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.area{jj});
                               fprintf(datei,';');
                           end
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.outlines{end}(:,1));
                           fprintf(datei,';');
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.outlines{end}(:,2));
                           fprintf(datei,';');
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.pixels{end});
                           fprintf(datei,';');
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.pixelvals{end});
                           fprintf(datei,';');
                           fprintf(datei,'% g',tempCellList.meshData{frame}{cells}.objects.area{end});
                           fprintf(datei,',');
                     end
            end
        end
            fprintf(datei,'%g,\n',tempCellList.cellId{frame}(cells));
    end
end

fclose(datei);
disp(['Analysis converted from ".mat" format to ".csv" format in file ' filename]); 
 jObj.stop;
 delete(hh)
%tar('cellAray.tgz','.');

function d=edist(x1,y1,x2,y2)
    % complementary for "getextradata", computes the length between 2 points
    d=sqrt((x2-x1).^2+(y2-y1).^2);
end

end
