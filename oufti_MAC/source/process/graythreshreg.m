function res = graythreshreg(img,varargin)
    % threshold calculated in a regionSelectionRect region
    if ~isempty(varargin), flevel=varargin{1}; else flevel=0; end
    global regionSelectionRect
    sz = size(img);
    if isempty(regionSelectionRect)
       res = graythresh2(img(ceil(sz(1)*0.05):floor(sz(1)*0.95),ceil(sz(2)*0.05):floor(sz(2)*0.95),1));
    else
        res = graythresh2(imcrop(img,regionSelectionRect));
    end
    function b=graythresh2(a)
        if flevel>0
            if gpuDeviceCount == 1
                c = reshape(a,1,[]);
                c = sort(c);
                level = c(ceil(min(flevel,1)*length(c)));
                b = graythresh(gather(c(c>=level)));
            else
                c = reshape(a,1,[]);
                c = sort(c);
                level = c(ceil(min(flevel,1)*length(c)));
                b = graythresh(c(c>=level));
            end
        else
            if isa(a,'gpuArray')
                b = graythresh(gather(a));
            else
                b = graythresh(a);
            end
        end
    end
end