function res = filterImage(img2,params,se)
% im2double(imread(['C:\Documents and Settings\Oleksii\Desktop\Audrey''s mRNA\gfps\0' num2str(k,'%02.2d') '.tif']));
img2a = bpass(img2,params.loCutoff,params.hiCutoff);
img2b = img2a;%imfilter(img2a,fspecial('disk',1));
% img2b0 = img2b;
% box = [693   646    63    71];
img2c = repmat(img2b,[1 1 4]);
if params.ridges
   for j=1:4, img2c(:,:,j) = img2b-imopen(img2b,se{j}); end
       img2b = min(img2c,[],3);
       img2b = bpass(img2b,params.loCutoff,params.hiCutoff);
end
res = img2b.*(imdilate(img2b,strel('arbitrary',[1 1 1; 1 1 1; 1 1 1]))==img2b).*(imerode(img2b,strel('disk',1))<img2b);
        % if integrmethod==2
        %     img2 = imfilter(img,disk);
        %     res = img2.*(res>0);
        % end
end
