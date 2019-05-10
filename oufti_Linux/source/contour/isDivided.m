function res=isDivided(mesh,img,thr,bgr,rsz)
% splits the cell based on phase profile
% takes the mesh, cropped phase image (img) and threshold - the minimum
% relative drop in the profile to consider the cell divided
% 
% Current problem: the profile is based on the colors already in the phase
% image, which makes the output dependent of the contrast of the image
if length(mesh)<5, res=0; return; end
isz = size(img);
lng = sqrt((mesh(:,1)-mesh(:,3)).^2+(mesh(:,2)-mesh(:,4)).^2);%1-img/max(max(img))
img = max(img-bgr,0);
% % % box = [1 1 size(img,2) size(img,1)];
% % % prf = getOneSignalC(double(mesh),box,img,rsz);
% img = max(img-bgr,0);
% 
prf = interp2a(1:isz(2),1:isz(1),img,(mesh(:,1)+mesh(:,3))/2,(mesh(:,2)+mesh(:,4))/2,'linear',0);
prf = 0.5*prf + 0.25*(prf([1 1:end-1])+prf([2:end end]));
prf = prf.*lng;

mn = mean(prf);
minima = [false reshape( (prf(2:end-1)<prf(1:end-2))&(prf(2:end-1)<=prf(3:end))|(prf(2:end-1)<=prf(1:end-2))&(prf(2:end-1)<prf(3:end)) ,1,[]) false];
if isempty(minima) || sum(prf)==0, res=-1; return; end
while true
    if sum(minima)==0, res=0; return; end
    im = find(minima);
    [min0,i0] = min(prf(minima));
    max1 = max(prf(1:im(i0)));
    max2 = max(prf(im(i0):end));
    if max1<0.5*mn || max2<0.5*mn, minima(im(i0))=0; continue; else break; end
end
if thr>=1
    res = 0;
elseif (max1+max2-2*min0)/(max1+max2)>thr
    res = im(i0);
    %%%if res < 1/3*length(prf), res = 0;end 
else
    res = 0;
end
end