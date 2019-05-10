function exportspots2xls(varargin)
% exportspots2xls
% exportspots2xls(list)
% exportspots2xls(list,filename)
% exportspots2xls(list,filename,field)
% exportspots2xls([],[],field)
% 
% This functions saves some of the spots data produced by the tools of 
% spotFinder family into an Excel or CSV file. The output data are saved as 
% a matrix in which each row corresponds to a spot and the columns are: 
% (A) frame number, (B) cell number, (C) spot number within this cell or 
% on the frame if SpotFinderF was used, (D) x coordinate, (E) y coordinate,
% (F) l coordinate, (G) relative l coordinate, i.e. l divided by cell 
% length, (H) d coordinate, (I) magnitude/m, (J) h, (K) w, (L) b. The 
% Excell (but not CSV) file also gets a header with the names of the 
% columns. The CSV file will contain NaN for the missing values, such as
% the cell number for SpotFinderF or h, w, and b for older versions of
% SpotFinderZ.
% 
% list (optional) - input cell/spot list (e.g. cellList or spotList)
% produced by SpotFinder tools 
% filename (optional) - name of the output file (must be .xls or .csv)
% field (optional) - name of spots field (default: 'spots')


% get the spots field name
if length(varargin)<3 || length(varargin{3})<=5 || ~ischar(varargin{3}) || ~strcmp(varargin{3},'spots')
    field = 'spots';
else
    field = varargin{3};
end

% get the input cellList
if isempty(varargin) || ~iscell(varargin{1})
    [filename,pathname] = uigetfile('*.mat', 'Select file to get spots information from','');
    if(filename==0), return; end;
    filename = fullfile(pathname,filename);
    warning off %#ok<WNOFF>
    l = load('-mat',filename,'cellList','spotList');
    warining on
    if isfield(l,'cellList')
        slist = l.cellList;
        mode = 2;
    elseif isfield(l,'spotList')
        slist = l.spotList;
        mode = 1;
    end
    clear('l')
else
    slist = varargin{1};
    mode = 0;
    for frame=1:length(slist)
        for i=1:length(slist{frame})
            if isfield(slist{frame}{i},'x')
                mode = 1;
                break
            elseif isfield(slist{frame}{i},field)
                mode = 2;
                break
            end
        end
    end
    if mode==0, disp('No spots data in the list or wrong list format'); return; end
end

% get the output file name
if length(varargin)<2 || isempty(varargin{2}) || ~ischar(varargin{2})
    [filename,foldername]=uiputfile({'*.xls';'*.csv'}, 'Enter the target Excel/CSV file name');
    if isequal(filename,0), return; end
    filename = fullfile(foldername,filename);
else
    filename = varargin{2};
end
[~,~,e] = fileparts(filename);
if ~strcmp(e,'.csv') && ~strcmp(e,'.xls'), disp('Wrong output file extension'); return; end


% create the matrix of spots data
if mode==1
    L = 0;
    for frame=1:length(slist)
        for spot=1:length(slist{frame})
            L = L+1;
        end
    end
    i = 0;
    M = zeros(L,12);
    for frame=1:length(slist)
        for spot=1:length(slist{frame})
            i = i+1;
            str = slist{frame}{spot};
            M(i,:) = [frame NaN spot str.x str.y NaN NaN NaN str.m str.h str.w str.b];
        end
    end
else
    % count spots
    L = 0;
    for frame=1:length(slist)
        for cell=1:length(slist{frame})
            if ~isempty(slist{frame}{cell}) && isfield(slist{frame}{cell},field)
                str = slist{frame}{cell}.(field);
                for spot=1:length(str.x)
                    L = L+1;
                end
            end
        end
    end
    i = 0;
    M = zeros(L,12);
    for frame=1:length(slist)
        for cell=1:length(slist{frame})
            if ~isempty(slist{frame}{cell}) && isfield(slist{frame}{cell},field)
                str = slist{frame}{cell}.(field);
                for spot=1:length(str.x)
                    i = i+1;
                    if isfield(slist{frame}{cell},'length'), r=str.l(spot)/slist{frame}{cell}.length; else r=NaN; end
                    if isfield(str,'b')
                        M(i,:) = [frame cell spot str.x(spot) str.y(spot) str.l(spot) r str.d(spot) str.magnitude(spot) str.h(spot) str.w(spot) str.b(spot)];
                    else
                        M(i,:) = [frame cell spot str.x(spot) str.y(spot) str.l(spot) r str.d(spot) str.magnitude(spot) NaN NaN NaN];
                    end
                end
            end
        end
    end
end

% save the result
if exist(filename,'file'), delete(filename); end
if strcmp(e,'.xls')
    xlswrite(filename,{'frame','cell','spot','x','y','l','rel l','d','magnitude','h','w','b'})
    xlswrite(filename,M,['A2:L' num2str(L+1)])
else
    csvwrite(filename,M)
end
