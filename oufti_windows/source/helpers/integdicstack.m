function integdicstack
dsp = 0;
folder = uigetdir;
folder2 = [folder '_processed\'];
[stack,fnames,folder] = tryToLoadFiles(folder,1);
mkdir(folder2);
for frame=1:size(stack,3)
    img = stack(:,:,frame);
    img2 = integdic(im2double(img),dsp);
    fname = [folder2 fnames{frame}];
    imwrite(img2,fname,'tif','Compression','none');
    disp(['Integdicstack: processing frame ' num2str(frame) ' of ' num2str(size(stack,3))])
end
end
    

function res = integdic(img,dsp)
se = strel('diamond', 1);
h = fspecial('gaussian',5,1);
hs = fspecial('sobel');
%x = fminbnd(@q,0,360)
img4 = qold(125.3736);
% img5 = qold(125.3736-180);
if dsp, figure;imshow(img,[min(min(img)) max(max(img))]); end
img4a = imfilter(imrotate(img4,360-125.3736),h);
img4a = imcrop(img4a,[round((size(img4a,2)-size(img,2))/2),...
    round((size(img4a,1)-size(img,1))/2),size(img,2),size(img,1)]);
img4b = (img4a-min(min(img4a)))/(max(max(img4a))-min(min(img4a)));
if dsp, figure;imshow(img4a,[min(min(img4)) max(max(img4))]); end
% figure;imshow(img5,[min(min(img5)) max(max(img5))])
% mean(reshape(img4,[],1)); % black on white > 0
% mean(reshape(img5,[],1)); % white on black > 0
res = im2uint16(img4b);


function res = q(a)
    disp(num2str(a))
img2 = imrotate(img,a);
img2(img2==0)=mean(mean(img));
img2 = im2double(imfilter(img2,h));
img2a = img2-median(reshape(img2,[],1));
m = max(max(img2));
n = histc(reshape(img2,1,[]),0:m/500:m);
[maxnv,maxn] = max(n);
img3 = ~((img2<(maxn+20)*m/500).*(img2>(maxn-20)*m/500));
img3a = img3;
for i=1:6
    img3a = imdilate(img3a,se);
end
img4 = img2*0;
img4(1,:)=img2a(1,:);
for i=2:size(img4,1)
    img4(i,:)=(img4(i-1,:)+img2a(i,:));
end
res = std(img4(end,:));
end


function img4 = qold(a)
img2 = imrotate(img,a);
img2(img2==0)=mean(mean(img));
img2 = im2double(imfilter(img2,h));
img2a = img2-median(reshape(img2,[],1));
m = max(max(img2));
n = histc(reshape(img2,1,[]),0:m/500:m);
[maxnv,maxn] = max(n);
gradimg = imfilter(img2,hs).^2+imfilter(img2,hs').^2;
thr = graythresh(gradimg*10000);
gradimg = im2bw(gradimg*10000,thr);
difimg = ~((img2<(maxn+20)*m/500).*(img2>(maxn-20)*m/500));
img3a = ~((~gradimg).*(~difimg));
for i=1:4
    img3a = imdilate(img3a,se);
end
img4 = img2*0;
img4(1,:)=img2a(1,:);
img4b = img4*0;
for i=2:size(img4,1)
    img4(i,:)=(img4(i-1,:)+img2a(i,:)).*img3a(i,:);
    img4b(i,:)=(img4b(i-1,:)+img3a(i,:)).*img3a(i,:);
end

v = zeros(1,size(img2,2));
for i=size(img4,1):-1:1
    v = v.*img3a(i,:);
    u1 = img4(i,:);
    u2 = img4b(i,:);
    u = u1*0;
    u(u2>0) = u1(u2>0)./u2(u2>0);
    v(v==0) = u(v==0);
    img4c(i,:)=v;
end
img4c = img4c.*img4b;
img4 = img4 - img4c;
BW = im2bw(img4, graythresh(img4)*2);
end

end