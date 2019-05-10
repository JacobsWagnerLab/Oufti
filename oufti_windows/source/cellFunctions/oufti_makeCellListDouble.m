function CL = oufti_makeCellListDouble(CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = oufti_makeCellListDouble(CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 21, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:    A structure containing two fields meshData and cellId    
%**********Input********:
%CL:    A structure containing two fields meshData and cellId
%==========================================================================
%The purpose of this function is to make all the fields and sub fields in
%the CL structure double.
%-------------------------------------------------------------------------- 
%-------------------------------------------------------------------------- 
    % make these fields double precision...
    sNames = {'mesh', 'model', 'length', ...
            'lengthvector', 'area', ...
            'volume', 'pdiv', 'box','steplength','steparea','stepvolume'};

    % ... 16 bit unsigned int ...
    ui16Names = {'algorithm', 'stage', ...
                'birthframe', 'timelapse', 'divisions'};

    % ... 32 bit unsigned int ...
    ui32Names = {'descendants', 'ancestors'};
    for f = 1:oufti_getLengthOfCellList(CL)
        if oufti_isFrameNonEmpty(f, CL)
            for i = CL.cellId{f}
                cell = oufti_getCellStructureFast(i, f, CL);
                if ~isempty(cell)
                    for name = sNames
                        if isfield(cell, name{1})
                            %CL = CL_setField(i, f, name{1}, single(cell.(name{1})), CL);
                            cell.(name{1}) = double(cell.(name{1}));
                        end
                    end
                    for name = ui16Names
                        if isfield(cell, name{1})
                            %CL = CL_setField(i, f, name{1}, uint16(cell.(name{1})), CL);
                            cell.(name{1}) = uint16(cell.(name{1}));
                        end
                    end
                    for name = ui32Names
                        if isfield(cell, name{1})
                            %CL = CL_setField(i, f, name{1}, uint32(cell.(name{1})), CL);
                            cell.(name{1}) = uint32(cell.(name{1}));
                        end
                    end
                    CL = oufti_addCell(i, f, cell, CL);
                end
            end
        end
    end
end