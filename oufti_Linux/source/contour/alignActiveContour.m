%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% interate.m implements the core of the snakes (active contours) algorithm.
% It is called by the snk.m file which is the GUI frontend. If you do not
% want to deal with GUI, look at this file and the included comments which
% explain how active contours work.
%
% To run this code with GUI
%   1. Type guide on the matlab prompt.
%   2. Click on "Go to Existing GUI"
%   3. Select the snk.fig file in the same directory as this file
%   4. Click the green arrow at the top to launch the GUI
%
%   Once the GUI has been launched, you can use snakes by
%   1. Click on "New Image" and load an input image. Samples image are
%   provided.
%   2. Set the smoothing parameter "sigma" or leave it at its default value
%   and click "Filter". This will smooth the image.
%   3. As soon as you click "Filter", cross hairs would appear and using
%   them and left click of you mouse you can pick initial contour location
%   on the image. A red circle would appead everywhere you click and in
%   most cases you should click all the way around the object you want to
%   segement. The last point must be picked using a right-click in order to
%   stop matlab for asking for more points.
%   4. Set the various snake parameters (relative weights of energy terms
%   in the snake objective function) or leave them with their default value
%   and click "Iterate" button. The snake would appear and move as it
%   converges to its low energy state.
%
% Copyright (c) Ritwik Kumar, Harvard University 2010
%               www.seas.harvard.edu/~rkkumar
%
% This code implements “Snakes: Active Contour Models” by Kass, Witkin and
% Terzopolous incorporating Eline, Eedge and Eterm energy factors. See the
% included report and the paper to learn more.
%
% If you find this useful, also look at Radon-Like Features based
% segmentation in  the following paper:
% Ritwik Kumar, Amelio V. Reina & Hanspeter Pfister, “Radon-Like Features 
% and their Application to Connectomics”, IEEE Computer Society Workshop %
% on Mathematical Methods in Biomedical Image Analysis (MMBIA) 2010
% http://seas.harvard.edu/~rkkumar
% Its code is also available on MATLAB Central
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pcc2,ftq] = alignActiveContour(image, pcCell, alpha, beta, gamma, kappa,...
                                         Wline, Wedge, Wterm, iterations, Sigma,thres,mpy,roiBox)
% image: This is the image data
% xs, ys: The initial snake coordinates
% alpha: Controls tension
% beta: Controls rigidity
% gamma: Step size
% kappa: Controls enegry term
% wl, we, wt: Weights for line, edge and terminal enegy components
% iterations: No. of iteration for which snake is to be moved

% %      [xs, ys] = creaseg_spline(pcCell(:,1), pcCell(:,2));
% %      pcCell = []; pcCell(:,1) = xs; pcCell(:,2) = ys;
% %     image = imageFilter(image, 0.2, 200, 0.02, 10);

if isempty(pcCell),pcc2 = []; ftq = 0;  return; 
else
    xs = pcCell(:,1);
    ys = pcCell(:,2);
end
%parameters
N = iterations; 
% smth = imadjust(image,[0.2 1],[]);
 smth = image;
% I = image;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Active contour another method
% % [pcc2,J]=Snake2D(I,pcCell,true);

pcc = [xs ys];
t = linspace(0,1,numel(pcc)-length(pcc)+3);
    [C,U] = bspline_deboor(3,t,pcc');
    pcc = C';
xs = pcc(:,1);
ys = pcc(:,2);

% % % pcCellClosed = [[xs; xs(1)],[ys; ys(1)]];
% % % pcCellClosedMask = poly2mask(pcCellClosed(:,1),pcCellClosed(:,2),size(I,1),size(I,2));
% % % [seg,phi,its] = creaseg_bernard(I,pcCellClosedMask,500,1,thres,'r',1)
% % %  [xs, ys] = creaseg_spline(xs', ys');
% Calculating size of image
[row col] = size(image);
% % % f = 1-I/255;
% % % [u,v] = GVF(f, 0.2, 80);
% % % disp(' Nomalizing the GVF external force ...');
% % % mag = sqrt(u.*u+v.*v);
% % % px = u./(mag+1e-10); py = v./(mag+1e-10);
% % % [x,y]= snakeinterp(xs,ys,3,1);
% % % for i = 1:25
% % % [x,y] = snakedeform2(x,y,0.05,0,1,0.6,0.6,px,py,5);
% % % [x,y] = snakeinterp(x,y,3,1);
% % % end



%Computing external forces
% % % Ix=ImageDerivatives2D(I,Sigma,'x');
% % % Iy=ImageDerivatives2D(I,Sigma,'y');
% % % Ixx=ImageDerivatives2D(I,Sigma,'xx');
% % % Ixy=ImageDerivatives2D(I,Sigma,'xy');
% % % Iyy=ImageDerivatives2D(I,Sigma,'yy');
% % % 
% % % 
% % % Eline = imgaussian(I,Sigma);
% % % Eterm = (Iyy.*Ix.^2 -2*Ixy.*Ix.*Iy + Ixx.*Iy.^2)./((1+Ix.^2 + Iy.^2).^(3/2));
% % % mag = sqrt(Ix.*Ix + Iy.*Iy); 
% % % Eedgex = Ix./(mag);
% % % Eedgey = Iy./(mag);
% % % Eedge = Eedgex + Eedgey;
% % % 
% % % Eextern= (Wline*Eline - Wedge*Eedge -Wterm * Eterm); 

eline = smth; %eline is simply the image intensities

[grady,gradx] = gradient(smth);
eedge = -1 * sqrt ((gradx .* gradx + grady .* grady));%eedge is measured by gradient in the image

%masks for taking various derivatives
m1 = [-1 1];
m2 = [-1;1];
m3 = [1 -2 1];
m4 = [1;-2;1];
m5 = [1 -1;-1 1];

cx = conv2(smth,m1,'same');
cy = conv2(smth,m2,'same');
cxx = conv2(smth,m3,'same');
cyy = conv2(smth,m4,'same');
cxy = conv2(smth,m5,'same');

for i = 1:row
    for j= 1:col
        % eterm as deined in Kass et al Snakes paper
        eterm(i,j) = (cyy(i,j)*cx(i,j)*cx(i,j) -2 *(cxy(i,j)*cx(i,j)*cy(i,j)) + ...
                      cxx(i,j)*cy(i,j)*cy(i,j))/(0.01+(cx(i,j)*cx(i,j) + ...
                      cy(i,j)*cy(i,j))^1.5);%#ok<AGROW>  
    end
end
% 
% % imview(eterm);
% % imview(abs(eedge));
 eext = (Wline*eline + Wedge*eedge + Wterm * eterm); %eext as a weighted sum of eline, eedge and eterm

[fx, fy] = gradient(eext); %computing the gradient


%initializing the snake
% xs=xs';
% ys=ys';
[m n] = size(xs);
[mm nn] = size(fx);
    
%populating the penta diagonal matrix
A = zeros(m,m);
% b = [(2*alpha + 6 *beta) -(alpha + 4*beta) beta];
b = [(2*alpha + 6*beta) -(alpha + 4*beta) beta];
brow = zeros(1,m);
brow(1,1:3) = brow(1,1:3) + b;
brow(1,m-1:m) = brow(1,m-1:m) + [beta -(alpha + 4*beta)]; % populating a template row
for i=1:m
    A(i,:) = brow;
    brow = circshift(brow',1)'; % Template row being rotated to egenrate different rows in pentadiagonal matrix
end
 [L,U] = lu(A+gamma.*eye(m,m),'vector');
%  [L U] = lu(A + gamma .* eye(m,m));
 B = inv(L);
 Ainv = U\B;
%  Ainv = inv(U) * inv(L); % Computing Ainv using LU factorization
%   Ainv = U\L;
%moving the snake in each iteration
for j=1:N;
  
    ssx = gamma*xs - kappa*interp2(fx,xs,ys,'linear');
    ssy = gamma*ys - kappa*interp2(fy,xs,ys,'linear');
    %calculating the new position of snake
    xs = Ainv * ssx;
    ys = Ainv * ssy;
    %Displaying the snake in its new position
    
% % %      % Looking for self-intersections
% % %         L = size(pcCell,1);
% % %         [i1,i2]=intxySelfC(double(xs),double(ys));
% % %         % Moving points halfway to the projection on the opposite strand
% % %         iMovCurveArr = []; xMovCurveArr = []; yMovCurveArr = [];
% % % 
% % %         for i=1:2:(length(i1)-1)
% % %             if i1(i)<=i1(i+1)
% % %                 iMovCurve = mod((i1(i)+1:i1(i+1))-1,L)+1;
% % %             else
% % %                 iMovCurve = mod((i1(i)+1:i1(i+1)+L)-1,L)+1;
% % %             end
% % %             if length(iMovCurve)<2, continue; end
% % %             if i2(i)+1>=i2(i+1)
% % %                 iRefCurve = mod((i2(i)+1:-1:i2(i+1))-1,L)+1;
% % %             else
% % %                 iRefCurve = mod((i2(i)+1+L:-1:i2(i+1))-1,L)+1;
% % %             end
% % %             % iMovCurve = mod((i1(i)+1:i1(i+1))-1,L)+1;
% % %             % if length(iMovCurve)<2, continue; end
% % %             % iRefCurve = mod((i2(i)+1:-1:i2(i+1))-1,L)+1;
% % %             xMovCurve = reshape(xs(iMovCurve),1,[]);
% % %             yMovCurve = reshape(ys(iMovCurve),1,[]);
% % %             xRefCurve = reshape(xs(iRefCurve),1,[]);
% % %             yRefCurve = reshape(ys(iRefCurve),1,[]);
% % %             [xMovCurve,yMovCurve]=projectCurve(xMovCurve,yMovCurve,xRefCurve,yRefCurve);
% % %             iMovCurveArr = [iMovCurveArr iMovCurve];%#ok<AGROW>
% % %             xMovCurveArr = [xMovCurveArr xMovCurve];%#ok<AGROW>
% % %             yMovCurveArr = [yMovCurveArr yMovCurve];%#ok<AGROW>
% % %         end
% % %         xs(iMovCurveArr) = xMovCurveArr;
% % %         ys(iMovCurveArr) = yMovCurveArr;


    imshow(image,[]); 
    hold on;
    plot(pcCell(:,1),pcCell(:,2),'b-');
    
    plot([xs; xs(1)], [ys; ys(1)], 'r-');
    hold off;
    pause(0.001)    
end

pcc2 = [[xs; xs(1)],[ys; ys(1)]];

ftq = 0.25;

end


