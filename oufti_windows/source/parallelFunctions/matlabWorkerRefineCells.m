function cells = matlabWorkerRefineCells(cellData, proccells, l_p,...
                 imge, extDx, extDy, frame,tempSe, tempMaskdx, tempMaskdy,tempCellListN,thres)
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
%function cells = matlabWorkerRefineCells(cells,proccells,clength,l_p,OptX,...
			%							   OptY,l_args,img,imge,extDx,extDy,...
			%							   extEnergy, allMap, thres, frame)
%Oufti
%@author:  Ahmad J Paintdakhi
%@date:    May 11 2012
%@copyright 2012-2013 Yale University
%=================================================================================
%**********output********:
%cells:  A structure containing information about the processed cells.  cells
%	     length could be any in a given frame.
%**********Input********:
%cells:      cell structure containing all the cells in a given frame.  
%            The strcutre contains all pertaining information regarding
%            the cell's model, mesh, ancestors, polarity,........etc.
%            Debug the the program before calling function 
%            processIndividualCells to inspect the whole structure.
%proccells:  An array containing the cell labels for a given frame.
%l_p:		 global parameters list
%imge:       regular image matrix erodded
%extDx:      x-component of the energy forces
%extDy:      y-component of the energy forces
%frame:      current frame number
%==================================================================================
% NO GLOBAL VARIABLES ARE ALLOWED HERE!

    % I now change the meaning of the argument clength. It used to be the
    % full cell length matrix, but to reduce memory usage (and to avoid an
    % error in createJob) it will henceforth contain only the cell length
    % of the cells to process and only <= 20 frames back from the current frame.

    % celln below is local cell numbering, not global.
    % Similarly, proccells is an array of cell ids corresponding to the
    % contents of the array cells.
    % cells is now a struct array, not a cell array of structs
%------------------------------------------------------------------------------------
    nr_cells = length(cellData);
    for celln = 1:nr_cells
        cells{celln}=refineAll(cellData{celln},proccells(celln),l_p,...
            imge, extDx, extDy, frame,tempSe, tempMaskdx, tempMaskdy,tempCellListN,thres);%#ok<AGROW>
        
    end
    

end