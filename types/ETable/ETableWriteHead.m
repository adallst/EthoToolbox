function ETableWriteHead(table, file, varargin)
% Write the header for a table to file

[~, names] = ETableAutoType(table, varargin{:});
body = cell(0,numel(names));

text = ETableSerialize(body, varargin{:}, ...
    'TableNamesOut', names, '-PrintHeader');

etho_filewrite(file, text);
