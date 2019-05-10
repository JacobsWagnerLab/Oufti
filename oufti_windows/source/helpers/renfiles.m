function renfiles(varargin)
% renfiles
% renfiles('metamorph')
% renfiles('elements')
% renfiles('copy')
% 
% This function renames all files in a time-lapse series taken in Nikon 
% Elements (the frame number following the 't' symbol) or Metamorph (frame
% number at the end) default formats into the form containing a fixed 
% number of digits (required for proper sorting by Windows) and sorts them 
% into folders corrsponding to filter blocks and xy-stage positions 
% (required for MicrobeTracker). It will prompt for the folder name which 
% contains the images.
%
% 'metamorph' / 'elements' - enforce one of the formats. Otherwise the
%     program will attempt to distinguish between them by itself.
% 'copy' - copy the files instead of moving.

global renfilesAllPath
if isempty(who('renfilesAllPath')) || isequal(renfilesAllPath,0), renfilesAllPath=[]; end

renfilesAllPath = uigetdir(renfilesAllPath,'Select the folder to process');
if isequal(renfilesAllPath,0), return; end
files = dir(fullfile(renfilesAllPath,'*.tif*'));
if isempty(files), disp('No TIFF files found in the folder'); return; end

% check if MetaMorph (number last) or Elements (number after 't' symbol) format is enforced
forcemode1 = false;
forcemode2 = false;
copymode = false;
for i=1:length(varargin)
    if ischar(varargin{i}) && strcmp(varargin{i},'metamorph')
        forcemode1 = true;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'elements')
        forcemode2 = true;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'copy')
        copymode = true;
    end
end
if forcemode1
    moderange = 1;
elseif forcemode2
    moderange = 2;
else
    moderange = 1:2;
end
for mode=moderange
    % get lists of filenames, basenames, basesuffices, framenumbers, etc.
    basenamelist = {};
    basenamelistT = {};
    basesuffixlist = {};
    numlist = [];
    extnamelist = {};
    maxndigits = 0;
    cnt = 0;
    for i=1:length(files)
        fullname = files(i).name;
        filename = fullname(1:end-4);
        if isempty(str2num(filename(end))), continue; end % Last symbol must be a digit
        if mode==1
            for j=0:20 % determine the number of digits at the end
                q = filename(end-j:end);
                if isempty(str2num(q)), break; end
            end
            ndigits = length(num2str(str2num(filename(end-j+1:end))));
            cnt = cnt+1;
            numlist(cnt) = str2num(filename(end-j+1:end));
            basenamelist{cnt} = filename(1:end-j);
            basenamelistT{cnt} = filename(1:end-j);
            basesuffixlist{cnt} = [];
        else
            t = strfind(filename(1:end-1),'t');
            if isempty(t), continue; end
            t = t(end); % the last 't' present indicating the timeframe in Elements
            for j=t+1:length(filename)+1
                if j>length(filename), break; end
                q = filename(t+1:j);
                if isempty(str2num(q)), break; end
            end
            ndigits = length(num2str(str2num(filename(t+1:j-1))));
            if ndigits==0, continue; end % no digits after t
            cnt = cnt+1;
            numlist(cnt) = str2num(filename(t+1:j-1));
            basenamelist{cnt} = filename(1:t-1);
            basenamelistT{cnt} = filename(1:t);
            basesuffixlist{cnt} = filename(j:end);
        end
        maxndigits = max(maxndigits,ndigits);
        extnamelist{cnt} = fullname;
    end
    
    % construct the list of unique basename/basesuffix pairs
    uniquenamelist = {};
    filenameindex = [];
    for i=1:length(basenamelist)
        [tf, loc] = ismember([basenamelist{i} '$' basesuffixlist{i}],uniquenamelist);
        if ~tf
            uniquenamelist = [uniquenamelist [basenamelist{i} '$' basesuffixlist{i}]];
            loc = length(uniquenamelist);
        end
        filenameindex = [filenameindex loc];
    end
    
    % convert the list of unique basename/basesuffix pairs into new folder list
    newfolderlist = {};
    for i=1:length(uniquenamelist)
        s = strfind(uniquenamelist{i},'$');
        newfolder1 = uniquenamelist{i}(1:s-1);
        newfolder2 = uniquenamelist{i}(s+1:end);
        if xor(isempty(newfolder1),isempty(newfolder2))
            newfolderlist = [newfolderlist [newfolder1 newfolder2]];
        else
            newfolderlist = [newfolderlist [newfolder1 '_' newfolder2]];
        end
    end
    
    if mode==1 && maxndigits>1, break; end
    if mode==2 && length(newfolderlist)<=1, disp('No files to convert'); return; end
end

% create new folders
for i=1:length(newfolderlist)
    mkdir(renfilesAllPath,newfolderlist{i})
end

% move the files
for i=1:length(extnamelist)
    oldname = extnamelist{i};
    oldfullname = fullfile(renfilesAllPath,oldname);
    basename = basenamelistT{i};
    basesuffix = basesuffixlist{i};
    numstring = num2str(numlist(i),['%0.' num2str(maxndigits) 'd']);
    newfullname = fullfile(renfilesAllPath,newfolderlist{filenameindex(i)},[basename numstring basesuffix '.tif']);
    % disp(['Moving ' oldfullname ' to ' newfullname])
    if copymode
        copyfile(oldfullname,newfullname);
    else
        movefile(oldfullname,newfullname);
    end
end
disp('Files converted')

