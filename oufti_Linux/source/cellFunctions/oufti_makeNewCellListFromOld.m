function newCellListFormat = oufti_makeNewCellListFromOld(oldCellList)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function newCellListFormat = oufti_makeNewCellListFromOld(oldCellList)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 22, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%newCellListFormat:  new cellList format containing fields meshData and
%cellId.
%**********input********:
%oldCellList:	old cellList as a cell array.
%==========================================================================
%The function makes the new cellList format from the old one with fields
%meshData and cellId.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------

%if oldCellList is empty then make new cellList with empty cell fields and
%return without invoking further lines in the function.
if isempty(oldCellList),newCellListFormat.meshData = {[]}; newCellListFormat.cellId = {[]}; return; end

newCellListFormat.meshData   = cell(1,length(oldCellList));
newCellListFormat.cellId = cell(1,length(oldCellList));
for frame = 1:length(oldCellList)
    cellStructureArray = oldCellList{frame};
    if isempty(cellStructureArray),continue;end
    onlyStructs = cellfun(@isstruct,cellStructureArray);
    indexOnlyStructs = find(onlyStructs>0);
    newCellListFormat = oufti_addFrame(frame, cellStructureArray(onlyStructs), indexOnlyStructs, newCellListFormat);
end
end