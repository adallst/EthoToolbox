function [table, fields] = EthoLoadTable(filename, varargin)

text = fileread(filename);
[table, fields] = EthoParseTable(text, varargin{:});
