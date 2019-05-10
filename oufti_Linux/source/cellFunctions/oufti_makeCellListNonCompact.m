function CL = oufti_makeNewCellListNonCompact(CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = makeNewCellListNonCompact(CL)
%The purpose of this function is to bring back to its original the cellList
%array which was compacted by the function makeNewCellListCompact function.
%oufti.v0.2.4
%@author:  Ahmad J Paintdakhi
%@date:    Nov 14 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:  cellList structure in original form
%**********Input********:
%CL:  cellList structure
%==========================================================================
if isfield(CL,'compact') && strcmp(CL.compact,'true'),...
   CL.compact = 'false'; else return; end
tempHistory = {[]};
for frame = 1:length(CL.meshData)
    counter = 0;
    tempHistory{frame} = cell(1,size(CL.cellId{frame},2));
    for cells = 1:length(CL.nonEmptyCells{frame})    
    if CL.nonEmptyCells{frame}(cells)
       counter = counter +1;
       tempHistory{frame}{cells} = CL.meshData{frame}{counter};
    end
    end
end

CL.meshData = tempHistory;
end