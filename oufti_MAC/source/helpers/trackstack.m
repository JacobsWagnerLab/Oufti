function varargout = trackstack(varargin)
% trackstack
% 
% Syntax:
% trackstack
% trackstack(cellList1)
% cellList2 = trackstack
% cellList2 = trackstack(cellList1)
% cellList2 = trackstack(cellList1,weights)
% cellList2 = trackstack(cellList1,cutoff)
% cellList2 = trackstack(cellList1,weights,cutoff)
% 
% This function processes a cell list obtained by Oufti in
% 'Individual Frames' mode attempting to assign the same number of the same
% cell on every frame of the list. It is designed to be used for moving
% cells in the case that the motion is too large to use the 'timelapse' mode.
% The function is based on Munker's algorithm for the assignment problem.
% 
% <cellList1> - input cell list. If not supplied, the program will request
%     to open a file with the list.
% <cellList2> - output cell list. If not supplied, the program will request
%     to select a file to write the data to. 
% <weights> - weight coefficients for calculating the "cost" or "penalty"
%     of assignment of a cell between two frames, consisting of 4 components:
%     - distance perpendicular to the main direction,
%     - distance along the main direction,
%     - angle,
%     - ratio of the areas.
%     The lower a value is, the less effect the component will have on the
%     assignment. Default: [0.2 1 1 1].
% <cutoff> - cutoff in units of the mean distance ot the nearest (in terms
% of the cost) neighbor. Default: 1, larger values will force to assign
% most cells, lower valus - to lose those that don't have a good match.

clist1 = {};
M = [0.2 1 1 1]; % cost coefficients: parallel distance, perpendicular distance, angle, log area ratio
cutoff = 1;
for i=1:length(varargin)
    if iscell(varargin{i})
        clist1 = varargin{i};
    elseif strcmp(class(varargin{i}),'double') && length(varargin{i})==4
        M = varargin{i};
    elseif strcmp(class(varargin{i}),'double') && length(varargin{i})==1
        cutoff = varargin{i};
    end
end
if isempty(clist1)
    [FileName,PathName] = uigetfile('','Select file with meshes','*.mat');
    if isempty(FileName) || isequal(FileName,0), return, end
    datafilename = fullfile(PathName,FileName);
    l=load(datafilename,'cellList');
    if isempty(fields(l)), return; end
    clist1 = l.cellList;
end

clist2 = {clist1{1}};
[setnew,indnew] = mesh2set(clist1{1});
for frame=2:length(clist1)
    indold = indnew;
    setold = setnew;
    [setnew,indnew] = mesh2set(clist1{frame});
    A = getweights(setnew,setnew,M);
    n = size(setnew,2);
    m = size(setold,2);
    A(1:n+1:end) = inf;
    mindist = mean(min(A)); % is slow, perform this operation only once
    A = getweights(setold,setnew,M);
    A = [A ones(m,ceil(m/2))*mindist*cutoff];%#ok
    ind = munkres(A);
    ind(ind<=0)=n+1;
    clistC = {};
    clistC(indold(ind<=n)) = clist1{frame}(indnew(ind(ind<=n)));%#ok
    clist2{frame} = clistC;
    setnew = setnew(:,ind(ind<=n));
    indnew = indold(ind<=n);
end

if nargout==0
    [FileName,PathName] = uiputfile('','Select processed file','.mat');
    if isempty(FileName) || isequal(FileName,0), return, end
    datafilename = fullfile(PathName,FileName);
    cellList = clist2;
    save(datafilename,'cellList');
else
    varargout{1} = clist2;
end



function [setres,indres] = mesh2set(meshes)
% set is constructed from a cellList frame with 4 rows: x, y, alpha, area
setres = [];
indres = [];
for cell=1:length(meshes)
    if ~isempty(meshes{cell}) && isfield(meshes{cell},'mesh') && length(meshes{cell}.mesh)>4
        mesh = meshes{cell}.mesh;
        l = length(mesh);
        x = mean(mesh(ceil(l/2),[1 3]));
        y = mean(mesh(ceil(l/2),[2 4]));
        dx = mesh(end,1)-mesh(1,1);
        dy = mesh(end,2)-mesh(1,2);
        alpha = mod(angle(dx+j*dy)+pi/2,pi)-pi/2;
        area = max(meshes{cell}.area,1);
        setres = [setres [x;y;alpha;area]];
        indres = [indres cell];
    elseif ~isempty(meshes{cell}) && isfield(meshes{cell},'model') && length(meshes{cell}.model)>1
        contour = meshes{cell}.model;
        l = length(contour);
        [x,y] = centerofmass(contour(:,1),contour(:,2));
        [m,i] = max(reshape( (repmat(contour(:,1),1,l)-repmat(contour(:,1)',l,1)).^2 + ...
                             (repmat(contour(:,2),1,l)-repmat(contour(:,2)',l,1)).^2,[],1));
        [i1,i2] = ind2sub([l l],i);
        dx = contour(i1,1)-contour(i2,1);
        dy = contour(i1,2)-contour(i2,2);
        alpha = mod(angle(dx+j*dy)+pi/2,pi)-pi/2;
        area = max(meshes{cell}.area,1);
        setres = [setres [x;y;alpha;area]];
        indres = [indres cell];
    end
end



function [x0,y0]=centerofmass(x,y)
% calculates the center of mass of a polygon defined by the coordinates of
% its vertices x and y
x = reshape(x,1,[]);
y = reshape(y,1,[]);

n = size(x,2);
dy = y(2:n)-y(1:n-1);
x2 = x(1:n-1).^2+x(2:n).^2+x(1:n-1).*x(2:n);
x0 = dy*x2';

dx = x(2:n)-x(1:n-1);
y2 = y(1:n-1).^2+y(2:n).^2+y(1:n-1).*y(2:n);
y0 = dx*y2';

a = dx*(y(1:n-1)+y(2:n))';
if a<1E-10
    x0 = mean(x);
    y0 = mean(y);
else
    a = 1/3/a;
    x0 = -x0*a;
    y0 =  y0*a;
end



function A = getweights(set1,set2,M)
n1 = size(set1,2);
n2 = size(set2,2);
alpha1 = repmat(set1(3,:)',1,n2);
alpha2 = repmat(set2(3,:) ,n1,1);
alphax = abs(alpha1-alpha2)<(pi+alpha1-alpha2) & abs(alpha1-alpha2)<(pi+alpha1-alpha2);
alpham = alphax.*(alpha1+alpha2)/2 + ~alphax.*(pi+alpha1+alpha2)/2;
dalpha = alphax.*(alpha1-alpha2) + ~alphax.*(mod(alpha1-alpha2,2*pi)-pi);

x1 = repmat(set1(1,:)',1,n2);
x2 = repmat(set2(1,:) ,n1,1);
y1 = repmat(set1(2,:)',1,n2);
y2 = repmat(set2(2,:) ,n1,1);
dx2 = (x2-x1).^2 + (y2-y1).^2;
beta = angle((x2-x1) + j*(y2-y1));

gamma2 = sin(alpham-beta).^2;%????????
d12 = dx2.*gamma2;
d22 = dx2.*(1-gamma2);

area1 = repmat(set1(4,:)',1,n2);
area2 = repmat(set2(4,:) ,n1,1);

A = M(1)^2*d12 + M(2)^2*d22 + (M(3)*dalpha).^2 + (M(4)*log2(area1./area2)).^2;




% The following portion of the code was oftained from MATLAB Central as
% "Munkres Assignment Algorithm" and is licensed under a separate FreeBSD
% license, presented below:
% 
% Copyright (c) 2009, Yi Cao
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the distribution
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.
% 
function [assignment,cost] = munkres(costMat)
% MUNKRES   Munkres (Hungarian) Algorithm for Linear Assignment Problem. 
%
% [ASSIGN,COST] = munkres(COSTMAT) returns the optimal column indices,
% ASSIGN assigned to each row and the minimum COST based on the assignment
% problem represented by the COSTMAT, where the (i,j)th element represents the cost to assign the jth
% job to the ith worker.
%

% This is vectorized implementation of the algorithm. It is the fastest
% among all Matlab implementations of the algorithm.

% Examples
% Example 1: a 5 x 5 example
%{
[assignment,cost] = munkres(magic(5));
disp(assignment); % 3 2 1 5 4
disp(cost); %15
%}
% Example 2: 400 x 400 random data
%{
n=400;
A=rand(n);
tic
[a,b]=munkres(A);
toc                 % about 2 seconds 
%}
% Example 3: rectangular assignment with inf costs
%{
A=rand(10,7);
A(A>0.7)=Inf;
[a,b]=munkres(A);
%}
% Reference:
% "Munkres' Assignment Algorithm, Modified for Rectangular Matrices", 
% http://csclab.murraystate.edu/bob.pilgrim/445/munkres.html

% version 2.2 by Yi Cao at Cranfield University on 1st March 2010

assignment = zeros(1,size(costMat,1));
cost = 0;

costMat(costMat~=costMat)=Inf;
validMat = costMat<Inf;
validCol = any(validMat,1);
validRow = any(validMat,2);

nRows = sum(validRow);
nCols = sum(validCol);
n = max(nRows,nCols);
if ~n
    return
end

maxv=10*max(costMat(validMat));

dMat = zeros(n) + maxv;
dMat(1:nRows,1:nCols) = costMat(validRow,validCol);

%*************************************************
% Munkres' Assignment Algorithm starts here
%*************************************************

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   STEP 1: Subtract the row minimum from each row.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
minR = min(dMat,[],2);
minC = min(bsxfun(@minus, dMat, minR));

%**************************************************************************  
%   STEP 2: Find a zero of dMat. If there are no starred zeros in its
%           column or row start the zero. Repeat for each zero
%**************************************************************************
zP = dMat == bsxfun(@plus, minC, minR);

starZ = zeros(n,1);
while any(zP(:))
    [r,c]=find(zP,1);
    starZ(r)=c;
    zP(r,:)=false;
    zP(:,c)=false;
end

while 1
%**************************************************************************
%   STEP 3: Cover each column with a starred zero. If all the columns are
%           covered then the matching is maximum
%**************************************************************************
    if all(starZ>0)
        break
    end
    coverColumn = false(1,n);
    coverColumn(starZ(starZ>0))=true;
    coverRow = false(n,1);
    primeZ = zeros(n,1);
    [rIdx, cIdx] = find(dMat(~coverRow,~coverColumn)==bsxfun(@plus,minR(~coverRow),minC(~coverColumn)));
    while 1
        %**************************************************************************
        %   STEP 4: Find a noncovered zero and prime it.  If there is no starred
        %           zero in the row containing this primed zero, Go to Step 5.  
        %           Otherwise, cover this row and uncover the column containing 
        %           the starred zero. Continue in this manner until there are no 
        %           uncovered zeros left. Save the smallest uncovered value and 
        %           Go to Step 6.
        %**************************************************************************
        cR = find(~coverRow);
        cC = find(~coverColumn);
        rIdx = cR(rIdx);
        cIdx = cC(cIdx);
        Step = 6;
        while ~isempty(cIdx)
            uZr = rIdx(1);
            uZc = cIdx(1);
            primeZ(uZr) = uZc;
            stz = starZ(uZr);
            if ~stz
                Step = 5;
                break;
            end
            coverRow(uZr) = true;
            coverColumn(stz) = false;
            z = rIdx==uZr;
            rIdx(z) = [];
            cIdx(z) = [];
            cR = find(~coverRow);
            z = dMat(~coverRow,stz) == minR(~coverRow) + minC(stz);
            rIdx = [rIdx(:);cR(z)];
            cIdx = [cIdx(:);stz(ones(sum(z),1))];
        end
        if Step == 6
            % *************************************************************************
            % STEP 6: Add the minimum uncovered value to every element of each covered
            %         row, and subtract it from every element of each uncovered column.
            %         Return to Step 4 without altering any stars, primes, or covered lines.
            %**************************************************************************
            [minval,rIdx,cIdx]=outerplus(dMat(~coverRow,~coverColumn),minR(~coverRow),minC(~coverColumn));            
            minC(~coverColumn) = minC(~coverColumn) + minval;
            minR(coverRow) = minR(coverRow) - minval;
        else
            break
        end
    end
    %**************************************************************************
    % STEP 5:
    %  Construct a series of alternating primed and starred zeros as
    %  follows:
    %  Let Z0 represent the uncovered primed zero found in Step 4.
    %  Let Z1 denote the starred zero in the column of Z0 (if any).
    %  Let Z2 denote the primed zero in the row of Z1 (there will always
    %  be one).  Continue until the series terminates at a primed zero
    %  that has no starred zero in its column.  Unstar each starred
    %  zero of the series, star each primed zero of the series, erase
    %  all primes and uncover every line in the matrix.  Return to Step 3.
    %**************************************************************************
    rowZ1 = find(starZ==uZc);
    starZ(uZr)=uZc;
    while rowZ1>0
        starZ(rowZ1)=0;
        uZc = primeZ(rowZ1);
        uZr = rowZ1;
        rowZ1 = find(starZ==uZc);
        starZ(uZr)=uZc;
    end
end

% Cost of assignment
rowIdx = find(validRow);
colIdx = find(validCol);
starZ = starZ(1:nRows);
vIdx = starZ <= nCols;
assignment(rowIdx(vIdx)) = colIdx(starZ(vIdx));
cost = trace(costMat(assignment>0,assignment(assignment>0)));

function [minval,rIdx,cIdx]=outerplus(M,x,y)
ny=size(M,2);
minval=inf;
for c=1:ny
    M(:,c)=M(:,c)-(x+y(c));
    minval = min(minval,min(M(:,c)));
end
[rIdx,cIdx]=find(M==minval);
