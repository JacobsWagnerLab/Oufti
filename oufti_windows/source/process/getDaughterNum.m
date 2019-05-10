function daughter = getDaughterNum
global cellList

try
    if iscell(cellList.cellId)
        daughter = max(cellfun(@max,(cellfun(@single,(cellList.cellId(~cellfun(@isempty,(cellList.cellId)))),...
                                            'uniformoutput',0)))) + 1;
    else
        daughter = max(max(cellList.cellId)) + 1;
    end
catch err
    disp(err.message);
    daughter = [];
end

end