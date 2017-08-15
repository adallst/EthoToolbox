function [table, fields] = ETableSubset(table, selectFields, varargin)

[table, fields] = ETableConvert(table, ...
    varargin{:}, 'TableTypeOut', 'cellarray');

keepFields = ismember(fields, selectFields);

table = table(:,keepFields);
fields = fields(keepFields);

[table, fields] = ETableConvert(table, ...
    'TableTypeOut', 'struct', ...
    varargin{:}, ...
    'TableTypeIn', 'cellarray', 'TableFields', fieldNames );
