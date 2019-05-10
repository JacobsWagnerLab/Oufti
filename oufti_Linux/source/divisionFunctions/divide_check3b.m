function [res lambda]=divide_check3b(IMreg,cmesh,mC1,mC2,w,thres,box,bgr)

if length(cmesh)<5, res=0; lambda=0; return; end
% function divide_check
testmode=false;
%testmode=true;
D1=0;
D2=0;

se = strel('disk',5);

xmesh=[cmesh(:,1) ; flipud(cmesh(:,3))];
ymesh=[cmesh(:,2) ; flipud(cmesh(:,4))];
xc=mean(mean(xmesh));
yc=mean(mean(ymesh));

xm=mean([cmesh(:,1) cmesh(:,3)],2);
ym=mean([cmesh(:,2) cmesh(:,4)],2);

[v1 v2 theta]=cell_coord(cmesh);

[xmeshr ymeshr]=rot_vec(xmesh,ymesh,xc,yc,-theta);



[szuy szux]=size(IMreg);
%deltax=(szux-1)/2;
%deltay=(szuy-1)/2;
deltax=(szux-1)/2;
deltay=(szuy-1)/2;

xmesh2=xmesh-box(3)+1;
ymesh2=ymesh-box(4)+1;
cmesh2=[cmesh(:,1)-box(3)+1 cmesh(:,2)-box(4)+1 cmesh(:,3)-box(3)+1 cmesh(:,4)-box(4)+1];
xmesh2a=cmesh(:,1);
xmesh2b=cmesh(:,3);
ymesh2a=cmesh(:,2);
ymesh2b=cmesh(:,4);


[R D3]=isDivided_mod(cmesh,IMreg,bgr);

if R==0,res=0; lambda=0;return,end

xc2=round(deltax);
yc2=round(deltay);
xc3a=(xmesh2a(R)+xmesh2b(R))/2;
yc3a=(ymesh2a(R)+ymesh2b(R))/2;
xb1=xmesh2a(R);
yb1=ymesh2a(R);
xb2=xmesh2b(R);
yb2=ymesh2b(R);
xbmax=max([xb1 xb2]);
xbmin=min([xb1 xb2]);
ybmax=max([yb1 yb2]);
ybmin=min([yb1 yb2]);

dxb=xbmax-xbmin;
dyb=ybmax-ybmin;

pstep=20;
proflinex=xbmin:dxb/(pstep-1):xbmax;
profliney=ybmin:dyb/(pstep-1):ybmax;
if isempty(proflinex)
    proflinex = ones(1,pstep)*xbmin;
end
if isempty(profliney)
    profliney = ones(1,pstep)*ybmin;
end

if xbmax==xb1,proflinex=fliplr(proflinex);end
if ybmax==yb1,profliney=fliplr(profliney);end

improf=interp2(1:szux,1:szuy,IMreg,proflinex,profliney,'linear');
% The weirdest thing happened here. The logical below found two minima
xcn=proflinex(improf==min(improf(3:pstep-3)));
ycn=profliney(improf==min(improf(3:pstep-3)));

[X Y]=meshgrid(-5:1:5,-5:1:5);
Xr=X*cosd(theta)-Y*sind(theta);
Yr=X*sind(theta)+Y*cosd(theta);
Xrt=Xr+xcn(1);
Yrt=Yr+ycn(1);

%figure
%plot(improf)
if testmode
    figure
    imagesc(IMreg)
    hold on
    plot(xmesh2,ymesh2)
    plot(xc2,yc2,'w*',xc3a,yc3a,'r*')
    plot(xb1,yb1,'k+',xb2,yb2,'k*')
    plot(xcn,ycn,'ro')
    plot(Xrt,Yrt,'k.')
    hold off
end

IMtest=interp2(1:szux,1:szuy,IMreg,Xrt,Yrt)';
if testmode
    figure
    imagesc(IMtest)
end



% H0=im2mat(hessian(IMtest,2.5));
% xct=6;
% yct=6;
% 
% H=reshape(H0(yct,xct,:,:),2,2);
% H(isnan(H))=0;
H0=hessian(IMtest);
Hev=eig(H0);
D4=Hev(1);
D5=Hev(2);


mC=normim(IMtest);


if nargin>2 && ~testmode
    c1=[D3 D4 D5 mC(:)'*mC1(:) mC(:)'*mC2(:)];
    lambda=c1*w;
    if lambda>thres-12, res=R; else res=0;end
else
    res=0;
end

if isnan(lambda), lambda=-10000;res=0;end


function [res d1]=isDivided_mod(mesh,img,bgr)
% splits the cell based on phase profile
% takes the mesh, cropped phase image (img) and threshold - the minimum
% relative drop in the profile to consider the cell divided
% 
% Current problem: the profile is based on the colors already in the phase
% image, which makes the output dependent of the contrast of the image
if length(mesh)<5, res=0; return; end
isz = size(img);
lng = sqrt((mesh(:,1)-mesh(:,3)).^2+(mesh(:,2)-mesh(:,4)).^2);%1-img/max(max(img))
% box = [1 1 size(img,2) size(img,1)];
% prf = getOneSignal(mesh,box,img,1);

% img=normim(img)+1;
% l=graythresh(normim(img));
% mask=im2bw(normim(img),l);
% imgm=~mask.*img;
% bgr=min(min(nonzeros(imgm)));
img = max(img-bgr,0);
prf = interp2a(1:isz(2),1:isz(1),img,(mesh(:,1)+mesh(:,3))/2,(mesh(:,2)+mesh(:,4))/2,'linear',0);
prf = 0.5*prf + 0.25*(prf([1 1:end-1])+prf([2:end end]));
prf = prf.*lng;

sprf=size(prf,1);
X=1:1:sprf;
Y=normpdf(X,sprf/2,sqrt(sprf));
%Y=Y/max(Y);
%figure
%plot(prf)

mn = mean(prf);
minima = [false reshape( (prf(2:end-1)<prf(1:end-2))&(prf(2:end-1)<=prf(3:end))|(prf(2:end-1)<=prf(1:end-2))&(prf(2:end-1)<prf(3:end)) ,1,[]) false];
%if isempty(minima) || sum(prf)==0, res=-1; return; end

while true
    if sum(minima)==0, res=0; d1=0; return; end
    im = find(minima);
    prf2=max(prf)-prf;
    %figure
    %plot(prf2)
    %size(Y)
    %size(prf2)
    prfbias=prf2.*Y';
    %figure
    %plot(prfbias)
    %hold on
    %size(minima)
    %size(prfbias(minima))
    %plot(find(minima),prfbias(minima),'*')
    %hold off
    [min0,i0] = max(prfbias(minima));
    %[min0,i0] = min(prf(minima));
    max1 = mean(prf(1:im(i0)));
    max2 = mean(prf(im(i0):end));
    if max1<0.5*mn || max2<0.5*mn, minima(im(i0))=0; continue; else break; end
end

res = im(i0);
d1=Y(im(i0))*(max1+max2-2*min0)/(max1+max2)-max(Y)/2;
end


end



% function [res lambda]=divide_check3b(IMreg,cmesh,mC1,mC2,w,thres,box)
% 
% if length(cmesh)<5, res=0; lambda=0; return; end
% % function divide_check
% testmode=false;
% %testmode=true;
% D1=0;
% D2=0;
% 
% se = strel('disk',5);
% 
% xmesh=[cmesh(:,1) ; flipud(cmesh(:,3))];
% ymesh=[cmesh(:,2) ; flipud(cmesh(:,4))];
% xc=mean(mean(xmesh));
% yc=mean(mean(ymesh));
% 
% xm=mean([cmesh(:,1) cmesh(:,3)],2);
% ym=mean([cmesh(:,2) cmesh(:,4)],2);
% 
% [v1 v2 theta]=cell_coord(cmesh);
% 
% [xmeshr ymeshr]=rot_vec(xmesh,ymesh,xc,yc,-theta);
% 
% 
% 
% [szuy szux]=size(IMreg);
% %deltax=(szux-1)/2;
% %deltay=(szuy-1)/2;
% deltax=(szux-1)/2;
% deltay=(szuy-1)/2;
% 
% xmesh2=xmesh-box(1)+1;
% ymesh2=ymesh-box(2)+1;
% cmesh2=[cmesh(:,1)-box(1)+1 cmesh(:,2)-box(2)+1 cmesh(:,3)-box(1)+1 cmesh(:,4)-box(2)+1];
% xmesh2a=cmesh(:,1)-box(1)+1;
% xmesh2b=cmesh(:,3)-box(1)+1;
% ymesh2a=cmesh(:,2)-box(2)+1;
% ymesh2b=cmesh(:,4)-box(2)+1;
% 
% [res lambda] = isDivided_mod(cmesh2,IMreg);
% 
% 
% [R D3]=isDivided_mod(cmesh2,IMreg);
% 
% if R==0,res=0; lambda=0;return,end
% 
% xc2=round(deltax);
% yc2=round(deltay);
% xc3a=(xmesh2a(R)+xmesh2b(R))/2;
% yc3a=(ymesh2a(R)+ymesh2b(R))/2;
% xb1=xmesh2a(R);
% yb1=ymesh2a(R);
% xb2=xmesh2b(R);
% yb2=ymesh2b(R);
% xbmax=max([xb1 xb2]);
% xbmin=min([xb1 xb2]);
% ybmax=max([yb1 yb2]);
% ybmin=min([yb1 yb2]);
% 
% dxb=xbmax-xbmin;
% dyb=ybmax-ybmin;
% 
% pstep=20;
% proflinex=xbmin:dxb/(pstep-1):xbmax;
% profliney=ybmin:dyb/(pstep-1):ybmax;
% if isempty(proflinex)
%     proflinex = ones(1,pstep)*xbmin;
% end
% if isempty(profliney)
%     profliney = ones(1,pstep)*ybmin;
% end
% 
% if xbmax==xb1,proflinex=fliplr(proflinex);end
% if ybmax==yb1,profliney=fliplr(profliney);end
% 
% improf=interp2(1:szux,1:szuy,IMreg,proflinex,profliney,'linear');
% % The weirdest thing happened here. The logical below found two minima
% xcn=proflinex(improf==min(improf(3:pstep-3)));
% ycn=profliney(improf==min(improf(3:pstep-3)));
% 
% [X Y]=meshgrid(-5:1:5,-5:1:5);
% Xr=X*cosd(theta)-Y*sind(theta);
% Yr=X*sind(theta)+Y*cosd(theta);
% Xrt=Xr+xcn(1);
% Yrt=Yr+ycn(1);
% 
% %figure
% %plot(improf)
% if testmode
%     figure
%     imagesc(IMreg)
%     hold on
%     plot(xmesh2,ymesh2)
%     plot(xc2,yc2,'w*',xc3a,yc3a,'r*')
%     plot(xb1,yb1,'k+',xb2,yb2,'k*')
%     plot(xcn,ycn,'ro')
%     plot(Xrt,Yrt,'k.')
%     hold off
% end
% 
% IMtest=interp2(1:szux,1:szuy,IMreg,Xrt,Yrt)';
% if testmode
%     figure
%     imagesc(IMtest)
% end
% 
% IMtest_label=bwlabel(IMtest);
% 
% 
% H0=im2mat(hessian(sym(2),ans));
% xct=6;
% yct=6;
% 
% H=reshape(H0(yct,xct,:,:),2,2);
% H(isnan(H))=0;
% 
% Hev=eig(H);
% D4=Hev(1);
% D5=Hev(2);
% 
% 
% mC=normim(IMtest);
% 
% 
% if nargin>2 && ~testmode
%     c1=[D3 D4 D5 mC(:)'*mC1(:) mC(:)'*mC2(:)];
%     lambda=c1*w;
%     if lambda>thres, res=R; else res=0;end
% else
%     res=0;
% end
% 
% if isnan(lambda), lambda=-10000;res=0;end
% 
% 
% 
% 
% function [res d1]=isDivided_mod(mesh,img)
% % splits the cell based on phase profile
% % takes the mesh, cropped phase image (img) and threshold - the minimum
% % relative drop in the profile to consider the cell divided
% % 
% % Current problem: the profile is based on the colors already in the phase
% % image, which makes the output dependent of the contrast of the image
% if length(mesh)<5, res=0; return; end
% isz = size(img);
% lng = sqrt((mesh(:,1)-mesh(:,3)).^2+(mesh(:,2)-mesh(:,4)).^2);%1-img/max(max(img))
% % box = [1 1 size(img,2) size(img,1)];
% % prf = getOneSignal(mesh,box,img,1);
% 
% img=-normim(img)+1;
% %l=graythresh(normim(img));
% %mask=im2bw(normim(img),l);
% %imgm=~mask.*img;
% %bgr=min(min(nonzeros(imgm)))
% %img = max(img-bgr,0);
% 
% prf = interp2a(1:isz(2),1:isz(1),img,(mesh(:,1)+mesh(:,3))/2,(mesh(:,2)+mesh(:,4))/2,'linear',0);
% prf = 0.5*prf + 0.25*(prf([1 1:end-1])+prf([2:end end]));
% prf = prf.*lng;
% 
% sprf=size(prf,1);
% X=1:1:sprf;
% Y=normpdf(X,sprf/2,sqrt(sprf));
% %Y=Y/max(Y);
% %figure
% %plot(prf)
% 
% mn = mean(prf);
% minima = [false reshape( (prf(2:end-1)<prf(1:end-2))&(prf(2:end-1)<=prf(3:end))|(prf(2:end-1)<=prf(1:end-2))&(prf(2:end-1)<prf(3:end)) ,1,[]) false];
% %if isempty(minima) || sum(prf)==0, res=-1; return; end
% 
% while true
%     if sum(minima)==0, res=0; d1=0; return; end
%     im = find(minima);
%     prf2=max(prf)-prf;
%     %figure
%     %plot(prf2)
%     %size(Y)
%     %size(prf2)
%     prfbias=prf2.*Y';
%     %figure
%     %plot(prfbias)
%     %hold on
%     %size(minima)
%     %size(prfbias(minima))
%     %plot(find(minima),prfbias(minima),'*')
%     %hold off
%     [min0,i0] = max(prfbias(minima));
%     %[min0,i0] = min(prf(minima));
%     max1 = mean(prf(1:im(i0)));
%     max2 = mean(prf(im(i0):end));
%     if max1<0.5*mn || max2<0.5*mn, minima(im(i0))=0; continue; else break; end
% end
% 
% res = im(i0);
% d1=Y(im(i0))*(max1+max2-2*min0)/(max1+max2)-max(Y)/2;
% end
% 
% 
% end
% 
% 
