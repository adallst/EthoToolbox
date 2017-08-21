function long = ETableMelt(wide, key, var_name, val_name, missing_func)
% Convert a wide-form table to a long-form table

if ~exist('key', 'var') || isempty(key)
    key = {};
else
    key = cellstr(key);
end
if ~exist('var_name', 'var') || isempty(var_name)
    var_name = 'variable';
end
if ~exist('val_name', 'var') || isempty(val_name)
    val_name = 'value';
end
if ~exist('missing_func', 'var') || isempty(missing_func)
    missing_func = @isempty;
end

[table, names] = ETableConvert(wide, 'TableTypeOut', 'cellarray');

if ~all(ismember(key, names))
    error('ETable:noSuchKey', 'Invalid key');
end

[nrows_in, ncols_in] = size(table);
nkeys = numel(key);
ncols_out = nkeys+2;
nrows_out = (ncols_in - nkeys) * nrows_in;

is_key = ismember(names, key);

nonkey_table = table(:, ~is_key);
nonkey_names = names(~is_key);
variable_names = repmat(nonkey_names, size(nonkey_table,1), 1);

variables = reshape(variable_names', [], 1);
values = reshape(nonkey_table', [], 1);

key_ind_out = repmat(1:nrows_in, size(nonkey_table, 2), 1);
key_part = table(key_ind_out(:), is_key);

long = [key_part, variables, values];
long_names = [names(is_key), var_name, val_name];
