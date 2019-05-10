function [cellIdContainer frameIdContainer] = divisionframe1(cellList,threshValue,flag)
if ~isfield(cellList,'meshData')
    cellList = oufti_makeNewCellListFromOld(cellList);
end
divfrm = [];
[~, cellId] = oufti_getFrame(1,cellList);
for celln = 1:max(cellId)*1
    cellprf = [];
    for frame=1:oufti_getLengthOfCellList(cellList)
        cellIdPosition = oufti_cellId2PositionInFrame(celln, frame, cellList);
        if isempty(cellIdPosition), continue; end
        tmpCellStructure = oufti_getCellStructure(celln,frame,cellList);
        if celln <= max(cellList.cellId{frame}) && oufti_doesCellStructureHaveMesh(celln, frame, cellList) ...
                && isfield(tmpCellStructure,'signal0') && ~isempty(tmpCellStructure.signal0)
            prf = tmpCellStructure.signal0;
   
            for i=1:3
                prf = 0.5*prf + threshValue*(prf([1 1:end-1])+prf([2:end end]));
            end
            mn = mean(prf);
            minima = [false reshape( (prf(2:end-1)<prf(1:end-2))&...
                (prf(2:end-1)<=prf(3:end))|(prf(2:end-1)<=prf(1:end-2))&...
                (prf(2:end-1)<prf(3:end)) ,1,[]) false];
            if isempty(minima) || sum(prf)==0
                res = 0;
            else
                depth = 0;
                while true
                    if sum(minima)==0, break; end
                    im = find(minima);
                    [min0,i0] = min(prf(minima));
                    max1 = max(prf(1:im(i0)));
                    max2 = max(prf(im(i0):end));
                    depth = [depth (max1+max2-2*min0)/(max1+max2)]; %#ok<AGROW>
                    if max1<0.5*mn || max2<0.5*mn
                        minima(im(i0))=0;
                        continue
                    else
                        break
                    end
                end
                res = max(depth);
            end
            cellprf(frame) = res; %#ok<AGROW>
        end
    end
    if isempty(cellprf), continue; end
    for i=1:4
        cellprf = 0.5*cellprf + threshValue*(cellprf([1 1:end-1])+cellprf([2:end end]));
    end
    cellprfmax = cellprf>cellprf([1 1:end-1]) & cellprf>cellprf([2:end end]) & cellprf>threshValue; %& cellprf>mean(cellprf);
    ind = find(cellprfmax,1,'first');
    if ~isempty(ind)
        divfrm(celln) = ind; %#ok<AGROW>
    end
    if flag == 0
        figure(1)
        plot(1:length(cellprf),cellprf,ind,cellprf(ind),'.r')
        xlabel('frame number')
        ylabel('degree of constriction')
        title(['Cell' num2str(celln)])
    else
        figure(1)
        plot(1:length(cellprf),cellprf,ind,cellprf(ind),'.r')
        xlabel('frame number')
        ylabel('degree of constriction')
        title(['Cell' num2str(celln) ' ---- in frame ' num2str(ind)])
        set(gca,'XMinorGrid','on');
        
        f = figure('OuterPosition',[400,700,300,100],'MenuBar','none','Name','','NumberTitle','off',...
                           'DockControls','off');
        h = uicontrol('Position',[40 10 200 40],'String','Continue',...
                              'Callback','uiresume(gcbf)');
        uiwait(gcf);
        close(f);
    end
end
if flag == 1, cellIdContainer = 0; frameIdContainer = 0; return; end
if ~isempty(divfrm)
    frameIdContainer  = nonzeros(divfrm);
    [frameIdContainer,ii] = sort(frameIdContainer);
    cellIdContainer = find(divfrm>0);
    cellIdContainer = cellIdContainer(ii);
end

[a,frameIdContainerOut] = hist(frameIdContainer,unique(frameIdContainer));
cellIdContainerOut = cell(1,length(a));
counter = 0;
for ii = 1:length(cellIdContainerOut)
    tempValue = 0;
    if a(ii) == 1
        counter = counter + 1;
        cellIdContainerOut{ii} = cellIdContainer(counter);
        
    else
        
        for jj = 1:a(ii)
        counter = counter + 1;  
        tempValue(jj) = cellIdContainer(counter); %#ok<AGROW>
        end
        cellIdContainerOut{ii} = tempValue;
        
    end
end

cellIdContainer = cellIdContainerOut;
frameIdContainer = frameIdContainerOut;




end %function