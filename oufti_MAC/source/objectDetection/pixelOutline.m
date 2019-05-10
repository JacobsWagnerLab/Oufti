function [nxy] = pixelOutline(binaryIM)
% % % %binaryIM should be a binary image. This function walks counterclockwise
% % % %around regions of ones and returns coordinates of pixel vertices suitable
% % % %for plotting on top of an image to outline a region of interest.
% % % 
% % % bw = bwconncomp(binaryIM,8);
% % % bw = bw.PixelIdxList;
% % % del = cellfun(@(x) length(x)<20,bw).*(1:length(bw));
% % % del(del==0)=[];
% % % bw(del)=[];
% % % nxy = cell(1,length(bw));
% % % [sz1 sz2] = size(binaryIM);
% % % 
% % % gix = [2 1 8;3 inf 7;4 5 6];
% % % indwin = [-sz1-1, -1, sz1-1;-sz1 0 sz1; -sz1+1 +1 +sz1+1];
% % % padwin = [nan 5 nan; 7 nan 3;nan 1 nan];
% % % padwin1 = [nan 1 nan; 3 nan 7; nan 5 nan];
% % % yr = {[.5 .5], [], [.5 -.5], [], [-.5 -.5], [], [-.5 .5], [], [.5 .5]};
% % % xr = {[-.5 .5], [], [.5 .5], [], [.5 -.5], [], [-.5 -.5], [], [-.5 .5]};
% % % for n = 1:length(bw)
% % %     mask = false(sz1,sz2);
% % %     mask(bw{n}) = 1;
% % % 
% % %     ix = bw{n};
% % %     r = (rem(ix-1,sz1)+1);
% % %     c = (ceil(ix./sz1));
% % % 
% % %     %N
% % %     eN = ix(r == 1);
% % %     tmp = setdiff(ix, eN);
% % %     N = ix(mask(tmp - 1) == 0);
% % %     N = cat(1,N, eN);
% % %     %W
% % %     eW = ix(c == 1);
% % %     tmp = setdiff(ix, eW);
% % %     W = ix(mask(tmp - sz1) == 0);
% % %     W = cat(1, W, eW);
% % %     %S
% % %     eS = ix(r == sz1);
% % %     tmp = setdiff(ix,eS);
% % %     S = ix(mask(tmp + 1) == 0);
% % %     S = cat(1,S, eS);
% % %     %E
% % %     eE = ix(c == sz2);
% % %     tmp = setdiff(ix,eE);
% % %     E = ix(mask(tmp + sz1) == 0);
% % %     E = cat(1,E,eE);
% % % 
% % %     ed = cat(1,N,W,S,E);
% % %     mask = false(sz1,sz2);
% % %     mask(ed) = 1;
% % % 
% % %     nx = []; ny = [];
% % %     fi = max(ed);
% % %     ordered = [];
% % %     try
% % %     while ~isempty(ed)
% % %         %matrix of pixel locations
% % %         ordered(end+1) = fi;
% % %         pxmat = indwin + fi;
% % %         win = mask(pxmat);
% % %         tmp = win.*gix;
% % %         tmp(tmp == 0) = inf;
% % %         mask(fi) = 0;
% % %         [~, filoc] = min(tmp(:));
% % %         y = (rem(fi-1,sz1)+1);
% % %         x = (ceil(fi./sz1));
% % %         im2win = ~binaryIM(pxmat).*padwin;
% % %         im2win(im2win == 0) = nan;
% % %         if any(diff(sort(im2win(~isnan(im2win)))) - 2)
% % %             im2win1 = ~binaryIM(pxmat).*padwin1;
% % %             im2win1(im2win1 == 0) = nan;
% % %             [~,io] = sort(im2win1(:));
% % %             edgeind = im2win(io);
% % %         else
% % %             edgeind = sort(im2win(:));
% % %         end
% % %         
% % %         edgeind(isnan(edgeind)) = [];
% % %         vL = length(edgeind);
% % %         nx(end+1:end+2*vL) = cat(2,xr{edgeind}) + x;
% % %         ny(end+1:end+2*vL) = cat(2,yr{edgeind}) + y;
% % %         ed(ed==fi) = [];    
% % %         fi = pxmat(filoc);
% % %     end
% % %     catch
% % %         xx = 1;
% % %     end
% % %     nxy{n} = [nx' ny'];
% % % end

%binaryIM should be a binary image. This function walks counterclockwise
%around regions of ones and returns coordinates of pixel vertices suitable
%for plotting on top of an image to outline a region of interest.
 
if nargin == 1
    %treat binaryIM as a binaryIM
    bw = bwconncomp(binaryIM,8);
    bw = bw.PixelIdxList;
    [sz1 sz2] = size(binaryIM);
else
    %arguments 2 and 3 must be size(image,1) and size(image,2),
    %respectively
    bw = {binaryIM};
    binaryIM = zeros(sz1,sz2);
    binaryIM(bw{1}) = 1;
end


nxy = cell(1,length(bw));

gix = [2 1 8;3 inf 7;4 5 6];
indwin = [-sz1-1, -1, sz1-1;-sz1 0 sz1; -sz1+1 +1 +sz1+1];
padwin = [nan 5 nan; 7 nan 3;nan 1 nan];
padwin1 = [nan 1 nan; 3 nan 7; nan 5 nan];
yr = {[.5 .5], [], [.5 -.5], [], [-.5 -.5], [], [-.5 .5], [], [.5 .5]};
xr = {[-.5 .5], [], [.5 .5], [], [.5 -.5], [], [-.5 -.5], [], [-.5 .5]};
for n = 1:length(bw)
    %ignore any unclosed pixelated polgons
    skip = false;
    for z = 1:length(bw{n})
        count1s = binaryIM(indwin + bw{n}(z));
        %sum(count1s(:)) == 1 for an isolated pixel, == 2 for a singly
        %connected pixel and ==3 for a doubly connected pixel....
        if sum(count1s(:)) < 3
            skip = true;
            break
        end
    end
    if skip, continue, end
    mask = zeros(sz1,sz2);
    mask(bw{n}) = 1;

    ix = bw{n};
    r = (rem(ix-1,sz1)+1);
    c = (ceil(ix./sz1));

    %N
    eN = ix(r == 1);
    tmp = setdiff(ix, eN);
    N = ix(mask(tmp - 1) == 0);
    N = cat(1,N, eN);
    %W
    eW = ix(c == 1);
    tmp = setdiff(ix, eW);
    W = ix(mask(tmp - sz1) == 0);
    W = cat(1, W, eW);
    %S
    eS = ix(r == sz1);
    tmp = setdiff(ix,eS);
    S = ix(mask(tmp + 1) == 0);
    S = cat(1,S, eS);
    %E
    eE = ix(c == sz2);
    tmp = setdiff(ix,eE);
    E = ix(mask(tmp + sz1) == 0);
    E = cat(1,E,eE);

    ed = cat(1,N,W,S,E);
    mask = zeros(sz1,sz2);
    mask(ed) = 1;

    nx = []; ny = [];
    fi = max(ed);
    ordered = [];
    while ~isempty(ed)
        %matrix of pixel locations
        ordered(end+1) = fi;
        pxmat = indwin + fi;
        
        win = mask(pxmat);
        if sum(win(:)) == 0
            nx = [];
            ny = [];
            break
        end
        
        tmp = win.*gix;
        tmp(tmp == 0) = inf;
        mask(fi) = 0;
        [~, filoc] = min(tmp(:));
        y = (rem(fi-1,sz1)+1);
        x = (ceil(fi./sz1));
        
        im2win = ~binaryIM(pxmat).*padwin;
        im2win(im2win == 0) = nan;
        if any(diff(sort(im2win(~isnan(im2win)))) - 2)
            im2win1 = ~binaryIM(pxmat).*padwin1;
            im2win1(im2win1 == 0) = nan;
            [~,io] = sort(im2win1(:));
            edgeind = im2win(io);
        else
            edgeind = sort(im2win(:));
        end
        
        edgeind(isnan(edgeind)) = [];
        vL = length(edgeind);
        nx(end+1) = x;
        ny(end+1) =  y;
        ed(ed==fi) = [];    
        fi = pxmat(filoc);
    end
    
        nxy{n} = [nx' ny'];
        if length(nx) < 5, continue, end
        nxy{n}(end+1,1:2) = nxy{n}(1,:);
    
end
nxy(cellfun(@isempty, nxy)) = [];



end