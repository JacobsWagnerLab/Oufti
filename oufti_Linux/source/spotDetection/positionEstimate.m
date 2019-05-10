function xy = positionEstimate(image)
image = double(image);
M0 = sum(image(:));
x = repmat(1:size(image,2),[size(image,1), 1]);
Mx = sum(sum(x.*image));
ay(:,1) = 1:size(image,1);
y = repmat(ay,[1,size(image,2)]);
My = sum(sum(y.*image));
xy = [Mx/M0, My/M0];
if isnan(xy),xy = [0,0];end
end