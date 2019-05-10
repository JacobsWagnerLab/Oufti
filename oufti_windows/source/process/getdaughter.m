function res = getdaughter(cell,generation,MaxCell)
    % gets the list of a given cell progeny born after the starting plane
    % in the indicated generation and for the indicated starting maximum
    % number of cells ("MaxCell", number of cells on the first frame)
    res = cell + MaxCell * 2^(max(1,generation)-1+ceil(log2(ceil(cell/MaxCell))));
end