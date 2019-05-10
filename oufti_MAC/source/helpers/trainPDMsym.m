function trainPDM

N=52;
% Opening a mesh file
[FileName,PathName] = uigetfile('*.mat','Select File with Mesh Data...');
load([PathName '\' FileName],'meshResultsInFile');

% Now building an array (cellArray) of the training set points
cellArray=[];
for frame=1:length(meshResultsInFile)
    for cell=1:length(meshResultsInFile{frame})
        %Convert polygons to contour
        plg=meshResultsInFile{frame}{cell};
        if isempty(plg), continue; end
        ctr = [reshape(plg(1,:,1:end-1),2,[])';plg(2,:,end);plg(1,:,end);plg(3,:,end);flipud(reshape(plg(4,:,1:end-1),2,[])')];
        dctr=diff(ctr,1,1);
        len=cumsum([0;sqrt((dctr.*dctr)*[1;1])]);
        l=length(ctr)-1;
        len1=linspace(0,len(l/2+1),N/2+1);
        len2=linspace(len(l/2+1),len(end),N/2+1);
        len3=[len1(1:end-1) len2];
        ctr1=interp1(len,ctr,len3);
        ctr2=ctr1(2:end,:);%The first and last points are no more the same. The end points are N/2 and N
        ctr2(:,1)=mean(ctr2(:,1))-ctr2(:,1);
        ctr2(:,2)=mean(ctr2(:,2))-ctr2(:,2);
        if len3(end)<5*sqrt(sum((ctr2(N/2,:)-ctr2(N,:)).^2,2))
            cellArray=cat(3,cellArray,ctr2);
        end
    end
end
disp('Mesh data loaded')
ncells = size(cellArray,3);
        
% Prealigning the set
for i=1:ncells;
    cCell = cellArray(:,:,i);
    alpha = angle(cCell(N,1)+j*cCell(N,2)-(cCell(N/2,1)+j*cCell(N/2,2)));
    cCell = M(cCell,1,alpha);
    cen = (cCell(ceil(N/4),1)+cCell(ceil(N*3/4),1)+j*cCell(ceil(N/4),2)+j*cCell(ceil(N*3/4),2))/2;
    alpha = angle(cCell(N/2,1)+j*cCell(N/2,2)-cen);
    if alpha>0, cCell(:,2)=-cCell(:,2); cCell=flipud(circshift(cCell,1)); end
    cellArray(:,:,i) = cCell;
end
disp('Cells prealigned')
    
        % %Reflecting cells
        % cen=(ctr2(ceil(N/4),1)+ctr2(ceil(N*3/4),1)+j*ctr2(ceil(N/4),2)+j*ctr2(ceil(N*3/4),2))/2;
        % alpha=angle(ctr2(N,1)+j*ctr2(N,2)-cen)-angle(ctr2(N/2,1)+j*ctr2(N/2,2)-cen);
        % if alpha<0, ctr2(:,2)=-ctr2(:,2); end

cellArray2 = cellArray;
cellArray2(:,2,:) = -cellArray2(:,2,:);
cellArray2 = flipdim(circshift(cellArray2,1),1);

cellArray = cat(3,cellArray,cellArray2);
w=ones(N,1);
%w2=repmat(w,[1 1 ncells]);
mCell = cellArray(:,:,1);
for i=1:10%:10
    %dist=sum(sum((s1-s2).^2,2).*w2,1);
    for k=1:ncells
        cCell = cellArray(:,:,k);
        tmin=fminbnd(@dist,-pi/5,pi/5);
        cellArray(:,:,k) = M(cCell,1,tmin);
    end
    mCell = mean(cellArray(:,:,:),3);
    w = 1./var(sum(cCell-mCell,2));
    disp(['Aligning: Step ' num2str(i)])
end
disp('Cells aligned')

% principal components analysis
data = [reshape(cellArray(:,1,:),N,[]);reshape(cellArray(:,2,:),N,[])]';
[coefPCA,scorePCA,latPCA] = princomp(data);
disp('PCA completed')

g = [mCell(:,1);mCell(:,2)];
g1 = coefPCA*g;
f = g;
f1 = g;


[FileName,PathName] = uiputfile('*.mat','Select File for PCA Data...');
save([PathName '\' FileName],'coefPCA','scorePCA','latPCA','mCell');

figure;
plot(mCell(:,1),mCell(:,2),'-',reshape(cellArray([N/4 N/2 N*3/4 N],1,:),4,[]),reshape(cellArray([N/4 N/2 N*3/4 N],2,:),4,[]),'.')

% figure;
% for i=1:334, ctr2=cellArray(:,:,i);l=length(ctr)-1;plot(ctr2(:,1),ctr2(:,2),'.-',ctr2(N,1),ctr2(N,2),'r.');pause(0.5);end


    function res=dist(t)
    res=sum(sum((M(cCell,1,t)-mCell).^2,2).*w);
    end
end

function a=M(a,s,t)
% rotates a set of points clockwise by an angle t and scales it by a factor s
cost = cos(t);
sint = sin(t);
mt = [s*cost -s*sint; s*sint s*cost];
for i=1:size(a,1)
    a(i,:)=a(i,:)*mt;
end
end

