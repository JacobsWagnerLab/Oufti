function [L,D]=projectToMesh(x,y,mesh,varargin)
% [L,D]=projectToMesh(X,Y,MESH,STEPLENGTH)
% This function projects each of the of points X,Y onto the centerline of
% the mesh MESH. For speed the function may optionally acquire STEPLENGTH
% variable, otherwise it is computed automatically. The function outputs
% the mesh coordinates L,D of the point.

if isempty(mesh) || isempty(x) || length(x)~=length(y), L=[]; D=[]; return; end
if isempty(varargin)
    stplng=0.5*sqrt(diff(mesh(:,1)+mesh(:,3)).^2+diff(mesh(:,2)+mesh(:,4)).^2); 
else
    stplng=varargin{1};
end
xCurve2 = (mesh(:,1)+mesh(:,3))/2;
yCurve2 = (mesh(:,2)+mesh(:,4))/2;
f = 1000;
delta = f*distance([xCurve2(1) yCurve2(1)],[xCurve2(2) yCurve2(2)]);
xCurve2(1) = xCurve2(1)*(f+1) - xCurve2(2)*f;
yCurve2(1) = yCurve2(1)*(f+1) - yCurve2(2)*f;
xCurve2(end) = xCurve2(end)*(f+1) - xCurve2(end-1)*f;
yCurve2(end) = yCurve2(end)*(f+1) - yCurve2(end-1)*f;
L = zeros(size(x));
D = zeros(size(x));
I = zeros(size(x));
stplng = [-delta;cumsum(stplng)];
for i=1:length(x)
    [dist,pn] = point2linedist(xCurve2,yCurve2,x(i),y(i));
    [tmp,j] = min(dist);
    L(i) = stplng(j)+distance(pn(j,:),[xCurve2(j) yCurve2(j)]);
    if (x(i)-xCurve2(j))*(yCurve2(j+1)-yCurve2(j))<(y(i)-yCurve2(j))*(xCurve2(j+1)-xCurve2(j))
        ori=1;
    else
        ori=-1;
    end
    D(i) = sqrt(dist(j))*ori;
    I(i) = j;
end

function c=distance(a,b)
c = (sum((a-b).^2))^0.5;
    
function [dist,pn] = point2linedist(xline,yline,xp,yp)
% point2linedist: distance,projections(line,point).
% A modification of SEGMENT_POINT_DIST_2D
% (http://people.scs.fsu.edu/~burkardt/m_src/geometry/segment_point_dist_2d.m)
dist = zeros(length(xline)-1,1);
pn = zeros(length(xline)-1,2);
p = [xp,yp];
for i=2:length(xline)
      p1 = [xline(i-1) yline(i-1)];
      p2 = [xline(i) yline(i)];
      if isequal(p1,p2)
          t = 0;
      else
          bot = sum((p2-p1).^2);
          t = (p-p1)*(p2-p1)'/bot;
          % if max(max(t))>1 || min(min(t))<0, dist=-1; return; end
          t = max(t,0);
          t = min(t,1);
      end
      pn(i-1,:) = p1 + t * ( p2 - p1 );
      dist(i-1) = sum ( ( pn(i-1,:) - p ).^2 );
end