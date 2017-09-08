function ETableWriteHead(table, file, varargin)
% Write the header for a table to file

args = etho_parse_args({
    'Mode', 'a';
    }, varargin);

[~, names] = ETableAutoType(table, args);
body = cell(0,numel(names));

text = ETableSerialize(body, args, ...
    'TableNamesOut', names, '-PrintHeader');

etho_filewrite(file, text, args.Mode);
