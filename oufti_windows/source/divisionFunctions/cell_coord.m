function [v1,v2,theta]=cell_coord(cmesh)

xmesh=[cmesh(:,1) ; flipud(cmesh(:,3))];
ymesh=[cmesh(:,2) ; flipud(cmesh(:,4))];
% % % xmesh = cmesh(:,2);
% % % ymesh = cmesh(:,1);
% % % xc=mean(mean(xmesh));
% % % yc=mean(mean(ymesh));

xm=mean([cmesh(:,1) cmesh(:,3)],2);
ym=mean([cmesh(:,2) cmesh(:,4)],2);
% % % xm = xmesh;
% % % ym = ymesh;

vx=xm-xc;
vy=ym-yc;
vv=[vx./sqrt(vx.^2+vy.^2) vy./sqrt(vx.^2+vy.^2)];

a=round(size(vv,1)/2-2);
b=round(size(vv,1)/2+2);

vv1=mean(vv(1:a,:),1);
vv2=mean(vv(b:end,:),1);

[vv1bx vv1by]=rot_vec(vv1(1),vv1(2),0,0,180);
vv1b=[vv1bx vv1by];

vvv=(vv1b+vv2)/2;
v1=vvv/norm(vvv);
v2=[-v1(2) v1(1)];

theta=rad2deg(angle(v1(1)+1i*v1(2)));

%figure;plot(cmesh(:,1),cmesh(:,2),'k',cmesh(:,3),cmesh(:,4),'k',xm,ym,'r',xc,yc,'k*')