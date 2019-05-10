function sgn = getOneSignalM(mesh,mbox,img,rsz)
    % This function integrates signal confined within each segment of the
    % mesh. Two versions are provided. This one is a faster but less
    % precise MATLAB-based approximation.
    % 
    sgn = [];
    if length(mesh)>1
        img2 = imcrop(img,mbox);
        if rsz>1
            img2 = imresize(img2,rsz);
        end
        for i=1:size(mesh,1)-1
            plgx = rsz*([mesh(i,[1 3]) mesh(i+1,[3 1])]-mbox(1)+1);
            plgy = rsz*([mesh(i,[2 4]) mesh(i+1,[4 2])]-mbox(2)+1);
            mask = poly2mask(plgx,plgy,size(img2,1),size(img2,2));
            s = sum(sum(mask));
            if s>0, s=(rsz^(-2))*sum(sum(mask.*img2))*polyarea(plgx,plgy)/s; end
            sgn = [sgn;s];
        end
    end
end