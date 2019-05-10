function updatelineage(lst,frame)

% This function updates the lineage information for the group of
    % selected cells. It assumes that on the current frame is correct and
    % goes through the successive frames
    
    global cellList cellListN
    cellListN = cellfun(@length,cellList.meshData);
     for i=1:length(lst)
        if length(cellList.meshData{frame})<oufti_cellId2PositionInFrame(lst(i),frame,cellList) || isempty(cellList.meshData{frame}{oufti_cellId2PositionInFrame(lst(i),frame,cellList)})...
                || ~isfield(cellList.meshData{frame}{oufti_cellId2PositionInFrame(lst(i),frame,cellList)},'timelapse')...
                || ~cellList.meshData{frame}{oufti_cellId2PositionInFrame(lst(i),frame,cellList)}.timelapse
            disp('Lineage could not be updated')
            return
        end
     end
    if length(cellListN)<=1 || ismember(0,cellListN(1)==cellListN) 
        disp('Lineage could not be updated')
        return
    end
    
    pcelllist = lst;
    for i=1:length(lst)
        pstructlist{i} = movestruct([],cellList.meshData{frame}{oufti_cellId2PositionInFrame(lst(i),frame,cellList)});%#ok<AGROW>
    end
    for cframe=frame+1:length(cellList.meshData)
        ccelllist = [];
        cstructlist = {};
        for i=1:length(pcelllist)
            pcell = pcelllist(i);
            mstruct = pstructlist{i};
            daughter = getDaughter();
            if length(cellList.meshData{cframe})>=daughter && ~isempty(cellList.meshData{cframe}{daughter})
                mstruct.descendants = [mstruct.descendants daughter];
                mstruct.divisions = [mstruct.divisions cframe];
                dstruct.birthframe = cframe;
                dstruct.ancestors = [mstruct.ancestors pcell];
                dstruct.descendants = [];
                dstruct.divisions = cframe;
                ccelllist = [ccelllist pcell daughter];%#ok<AGROW>
                cstructlist = [cstructlist mstruct dstruct];%#ok<AGROW>
                cellList.meshData{cframe}{oufti_cellId2PositionInFrame(daughter,cframe,cellList)} = movestruct(cellList.meshData{cframe}{oufti_cellId2PositionInFrame(daughter,cframe,cellList)},dstruct);
            else
                ccelllist = [ccelllist pcell];%#ok<AGROW>
                cstructlist = [cstructlist mstruct];%#ok<AGROW>
            end
            if length(cellList.meshData{cframe})>=pcell && ~isempty(cellList.meshData{cframe}{oufti_cellId2PositionInFrame(pcell,cframe,cellList)})
                cellList.meshData{cframe}{oufti_cellId2PositionInFrame(pcell,cframe,cellList)} = movestruct(cellList.meshData{cframe}{oufti_cellId2PositionInFrame(pcell,cframe,cellList)},mstruct);
            end
        end
        pcelllist = ccelllist;
        pstructlist = cstructlist;
    end
end
function s1=movestruct(s1,s2)
    % update lineage for the updatelineage function
    s1.birthframe = s2.birthframe;
    s1.ancestors = s2.ancestors;
    s1.descendants = s2.descendants;
    s1.divisions = s2.divisions;
end