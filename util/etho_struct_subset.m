function so = etho_struct_subset(si, names, newNames)
% Extract a subset of fields from a struct
% Usage:
%   so = etho_struct_subset(si, names)
%   so = etho_struct_subset(si, names, newNames)
%
% * `si` is a (possibly non-scalar) struct
% * `names` is cell array of field names to be selected from `si`
% * `so` is a copy of `si` but including only those fields listed in `names`.
% * `newNames`, if supplied, is a cell array of names to use in `so` instead of
%   those originally appearing in `si`, such that
%     so.(newNames{i}) == si.(names{i})

if ~exist('newNames','var') || isempty(newNames)
    newNames = names;
end

origNames = fieldnames(si);
origData = struct2cell(si);

[hasField, fieldIndex] = ismember(names, origNames);
if ~all(hasField)
    warning('etho_struct_subset:noSuchField', ...
        'One or more requested fields are not in the original struct.');
    fieldIndex = fieldIndex(hasField);
    newNames = newNames(hasField);
end

newData = etho_ndim_slice(origData, fieldIndex);

so = cell2struct(

so = rmfield(si, setdiff(fieldnames(si), names));
so = orderfields(so, names);
