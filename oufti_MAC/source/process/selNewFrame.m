function newlst2 = selNewFrame(lst,oldframe,newframe)
 % updates the list of selected cells ("lst" as selected on frame 
 % "oldframe") and oputputs as mewlst2 (on frame "newframe")
global cellList cellListN
if ~isfield(cellList,'meshData'),cellList = oufti_makeNewCellListFromOld(cellList);end

cellListN = cellfun(@length,cellList.meshData);
newlst = [];
newlst2 = [];
if ~oufti_doesFrameExist(max(newframe, oldframe), cellList) || ...
    oufti_isFrameEmpty(newframe, cellList) || ...
    oufti_isFrameEmpty(oldframe, cellList)
%max(newframe,oldframe)>length(cellList) || max(newframe,oldframe)>length(cellListN) ||...
%     isempty(lst) || isempty(cellList{oldframe}) || isempty(cellList{newframe}) ||...
%     cellListN(oldframe)~=cellListN(newframe), 
 return
end
lst = sort(lst);
if newframe>oldframe
    maxcell = cellListN(oldframe);
        % find all potentially daugnter cells
        for i=1:length(lst)
            ccell = lst(i);
            ccell2 = [];
            
            if oufti_doesCellExist(ccell, newframe, cellList) && oufti_doesCellExist(ccell, oldframe, cellList)
                cellNew = oufti_getCellStructure(ccell, newframe, cellList);
                cellOld = oufti_getCellStructure(ccell, oldframe, cellList);
                if isstruct(cellNew) && isstruct(cellOld) && ... 
                   (~isfield(cellNew, 'birthframe') || cellNew.birthframe == cellOld.birthframe)
               %length(cellList{newframe})>=ccell && ~isempty(cellList{newframe}{ccell}) &&...
               %         length(cellList{oldframe})>=ccell && ~isempty(cellList{oldframe}{ccell}) &&...
               %         (~isfield(cellList{newframe}{ccell},'birthframe') || cellList{newframe}{ccell}.birthframe==cellList{oldframe}{ccell}.birthframe)
                    nchildren = length(cellOld.divisions);
                    ccell2 = getallchildren(ccell,maxcell*2^nchildren,oufti_getFrameLength(newframe, cellList));
                end
            end
            newlst = [newlst ccell2]; %#ok<AGROW>
        end
        % remove duplicates
        %newlst=sort(newlst);
        %ind = newlst - circshift(newlst',1)';
        %ind(1)=1;
        %if ~isempty(newlst)
        %    newlst = newlst(ind>0);
        %end
        newlst = unique(newlst);
        if isempty(newlst),newlst = [];end
        % get those alrady existing on the old frame and their possible progeny
        lstNE = newlst(~ismember(newlst,lst));
        newlstNE = [];
        for ccell = lstNE
            ccell2 = [];
            
            if oufti_doesCellExist(ccell, newframe, cellList) && oufti_doesCellExist(ccell, oldframe, cellList)
                cellNew = oufti_getCellStructure(ccell, newframe, cellList);
                cellOld = oufti_getCellStructure(ccell, oldframe, cellList);
                if ~isempty(cellNew) && ~isempty(cellOld) && ... 
                   (~isfield(cellNew, 'birthframe') || cellNew.birthframe == cellOld.birthframe)
              %length(cellList{newframe})>=ccell && ~isempty(cellList{newframe}{ccell}) &&...
              %          length(cellList{oldframe})>=ccell && ~isempty(cellList{oldframe}{ccell}) &&...
              %          (~isfield(cellList{newframe}{ccell},'birthframe') || cellList{newframe}{ccell}.birthframe==cellList{oldframe}{ccell}.birthframe)
                    %nchildren = length(cellList{oldframe}{ccell}.divisions);
                    nchildren = length(cellOld.divisions);
                    ccell2 = getallchildren(ccell,maxcell*2^nchildren,oufti_getFrameLength(newframe, cellList));
                end
            end
            newlstNE = [newlstNE ccell2]; %#ok<AGROW>
        end
        % remove non-existing progeny from existing progeny
        newlst = newlst(~ismember(newlst,newlstNE));
    else
        % I'd rather see that the parents are selected if the cell was born
        % in between newframe and oldframe
                
% % %         for celln = lst %1:length(cellList{oldframe})
% % %             cn = celln;
% % %             nf = newframe;
% % %             of = oldframe;
            
% % %             while ~oufti_doesCellExist(cn, newframe, cellList)
% % %                 %(cn > length(cellList{newframe}) || isempty(cellList{newframe}{cn}))
% % %                 
% % %                 % The cell didn't exist. Find parent!
% % % 
% % %                 if (nf < newframe)
% % %                     % We've moved past newframe without finding an
% % %                     % ancestor. Something's wrong.
% % %                     disp(['Was looking for an ancestor to cell ' num2str(celln) ' at frame ' num2str(newframe) ' with no sucess.']);
% % %                     cn = [];
% % %                     break;
% % %                 end
% % %                 if ~oufti_doesCellExist(cn, of, cellList) %cn > length(cellList{of})
% % %                     % the cell didn't exitst at the old frame either.
% % %                     % take it out of the list.
% % %                     lst = setdiff(lst, cn);
% % %                     break;
% % %                 end
% % %                 
% % %                 cell = oufti_getCellStructure(cn, of, cellList);
% % %                 if ~isempty(cell) % ~isempty(cellList{of}{cn})
% % %                     
% % %                     cn_new = cell.ancestors;
% % %                     nf     = cell.birthframe;
% % %                     of     = nf;
% % %                     if ~isempty(cn_new)
% % %                         cn = cn_new(end);
% % %                     else
% % %                         cn=[];
% % %                         break;
% % %                     end
% % %                 else
% % %                     % Lost track of the cell. It may have been deleted.
% % %                     cn = [];
% % %                     break;
% % %                 end
% % %             end
% % %             
% % %             if cn >= 0
% % %                 lst = union(lst, cn);
% % %             end
% % %         end
    newlst = lst; %union(lst);
end
    
    % keep only the cells existing on the new frame
    for i=newlst
        if oufti_doesCellExist(i, newframe, cellList)
            newlst2 = [newlst2 i]; %#ok<AGROW>
        end
    end
    
    if newframe==oldframe+1 && isempty(newlst2) % for processing selected cells
        newlst2 = lst;
    end

end