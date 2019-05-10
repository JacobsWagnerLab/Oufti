function res = getmother(cell,MaxCell)
    if cell>MaxCell
        MaxCell2 = MaxCell * 2^(-1+ceil(log2(ceil(cell/MaxCell))));
        res = cell - MaxCell2;
    else
        res = [];
    end
end