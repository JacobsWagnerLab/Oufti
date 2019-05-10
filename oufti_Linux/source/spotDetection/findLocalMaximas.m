function maxValues = findLocalMaximas(tempImage)

[r,c] = size(tempImage);

[~, pixvals] = sort(tempImage(:),'descend');
[n, m] = meshgrid(1:c,1:r);
n = n(pixvals);
m = m(pixvals);
% % % maxValues = [];
% % % values = double(tempImage(tempImage>0));
% % % [~,b] = peakfinderSpots(values,(max(values)-min(values))/4);
% % % [a1,~] = sort(b,'descend');
% % % 
% % % for ii = 1:length(a1)
% % %     [y,x] = find(tempImage == a1(ii));
% % %     maxValues = [maxValues; x(1),y(1),a1(ii)];
% % % end
% % % dxy = ((maxValues(:,1) - maxValues(1,1)).^2 + (maxValues(:,2) - maxValues(1,2)).^2).^(1/2);
% % % dxy = round(dxy);
% % % [~,yy] = unique(dxy);
% % % maxValues = maxValues(yy,1:3);
% % % dxy = ((maxValues(:,1) - maxValues(1,1)).^2 + (maxValues(:,2) - maxValues(1,2)).^2).^(1/2);
% % % dxy = round(dxy);
% % % xx = dxy>2;
% % % maxValues = [maxValues(1,1:3); maxValues(xx,1:3)];
% % % if size(maxValues,1) > 4
% % %     maxValues = maxValues(1:4,:);
% % % end

kx0 = max(tempImage(:));
[y0,x0] = find(tempImage == max(tempImage(:)));

dxy = ((n - x0(1)).^2 + (m - y0(1)).^2).^(1/2);

nextpeak = find(dxy > 1.6,1);
x1= n(nextpeak);
y1 = m(nextpeak);
kx1 = pixvals(nextpeak);

dxy1 = ((n - x1(1)).^2 + (m - y1(1)).^2).^(1/2);
nextpeak = find(dxy1 > 2,1);

x2= n(nextpeak);
y2 = m(nextpeak);
kx2 = pixvals(nextpeak);

dxy2 = ((n - x2(1)).^2 + (m - y2(1)).^2).^(1/2)-3;
nextpeak = find(dxy2 > 2.5,1);

x3= n(nextpeak);
y3 = m(nextpeak);
kx3 = pixvals(nextpeak);

dxy3 = ((n - x3(1)).^2 + (m - y3(1)).^2).^(1/2);
nextpeak = find(dxy3 > 3,1);

x4= n(nextpeak);
y4 = m(nextpeak);
kx4 = pixvals(nextpeak);

maxValues = [x0(1),y0(1);x1,y1;x2,y2;x3,y3;x4,y4];
maxValues = unique(maxValues,'rows');

for jj = 1:4
    maxValuesTemp = maxValues;
    for ii = 1:size(maxValues,1) - 1
        if maxValues(ii,1) == 1 && maxValues(ii,2) == 1
            maxValuesTemp(ii,:) = NaN;
            continue;
        end
        diff = abs(maxValues(ii,:) - maxValues(ii+1,:));
        if (diff(1) + diff(2)) < 2.5 || (diff(1) + diff(2)) > 20
            maxValuesTemp(ii,:) = NaN;
        end
    end
    notNaN = ~isnan(maxValuesTemp);
    x = maxValues(notNaN(:,1),1);
    y = maxValues(notNaN(:,2),2);
    maxValues = zeros(numel(x),2);
    maxValues(:,1)  = x;
    maxValues(:,2)  = y;
end




end
