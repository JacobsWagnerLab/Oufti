function regions = splitOverlappedRegions(regionValue)
region = regionValue;
se = strel('diamond',3);
bw = cell2mat(bwboundaries(region));
if polyarea(bw(:,2),bw(:,1)) < 1000
    fsmoothValue = 20;
else
    fsmoothValue = 80;
end
bw = frdescp(bw);
bw = ifdescp(bw,fsmoothValue);
thres = graythreshreg(region);
regions = im2bw(region,thres);
cout = cpda(regionValue,1.5,0.7,0.2,10,0);
coutNew = [];
indexNum = [];
curveValue = 0;
for ii = 1:size(cout,1)
    tempIndex = [];
    for jj = 1:length(bw)
        if sum(ceil(bw(jj,:)) == cout(ii,:)) == 2 || sum(ceil(bw(jj,:))-1 == cout(ii,:)) == 2 || sum(ceil(bw(jj,:))+1 == cout(ii,:)) == 2
            tempIndex = jj;
            break;
        elseif sum(floor(bw(jj,:)) == cout(ii,:)) == 2 || sum(floor(bw(jj,:))-1 == cout(ii,:)) == 2 || sum(floor(bw(jj,:))+1 == cout(ii,:)) == 2
            tempIndex = jj;
            break;
        elseif sum(round(bw(jj,:)) == cout(ii,:)) == 2 || sum(round(bw(jj,:))-1 == cout(ii,:)) == 2 || sum(round(bw(jj,:))+1 == cout(ii,:)) == 2
            tempIndex = jj;
            break;
        end
    end
    try
        x1y1 = bw(tempIndex,:);
        x2y2 = bw(tempIndex+1,:);
        x3y3 = bw(tempIndex+2,:);
    catch
        x1y1 = bw(tempIndex,:);
        x2y2 = bw(tempIndex+1,:);
        x3y3 = bw(tempIndex-1,:);
    end
    try
        curveValue1 = 2*abs((x2y2(1,2)-x1y1(1,2)).*(x3y3(1,1) - x1y1(1,1))-(x3y3(1,2)-x1y1(1,2)).*(x2y2(1,1)-x1y1(1,1))) ./ ...
         sqrt(((x2y2(1,2)-x1y1(1,2)).^2+(x2y2(1,1)-x1y1(1,1)).^2)*((x3y3(1,2)-x1y1(1,2)).^2+(x3y3(1,1)- ...
         x1y1(1,1)).^2)*((x3y3(1,2)-x2y2(1,2)).^2+(x3y3(1,1)-x2y2(1,1)).^2)); 
    catch
        curveValue1 = 0;
    end
    try
        x1y1 = bw(tempIndex,:);
        x2y2 = bw(tempIndex-1,:);
        x3y3 = bw(tempIndex-2,:);
    catch
        x1y1 = bw(tempIndex,:);
        x2y2 = bw(tempIndex+1,:);
        x3y3 = bw(tempIndex-1,:);
    end
    try
        curveValue2 = 2*abs((x2y2(1,2)-x1y1(1,2)).*(x3y3(1,1) - x1y1(1,1))-(x3y3(1,2)-x1y1(1,2)).*(x2y2(1,1)-x1y1(1,1))) ./ ...
         sqrt(((x2y2(1,2)-x1y1(1,2)).^2+(x2y2(1,1)-x1y1(1,1)).^2)*((x3y3(1,2)-x1y1(1,2)).^2+(x3y3(1,1)- ...
         x1y1(1,1)).^2)*((x3y3(1,2)-x2y2(1,2)).^2+(x3y3(1,1)-x2y2(1,1)).^2)); 
    catch
        curveValue2 = 0;
    end
    curveValueDifference = abs(curveValue1-curveValue2);
    curveValueMean = (curveValue1 + curveValue2)/2;
    percentDifference = curveValueDifference/curveValueMean;
    if percentDifference < 0.65
% % if abs(sum(bw(tempIndex,1) - ([bw(tempIndex-3:tempIndex-1,1); bw(tempIndex:tempIndex+2,1)]))) >= 12
    coutNew = [coutNew ;cout(ii,:)]; %#ok<AGROW>
    indexNum = [indexNum;tempIndex]; %#ok<AGROW>
    end
end

if isempty(coutNew) || size(coutNew,1) == 1
     regions = im2bw(region,0.1);
    return;
elseif size(coutNew,1) == 2 || size(coutNew,1) == 3
    if size(coutNew,1)  == 2
       ind = getIndexBetweenTwoPoints(size(region),coutNew(1,2),coutNew(2,2),coutNew(1,1),coutNew(2,1));
       [Iadj,~,~] = neighbourND(ind,size(region));
       regions(Iadj) = 0;
       regions = bwlabel(regions,8);
       return
    else
        xx = 1;
        
    end
    
elseif size(coutNew,1) > 3
    
    xx = 1;
    
    
    
    
end













% % % % % % % % % % % % % % % indexToCurvePoints = zeros(size(bw,1),1);
% % % % % % % % % % % % % % % indexToAngles      = zeros(size(bw,1),1);
% % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % [~,angles] = curvaturePoints(bw);
% % % % % % % % % % % % % % % x1 = bw(1:end-2,2);
% % % % % % % % % % % % % % % x2 = bw(2:end-1,2);
% % % % % % % % % % % % % % % x3 = bw(3:end,2);
% % % % % % % % % % % % % % % y1 = bw(1:end-2,1);
% % % % % % % % % % % % % % % y2 = bw(2:end-1,1);
% % % % % % % % % % % % % % % y3 = bw(3:end,1);
% % % % % % % % % % % % % % % a = sqrt((x3-x2).^2+(y3-y2).^2); % a, b, and c are the three sides
% % % % % % % % % % % % % % % b = sqrt((x1-x3).^2+(y1-y3).^2);
% % % % % % % % % % % % % % % c = sqrt((x2-x1).^2+(y2-y1).^2);
% % % % % % % % % % % % % % % A = 1/2*(x1.*y2+x2.*y3+x3.*y1-x1.*y3-x2.*y1-x3.*y2);
% % % % % % % % % % % % % % % curvePoints = abs((4*A)./(a.*b.*c));
% % % % % % % % % % % % % % % threeStdCurvePoints = [];
% % % % % % % % % % % % % % % % % % if max(curvePoints) > 0.9
% % % % % % % % % % % % % % % % % %     angles = angles(~(curvePoints == max(curvePoints)));
% % % % % % % % % % % % % % % % % %     curvePoints = curvePoints(~(curvePoints == max(curvePoints)));
% % % % % % % % % % % % % % % % % %    
% % % % % % % % % % % % % % % % % % end
% % % % % % % % % % % % % % % indexToCurvePoints(logical(curvePoints)) = curvePoints > std(curvePoints)*3.2;
% % % % % % % % % % % % % % % indexToAngles(logical(curvePoints)) = curvePoints > std(curvePoints)*3.2;
% % % % % % % % % % % % % % % threeStdCurvePoints(:,1) = bw(logical(indexToCurvePoints),1);
% % % % % % % % % % % % % % % threeStdCurvePoints(:,2) = bw(logical(indexToCurvePoints),2);
% % % % % % % % % % % % % % % threeStdAngles = angles(find(indexToAngles == 1));
% % % % % % % % % % % % % % % newIndex = [];
% % % % % % % % % % % % % % % if length(threeStdCurvePoints(:,1)) >= 2
% % % % % % % % % % % % % % %     for ii = 2:length(threeStdCurvePoints)
% % % % % % % % % % % % % % %          if abs(threeStdCurvePoints(ii,1) - threeStdCurvePoints(ii-1,1)) < 4 && ...
% % % % % % % % % % % % % % %             abs(threeStdCurvePoints(ii,2) - threeStdCurvePoints(ii-1,2)) < 4
% % % % % % % % % % % % % % %             newIndex = [newIndex; ii-1]; %#ok<AGROW>
% % % % % % % % % % % % % % %          end
% % % % % % % % % % % % % % %     end
% % % % % % % % % % % % % % % end
% % % % % % % % % % % % % % % threeStdCurvePoints(newIndex,:) = [];
% % % % % % % % % % % % % % % threeStdAngles(newIndex) = [];
% % % % % % % % % % % % % % % indexToAngles = 24 < abs(threeStdAngles.*(180/pi)) | threeStdAngles < -0.57;
% % % % % % % % % % % % % % % threeStdCurvePoints = threeStdCurvePoints(indexToAngles,:);
% % % % % % % % % % % % % % % threeStdAngles = threeStdAngles(indexToAngles);
% % % % % % % % % % % % % % % NE = [0 0; 1 0; 2 0; 3 0; 4 0; 0 -1; 0 -2; 1 -1; 1 -2; 2 -1; 2 -2; 3 -1; 3 -2; 4 -1; 4 -2];
% % % % % % % % % % % % % % % NW = [0 0; 0 -1; 0 -2; -1 0; -2 0; -3 0; -4 0; -1 -1; -2 -1; -3 -1; -4 -1; -1 -2; -2 -2; -3 -2; -4 -2];
% % % % % % % % % % % % % % % SW = [0 0; -1 0; -2 0; -3 0; -4 0; 0 1; 0 2; -1 1; -1 2; -2 1; -2 2; -3 1; -3 2; -4 1; -4 2];
% % % % % % % % % % % % % % % SE = [0 0; 1 0; 2 0; 3 0; 4 0; 0 1; 0 2; 1 1; 1 2; 2 1; 2 2; 3 1; 3 2; 4 1; 4 2];
% % % % % % % % % % % % % % % fourNeighb = [0 0; -1 0; 1 0; 0 -1; -1 -1; 1 -1];
% % % % % % % % % % % % % % % for jj = 1:size(threeStdCurvePoints,1)
% % % % % % % % % % % % % % %     tempCoord = threeStdCurvePoints(jj,:);
% % % % % % % % % % % % % % %     neighbNE = NE +repmat(round(fliplr(tempCoord)), [15 1]);
% % % % % % % % % % % % % % %     neighbNW = NW +repmat(round(fliplr(tempCoord)), [15 1]);
% % % % % % % % % % % % % % %     neighbSW = SW +repmat(round(fliplr(tempCoord)), [15 1]);
% % % % % % % % % % % % % % %     neighbSE = SE +repmat(round(fliplr(tempCoord)), [15 1]);
% % % % % % % % % % % % % % %     reg1 = sum(sum(region(min(size(region,1),neighbNE(:,2)),min(neighbNE(:,1),size(region,2)))));
% % % % % % % % % % % % % % %     reg2 = sum(sum(region(min(size(region,1),neighbNW(:,2)),min(neighbNW(:,1),size(region,2)))));
% % % % % % % % % % % % % % %     reg3 = sum(sum(region(min(size(region,1),neighbSW(:,2)),min(neighbSW(:,1),size(region,2)))));
% % % % % % % % % % % % % % %     reg4 = sum(sum(region(min(size(region,1),neighbSE(:,2)),min(neighbSE(:,1),size(region,2)))));
% % % % % % % % % % % % % % %     allRegs = [reg1 reg2 reg3 reg4];
% % % % % % % % % % % % % % %     [~,indexToDirection] = min(allRegs);
% % % % % % % % % % % % % % %     directions = {'neighbNE','neighbNW','neighbSW','neighbSE'};
% % % % % % % % % % % % % % %     switch directions{indexToDirection}
% % % % % % % % % % % % % % %         case 'neighbNE'
% % % % % % % % % % % % % % %             xValue = round(tempCoord(2));
% % % % % % % % % % % % % % %             yValue = round(tempCoord(1));
% % % % % % % % % % % % % % %             region(yValue,xValue) = 1;
% % % % % % % % % % % % % % %              if abs(threeStdAngles(jj)*(180/pi)) > 70
% % % % % % % % % % % % % % %                 while region(yValue,xValue) == 1
% % % % % % % % % % % % % % %                     fourNeighbRegion = fourNeighb +repmat([yValue xValue], [6 1]);
% % % % % % % % % % % % % % %                     region(fourNeighbRegion(:,1),fourNeighbRegion(:,2)) = 0;
% % % % % % % % % % % % % % %                     xValue = xValue - 1;
% % % % % % % % % % % % % % %                     yValue = yValue + 4;
% % % % % % % % % % % % % % %                 end
% % % % % % % % % % % % % % %              else
% % % % % % % % % % % % % % %                  while region(yValue,xValue) == 1
% % % % % % % % % % % % % % %                     fourNeighbRegion = fourNeighb +repmat([yValue xValue], [6 1]);
% % % % % % % % % % % % % % %                     region(fourNeighbRegion(:,1),fourNeighbRegion(:,2)) = 0;
% % % % % % % % % % % % % % %                     xValue = xValue - 3;
% % % % % % % % % % % % % % %                     yValue = yValue + 2;
% % % % % % % % % % % % % % %                 end
% % % % % % % % % % % % % % %                  
% % % % % % % % % % % % % % %              end
% % % % % % % % % % % % % % %             
% % % % % % % % % % % % % % %         case 'neighbNW'
% % % % % % % % % % % % % % %             xValue = round(tempCoord(2));
% % % % % % % % % % % % % % %             yValue = round(tempCoord(1));
% % % % % % % % % % % % % % %             region(yValue,xValue) = 1;
% % % % % % % % % % % % % % %             neighb = [0 0; -1 0; 0 -2; 0 -3; 0 -4; 1 0; 0 -1; -1 -1; 1 -1];
% % % % % % % % % % % % % % %             if abs(threeStdAngles(jj)*(180/pi)) > 70
% % % % % % % % % % % % % % %                 try
% % % % % % % % % % % % % % %                     while region(yValue,xValue) == 1
% % % % % % % % % % % % % % %                         fourNeighbRegion = neighb +repmat([yValue xValue], [9 1]);
% % % % % % % % % % % % % % %                         region(fourNeighbRegion(:,1),fourNeighbRegion(:,2)) = 0;
% % % % % % % % % % % % % % %                         xValue = xValue + 5;
% % % % % % % % % % % % % % %                         yValue = yValue + 1;
% % % % % % % % % % % % % % %                     end
% % % % % % % % % % % % % % %                 catch 
% % % % % % % % % % % % % % %                 end
% % % % % % % % % % % % % % %             else
% % % % % % % % % % % % % % %                 while region(yValue,xValue) == 1
% % % % % % % % % % % % % % %                     fourNeighbRegion = fourNeighb +repmat([yValue xValue], [6 1]);
% % % % % % % % % % % % % % %                     region(fourNeighbRegion(:,1),fourNeighbRegion(:,2)) = 0;
% % % % % % % % % % % % % % %                     xValue = xValue + 1;
% % % % % % % % % % % % % % %                     yValue = yValue + 2;
% % % % % % % % % % % % % % %                 end
% % % % % % % % % % % % % % %             end
% % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % %         case 'neighbSW'
% % % % % % % % % % % % % % %             xValue = round(tempCoord(2));
% % % % % % % % % % % % % % %             yValue = round(tempCoord(1));
% % % % % % % % % % % % % % %             region(yValue,xValue) = 1;
% % % % % % % % % % % % % % %             if abs(threeStdAngles(jj)*(180/pi)) > 27
% % % % % % % % % % % % % % %                 while region(yValue,xValue) == 1
% % % % % % % % % % % % % % %                     fourNeighbRegion = fourNeighb +repmat([yValue xValue], [6 1]);
% % % % % % % % % % % % % % %                     region(fourNeighbRegion(:,1),fourNeighbRegion(:,2)) = 0;
% % % % % % % % % % % % % % %                     xValue = xValue + 1;
% % % % % % % % % % % % % % %                     yValue = yValue - 3;
% % % % % % % % % % % % % % %                 end
% % % % % % % % % % % % % % %             else
% % % % % % % % % % % % % % %                while region(yValue,xValue) == 1
% % % % % % % % % % % % % % %                     fourNeighbRegion = fourNeighb +repmat([yValue xValue], [6 1]);
% % % % % % % % % % % % % % %                     region(fourNeighbRegion(:,1),fourNeighbRegion(:,2)) = 0;
% % % % % % % % % % % % % % %                     xValue = xValue + 2;
% % % % % % % % % % % % % % %                     yValue = yValue - 1;
% % % % % % % % % % % % % % %                 end    
% % % % % % % % % % % % % % %             end
% % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % %         case 'neighbSE'
% % % % % % % % % % % % % % %             xValue = round(tempCoord(2));
% % % % % % % % % % % % % % %             yValue = round(tempCoord(1));
% % % % % % % % % % % % % % %             region(yValue,xValue) = 1;
% % % % % % % % % % % % % % %             if abs(threeStdAngles(jj)*(180/pi)) > 27
% % % % % % % % % % % % % % %                 neighb = [0 0; 0 -1; 0 1; 0 -1; -1 -1; 1 -1; 0 2; 0 3];
% % % % % % % % % % % % % % %                 while region(yValue,xValue) == 1
% % % % % % % % % % % % % % %                     fourNeighbRegion = neighb +repmat([yValue xValue], [8 1]);
% % % % % % % % % % % % % % %                     region(fourNeighbRegion(:,1),fourNeighbRegion(:,2)) = 0;
% % % % % % % % % % % % % % %                     xValue = xValue - 3;
% % % % % % % % % % % % % % %                     yValue = yValue - 1;
% % % % % % % % % % % % % % %                 end
% % % % % % % % % % % % % % %             else
% % % % % % % % % % % % % % %                 
% % % % % % % % % % % % % % %                 while region(yValue,xValue) == 1
% % % % % % % % % % % % % % %                     fourNeighbRegion = fourNeighb +repmat([yValue xValue], [6 1]);
% % % % % % % % % % % % % % %                     region(fourNeighbRegion(:,1),fourNeighbRegion(:,2)) = 0;
% % % % % % % % % % % % % % %                     xValue = xValue - 1;
% % % % % % % % % % % % % % %                     yValue = yValue - 2;
% % % % % % % % % % % % % % %                 end
% % % % % % % % % % % % % % %             end
% % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % %     end
% % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % end

regions = imopen(region,se);
regions = bwlabel(regions,8);

end % end of function splitOverlappedRegions

function [points,angles] = curvaturePoints(input)

x_1 = diff(input(:,1));
x_2 = diff(input(:,1),2);
x_2(end+1) = x_1(1);
y_1 = diff(input(:,2));
y_2 = diff(input(:,2),2);
y_2(end+1) = x_1(1);

points = abs((x_1.*y_2) - (y_1.*x_2))./sqrt((x_1.^2 + y_1.^2).^3);
angles = atan(y_1./x_1);
end



function [sampled_outline] = sampleOutline(nby2polygon)
% nby2polygon is what it says it is and will be resampled to a polygon of
% the same shape but with fewer vertices
nby2polygon(diff(nby2polygon(:,1)) == 0,:) = [];
nby2polygon(diff(nby2polygon(:,2)) == 0,:) = [];
if nby2polygon(1,1) ~= nby2polygon(end,1) || nby2polygon(1,2) ~= nby2polygon(end,2)
    nby2polygon(end+1,1:2) = nby2polygon(1,:);
end

ndlen = size(nby2polygon,1);

error_max = .015;
sampled_outline = nby2polygon(1,:);
ix = 1;

while ix(end) < ndlen
    bins = 3;
    ix = ix(end):min([ix(end)+bins-1, ndlen]);
    x = nby2polygon(ix,1);
    y = nby2polygon(ix,2);
    %fit a straight line through the data points, and remember the error
    
    [~, e] = linfitfn(x,y);
    
    while e < error_max
        bins = bins + 1;
        ix = ix(end):min([ix(end)+bins-1, ndlen]);
        x = nby2polygon(ix,1);
        y = nby2polygon(ix,2);
        [~, er] = linfitfn(x,y);
        %add er to e and.....
        %faster than an if statement
        e = (e+er)+(length(ix)==1)*error_max;
    end
    
    %and keep the point of the polygon where the error limit is exceeded
    sampled_outline(end+1,1:2) = nby2polygon(ix(end),1:2);
end

function d=edist(x1,y1,x2,y2)
    % complementary for "getextradata", computes the length between 2 points
    d=sqrt((x2-x1).^2+(y2-y1).^2);
end  

end