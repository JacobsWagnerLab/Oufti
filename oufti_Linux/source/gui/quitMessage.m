function quitMessage()
global handles1 rawPhaseData rawS1Data rawS2Data cellList cellListN selectedList shiftframes imsizes handles %#ok<NUSED>
Yes = getString(message('MATLAB:finishdlg:Yes'));
No = getString(message('MATLAB:finishdlg:No'));
button = questdlg(getString(message('MATLAB:finishdlg:ReadyToQuit')), ...
                  getString(message('MATLAB:finishdlg:ExitingDialogTitle')),Yes,No,No);

 switch button
  case Yes,
    disp(getString(message('MATLAB:finishdlg:ExitingMATLAB')));
    %Save variables to matlab.mat
    % close open windows
    try
    if ishandle(handles.hfig),delete(handles.hfig);end
    if exist('handles','var') && isstruct(handles)
        fields = fieldnames(handles);
        for i=1:length(fields)
            eval(['cfield = handles.' fields{i} ';'])
            if ishandle(cfield)
                delete(cfield);
            elseif isstruct(cfield)
                fields2 = fieldnames(cfield);
                for k=1:length(cfield)
                    for j=1:length(fields2)
                        eval(['if ishandle(cfield(' num2str(k) ').' fields2{j} '), delete(cfield(' num2str(k) ').' fields2{j} '); end'])
                    end
                end
            end
        end
    end
    % cleas variables
    catch
        close force gcf
        if ishandle(handles.hfig),delete(handles.hfig);end
        clear global rawPhaseData rawS1Data rawS2Data cellList cellListN selectedList shiftframes handles imsizes handles1 p
    end
  case No,
    quit cancel;
 end

    
end
     

