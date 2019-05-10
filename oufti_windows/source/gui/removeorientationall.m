function cellList = removeorientationall(cellList,cellId)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function cellList = removeorientationall(cellList,cellId)
%oufti.v0.2.8
%@author:  oleksii Sliusarenko
%@update:  Ahmad J. Paintdakhi
%@date:    March 27, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%cellList:    updated cellList changes to the polarity field in all data in
%             cellList
%**********Input********:
%cellList:    A structure containing two fields meshData and cellId
%cellId:    cellId is the cell # where field changes will occur.
%==========================================================================
%The function changes polarity field to 0 for cell(cellId) in all the
%frames.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------
 
for frame=1:oufti_getLengthOfCellList(cellList)
    if oufti_doesCellExist(cellId, frame, cellList)
       cellList = oufti_addFieldToCellList(cellId, frame, 'polarity', 0, cellList);
    end
end

end

