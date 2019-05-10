function res=intxy2(ax,ay,bx,by)
% modified intxy, finds the first point along line a where an intersection 
% rewritten to accept unsorted sets, 2xN of N segments
% finds all intersections, only gives the row numbers in the first set

%# intxy2C
    if isempty(ax)
        res=[];
    else
        res=intxy2C(ax,ay,bx,by);
    end
% below is a MATLAB version of the C/C++ routine above, slow but same results
% 
%     res = zeros(size(ax,2),1);
%     for i=1:size(ax,2)
%         %vector to next vertex in a
%         u=[ax(2,i)-ax(1,i) ay(2,i)-ay(1,i)];
%         %go through each vertex in b
%         for j=1:size(bx,2)
%             %check for intersections at the vortices
%             if (ax(1,i)==bx(1,j) && ay(1,i)==by(1,j)) || (ax(2,i)==bx(1,j) && ay(2,i)==by(1,j))...
%                 || (ax(1,i)==bx(2,j) && ay(1,i)==by(2,j)) ||(ax(2,i)==bx(2,j) && ay(2,i)==by(2,j))
%                 res(i) = 1;
%                 continue
%             end
%             %vector from ith vertex in a to jth vertex in b
%             v=[bx(2,j)-ax(1,i) by(2,j)-ay(1,i)];
%             %vector from ith+1 vertex in a to jth vertex in b
%             w=[bx(1,j)-ax(2,i) by(1,j)-ay(2,i)];
%             %vector from ith vertex of a to jth-1 vertex of b
%             vv=[bx(1,j)-ax(1,i) by(1,j)-ay(1,i)];
%             %vector from jth-1 vertex of b to jth vertex of b
%             z=[bx(2,j)-bx(1,j) by(2,j)-by(1,j)];
%             %cross product of u and v
%             cpuv=u(1)*v(2)-u(2)*v(1);
%             %cross product of u and vv
%             cpuvv=u(1)*vv(2)-u(2)*vv(1);
%             %cross product of v and z
%             cpvz=v(1)*z(2)-v(2)*z(1);
%             %cross product of w and z
%             cpwz=w(1)*z(2)-w(2)*z(1);
%             % check if there is an intersection
%             if cpuv*cpuvv<0 && cpvz*cpwz<0
%                 res(i) = 1;
%             end
%         end
%     end
munlock
end