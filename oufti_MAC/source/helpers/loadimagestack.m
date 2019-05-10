function [res,data] = loadimagestack(channel,filename,useWaitBar,flag)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function [res,data] = loadimagestack(channel,filename,useWaitBar,flag)
%oufti.v0.2.9
%@author:  Ahmad J Paintdakhi
%@date:    November 06 2013
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%res:  if flag was set to true initially
%data: image data
%**********Input********:
%filename:  name of the original stack file (must be TIFF or BioFormats
%           must be loaded, e.g. with checkbformats function)
%usewaitbar:   (optional) - 1 (true) to display a waitbar
%channel:   1 - rawPhaseData, 3 - rawSignal1, 4 - rawSignal2
%flag:  1 - if called from oufti.m function and 0 - if called from anywhere
%else.
%=========================================================================
% PURPOSE:
% This function loads stack images either in "tif"/"tiff" format or any of
% the formats supported by bio-format library.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

global rawPhaseData rawS1Data rawS2Data cellList imsizes imageLimits imageForce
bformats = checkbformats(1);
res = false;
data = [];
if channel==1
   str='rawPhaseData';
elseif channel==3
   str='rawS1Data';
elseif channel==4
   str='rawS2Data';
else
   disp('Error loading images: channel not supported');
end
if (length(filename)>4 && strcmpi(filename(end-3:end),'.tif')) || (length(filename)>5 && strcmpi(filename(end-4:end),'.tiff'))
   % loading TIFF files
   try
      info = imfinfo(filename);
      numImages = numel(info);
      if useWaitBar, w = waitbar(0, 'Loading images, please wait...'); end
      lng = info(1).BitDepth;
      if lng==8
         cls='uint8';
      elseif lng==16
         cls='uint16';
      elseif lng==32
         cls='uint32';
      else
         disp('Error in image bitdepth loading multipage TIFF images: no images loaded');return;
      end
      eval([str '=zeros(' num2str(info(1).Height) ',' num2str(info(1).Width) ',' num2str(numImages) ',''' cls ''');'])
      for i = 1:numImages
          img = imread(filename,i,'Info',info);
          eval([str '(:,:,' num2str(i) ')=img;'])
          if useWaitBar, waitbar(i/numImages, w); end
      end
      if useWaitBar, close(w); end
      if ~flag, disp(['Loaded ' num2str(numImages) ' images from a multipage TIFF']);end
      if flag
         eval(['imageLimits{channel} = 2^' num2str(lng) '*mean(stretchlim(' str ',[0.0001 0.9999]),2);']);
         eval(['imsizes(channel,:) = [size(' str ',1) size(' str ',2) size(' str ',3)];']);
         disp(['Loaded ' num2str(imsizes(channel,3)) ' images from a multipage TIFF'])
         imageForce = [];
         for ii = 1:imsizes(channel,3)
                imageForce(ii).forceX = [];
                imageForce(ii).forceY = [];
         end
         try
            if ~isempty(cellList.meshData{1}) && sum(cellfun(@isempty,cellList.meshData)) ~= numImages || (numel(cellList.meshData) == 1 && ~isempty(cellList.meshData{1}))
                newData = questdlg('New Dataset?','new cellList','yes','no','yes');
                 switch newData
                     case 'yes'
                         clear global cellList;
                         cellList = oufti_initializeCellList();
                     case 'no'
                        cellList = oufti_allocateCellList(cellList,1:imsizes(channel,3));
                 end
            else
                 cellList = oufti_allocateCellList(cellList,1:imsizes(channel,3));
            end
         catch
             disp('no images loaded');
             return;
         end
         res = true;
      end
   catch
         disp('Error loading multipage TIFF images: no images loaded');
   end
elseif bformats
   % loading all formats other than TIFF
   try
      breader = loci.formats.ChannelFiller();
      breader = loci.formats.ChannelSeparator(breader);
      breader = loci.formats.gui.BufferedImageReader(breader);
      breader.setId(filename);
      numSeries = breader.getSeriesCount();
      if numSeries~=1, disp('Incorrect image stack format: no images loaded'); return; end; 
      breader.setSeries(0);
      wd = breader.getSizeX();
      hi = breader.getSizeY();
      shape = [wd hi];
      numImages = breader.getImageCount();
      if numImages<1, disp('Incorrect image stack format: no images loaded'); return; end;
      nBytes = loci.formats.FormatTools.getBytesPerPixel(breader.getPixelType());
      if nBytes==1
         cls = 'uint8';
      else
         cls = 'uint16';
      end
      eval([str '=zeros(' num2str(hi) ',' num2str(wd) ',' num2str(numImages) ',''' cls ''');'])
      if useWaitBar, w = waitbar(0, 'Loading images, please wait...'); end
      for i = 1:numImages
          img = breader.openImage(i-1);
          pix = img.getData.getPixels(0, 0, wd, hi, []);
          arr = reshape(pix, shape)';
          if nBytes==1
             arr2 = uint8(arr/256);
          else
             arr2 = uint16(arr);
          end
          eval([str '(:,:,' num2str(i) ')=arr2;'])
          if useWaitBar, waitbar(i/numImages, w); end
      end
      if useWaitBar, close(w); end
      if ~flag, disp(['Loaded ' num2str(numImages) ' images from a multipage TIFF']); end
      if flag
         if strcmp(cls,'uint8'), lng=8; elseif strcmp(cls,'uint16'), lng=16; elseif strcmp(cls,'uint32'), lng=32;
         else disp('Error in image bitdepth loading images using BioFormats: no images loaded');return; end
         eval(['imageLimits{channel} = 2^' num2str(lng) '*mean(stretchlim(' str ',[0.0001 0.9999]),2);']);
         eval(['imsizes(channel,:) = [size(' str ',1) size(' str ',2) size(' str ',3)];']);
         disp(['Loaded ' num2str(imsizes(channel,3)) ' images using BioFormats']);
         imageForce = [];
         for ii = 1:imsizes(channel,3)
                imageForce(ii).forceX = [];
                imageForce(ii).forceY = [];
         end
         if ~isempty(cellList) && ~sum(cellfun(@isempty,cellList.meshData))
             newData = questdlg('New Dataset?','new cellList','yes','no','yes');
             switch newData
                 case 'yes'
                     clear global cellList;
                     cellList = oufti_initializeCellList();
                 case 'no'
                    cellList = oufti_allocateCellList(cellList,1:imsizes(channel,3));
             end
        else
             cellList = oufti_allocateCellList(cellList,1:imsizes(channel,3));
        end
         res = true;
      end
  catch
       disp('Error loading images using BioFormats: no images loaded');
  end
else % unsupported format of images
    disp('Error loading images: the stack must be in TIFF format for BioFormats must be loaded');
end

if ~flag && channel == 3, data = rawS1Data;end
if ~flag && channel == 1, data = rawPhaseData;end
if flag && channel == 1, data = rawPhaseData;end

end
