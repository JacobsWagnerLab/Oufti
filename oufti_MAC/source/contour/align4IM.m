function cCell = align4IM(mesh,~)

   % Align to a 'bad' mesh
%     pp=[mesh(:,1:2);flipud(mesh(2:end-1,3:4))];
%     fpp = frdescp(pp);
%     cCell = ifdescp(fpp,p.fsmooth);
%     mesh = model2mesh(cCell,p.fmeshstep);
    if length(mesh)>4
        cCell = [mesh(:,1:2);flipud(mesh(2:end-1,3:4))];
    else
        cCell = [];
    end
    cCell = makeccw(cCell);
end