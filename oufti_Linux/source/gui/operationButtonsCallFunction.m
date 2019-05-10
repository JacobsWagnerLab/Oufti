function operationButtonsCallFunction(hObject, eventdata)
global handles p
if hObject == handles.pauseButton
    p.pauseButton = 1;
elseif hObject == handles.stopButton
    p.stopButton = 1;

end

end