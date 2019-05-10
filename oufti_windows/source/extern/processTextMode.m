function processTextMode(range,mode,lst,addsig,addas,savefile,saveselect,shiftfluo)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function processTextMode(range,mode,lst,addsig,addas,savefile,saveselect,shiftfluo)
%oufti.v0.3.1
%@author:  Ahmad J Paintdakhi
%@date:    June 11 2013
%@copyright 2012-2013 Yale University
%==========================================================================
% Main processing function, decides on which frames and what type of
% cell detection or cell analysis to do, to be called by "Detection &
% analysis" buttons or from eacher variant of the batch mode
% 
% "range" - range of frames to run, can be []-all frames
% "mode" - 1-tlapse, 2-1st ind, 3-all ind, 4-reuse
% "lst" - list of cells on the frame previous to range(1)
% "addsig" - [0 0 0 0]=[0 0 0]=[0 0]=0=[]-no signal, 1st one phase, etc. 
% "addas" - default {}={0,-,1,2}, if numeric X, creates signalX, else - X
% "savefile" - filename to save to
global p cellList cellListN  
if ~isfield(cellList,'meshData')
    cellList = oufti_makeNewCellListFromOld(cellList);
end
cellListN = cellfun(@length,cellList.meshData);
if isempty(p) || ~isfield(p,'algorithm'), disp('Error: parameters not initialized.'); return; end
nFrames = oufti_getLengthOfCellList(cellList);  
if mode==4 && ~isempty(range) &&(nFrames<range(1)), disp('Processing error: selected frame out of range'); return; end
if mode==4 && isempty(range) && oufti_isFrameEmpty(1, cellList), disp('Processing error: for all frames, the 1st frame must not be empty'); return; end
if mode~=4 && ~isempty(lst) && (isempty(range) || range(1)==1), disp('Processing error: selected cells regime does not work on the 1st frame'); return; end  
listtorun = lst; % cellstructure array containing all cell info
if mode == 1
for frame = range(1):range(2)

time1 = clock;
shiftmeshes(frame,1)
if isempty(lst), listtorun=[]; end           
listtorun = processFrameGreaterThanOneTextMode(frame,listtorun,savefile);
cellListN = cellfun(@length,cellList.meshData);                                           
shiftmeshes(frame,-1)
try
    disp(['Adding Signals to frame: ' num2str(frame)])
    for i=1:length(addsig)
        if addsig(i)
                if length(addas)<i, addas0 = max(i-2,0); else addas0 = addas{i}; end
          addSignalToFrame(frame,i,addas0,listtorun,p.sgnResize,p.approxSignal,shiftfluo);
        end
    end
 catch err
     disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
     disp(err.message)
     savemesh(savefile,[],saveselect,[]);
     continue;
end
time2 = clock;
disp(['frame ' num2str(frame) ' finished, elapsed time ' num2str(etime(time2,time1)) ' s']);
end

elseif mode == 4
    try
        disp(['Adding Signals to frame: ' num2str(range)])
        for i=1:length(addsig)
            if addsig(i)
                if length(addas)<i, addas0 = max(i-2,0); else addas0 = addas{i}; end
            addSignalToFrame(range,i,addas0,listtorun,p.sgnResize,p.approxSignal,shiftfluo);
            end
        end
    catch err
     disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
     disp(err.message)
     savemesh(savefile,[],saveselect,[]);
     return;
    end
else
    disp('mode value must be 1 or 4')
    return;
end

end




