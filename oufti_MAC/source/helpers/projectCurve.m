function [xCurve1,yCurve1]=projectCurve(xCurve1,yCurve1,xCurve2,yCurve2)
if isempty(xCurve1) || length(xCurve2)<2, return; end
for i=1:length(xCurve1)
    [dist,pn] = point2linedist(xCurve2,yCurve2,xCurve1(i),yCurve1(i));
    [tmp,j] = min(dist);
    xCurve1(i) = (xCurve1(i)+pn(j,1))/2;
    yCurve1(i) = (yCurve1(i)+pn(j,2))/2;
end
    
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