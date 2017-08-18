function [type, names, nrows] = ETableAutoType(table, varargin)
% Attempt to automatically determine the type of a tabular data structure
% Usage:
%   [type, names, nrows] = ETableAutoType(table, ['Parameter', value, ...])
%     `table`
%       Any tabular data structure
%     `type`
%       A string giving the automatically determined type of the table, one of
%       'struct', 'cellarray', or 'columns'
%     `names`
%       The automatically determined field names of the table. If the table is
%       a struct, this is fieldnames(table). Otherwise, if the TableNamesIn
%       parameter is supplied, it is this value. Otherwise, it is a cell array
%       {'var1', 'var2', 'var3', ...} with one entry for each field.
%     `nrows`
%       The number of rows identified in the table.
% Parameters:
%   'TableNames'
%   'TableNamesIn'
%       Either of these provides names for the fields in the table. If the input
%       table is a struct, this parameter is ignored.

pars = etho_parse_args({
    'TableNames', {};
    '>TableNamesIn', 'TableNames';
    }, varargin);
names = pars.TableNamesIn;

if isstruct(table) && isscalar(table)
    type = 'struct';
    names = fieldnames(table);
    nrows = size(table.(names{1}), 1);
elseif isstruct(table)
    type = 'structarray';
    names = fieldnames(table);
    nrows = numel(table);
elseif iscell(table) && isvector(table)
    type = 'columns';
    if isempty(names)
        ncols = numel(table);
        names = strcat('var', strsplit(num2str(1:ncols)));
    end
    nrows = size(table{1}, 1);
elseif iscell(table) && ismatrix(table)
    type = 'cellarray';
    if isempty(names)
        ncols = size(table, 2);
        names = strcat('var', strsplit(num2str(1:ncols)));
    end
    nrows = size(table, 1);
else
    type = 'none';
    names = {};
    nrows = 0;
end
