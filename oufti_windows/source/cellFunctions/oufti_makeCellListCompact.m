function CL = oufti_makeNewCellListCompact(CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = makeNewCellListCompact(CL)
%The purpose of this function is to compact the cellList array by removing
%empty cells from each frame.
%oufti.v0.2.4
%@author:  Ahmad J Paintdakhi
%@date:    Nov 14 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:  cellList structure but compacted that is empty cells are removed from
%each frame.
%**********Input********:
%CL:  cellList structure
%==========================================================================

fieldNamesCellList = {  'ancestors'
                        'birthframe'
                        'box'
                        'descendants'
                        'divisions'
                        'mesh'};
if ~isfield(CL,'meshData')
    for frame = 1:length(CL)
        tmpCL = cell(size(CL{frame}));
        for cells = 1:length(CL{frame})
            if isempty(CL{frame}{cells}),tmpCL{frame}{cells} = [];continue;end
            tmpCL{frame}{cells}.(fieldNamesCellList{1})= CL{frame}{cells}.(fieldNamesCellList{1});
            tmpCL{frame}{cells}.(fieldNamesCellList{2})= CL{frame}{cells}.(fieldNamesCellList{2});
            tmpCL{frame}{cells}.(fieldNamesCellList{3})= CL{frame}{cells}.(fieldNamesCellList{3});
            tmpCL{frame}{cells}.(fieldNamesCellList{4})= CL{frame}{cells}.(fieldNamesCellList{4});
            tmpCL{frame}{cells}.(fieldNamesCellList{5})= CL{frame}{cells}.(fieldNamesCellList{5});
            tmpCL{frame}{cells}.(fieldNamesCellList{6})= CL{frame}{cells}.(fieldNamesCellList{6});
        end
        CL{frame} = tmpCL{frame};
    end
else
    for frame = 1:length(CL.meshData)
        tmpCL = cell(size(CL.meshData{frame}));
        for cells = 1:length(CL.meshData{frame})
            if isempty(CL.meshData{frame}{cells}),tmpCL{frame}{cells} = [];continue;end
            tmpCL{frame}{cells}.(fieldNamesCellList{1})= CL.meshData{frame}{cells}.(fieldNamesCellList{1});
            tmpCL{frame}{cells}.(fieldNamesCellList{2})= CL.meshData{frame}{cells}.(fieldNamesCellList{2});
            tmpCL{frame}{cells}.(fieldNamesCellList{3})= CL.meshData{frame}{cells}.(fieldNamesCellList{3});
            tmpCL{frame}{cells}.(fieldNamesCellList{4})= CL.meshData{frame}{cells}.(fieldNamesCellList{4});
            tmpCL{frame}{cells}.(fieldNamesCellList{5})= CL.meshData{frame}{cells}.(fieldNamesCellList{5});
            tmpCL{frame}{cells}.(fieldNamesCellList{6})= CL.meshData{frame}{cells}.(fieldNamesCellList{6});
        end
        if isempty(tmpCL)
            CL.meshData{frame} = [];
        else
            CL.meshData{frame} = tmpCL{frame};
        end
    end
end

end

            