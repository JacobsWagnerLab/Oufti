function setdispfiguretitle(fig,celldata,a)
    if ~isempty(celldata)
        if celldata(1)==0, frame='?'; else frame = num2str(celldata(1)); end
        if celldata(2)==0, cell='?'; else cell = num2str(celldata(2)); end
        if length(celldata)<3 || celldata(3)==0, mode='fit'; else mode = 'mask'; end
        nm = ['Aligning: frame ' frame ', cell ' cell ', step ' num2str(a) ', ' mode ' mode'];
    else
        nm = ['Aligning: step: ' num2str(a)];
    end
    set(fig,'Name',nm);
end