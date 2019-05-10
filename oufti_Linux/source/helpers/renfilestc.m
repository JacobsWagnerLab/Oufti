function renfilestc(varargin)
% This function moves/copies pairs/groups of files sorted by time into
% those sorted by filter block (the new folder names will be the file names
% in the original system, the file names will be the old folder names).
% It is designed for Nikon Elements software tiff output
% 
% renfilestc('multiple','copy')
% 
% It will prompt for the folder name containing the subfolders with images
% Optional parameter 'multiple' will require selecting the paren folder and
% will process all subfolders.
% Optional parameter 'copy' tells the program to copy the files instead of 
% moving.

global renfilesTCPath
if isempty(who('renfilesTCPath')) || isequal(renfilesTCPath,0), renfilesTCPath=[]; end
renfilesTCPath = uigetdir(renfilesTCPath,'Select the folder to process');
multiple = false;
copymode = false;
for i=1:length(varargin)
    if strcmp(varargin{i},'multiple'), multiple = true; end
    if strcmp(varargin{i},'copy'), copymode = true; end
end
if multiple
    folders = dir(renfilesTCPath);
    for d = 1:length(folders)
        if folders(d).isdir && ~strcmp(folders(d).name(1),'.')
            disp(['folder: ' folders(d).name ', subfolders:'])
            processfolder([renfilesTCPath '\' folders(d).name],copymode)
        end
    end
else
    processfolder(renfilesTCPath,copymode)
end

function processfolder(renfilesTCPath,move)
files = dir(renfilesTCPath);
for i=1:length(files)
    if files(i).isdir
        olddirname = files(i).name;
        if isequal(olddirname(1),'.'), continue; end
        files2 = dir(fullfile(renfilesTCPath,olddirname,'\*.tif'));
        for j=1:length(files2)
            if files2(j).isdir; continue; end
            oldfilename = files2(j).name;
            d = strfind(oldfilename,'.');
            if isempty(d)
                d = length(in);
            else
                d = d(end)-1;
            end
            newdirname = oldfilename(1:d);
            files3 = dir(renfilesTCPath);
            names3 = {};
            for k=1:length(files3)
                names3{k} = files3(k).name;
            end
            if ~ismember(names3,newdirname)
                mkdir([renfilesTCPath '\' newdirname])
            end
            if ~copymode
                movefile([renfilesTCPath '\' olddirname '\' oldfilename],[renfilesTCPath  '\' newdirname '\' olddirname '.tif']);
            else
                copyfile([renfilesTCPath '\' olddirname '\' oldfilename],[renfilesTCPath  '\' newdirname '\' olddirname '.tif']);
            end
        end
        disp(files(i).name)
    end
end