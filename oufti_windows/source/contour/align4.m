
function [pcc,ftq] = align4(im,mpx,mpy,ngmap,pcc,p,roiBox,thres,celldata)
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
% % % if ~isfield(p,'maxmesh') || ~isfield(p,'moveall')
% % %    p.maxmesh = 1000;
% % %    p.moveall = 0.4;
% % % end
% % % isnanpcc = isnan(sum(pcc,2));
% % % if max(isnanpcc)==1, pcc=pcc(~isnanpcc,:); end
neededParams = {'meshTolerance','meshWidth','cellwidth','moveall',...
                'fitMaxIter','imageforce','attrCoeff','attrPower','repCoeff'};
if sum(~isfield(p,neededParams) == 1)
    missingField = ~isfield(p,neededParams);
    disp('Make sure these parameter values are not missing ');
    disp(neededParams(missingField));
    return;
end

ftq = 0;
if isempty(pcc) || length(pcc)>p.maxmesh*4,pcc = []; ftq = 0;  return; end
dsp = p.fitDisplay;
if dsp
   fig = createdispfigure(celldata);
   nextstop = 1; contmode = false;
else
   nextstop = Inf;
end

% Get and smooth the boundary of the region
if ~(isfield(p,'smoothbeforefit') && ~p.smoothbeforefit)
   fpp = frdescp(pcc);
   cCell = ifdescp(fpp,p.fsmooth);
   xs = cCell(:,1); 
   ys = cCell(:,2);
   cCell = [[xs; xs(1)],[ys; ys(1)]];
   mesh = model2MeshForRefine(double(cCell),p.fmeshstep,p.meshTolerance,p.meshWidth);
    if length(mesh)>length(cCell)/2 - 2 
        pcc = [mesh(:,1:2);flipud(mesh(2:end-1,3:4))];
    end
end
if isempty(pcc) || length(pcc(:,1)) < 10 || isempty(im), pcc = []; ftq = 0; return; end
if mod(length(pcc(:,1)),2), pcc = pcc(1:end-1,:); end 
pcc = double(makeccw(pcc));

% Initializations
L = size(pcc,1); N = ceil(L/2)+1;stp = 1;H = ceil(p.cellwidth*pi/2/stp/2);
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
[fx,fy] = getRigidityForces_(x',y',A);
[Tx,Ty] = getnormals(x',y');
f = Tx.*fx + Ty.*fy;
f = f((end+1)/2:(end+1)/2+H);
hcorr = [f;zeros(N-2*H-2,1);flipud(f);f(2:end);zeros(N-2*H-2,1);flipud(f(2:end))];
rgt = [1:H+1 (H+1)*ones(1,N-2*H-2) H+1:-1:1 2:H+1 (H+1)*ones(1,N-2*H-2) H+1:-1:2]'/(H+1);
if length(rgt)>L % N-2
   L2 = length(rgt); 
   rm = ceil((L2-L)/2);
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
%------------------------------------------------------------------
% fitMaxIter should really not exceed 500 as it would be waist of 
% resources and very redundant plus slowing down the processing by 
% many fold.......Ahmad.P September 17 2012
% % % if p.fitMaxIter <= 500, p.fitMaxIter = 500;end
%------------------------------------------------------------------
ftqHistory = 0;
areaCell = [];
ftqHistoryCounter = 0;
if p.imageforce >= 7, ftqThresh = 13; else ftqThresh = 21;end

for a=1:p.fitMaxIter
% Vector image forces (Fix,Fiy)
% % % Fix = -p.imageforce * interp2a(1:roiBox(3)+1,1:roiBox(4)+1,mpx,xCell,yCell,'linear',0);
% % % Fiy =  p.imageforce * interp2a(1:roiBox(3)+1,1:roiBox(4)+1,mpy,xCell,yCell,'linear',0);
Fix = -p.imageforce * interp2_(mpx,double(xCell),double(yCell),'linear',0);
% % % FixGreaterThanZero = Fix>0;
% % % FixLessThanZero    = Fix<0;
% % % FixEqualZero       = Fix==0;
% % % Fix(FixGreaterThanZero) = 1;
% % % Fix(FixLessThanZero )   = -1;
% % % Fix(FixEqualZero)       = 0;
Fiy =  p.imageforce * interp2_(mpy,double(xCell),double(yCell),'linear',0);
% % % FiyGreaterThanZero = Fiy>0;
% % % FiyLessThanZero    = Fiy<0;
% % % FiyEqualZero       = Fiy==0;
% % % Fiy(FiyGreaterThanZero) = 1;
% % % Fiy(FiyLessThanZero )   = -1;
% % % Fiy(FiyEqualZero)       = 0;
% Get normals to the centerline (Tx,Ty)
Tx = circShiftNew(yCell,-1) - circShiftNew(yCell,1);
Ty = circShiftNew(xCell,1) - circShiftNew(xCell,-1);
dtxy = sqrt(Tx.^2 + Ty.^2);
dtxy = dtxy + nanmean(dtxy)/100;
if min(dtxy)==0, pcc=[];ftq=0;return;end
Tx = Tx./dtxy;
Ty = Ty./dtxy;
% [Tx,Ty] = getnormals(xCell,yCell);
Lx = Ty;  Ly = -Tx;
% Get area outside the cell & attraction/repulsion (Fax,Fay)
% Matrix attRegion wide outside
TxM = repmat_(xCell,1,2*p.attrRegion+1)+Tx*(-p.attrRegion:p.attrRegion);
TyM = repmat_(yCell,1,2*p.attrRegion+1)+Ty*(-p.attrRegion:p.attrRegion);
% Matrix attRegion wide outside
% % % Clr0 = interp2a(1:roiBox(3)+1,1:roiBox(4)+1,im,TxM,TyM,'linear',0);
Clr0 = interp2_(im,TxM,TyM,'linear',0);
% Non-normalized 'area' attraction
Clr = 1-1./(1+(Clr0/thres/p.thresFactorF).^p.attrPower);

% Cell area
are = polyarea(xCell,yCell);
% Scalar repulsion/attraction forces
T = p.attrCoeff * nanmean(Clr(:,p.attrRegion+1:end),2) - p.repCoeff * (are<p.repArea*p.areaMax) * (1-nanmean(Clr(:,1:p.attrRegion+1),2));
% Vector repulsion/attraction forces
Fax = Tx.*T;
% % % FaxGreaterThanZero = Fax>0;
% % % FaxLessThanZero    = Fax<0;
% % % FaxEqualZero       = Fax==0;
% % % Fax(FaxGreaterThanZero) = 1;
% % % Fax(FaxLessThanZero )   = -1;
% % % Fax(FaxEqualZero)       = 0;

Fay = Ty.*T;
% % % FayGreaterThanZero = Fay>0;
% % % FayLessThanZero    = Fay<0;
% % % FayEqualZero       = Fay==0;
% % % Fay(FayGreaterThanZero) = 1;
% % % Fay(FayLessThanZero )   = -1;
% % % Fay(FayEqualZero)       = 0;
% % % T = - p.neighRepA * interp2a(1:roiBox(3)+1,1:roiBox(4)+1,ngmap,xCell,yCell,'linear',0);
T = - p.neighRepA * interp2_(ngmap,xCell,yCell,'linear',0);
Fnrx = Tx.*T;  Fnry = Ty.*T;       
% Opposite points interaction (Fdstx,Fdsty)
Dst = sqrt((xCell(lside)-xCell(rside)).^2 + (yCell(lside)-yCell(rside)).^2);
Fdst = (cellWidth-Dst)./cellWidth;
g = 5;
Fdst((Dst./cellWidth)<0.5)=Fdst((Dst./cellWidth)<0.5).*g-(g-1)*0.5;
Fdst = p.wspringconst*wdt.*Fdst.*cellWidth;
Fdst1x = Fdst.*(xCell(lside)-xCell(rside))./Dst;
Fdst1y = Fdst.*(yCell(lside)-yCell(rside))./Dst;
Fdstx = zeros(L,1); Fdsty = zeros(L,1);
Fdstx(lside) = Fdst1x; Fdsty(lside) = Fdst1y;
Fdstx(rside) = -Fdst1x; Fdsty(rside) = -Fdst1y;
% Rigidity (Frx,Fry)
[D4x,D4y] = getRigidityForces_(double(xCell),double(yCell),A);
Frx = p.rigidity * (D4x - Tx.*hcorr).*rgt;
Fry = p.rigidity * (D4y - Ty.*hcorr).*rgt;
% Backbone rigidity (Fbrx,Fbry)
xCnt = (xCell(1:N)+flipud(xCell([N:L 1])))/2;
yCnt = (yCell(1:N)+flipud(yCell([N:L 1])))/2;
Tbx = circShiftNew(yCnt,-1) - circShiftNew(yCnt,1);
Tby = circShiftNew(xCnt,1) - circShiftNew(xCnt,-1);
Tbx(end) = Tbx(end-1); Tby(end) = Tby(end-1);
Tbx(1) = Tbx(2); Tby(1) = Tby(2);
dtxy = sqrt(Tbx.^2 + Tby.^2);
Tbx = Tbx./dtxy; Tby = Tby./dtxy;
try
    if ispc        
        [D4btx,D4bty] = getRigidityForcesL_(double(xCnt),double(yCnt),B);
    else  
        [D4btx,D4bty] = getrigidityforcesL(double(xCnt),double(yCnt),B);
    end
catch 
    [D4btx,D4bty] = getrigidityforcesL(double(xCnt),double(yCnt),B);
end
D4b = (D4btx.*Tbx + D4bty.*Tby)/2;
D4bx = p.rigidityB * D4b.*Tbx; D4by = p.rigidityB * D4b.*Tby;
Fbrx = [D4bx;flipud(D4bx(2:end-1))]; Fbry = [D4by;flipud(D4by(2:end-1))];
% Perpendicular ribs (Fpx,Fpy)
Fpbx = xCell(lside)-xCell(rside); Fpby = yCell(lside)-yCell(rside);
Fp = Fpbx.*Tbx(2:end-1) + Fpby.*Tby(2:end-1);
Fpx = zeros(L,1); Fpy = zeros(L,1);
Fpbx = p.horalign*(Fpbx-Fp.*Tbx(2:end-1));
Fpby = p.horalign*(Fpby-Fp.*Tby(2:end-1));
Fpx(lside) = -Fpbx; Fpy(lside) = -Fpby;
Fpx(rside) = Fpbx; Fpy(rside) = Fpby;       
% Equal distances between points (Fqx,Fqy)
Fqx = p.eqaldist*(circShiftNew(xCell,1)+ circShiftNew(xCell,-1)-2*xCell);
Fqy = p.eqaldist*(circShiftNew(yCell,1)+ circShiftNew(yCell,-1)-2*yCell);
Fq = Lx.*Fqx + Ly.*Fqy;
Fqx = Fq.*Lx; Fqy = Fq.*Ly;
% Get the resulting force
if a>1, Fo = [Fx;Fy]; end
if isempty(who('Kstp2'))||isempty(Kstp2), Kstp2 = 1; end
Fx = (Fix + Fax + Fnrx + Fdstx) + Frx;
Fy = (Fiy + Fay + Fnry + Fdsty) + Fry;
Fs = Fx.*Tx + Fy.*Ty;
Fx = Fs.*Tx + Fpx + Fbrx + Fqx;
Fy = Fs.*Ty + Fpy + Fbry + Fqy;
% Normalize
Fm = abs(Fs).^0.2;
Fm = Fm+nanmean(Fm)/100;
% % % Fm = abs(Fs)/norm(Fs);
if min(Fm)==0, disp('Error - zero force'); pcc=[]; ftq = 0; return; end
if a>1
   K = sum((Fo.*[Fx;Fy])>0)/2/L;
   if K<0.4
      Kstp=Kstp/1.4; % Kstp saturates oscillations perpendicular to the coutour
   elseif K>0.6
          Kstp=min(1,Kstp.*1.2);
   end
end
mxf = p.fitStep*Kstp*max(max(abs(Fx))+max(abs(Fy)));
asd = (xCell - circShiftNew(xCell,1)).^2+(yCell- circShiftNew(yCell,1)).^2;
mnd = sqrt(min(asd));
med = sqrt(nanmean(asd));
Kstp2 = min([Kstp2*1.1 1 mnd/mxf/2 3*mnd/med]); % Katp2 prevents points crossing
if p.moveall>0
   if a>1
      mfxold = mfx;
      mfyold = mfy;
      MFold = MF;
   end
    xm = xCell-nanmean(xCell); ym = yCell-nanmean(yCell);
    MF = nanmean(-Fy.*xm+Fx.*ym); MI = sum(xm.^2+ym.^2);
    Fmrx =  ym*MF/MI; Fmry = -xm*MF/MI;
    mfx = nanmean(Fx); mfy = nanmean(Fy);
    if isfield(p,'fitStepM'), mfitstep = p.fitStepM; else mfitstep = p.fitStep; end
    if isempty(who('Kstpm'))||isempty(Kstpm), Kstpm = mfitstep; end
    Kstpm = min([Kstpm*1.5 mfitstep/(sqrt(nanmean(Fx)^2+nanmean(Fy)^2)) mfitstep/abs(MF)*sqrt(MI)]); % Katpm prevents large (>1px) mean steps
    if a>1 && (mfx*sign(mfxold)<-abs(mfxold)/2 || mfy*sign(mfyold)<-abs(mfyold)/2 || MF*sign(MFold)<-abs(MFold)/2)
       Kstpm = Kstpm/2;
    end
end
if a>=nextstop % Displaying results
   figHandle = figure(fig);
   imshow(im,[]);
   set(gca,'nextplot','add');
   plot(xCell,yCell,'k');
   plot(xCnt,yCnt,'k');
   for b=2:L/2; plot(xCell([b L+2-b]),yCell([b L+2-b]),'m');end
   %quiver(xCell,yCell,3*Fx,3*Fy,0,'r');
   %quiver(xCell,yCell,3*Tx,3*Ty,0,'color',[0 0 0]);
   %quiver(xCnt,yCnt,3*Tbx,3*Tby,0,'color',[0 0 0]);
   quiver(xCell,yCell,3*Fix,3*Fiy,0,'color',[1 0 0]);
   quiver(xCell,yCell,3*Fax,3*Fay,0,'color',[0.7 0 0.7]);
   quiver(xCell,yCell,3*Frx,3*Fry,0,'color',[0 0 1]);
   quiver(xCell,yCell,3*Fdstx,3*Fdsty,0,'color',[1 0.5 0]);
   %quiver(xCell,yCell,3*p.horalign*(Fdstx-Fp.*Tx),3*p.horalign*(Fdsty-Fp.*Ty),0,'color',[1 0.3 .3]);
   quiver(xCell,yCell,3*Fqx,3*Fqy,0,'color',[0.6 0.9 0]);
   quiver(xCnt,yCnt,3*D4bx,3*D4by,0,'color',[0 0.9 0.6]);
   quiver(xCell,yCell,3*Fpx,3*Fpy,0,'color',[1 0.9 0.2]);
   quiver(xCell,yCell,3*Fx,3*Fy,0,'color',[0.3 0.3 1]);
   quiver(xCell,yCell,3*Fs,3*Fs,0,'c');
   set(gca,'nextplot','replace');
   setdispfiguretitle(fig,celldata,a)
   drawnow(); pause(0.05);
   if ~contmode || a==p.fitMaxIter
      waitfor(fig,'UserData');
      if ishandle(fig)
         u = get(fig,'UserData');
      else
         u = 'stop';
      end
      if strcmp(u,'next')
         nextstop = a+1;
      elseif strcmp(u,'next100')
             nextstop = a+100;
      elseif strcmp(u,'skip')
             nextstop = Inf;
      elseif strcmp(u,'continue')
             nextstop = a+1;
             contmode = 1;
      elseif strcmp(u,'stop')
      % ftq = sum(abs(Fm))/length(Fm)/2;
      error('Testing mode terminated'); 
      %break;
      elseif strcmp(u,'finish')
             break;
      end
      set(fig,'UserData','');
   end
      drawnow(); pause(0.05);

end %Display results
        
% Move
if p.moveall>0
   Fx = Kstp*Kstp2*p.scaleFactor*p.fitStep*Fx*(1-p.moveall)+Kstpm*(nanmean(Fx)+Fmrx)*p.moveall;
   Fy = Kstp*Kstp2*p.scaleFactor*p.fitStep*Fy*(1-p.moveall)+Kstpm*(nanmean(Fy)+Fmry)*p.moveall;
else
   Fx = Kstp*Kstp2*p.scaleFactor*p.fitStep*Fx;
   Fy = Kstp*Kstp2*p.scaleFactor*p.fitStep*Fy;
end
xCell = xCell + Fx; yCell = yCell + Fy;
if max(isnan(xCell))==1, pcc=[]; ftq=0; return; end
        
% Looking for self-intersections
[i1,i2]=intxySelfC(double(xCell),double(yCell));
% Moving points halfway to the projection on the opposite strand
iMovCurveArr = []; xMovCurveArr = []; yMovCurveArr = [];
% % % for i = 1:2:(length(i1)-1)
% % %     xCell(i1(i):i1(i+1)) = [];
% % %     yCell(i1(i):i1(i+1)) = [];
% % % end
for i=1:2:(length(i1)-1)
    if i1(i)<=i1(i+1)
       iMovCurve = mod((i1(i)+1:i1(i+1))-1,L)+1;
    else
       iMovCurve = mod((i1(i)+1:i1(i+1)+L)-1,L)+1;
    end
    if length(iMovCurve)<2, continue; end
    if i2(i)+1>=i2(i+1)
       iRefCurve = mod((i2(i)+1:-1:i2(i+1))-1,L)+1;
    else
       iRefCurve = mod((i2(i)+1+L:-1:i2(i+1))-1,L)+1;
    end
    % iMovCurve = mod((i1(i)+1:i1(i+1))-1,L)+1;
    % if length(iMovCurve)<2, continue; end
    % iRefCurve = mod((i2(i)+1:-1:i2(i+1))-1,L)+1;
    xMovCurve = reshape(xCell(iMovCurve),1,[]);
    yMovCurve = reshape(yCell(iMovCurve),1,[]);
    xRefCurve = reshape(xCell(iRefCurve),1,[]);
    yRefCurve = reshape(yCell(iRefCurve),1,[]);
    [xMovCurve,yMovCurve]=projectCurve(xMovCurve,yMovCurve,xRefCurve,yRefCurve);
    iMovCurveArr = [iMovCurveArr iMovCurve];%#ok<AGROW>
    xMovCurveArr = [xMovCurveArr xMovCurve];%#ok<AGROW>
    yMovCurveArr = [yMovCurveArr yMovCurve];%#ok<AGROW>
end

xCell(iMovCurveArr) = xMovCurveArr;
yCell(iMovCurveArr) = yMovCurveArr;
% Condition to finish
ftq = sum(abs(Fm))/length(Fm)/2;
%if ftq < p.fitConvLevel; break; end
%------------------------------------------------------------------------
%check for amount of change in ftq value compare to previous 10
%frames if the value is greater than change of 0.01 then keep
%looping otherwise break the loop to save processing time and
%randomness of image force minimizing function.  Ahmad.P Sept 18.
%2012.
%areaCell = [areaCell; are];
fitQualitySumOfForces = sum(abs(Fs))/(length(Fs)/2);
if fitQualitySumOfForces < p.fitCondition, break;end
% % % ftqHistory = [ftqHistory;ftq];%#ok<AGROW>
% % % if ftqHistory(end-1) - ftq < 1e-4 && ftqHistory(end-1) - ftq > 0; 
% % %    ftqHistoryCounter = ftqHistoryCounter + 1;
% % % end
% % % if ftqHistoryCounter > ftqThresh, break; end   
%-------------------------------------------------------------------------
end % for a=1:p.fitMaxIter

% Output model
pcc = [xCell,yCell];
if isfield(p,'smoothafterfit') && p.smoothafterfit
   fpp = frdescp(pcc);
   cCell = ifdescp(fpp,p.fsmooth);
   mesh = model2mesh(double(cCell),p.fmeshstep,p.meshTolerance,p.meshWidth);
   if length(mesh)>4
      pcc = [mesh(:,1:2);flipud(mesh(2:end-1,3:4))];
   else
      pcc = [];
   end
      pcc = makeccw(pcc);
end

%     if mislocked('align4'), munlock('align4');end
%     if mislocked('model2mesh'), munlock('model2mesh');end
%     if mislocked('intxyMulti'), munlock('intxyMulti');end
%     if mislocked('makeccw'), munlock('makeccw');end
%     if mislocked('getrigidityforces'), munlock('getrigidityforces');end
%     clear ('align4','model2mesh','makeccw','getrigidityforces','intxyMulti');
%     clearvars -except pcc ftq;
end  % end of align4 function  ---ahmadP