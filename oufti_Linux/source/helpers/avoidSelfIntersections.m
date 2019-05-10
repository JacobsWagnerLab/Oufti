function [xCell,yCell] = avoidSelfIntersections(xCell,yCell)

[i1,i2]=intxySelfC(double(xCell),double(yCell));

iMovCurveArr = []; xMovCurveArr = []; yMovCurveArr = [];
L = size(xCell,1);
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

end