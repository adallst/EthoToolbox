function tf = isequiv(A, B)
% Determine if two objects are equivalent

if ischar(A)
    A = cellstr(A);
end
if ischar(B)
    B = cellstr(B);
end

if ndims(A) ~= ndims(B)
    tf = false;
    return;
end

if ~all(size(A) == size(B))
    tf = false;
    return;
end

A = A(:);
B = B(:);

if iscellstr(A) && iscellstr(B)
    tf = all(strcmp(A, B));
elseif iscell(A) && iscell(B)
    tf = false(size(A));
    for i=1:numel(A)
        tf(i) = isequiv(A{i}, B{i});
    end
    tf = all(tf);
else
    try
        tf = all(A == B);
    catch
        tf = false;
    end
end
