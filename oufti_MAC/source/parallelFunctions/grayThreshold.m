function b=grayThreshold(a,flevel)
        if  flevel>0
            c = reshape(a,1,[]);
            c = sort(c);
            level = c(ceil(min(flevel,1)*length(c)));
            b = graythresh(c(c>=level));
        else
            b = graythresh(a);
        end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%