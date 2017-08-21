function ETableWriteBody(table, file, varargin)

text = ETableSerialize(table, varargin{:}, '~PrintHeader');

etho_filewrite(file, text);
