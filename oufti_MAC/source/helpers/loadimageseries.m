function [loadedData, filenames, dirName] = loadimageseries(pathToFolder,varargin)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function [loadedData, filenames, dirName] = loadimageseries(pathToFolder,varargin)
%oufti v0.3.1
%@author:  Ahmad J Paintdakhi
%@date:    March 05 2013
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%loadedData:    x_dimansion x y_dimension x number_of_images - stack of
%              loaded images
%filenames: the number of files in the directory.
%dirName:   name of the directory from where images need to be collected.
%**********Input********:
%pathToFolder:  path of the directory where images are located.
%varargin:  number of input arguements.
%=========================================================================
% PURPOSE:
% This finction loads a series of TIFF images into the stack loadedData
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

% check if waitbar is used
if isempty(varargin), useWaitBar=true; else useWaitBar=varargin{1}; end
    
% set initial variables
loadedData = [];
filenames = '';
dirName = '';
    
if isdir(pathToFolder)
% try to open the selected directory and read files
if(useWaitBar), w = waitbar(0, 'Loading image files, please wait...'); end;
  try
     files = dir([pathToFolder '/*.tif*']);
     name_counter = 0;
     loadedDataTmp=[];
     for i=1:length(files)
         if files(i).isdir==1, continue; end;
            if isempty(loadedDataTmp)
               loadedDataTmp = imread([pathToFolder '/' files(i).name]);
               filenames = [];
            end
            name_counter = name_counter+1;
     end;
     [sz1,sz2,sz3] = size(loadedDataTmp);
     sz = [sz1 sz2 sz3];
     loadedData = zeros([sz(1:2) name_counter],class(loadedDataTmp));
     name_counter = 1;
     for i=1:length(files)
         if(files(i).isdir == 1), continue; end;
         loadedDataTmp = imread([pathToFolder '/' files(i).name]);
         [sz1,sz2,sz3] = size(loadedDataTmp);
         if prod(([sz1,sz2,sz3]==sz)*1)
            loadedData(:,:,name_counter) = sum(loadedDataTmp,3);
         else
             errordlg('Unable to open images: The images are of different sizes.', 'Error loading files');
             if(useWaitBar),close(w);end;
             return;
         end
         filenames{name_counter} = files(i).name;
         name_counter = name_counter+1;
         if(useWaitBar),waitbar(i/length(files), w);end;
     end;
     if isempty(loadedData)
        errordlg('No image files to open in that directory!', 'Error loading files');
        if(useWaitBar),close(w);end;
        return;
     end;
     disp(['Images loaded from folder: ' pathToFolder]);
  catch
       loadedData=[];
       disp('Error loading images: no images loaded');
       errordlg(['Could not open files! Make sure you selected the ', ...
                'correct directory, all the filenames are the same length in ', ...
                'that directory, and there are no other non-image files in ', ...
                'that directory.'], 'Error loading files');
        if(useWaitBar),close(w);end;
        return;
  end;
  if(useWaitBar),close(w);end;

%If we got this far, then it was a success, so grab the directory
%name that we loaded so we can display it later
  split = strsplit('/', pathToFolder);
  split = strsplit('\', split{end}); %I need this for windows cause windows does things backwards...
  dirName = split{end};
else
   disp('Error loading images: indicated folder not found')
   % alternatively load images from a stack file (multipage TIFF or using BioFormats)
   % loadedData = loadimagestack(pathToFolder,useWaitBar);
end

end

function parts = strsplit(splitstr, str, option)
%STRSPLIT Split string into pieces. (packaged with cellFinder because we
%   need this function to parse out filenames and such)
%
%   STRSPLIT(SPLITSTR, STR, OPTION) splits the string STR at every occurrence
%   of SPLITSTR and returns the result as a cell array of strings.  By default,
%   SPLITSTR is not included in the output.
%
%   STRSPLIT(SPLITSTR, STR, OPTION) can be used to control how SPLITSTR is
%   included in the output.  If OPTION is 'include', SPLITSTR will be included
%   as a separate string.  If OPTION is 'append', SPLITSTR will be appended to
%   each output string, as if the input string was split at the position right
%   after the occurrence SPLITSTR.  If OPTION is 'omit', SPLITSTR will not be
%   included in the output.

%   Author:      Peter J. Acklam
%   Time-stamp:  2004-09-22 08:48:01 +0200
%   E-mail:      pjacklam@online.no
%   URL:         http://home.online.no/~pjacklam

   nargsin = nargin;
   error(nargchk(2, 3, nargsin));
   if nargsin < 3
      option = 'omit';
   else
      option = lower(option);
   end

   splitlen = length(splitstr);
   parts = {};

   while true
      k = strfind(str, splitstr);
      if isempty(k)
         parts{end+1} = str;
         break
      end
      switch option
         case 'include'
            parts(end+1:end+2) = {str(1:k(1)-1), splitstr};
         case 'append'
            parts{end+1} = str(1 : k(1)+splitlen-1);
         case 'omit'
            parts{end+1} = str(1 : k(1)-1);
         otherwise
            error(['Invalid option string -- ', option]);
      end
      str = str(k(1)+splitlen : end);
   end
end