function integdic(varargin)
% This function converts digital interference contrast (DIC) files into a
% format relembling phase contrast images, i.e. dask cells on a light
% background.
% 
% The function will require the user to input the initial folder fith TIFF
% DIC images. The processed images will be saved into a folder with the
% suffix '_processed' added.
% 
% The function takes an optional numeric parameter indicating the
% orientation angle of the principal axis of the DIC polarizer. If the
% number is not provided or the parameter 'detectmin' is indicated the
% function will detect the angle automaticall by maximizing the contrast of
% resulting images. If the parameter 'disp' is provided, the function will
% display processed images.
% 
% Version 3 of 2010/08/01
warning('off','images:initSize:adjustingMag');
global integdicFolder
if isempty(who('integdicFolder')) || ~ischar(integdicFolder), integdicFolder=''; end
folder = uigetdir(integdicFolder,'Select folder with signal images');
if isempty(folder)||isequal(folder,0), return, end
flist = dir(fullfile(folder,'*.tif'));
if isempty(flist)||isequal(flist,0), disp('No images found'); return, end
folder2 = [folder '_processed'];
for j=1:10000
    if ~isempty(dir(folder2))
        folder2=[folder '_processed_' num2str(j)];
    else
        mkdir(folder2);
        break
    end
end
x = [];
if (nargin>0 && strcmp(varargin{1},'detectmin')) || (nargin>1 && strcmp(varargin{2},'detectmin'))
    detectmin = true;
else
    detectmin = false;
end
if (nargin>0 && strcmp(varargin{1},'disp')) || (nargin>1 && strcmp(varargin{2},'disp'))
    dsp = true;
else
    dsp = false;
end
if nargin>0 && isnumeric(varargin{1})
    x = varargin{1};
end

for j=1:length(flist)
    img = mean(im2double(imread(fullfile(folder,flist(j).name))),3);
    se = strel('diamond', 1);
    h = fspecial('gaussian',5,1);
    hs = fspecial('sobel');
    if isempty(x) && detectmin
        x = fminbnd(@qopt,0,360); % detect rotation angle
        disp(['File ' flist(j).name ': polarization angle estimated as ' num2str(x) ' degrees']);
    elseif isempty(x) && ~detectmin
        x = 135; % set default rotation angle
    end
    img4 = qfin(x); % rotate (expanding size) and integrate image
    if dsp, figure;imshow(img,[min(min(img)) max(max(img))]); end
    img4a = imfilter(imrotate(img4,-x),h); % rotate image back (expanding size)
    img4a = imcrop(img4a,[round((size(img4a,2)-size(img,2))/2),...
        round((size(img4a,1)-size(img,1))/2),size(img,2),size(img,1)]); % crop image to original size
    img4b = (img4a-min(min(img4a)))/(max(max(img4a))-min(min(img4a))); % normalize image
    if dsp, figure;imshow(img4a,[min(min(img4)) max(max(img4))]); end
    imwrite(im2uint16(img4b),fullfile(folder2,flist(j).name),'tif','Compression','none'); % record image to disk
    x = [];
end

function res = qopt(a)
    % this function produces a measure of reconstructed image quality in
    % order to estimate the rotation angle
    img2 = imrotate(img-median(reshape(img,[],1)),a);
    img2a = imfilter(img2,h);
    img4 = img2*0;
    img4(1,:)=img2a(1,:);
    for i=2:size(img4,1)
        img4(i,:)=(img4(i-1,:)+img2a(i,:));
    end
    res = std(img4(end,:));
end


function img4 = qfin(a)
    % this function produces the final version of the image
    img1a = img-median(reshape(img,[],1));
    img2 = imrotate(img1a,a);
    img2a = imfilter(img2,h);
% % %     m = max(max(img2));
% % %     gradimg = imfilter(img2,hs).^2+imfilter(img2,hs').^2;
% % %     thr = graythresh(gradimg);
% % %     gradimg = im2bw(gradimg,thr);
% % %     difimg = (img2>m*0.04) | (img2<-m*0.04);
% % %     img3a = gradimg & difimg;
% % %     for i=1:1 % number of steps to pre-erode (eliminationg noise)
% % %         img3a = imerode(img3a,se);
% % %     end
% % %     for i=1:1 % number of steps to dilate (expanding cells)
% % %         img3a = imdilate(img3a,se);
% % %     end
% % %     img4 = img2*0;
% % %     img4(1,:)=img2a(1,:);
% % %     img4b = img4*0;
% % %     for i=2:size(img4,1)
% % %         img4(i,:)=(img4(i-1,:)+img2a(i,:)).*img3a(i,:);
% % %         img4b(i,:)=(img4b(i-1,:)+img3a(i,:)).*img3a(i,:);
% % %     end
% % % 
% % %     c = zeros(1,size(img2,2));
% % %     for i=size(img4,1):-1:1
% % %         u1 = img4(i,:);
% % %         u2 = img4b(i,:);
% % %         u = zeros(1,size(img2,2));
% % %         c(c~=0&u2==0)=0;
% % %         c(c==0&u2~=0)=u1(c==0&u2~=0)./u2(c==0&u2~=0);
% % %         u(u2>0) = u1(u2>0)-u2(u2>0).*c(u2>0);
% % %         img4(i,:) = u;
% % %     end
    img4 = hilbert(img2a);
    img4 = imag(img4);
  
end

end