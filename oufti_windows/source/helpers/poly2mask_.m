

function BW = poly2mask_(x,y,M,N)


[xe,ye] = poly2edgelist(x,y);



BW = list2mask(M,N,xe,ye);

function [xe, ye] = poly2edgelist(x,y)


% Scale and quantize (x,y) locations to the higher resolution grid.
x = round(5*(x - 0.5) + 1);
y = round(5*(y - 0.5) + 1);

num_segments = length(x) - 1;
x_segments = cell(num_segments,1);
y_segments = cell(num_segments,1);
for k = 1:num_segments
    [x_segments{k},y_segments{k}] = iptui.intline(x(k),x(k+1),y(k),y(k+1));
end

% Concatenate segment vertices.
x = cat(1,x_segments{:});
y = cat(1,y_segments{:});

% Horizontal edges are located where the x-value changes.
d = diff(x);
edge_indices = find(d);
xe = x(edge_indices);

% Wherever the diff is negative, the x-coordinate should be x-1 instead of
% x.
shift = find(d(edge_indices) < 0);
xe(shift) = xe(shift) - 1;

% In order for the result to be the same no matter which direction we are
% tracing the polynomial, the y-value for a diagonal transition has to be
% biased the same way no matter what.  We'll always chooser the smaller
% y-value associated with diagonal transitions.
ye = min(y(edge_indices), y(edge_indices+1));
end
function BW = list2mask(M,N,xe,ye)


shift = (5 - 1)/2;

% Scale x values, throwing away edgelist points that aren't on a pixel's
% center column. 
xe = (xe+shift)/5;
idx = xe == floor(xe);
xe = xe(idx);
ye = ye(idx);

% Scale y values.
ye = ceil((ye + shift)/5);

% Throw away horizontal edges that are too far left, too far right, or below the image.
bad_indices = find((xe < 1) | (xe > N) | (ye > M));
xe(bad_indices) = [];
ye(bad_indices) = [];

% Treat horizontal edges above the top of the image as they are along the
% upper edge.
ye = max(1,ye);

% Insert the edge list locations into a sparse matrix, taking
% advantage of the accumulation behavior of the SPARSE function.
S = sparse(ye,xe,1,M,N);

% We reduce the memory consumption of edgelist2mask by processing only a
% group of columns at a time (g274577); this does not compromise speed.
BW = false(size(S));
numCols = size(S,2);
columnChunk = 1000;
for k = 1:columnChunk:numCols
  firstColumn = k;
  lastColumn = min(k + columnChunk - 1, numCols);
  columns = full(S(:, firstColumn:lastColumn));
  BW(:, firstColumn:lastColumn) = parityscan(columns); 
end
end

end