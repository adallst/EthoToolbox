function type = ETableAutoType(table)
% Attempt to automatically determine the type of a tabular data structure
% Usage:
%   type = ETableAutoType(table)
%     `table`
%       Any tabular data structure
%     `type`
%       A string giving the automatically determined type of the table, one of
%       'struct', 'cellarray', or 'columns'

if isstruct(table) && isscalar(table)
    type = 'struct';
elseif isstruct(table)
    type = 'structarray';
elseif iscell(table) && isvector(table)
    type = 'columns';
elseif iscell(table) && ismatrix(table)
    type = 'cellarray';
else
    type = 'none';
end
