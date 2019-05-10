function saveimagestack(images,filename,varargin)
% saveimagestack(imagestack,filename,usewaitbar)
% 
% This function saves a set of images into a multipage TIFF file
% 
% imagestack - 3D array containing the images
% filename - name of the target stack file (TIFF by default)
% usewaitbar (optional) - 1 (true) to display a waitbar

errorcountmax = 10;

[d,f,e] = fileparts(filename);
if isempty(f), disp('Not a valid file name'); return; end
if isempty(e), e='.tif'; end
filename = fullfile2(d,[f e]);

if length(varargin)>=1 && varargin{1}==1, usewaitbar=true; else usewaitbar=false; end
if usewaitbar, w = waitbar(0, 'Saving images, please wait...'); end;
numImages = size(images,3);
frame = 1;
errorcount = 0;
errorcount2 = 0;
while true
    if frame==1
        imwrite(images(:,:,frame),filename,'writemode','overwrite','Compression','none');
        frame = frame+1;
    else
        try
            imwrite(images(:,:,frame),filename,'writemode','append','Compression','none');
            frame = frame+1;
            errorcount = 0;
        catch
            errorcount = errorcount+1;
            errorcount2 = errorcount2+1;
            % if errorcount<errorcountmax
            %     disp(['Saving images: error on frame ' num2str(frame) ' - attempting again'])
            % else
            %     disp(['Saving images: error on frame ' num2str(frame) ' - terminating'])
            % end
            pause(0.1)
        end
    end
    if usewaitbar, waitbar(frame/numImages, w); end
    if frame==numImages+1 || errorcount==errorcountmax, break; end
end
if usewaitbar, close(w); end
if errorcount>=errorcountmax
    disp('Saving images failed')
elseif errorcount2>0
    disp(['Saving images completed to file ' filename ', ' num2str(errorcount2) ' errors encountered'])
else
    disp(['Saving images successful to file ' filename])
end
