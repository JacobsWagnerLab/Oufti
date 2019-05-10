function res = getallchildren(cell,MaxCell,cellsOnFrame)
    % gets all POSSIBLE progeny of "cell" on the current frame
    % (the real progeny is computed in the parent function "selNewFrame")
    MaxCell2 = MaxCell * 2^(ceil(log2(ceil(cell/MaxCell))));
    res = cell:MaxCell2:cellsOnFrame;
     if isempty(res)
        res = cell;
    end
end