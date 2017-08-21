function [y, i, j] = etho_unique_ordered(x, varargin)
% Extract unique elements of a list, preserving ordering
% Usage:
%   [y, i, j] = etho_unique_ordered(x)
%   [y, i, j] = etho_unique_ordered(x, 'rows')
%   ... = etho_unique_ordered(..., 'first')
%   ... = etho_unique_ordered(..., 'last')
% Acts just like the builtin function `unique`, but preserves the original
% ordering of the input.

% y = x(i)
% x = y(j)

[y_sorted, i_sorted, j_sorted] = unique(x, varargin{:});
[i_ordered, i_unsort] = sort(i_sorted);
j_ordered = i_unsort(j_sorted);

if ismember('rows', varargin)
    y_ordered = y_sorted(i_unsort,:);
else
    y_ordered = y_sorted(i_unsort);
end
