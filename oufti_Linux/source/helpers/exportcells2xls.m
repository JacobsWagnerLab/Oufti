function exportcells2xls(varargin)
% exportcells2xls
% exportcells2xls(cellList)
% exportcells2xls(cellList,filename)
% 
% This functions saves some of the data from cellList produced by
% oufti into an Excel or CSV file. The output data are saved as a
% matrix in which each row corresponds to a bacterial cell and the columns
% are: (A) frame number, (B) cell number, (C) cell length, (D) cell area,
% (E) cell volume, (F) max width of the cell, (G) sum of the signal1, 
% (H) sum of the signal2. The Excell (but not CSV) file also gets a header
% with the names of the columns. The CSV file will contain NaN for the 
% values of the signals if they are missing in the cell list.
% 
% cellList (optional) - input cell list produced by MicrobeTracker
% filename (optional) - name of the output file (must be .xls or .csv) 


% get the input cellList
if isempty(varargin) || ~iscell(varargin{1})
    [filename,pathname] = uigetfile('*.mat', 'Select file to get cell meshes from','');
    if(filename==0), return; end;
    filename = fullfile(pathname,filename);
    l = load('-mat',filename,'cellList');
    clist = l.cellList;
    clear('l')
else
    clist = varargin{1};
end

% get the output file name
if length(varargin)<2 || isempty(varargin{2}) || ~ischar(varargin{2})
    [filename,foldername]=uiputfile({'*.xls';'*.csv'}, 'Enter the target Excel/CSV file name');
    if isequal(filename,0), return; end
    filename = fullfile(foldername,filename);
else
    filename = varargin{2};
end
[d,f,e] = fileparts(filename);
if ~strcmp(e,'.csv') && ~strcmp(e,'.xls'), disp('Wrong output file extension'); return; end

% create the matrix of cell data
L = 0;
for frame=1:length(clist)
    for cell=1:length(clist{frame})
        str = clist{frame}{cell};
        if ~isempty(str) && isfield(str,'length')
            L = L+1;
        end
    end
end
i = 0;
M = zeros(L,8);
for frame=1:length(clist)
    for cell=1:length(clist{frame})
        str = clist{frame}{cell};
        if ~isempty(str) && isfield(str,'length')
            i = i+1;
            if isfield(str,'signal1'), sgn1 = sum(str.signal1); else sgn1 = NaN; end
            if isfield(str,'signal2'), sgn2 = sum(str.signal2); else sgn2 = NaN; end
            M(i,:) = [frame cell str.length str.area str.volume max(str.steparea./str.steplength) sgn1 sgn2];
        end
    end
end

% save the result
if exist(filename,'file'), delete(filename); end
if strcmp(e,'.xls')
    xlswrite(filename,{'frame','cell','length','area','volume','max width','signal1','signal2'})
    xlswrite(filename,M,['A2:H' num2str(L+1)])
else
    csvwrite(filename,M)
end