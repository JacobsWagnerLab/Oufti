function out = comparespots(positions1,positions2)
Larray = [];
for frame = 1:length(positions1)
    pos1 = positions1{frame};
    L = length(pos1);
    pos2 = positions2{frame};
    M = (repmat(pos1(:,1),1,L)-repmat(pos2(:,1)',L,1)).^2 + ...
        (repmat(pos1(:,2),1,L)-repmat(pos2(:,2)',L,1)).^2;
    m = min(M,[],1);
    Larray = [Larray;m];
end
out = sqrt(Larray);