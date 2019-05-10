function initModel
    % used in "process" function to define a set of array (globals
    % variables) according to the chosen algorithm and some other
    % parameters. These arrays are used later in the corresponding
    % PDM-based model (algoritms 2 and 3)
    global coefPCA coefS mCell N weights dMax p
    if p.algorithm==2
        load(p.trainingFile,'coefPCA','latPCA','mCell')
        N = size(coefPCA,1)/2;
        coef4 = [mCell(:,1);mCell(:,2)];
        coef4max = sqrt(sum(coef4.^2));
        coef4 = coef4/coef4max;
        coefPCA = [[ones(N,1) zeros(N,1);zeros(N,1) ones(N,1)]/sqrt(N) coef4 coefPCA(:,1:p.Nkeep)];
        weights = 1*[1;1;1;sqrt(latPCA(1:p.Nkeep))/sqrt(latPCA(1))];
        dMax = (1/1)*sqrt(max((mCell(:,1)-mean(mCell(:,1))).^2+(mCell(:,2)-mean(mCell(:,2))).^2));
    elseif p.algorithm==3
        % scaleFactor
        load(p.trainingFile,'coefPCA','latPCA','mCell')
        if isfield(p,'scaleFactor'), mCell=mCell.*p.scaleFactor;
        else p.scaleFactor = 1;
        end
        N = size(coefPCA,1)/2;
        coef4 = sin([mCell(:,1);0*mCell(:,2)]/max(mCell(:,1))*pi/2);
        coef4max = sqrt(sum(coef4.^2));
        coef4 = coef4/coef4max;
        coefS = [ones(N,1) zeros(N,1);zeros(N,1) ones(N,1)]/sqrt(N);
        coefPCA = [coef4 coefPCA(:,1:p.Nkeep)];
        weights = 1*[1;1;1;0.98;0.98;0.98*sqrt(latPCA(1:p.Nkeep))/sqrt(latPCA(1))/2]; %08/18/08
        dMax = (1/1)*sqrt(max((mCell(:,1)-mean(mCell(:,1))).^2+(mCell(:,2)-mean(mCell(:,2))).^2));
    end
end