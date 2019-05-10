function clist=cleancelllistwti(clist,varargin)
% cleaning cellList for dividing cells
% Works on the cellList structure directly, not file,
% starting frame can be indicated as the optional secon argument
% outputs the updated structure
% 
% The function removes all cells before the starting frame (if indicated)
% and then removes every cell and its progeny if this cell dissapears. The
% function can be used to remove defective cells and the cells deleted on
% one frame (to remove them from the later, but not previous frames).
if nargin>=2
    startframe = varargin{1};
else
    startframe=1;
end
for frame = 1:startframe-1
    clist{frame}=[];
end
dellistold = [];
dellistnew = [];
for frame = startframe:length(clist)
    disp(['Frame = ' num2str(frame)])
    for cell = 1:length(clist{frame})
        if isempty(clist{frame}{cell}) || length(clist{frame}{cell}.mesh)<5
            if ismember(cell,dellistold)
                ccell = cell;
                cframe = frame;
                while true
                    ccellnew = [];
                    cframenew = [];
                    for i=1:length(ccell)
                        [cframei,ccelli]=delcell(cframe(i),ccell(i));
                        ccellnew = [ccellnew ccelli];
                        cframenew = [cframenew cframei];
                    end
                    cframe = cframenew;
                    ccell = ccellnew;
                    if isempty(cframe), break; end
                end
            end
        else
            dellistnew = [dellistnew cell];
        end
    end
    dellistold = dellistnew;
end

    function [f2,c2] = delcell(f,c)
        f2 = [];
        c2 = [];
        for frm=f:length(clist)
            if (length(clist{frm})>=c)&&~isempty(clist{frm}{c})
                if clist{frm}{c}.birthframe==frm
                    return
                end
                if length(clist{frm}{c}.descendants)>=1
                    f2 = frm+clist{frm}{c}.descendants*0;
                    c2 = clist{frm}{c}.descendants;
                    clist{frm}{c}=[];
                    return
                end
                clist{frm}{c}=[];
            end
        end
    end
end