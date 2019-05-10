function res = getparamstring(hndls)
    str = get(hndls.params,'String');
    if ~iscell(str) && size(str,1)==1
        res = textscan(str,'%s','delimiter','');
    elseif ~iscell(str) && size(str,1)>1
        for i=1:size(str,1)
            tmp1 = strtrim(str(i,:));
            if ~isempty(tmp1)
                tmp2 = textscan(tmp1,'%s','delimiter','');
                str2{i,1} = tmp2{1}{1};
            end
        end
        res = str2;
    else
        res = str;
    end
    if length(res)==1
        res=res{1};
    end
end