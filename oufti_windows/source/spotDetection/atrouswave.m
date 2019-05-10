function out = atrouswave(image,scale,lowPass,~,~)


%
% IN:
%       I - Image
%       J - Scale (number of decomposition levels)
%       ld - Detection level
%
% Example: out = atrouswave(I);
%


if nargin < 3
    % detection level
    ld = 1;
end
if nargin < 2
    % scale
    scale = 3;
end
%% low-pass filtering
if lowPass ~= 0
    lpfl = ceil(lowPass);
    image = padarray(image,[lpfl lpfl],'both','replicate');
    image = filter2(ones(lpfl)/lpfl^2,image,'same');
    image = image(lpfl+1:end-lpfl,lpfl+1:end-lpfl);
end


%% wavelet decomposition
% basic kernel
h = [1 4 6 4 1]/16;
% initialize Ai-1 with the original image
Aip = image;
W = zeros(size(image,1),size(image,2),scale);
% decomposition scales
for i = 1:scale
    % augmented kernel
    ha = [];
    for ind = 1:length(h)-1
        ha = [ha h(ind) zeros(1,2^(i-1)-1)];
    end
    ha = [ha h(ind+1)];
    Aippad = padarray(Aip,[floor(length(ha)/2) floor(length(ha)/2)],'symmetric');
    Ai = conv2(ha,ha',Aippad,'valid');
    W(:,:,i) = Aip - Ai;
    Aip = Ai;
end

%% detection
k = 3;
t = zeros(scale,1);
for tind = 1:scale
    frame = W(:,:,tind);
    t(tind) = k*mad(frame(:),1)/0.67;
    frame(frame<t(tind)) = 0;
    W(:,:,tind) = frame;
end
P = prod(W,3);
% % % out = abs(P)>ld;
out = P;
end