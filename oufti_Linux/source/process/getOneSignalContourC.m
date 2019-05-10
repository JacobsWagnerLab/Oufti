function sgn = getOneSignalContourC(contour,mbox,img,rsz)
    % This function integrates signal confined within the contour (which is 
    % not segmented in the way the mesh is). This is a slower but more
    % precise C-based function (requires 'aip' function to run).
    % 
    if length(contour)>1
        img2 = imcrop(img,mbox);
        if rsz>1
            img2 = imresize(img2,rsz);
        end
        c = repmat(1:size(img2,2),size(img2,1),1);
        r = repmat((1:size(img2,1))',1,size(img2,2));
        plgx = rsz*(contour(:,1)-mbox(1)+1);
        plgy = rsz*(contour(:,2)-mbox(2)+1);
        [plgx,plgy] = poly2cw(plgx,plgy); % making contour clockwise
        [plgx2,plgy2] = expandpoly(plgx,plgy,1.42,1); % making contours clockwise
        if sum(isnan(plgx2))>0, sgn=[]; return; end
        mask = poly2mask(plgx2,plgy2,size(img2,1),size(img2,2));
        f = find(mask);
        int = 0;
        if ~isempty(f)
            for px=f'
                 int = int+img2(px)*aip(plgx,plgy,c(px)-0.5,r(px)-0.5);
            end
        end
        sgn = sum(int);
    end
end