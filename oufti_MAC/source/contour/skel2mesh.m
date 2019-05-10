function [pintx,pinty,q]=skel2mesh(sk)
    % This function finds intersections of ribs with the contour
    % To be used in "model2mesh" function
    
    if isempty(sk), pintx=[]; pinty=[]; q=false; return; end
    % Find the intersection of the skel with the contour closest to prevpoint
    pintx=[];
    pinty=[];
    [intX,intY,indS,indC]=intxyMulti(sk(:,1),sk(:,2),coord(:,1),coord(:,2));
    if isempty(intX) || isempty(indC) || isempty(prevpoint)
        q=false;
        return;
    end
    [~,ind] = min(modL(indC,prevpoint));
    prevpoint = indC(ind);
    indS=indS(ind);
    if indS>(size(sk,1)+1-indS)
        sk = sk(ceil(indS):-1:1,:);
    else
        sk = sk(floor(indS):end,:);
    end
    % 2. define the first pair of intersections as this point
    % 3. get the list of intersections for the next pair
    % 4. if more than one, take the next in the correct direction
    % 5. if no intersections found in the reqion between points, stop
    % 6. goto 3.
    % Define the lines used to compute intersections
    d=diff(sk,1,1);
    plinesx1 = repmat_(sk(1:end-1,1),1,2)+lng/stp*d(:,2)*[0 1];
    plinesy1 = repmat_(sk(1:end-1,2),1,2)-lng/stp*d(:,1)*[0 1];
    plinesx2 = repmat_(sk(1:end-1,1),1,2)+lng/stp*d(:,2)*[0 -1];
    plinesy2 = repmat_(sk(1:end-1,2),1,2)-lng/stp*d(:,1)*[0 -1];
    % Allocate memory for the intersection points
    pintx = zeros(size(sk,1)-1,2);
    pinty = zeros(size(sk,1)-1,2);
    % Define the first pair of intersections as the prevpoint
    pintx(1,:) = [intX(ind) intX(ind)];
    pinty(1,:) = [intY(ind) intY(ind)];
    prevpoint1 = prevpoint;
    prevpoint2 = prevpoint;
    
    % for i=1:size(d,1), plot(plinesx(i,:),plinesy(i,:),'r'); end % Testing
    q=true;
    fg = 1;
    jmax = size(sk,1)-1;
    for j=2:jmax
        % gdisp(['Use 1: ' num2str(size(plinesx1(j,:))) ' ' num2str(size(coord(:,1))) ' j=' num2str(j)]); % Testing
        [pintx1,pinty1,tmp,indC1]=intxyMulti(plinesx1(j,:),plinesy1(j,:),coord(:,1),coord(:,2),floor(prevpoint1),1);%
        [pintx2,pinty2,tmp,indC2]=intxyMulti(plinesx2(j,:),plinesy2(j,:),coord(:,1),coord(:,2),ceil(prevpoint2),-1);%
        if (~isempty(pintx1))&&(~isempty(pintx2))
            if pintx1~=pintx2
                if fg==3
                    break;
                end
                fg = 2;
                [prevpoint1,ind1] = min(modL(indC1,prevpoint1));
                [prevpoint2,ind2] = min(modL(indC2,prevpoint2));
                prevpoint1 = indC1(ind1); 
                prevpoint2 = indC2(ind2);
                pintx(j,:)=[pintx1(ind1) pintx2(ind2)];
                pinty(j,:)=[pinty1(ind1) pinty2(ind2)];
            else
                q=false;
                return
            end
        elseif fg==2
            fg = 3;
        end
    end
    pinty = pinty(pintx(:,1)~=0,:);
    pintx = pintx(pintx(:,1)~=0,:);
    [intX,intY,indS,indC]=intxyMulti(sk(:,1),sk(:,2),coord(:,1),coord(:,2));
    [prevpoint,ind] = max(modL(indC,prevpoint));
    pintx = [pintx;[intX(ind) intX(ind)]];
    pinty = [pinty;[intY(ind) intY(ind)]];
    nonan = ~isnan(pintx(:,1))&~isnan(pinty(:,1))&~isnan(pintx(:,2))&~isnan(pinty(:,2));
    pintx = pintx(nonan,:);
    pinty = pinty(nonan,:);
    clearvars -except pintx pinty q;
    
end