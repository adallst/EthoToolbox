function [table, names] = ETableConvert(table, varargin)
% ETableConvert   Convert from one tabular structure to another
% Usage:
%   [table, names] = ETableConvert(table, ['Parameter', value, ...])
%
% Converts the input tabular data to a different data structure representing
% the same data. See `ETable help` for valid data structures.
% Valid parameters are:
%   'TableType': {['auto'] | 'struct' | 'columns' | 'cellarray'}
%   'TableTypeIn'
%   'TableTypeOut'
%       Specify the type of the table. If not supplied, TableTypeIn and
%       TableTypeOut inherit the value of TableType.
%       TableTypeIn acts as a "hint" for the type of the input. If 'auto' (the
%       default), attempt to determine the type based on its Matlab type and
%       structure.
%       TableTypeOut specifies the output type of the conversion. If 'auto' (the
%       default), no conversion occurs.
%   'TableNames': {cell array of strings}
%   'TableNamesIn'
%   'TableNamesOut'
%       The field names for the table. If not supplied, TableNamesIn and
%       TableNamesOut inherit the value of TableNames.
%       If TableNamesIn is empty (the default) and the input table is a struct,
%       the field names of the struct are used instead.
%       If TableNamesOut is empty (the default), the field names are not
%       changed.
%
% Returns:
%   table
%     The converted tabular data.
%   names
%     The field names for the tabular data. If table is a struct, equivalent
%     to fieldnames(table).

% Valid table formats:
% struct:
%   The table is represented a struct such that table.(field{i})(j) is the j'th
%   row of the i'th column.
% columns:
%   The table is represented as a cell array such that table{i}(j) is the j'th
%   row of the i'th column.
% cellarray:
%   The table is represented as a cell array such that table{j,i} is the j'th
%   row of the i'th column.

pars = etho_parse_args({
    'TableType',      'auto';
    '>TableTypeOut',  'TableType';
    '>TableTypeIn',   'TableType';
    'TableNames',     { };
    '>TableNamesIn',  'TableNames';
    '>TableNamesOut', 'TableNames';
    }, varargin);

all_table_types = {'struct', 'columns', 'cellarray'};
type_in = lower(pars.TableTypeIn);
type_out = lower(pars.TableTypeOut);
names_in = cellstr(pars.TableNamesIn);
names_out = cellstr(pars.TableNamesOut);

[auto_type, auto_names] = ETableAutoType(table, pars);

if ~ismember(type_in, all_table_types)
    if ~ismember(type_in, {'auto',''})
        warning('ETable:badTypeIn', ...
            'Unknown ''TableTypeIn'' value ''%s'', treating as ''auto''', ...
            type_in);
    end
    type_in = auto_type;
end
if ~ismember(type_out, all_table_types)
    if ismember(type_out, {'auto', ''})
        type_out = type_in;
    else
        error('ETable:badTypeOut', ...
            'Unknown ''TableTypeOut'' value ''%s''', type_out);
    end
end
if isempty(names_in)
    names_in = auto_names;
elseif ismember(type_in, {'struct', 'structarray'})
    table = etho_struct_subset(table, names_in);
end
if isempty(names_out)
    names_out = names_in;
end

[~, type_in_idx] = ismember(type_in, all_table_types);
[~, type_out_idx] = ismember(type_out, all_table_types);

% Select the conversion function from the matrix below.
conversionTable = {
    @no_change,             @struct_to_columns,      @struct_to_cellarray;
    @columns_to_struct,     @no_change,              @columns_to_cellarray;
    @cellarray_to_struct,   @cellarray_to_columns,   @no_change;
    };
[table, names] = conversionTable{type_in_idx, type_out_idx}(table, names_out);


function [table, names] = no_change(table, names)
% PASS

function [table, names] = struct_to_columns(table, names)
if isempty(names)
    names = fieldnames(table);
end
table = struct2cell(table);

function [table, names] = columns_to_cellarray(table, names)
for i=1:numel(table)
    if ~iscell(table{i})
        table{i} = num2cell(table{i});
    end
end
table = horzcat(table{:});

function [table, names] = struct_to_cellarray(table, names)
[table, names] = struct_to_columns(table, names);
[table, names] = columns_to_cellarray(table, names);

function [table, names] = cellarray_to_columns(table, names)
[nrow, ncol] = size(table);
table = mat2cell(table, nrow, ones(1,ncol));
for i=1:ncol
    if all(cellfun(@(t)isnumeric(t)||islogical(t), table{i}))
        table{i} = vertcat(table{i}{:});
    end
end

function [table, names] = columns_to_struct(table, names)
table = cell2struct(table(:), names);

function [table, names] = cellarray_to_struct(table, names)
[table, names] = cellarray_to_columns(table, names);
[table, names] = columns_to_struct(table, names);
