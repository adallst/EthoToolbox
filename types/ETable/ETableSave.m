function ETableSave(table, file, varargin)

text = ETableSerialize(table, varargin{:});

etho_filewrite(file, text);
