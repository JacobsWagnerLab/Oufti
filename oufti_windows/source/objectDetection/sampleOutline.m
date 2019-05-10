function [sampled_outline] = sampleOutline(nby2polygon)
% nby2polygon is what it says it is and will be resampled to a polygon of
% the same shape but with fewer vertices

nby2polygon(diff(nby2polygon(:,1)) == 0,:) = [];
nby2polygon(diff(nby2polygon(:,2)) == 0,:) = [];
if nby2polygon(1,1) ~= nby2polygon(end,1) || nby2polygon(1,2) ~= nby2polygon(end,2)
    nby2polygon(end+1,1:2) = nby2polygon(1,:);
end

ndlen = size(nby2polygon,1);

error_max = .02;
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

end