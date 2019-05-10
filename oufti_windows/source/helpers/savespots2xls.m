function savespots2xls(slist)
% This functions saves the spotList variable produced by SpotFinderF into
% an Excel file. It takes one input argument and asks the user for the
% output file name.

L = 0;
for frame=1:length(slist)
    L = L+length(slist{frame});
end
if L<1, disp('No spots in the array'); return; end

[filename,foldername]=uiputfile('*.xls', 'Enter the target Excel file name');
if isequal(filename,0), return; end
filename = fullfile(foldername,filename);

M = zeros(L,8);
i = 0;
for frame=1:length(slist)
    for spot=1:length(slist{frame})
        i = i+1;
        str = slist{frame}{spot};
        M(i,:) = [frame spot str.x str.y str.m str.h str.w str.b]; 
    end
end

if exist(filename,'file'), delete(filename); end
xlswrite(filename,{'frame','spot','x','y','m','h','w','b'})
xlswrite(filename,M,['A2:H' num2str(L+1)])