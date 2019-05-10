function [cellWidth,Tx,Ty,hcorr,rgt,wdt,A,B,pcc] = align4_InitialValues(im,pcc,p)


%warning off all
% A modification of align function to work with filamentous cells
% works only with p.algorithm == 4, f is absolete
% Parameters: 
% p.fitDisplay, p.fitConvLevel, p.fitMaxIter, p.fitStep - refine step
% Algorithm 4 model array (pcc) is 2L array
% %      [xs, ys] = creaseg_spline(pcc(:,1), pcc(:,2));
% %      pcc = []; pcc(:,1) = xs; pcc(:,2) = ys;
    % im = imageFilter(im, 0.2, 200, 0.02, 10);
     
    % Simplifying some p parameters
% % %     t = linspace(0,1,numel(pcc)-length(pcc)+5);
% % %     [C,U] = bspline_deboor(5,t,pcc');
% % %     pcc = C';
% % %     tempPcc(:,1) = [pcc(:,1);pcc(:,3)];
% % %     tempPcc(:,2) = [pcc(:,2);pcc(:,4)];
if ~isfield(p,'maxmesh'), p.maxmesh = 1000; end
isnanpcc = isnan(sum(pcc,2));
if max(isnanpcc)==1, pcc=pcc(~isnanpcc,:); end
if isempty(pcc) || length(pcc)>p.maxmesh*4,pcc = []; ftq = 0;  return; end

% Get and smooth the boundary of the region
if ~(isfield(p,'smoothbeforefit') && ~p.smoothbeforefit)
   fpp = frdescp(pcc);
   cCell = ifdescp(fpp,p.fsmooth);
   xs = cCell(:,1); 
   ys = cCell(:,2);
   cCell = [[xs; xs(1)],[ys; ys(1)]];
mesh = model2mesh(double(cCell),p.fmeshstep,p.meshTolerance,p.meshWidth);
if length(mesh)>4
   pcc = [mesh(:,1:2);flipud(mesh(2:end-1,3:4))];
else
   pcc = [];
end

if mod(length(pcc(:,1)),2), pcc = pcc(1:end-1,:); end 

pcc = makeccw(pcc);
% % % end
if isempty(pcc) || isempty(im), pcc = []; ftq = 0; return; end
    
% Initializations
L = size(pcc,1); N = L/2+1;stp = 1;H = ceil(p.cellwidth*pi/2/stp/2);
%heads = [ones(1,H),zeros(1,N-2*H),ones(1,2*H-1),zeros(1,N-2*H),ones(1,H-1)]';
%hcorr = heads * ddx*pi/4/(H-1);
xCell = pcc(:,1);yCell = pcc(:,2);Kstp = 1;
% Construct model cell and the rigidity forces in it
ddx = round(p.rigidityRange);
A = 1/2./(1:ddx); A = A/(2*sum(A)-A(1));
ddxB = round(p.rigidityRangeB);
B = 1/2./sqrt(1:ddxB); B = B/(2*sum(B)-B(1));
HA = H+1:-1:1; HA = pi*HA/(2*sum(HA)-HA(1)); % ???
x(H+1+2*ddx) = 0; y(H+1+2*ddx) = 0;   
for i=H+2*ddx:-1:H+1
    x(i) = x(i+1) - stp; y(i) = y(i+1);  
end     
alpha = HA(H+1);
for i=H:-1:1
    x(i) = x(i+1) - stp*cos(alpha);
    y(i) = y(i+1) + stp*sin(alpha);
    alpha = HA(i) + alpha;
end
x = [fliplr(x(2:end)),x];
y = [2*y(1)-fliplr(y(2:end)),y];
y = y*p.cellwidth*p.scaleFactor/abs(y(1));
[fx,fy] = getrigidityforces(x',y',A);
[Tx,Ty] = getnormals(x',y');
f = Tx.*fx + Ty.*fy;
f = f((end+1)/2:(end+1)/2+H);
hcorr = [f;zeros(N-2*H-2,1);flipud(f);f(2:end);zeros(N-2*H-2,1);flipud(f(2:end))];
rgt = [1:H+1 (H+1)*ones(1,N-2*H-2) H+1:-1:1 2:H+1 (H+1)*ones(1,N-2*H-2) H+1:-1:2]'/(H+1);
if length(rgt)>L % N-2
   L2 = length(rgt); 
   rm = (L2-L)/2;
   lv = ceil(N/2)-1;
   hcorr = hcorr([1:lv lv+1+rm:L2/2+1+lv L2/2+1+lv+1+rm:end]);
   rgt = rgt([1:lv lv+1+rm:L2/2+1+lv L2/2+1+lv+1+rm:end]); 
end
% Opposite points interaction (Fdstx,Fdsty)
lside = 2:N-1;
rside = L:-1:N+1;
% wdt = [zeros(1,H) H*ones(1,N-2*H-2) zeros(1,H)]'/H;
cellWidth = [2*abs(y(end/2+3/2:end/2+1/2+H)-y(end/2+1/2))';p.cellwidth*p.scaleFactor*ones(N-2*H-2,1);2*abs(y(end/2+1/2+H:-1:end/2+3/2)-y(end/2+1/2))'];
if length(cellWidth)>N-2, cellWidth = cellWidth([1:ceil(N/2)-1 end+2-floor(N/2):end]); end
wdt = cellWidth/max(cellWidth);

end