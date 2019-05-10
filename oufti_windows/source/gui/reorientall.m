function cellList = reorientall(cellList,cellId,flagForOrient)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function cellList = reorientall(cellList,cellId,flagForOrient)
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
%The function sets polarity field to 1 in cell(cellId) and if flagForOrient
%is true then it also orients the fields of cell(cellId).
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------

tflag = false;
for frame=1:oufti_getLengthOfCellList(cellList)
    if oufti_doesCellExist(cellId, frame, cellList)
       % terminate if the cell just divided (except on the 1st frame)
       if tflag && cellList.meshData{frame}{oufti_cellId2PositionInFrame(cellId,frame,cellList)}.birthframe==frame
          return
       end
       tflag = true;
       % reorient
       if flagForOrient
          cellStructure = oufti_getCellStructure(cellId,frame,cellList);
          cellList = oufti_addCell(cellId,frame,reorient(cellStructure),cellList);
       end
       % set the polarity variable
       cellList = oufti_addFieldToCellList(cellId, frame, 'polarity', 1, cellList);
   end
end

end

