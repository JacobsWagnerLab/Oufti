function [spotStructure,xx] = matlabWorkerSpotCells(cellData, proccells, params, ...
                 image,adjustMode,handles1_)

%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
%function spotStructure = matlabWorkerSpotCells(cellData, proccells, params, ...
%                 image,adjustMode)
%oufti.v0.2.6
%@author:  Ahmad J Paintdakhi
%@date:    November 26, 2012
%@copyright 2012-2013 Yale University

%=================================================================================
%**********output********:
%spotStructure:  A structure containing information spot parameters such as
%length, width, intensity, etc...

%**********Input********:
%cellData:   Cell information with all variables.
%proccells:  An array containing the cell labels for a given frame.
%params:	 parameter array.
%image:		 image of a current frame.
%adjustMode:  Either 1 or 0, if 1 spots are shown on a current GUI window
%             if 0 spots are not shown but rather processed using parallel 
%             computation.
%==================================================================================
% NO GLOBAL VARIABLES ARE ALLOWED HERE!

%------------------------------------------------------------------------------------
 xx = [];
 spot.l                            = [];
 spot.d                            = [];
 spot.x                            = [];
 spot.y                            = [];
 spot.positions                    = [];
 spot.adj_Rsquared                 = [];
spotStructure = [];
numCells = length(cellData);
for celln = 1:numCells
    try
        [spotStructure{celln},xx,~] = processIndividualSpots(cellData{celln},proccells(celln),params,...
                               image,adjustMode);%#ok<AGROW>    
    catch
        spotStructure{celln} = spot;
    end
end

end