function [vxp vyp]=rot_vec(vx,vy,Ox,Oy,theta)

vx1=vx-Ox;
vy1=vy-Oy;

vxp1=cosd(-theta)*vx1+sind(-theta)*vy1;
vyp1=-sind(-theta)*vx1+cosd(-theta)*vy1;

vxp=vxp1+Ox;
vyp=vyp1+Oy;