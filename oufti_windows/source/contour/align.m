function [pcc,ftq] = align(im,mpx,mpy,ngmap,pcc,p,f,roiBox,thres,celldata)
% A modification of align function with adding non-linear bending
% 
% Parameters: 
% p.fitDisplay1, p.fitConvLevel1, p.fitMaxIter1, p.fitStep1 - 1st frame
% p.fitDisplay, p.fitConvLevel, p.fitMaxIter, p.fitStep - refine step
% f = true - region fitting (frame=1), else - refinement step (frame>=1)
% 
% New model array (pcc) includes:
% 1   - rotation
% 2   - bending
% 3,4 - shift
% 5   - stretching along x
% 6-  - other parameters deternimed by the principal components analysis
global coefPCA coefS N weights dMax mCell

    pcc = reshape(pcc,[],1);
    if f % fitting to "mask"
        dsp = p.fitDisplay;
        lev = 0.0005;
        amax = p.fitMaxIter;
        stp = p.fitStep;
    else % fitting to the force field
        dsp = p.fitDisplay;
        lev = 0.0005;
        amax = p.fitMaxIter;
        stp = p.fitStep;
    end
    if dsp
        fig = createdispfigure([celldata f]);
        nextstop = 1;
        contmode = false;
    else
        nextstop = Inf;
    end
    
    weights2 = weights.^p.rigidity;
    Kstp = 1;
            % if p.algorithm==2, Kstp=ones(4+p.Nkeep,1); end
            % if p.algorithm==3, Kstp=ones(5+p.Nkeep,1); end

    [cCell,cCell2] = model2geom(pcc,p.algorithm,coefPCA,mCell);
    if isempty(cCell), pcc=[]; ftq=0; return; end
    for a=1:amax
        % Compute forces
        xCell = cCell(:,1);
        yCell = cCell(:,2);
        Fx = interp2a(1:roiBox(3)+1,1:roiBox(4)+1,mpx,xCell,yCell,'linear',0);
        Fy = interp2a(1:roiBox(3)+1,1:roiBox(4)+1,mpy,xCell,yCell,'linear',0);

        if ~f % for alignment to the image
            Tx = -(circShiftNew(cCell(:,2),-1) - circShiftNew(cCell(:,2),1));
            Ty = -(circShiftNew(cCell(:,1),1) - circShiftNew(cCell(:,1),-1));
            dtxy = sqrt(Tx.^2+Ty.^2);%sqrt(sum(Tx.^2 + Ty.^2)/N);
            Tx = Tx./dtxy;
            Ty = Ty./dtxy;
            TxM = repmat(cCell(:,1),1,p.attrRegion+1)+Tx*(0:p.attrRegion);
            TyM = repmat(cCell(:,2),1,p.attrRegion+1)+Ty*(0:p.attrRegion);
            Clr0 = interp2a(1:roiBox(3)+1,1:roiBox(4)+1,im,TxM,TyM,'linear',0);
            Clr = 1-1./(1+(Clr0/thres/p.thresFactorF).^p.attrPower);
            are = polyarea(cCell(:,1),cCell(:,2));
            Tnr = - p.neighRepA * interp2a(1:roiBox(3)+1,1:roiBox(4)+1,ngmap,xCell,yCell,'linear',0);
            % T = p.attrCoeff * sum(Clr,2) - p.repCoeff * (are<p.repArea*p.areaMax) * (1-Clr(:,1)) + Tnr;
            T = p.attrCoeff * mean(Clr(:,p.attrRegion+1:end),2) - p.repCoeff * (are<p.repArea*p.areaMax) * (1-mean(Clr(:,1:p.attrRegion+1),2)) + Tnr;
            Tx = Tx.*T;
            Ty = Ty.*T;
            F = [-Fx;Fy] + [Tx;Ty]; % F is a vector of forces in the image frame of reference
        else % for pre-alignment to the mask
            Tx = -(circShiftNew(cCell(:,2),-1) - circShiftNew(cCell(:,2),1));
            Ty = -(circShiftNew(cCell(:,1),1) - circShiftNew(cCell(:,1),-1));
            dtxy = sqrt(sum(Tx.^2 + Ty.^2)/N);
            Tx = Tx/dtxy;
            Ty = Ty/dtxy;
            TxM = repmat(cCell(:,1),1,p.attrRegion+1)+Tx*(0:p.attrRegion);
            TyM = repmat(cCell(:,2),1,p.attrRegion+1)+Ty*(0:p.attrRegion);
            Clr0 = interp2a(1:roiBox(3)+1,1:roiBox(4)+1,im,TxM,TyM,'linear',0);
            Clr = 1-1./(1+(Clr0/thres/p.thresFactorF).^p.attrPower); % ?
            are = polyarea(cCell(:,1),cCell(:,2));
            T = p.attrCoeff * sum(Clr,2) - p.repCoeff * (are<p.repArea*p.areaMax) * (1-Clr(:,1));
            Tx = Tx.*T;
            Ty = Ty.*T;
            F = [-Fx;Fy] + [Tx;Ty]; % F is a vector of forces in the image frame of reference
        end
        if p.algorithm==2
            F2 = M(reshape(F,[],2),-pcc(1));
            F2 = [F2(:,1);F2(:,2)];
            Fpc = weights.*([coefPCA(:,1:2)'*F;coefPCA(:,3:end)'*F2]);

            % rigidity forces
            Fpc = Fpc - p.rigidity*[0;0;0;ones(p.Nkeep,1)].*(pcc(2:end).^3).*(1./(weights.^2)-1);

            %Fpc = ([coefPCA(:,1:2)'*F;coefPCA(:,3:end)'*F2]);
            if max(Fpc.^2)>0, Fpc = Fpc/max(Fpc.^2).^0.25; end

            % Compute torque
            Mm = sum( - Fx.*(yCell-mean(yCell)) - Fy.*(xCell-mean(xCell)) )/N/dMax/dMax;
            pcc(1) = pcc(1) + Mm;
            
            if a>1, Fpc2old=Fpc2; end
            Fpc2 = [Mm;Fpc];
        elseif p.algorithm==3
            % Check 1
            F2 = M(reshape(F,[],2),-pcc(3)); % F2 is a vector of forces in the cell frame

            F3 = Bf(cCell2,F2,pcc(4)); % F3 is a vector of forces in the unbent cell frame
            F3y = F3(:,2); % Only y componet affects the bending in unbent cell frame

            F3 = [F3(:,1);F3(:,2)];
            Fpc = weights(5:end).*(coefPCA'*F3);
            % Fpc is a vector of forces acting on the linear components
            
            % if f % Fitting to mask ???????????
            %     Fpc(1) = Fpc(1) + 0*weights(5);
            % end
            
            % Add rigidity forces
            % Fpc = Fpc - p.rigidity*[0;ones(p.Nkeep,1)].*(pcc(5:end).^3).*(1./(weights(5:end).^2)-1);
            pcc = pcc.*weights2; % Imposing rigidity, modified from a force method 08/18/08

            % Compute torque
            Mm = sum( - Fx.*(yCell-mean(yCell)) - Fy.*(xCell-mean(xCell)) )/N/dMax/dMax;

            % Compute bending "torque", must be done in the unbent cell frame
            Bm = -sum((F3y-mean(F3y)).*cCell2(:,1).^2)/N/dMax/dMax/dMax;

            % Normalize Fpc
            if a>1, Fpc2old=Fpc2; end
            Fpc2 = [weights(1:4).*[coefS'*F;Mm;Bm];Fpc];
            if max(Fpc.^2)>0, Fpc2 = Fpc2/max(Fpc2.^2).^0.25; end
        end
        
        if a>1
            K = sum(sign(Fpc2.*Fpc2old))/(5+p.Nkeep);
            if K<0.3
                Kstp=Kstp/1.5;
            elseif K>0.7
                Kstp=min(1,Kstp.*1.5);
            end
        end
        % Shift & transform
        pcc = pcc + Kstp*stp*p.scaleFactor*Fpc2;
        [cCell,cCell2] = model2geom(pcc,p.algorithm,coefPCA,mCell);
        
        % if a>1
        %     K = sign(Fpc2.*Fpc2old);
        %     Kstp(K>0) = min(1,Kstp(K>0).*1.5);
        %     Kstp(K<0) = Kstp(K<0)/1.5;
        % end
        % Shift & transform
        % pcc = pcc + Kstp.*stp.*Fpc2;
        % [cCell,cCell2] = model2geom(pcc,p.algorithm);
        
        if a>=nextstop % Displaying results
            figure(fig)
            %emap = emap-min(min(emap));
           % image(repmat(im,[1 1 3])/max(max(im+0)));
            %colormap(gray(2));
            imshow(im,[]);
            set(gca,'nextplot','add');
            plot(cCell(:,1),cCell(:,2));
            for b=1:N/2-1; plot(cCell([b N-b],1),cCell([b N-b],2),'m');end
            quiver(cCell(:,1),cCell(:,2),-3*Fx,3*Fy,0,'r');
            %quiver(cCell(:,1),cCell(:,2),Tx,Ty,0,'y');
            set(gca,'nextplot','replace');
            setdispfiguretitle(fig,celldata,a)
            drawnow
            if ~contmode || a==p.fitMaxIter
                waitfor(fig,'UserData');
                if ishandle(fig)
                    u = get(fig,'UserData');
                else
                    u = 'stop';
                end
                if strcmp(u,'next')
                    nextstop = a+1;
                elseif strcmp(u,'next100')
                    nextstop = a+100;
                elseif strcmp(u,'skip')
                    nextstop = Inf;
                elseif strcmp(u,'continue')
                    nextstop = a+1;
                    contmode = 1;
                elseif strcmp(u,'stop')
                    % ftq = sum(abs(Fpc2))/length(Fpc2);
                    % break;
                    error('Testing mode terminated')
                elseif strcmp(u,'debug')
                   dbstop if warning Oufti:DebugStop
                   warning('Oufti:DebugStop','Program stopped in debugger')
                end
                set(fig,'UserData','');
            end
            pause(0.05);
        end

        % Condition to finish
        ftq = sum(abs(Fpc2))/length(Fpc2);
        if ftq<lev; break; end
    end
    pcc = reshape(pcc,1,[]);
    % evaluate the result by some "closeness" criterium
    % fitquality - is a weighter mean square deviation from the average
    % cell in pixels. Typical values: 1-2
    % TODO: The rejection value should be estimated from image analysis
    % ftq =sum((interp2a(1:roiBox(3)+1,1:roiBox(4)+1,emap,xCell,yCell,'linear',0)).^2);
    % ftq = sum((interp2a(1:roiBox(3)+1,1:roiBox(4)+1,emap,xCell,yCell,'linear',0)).^4);
end