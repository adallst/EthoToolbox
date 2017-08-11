function [table, fields] = ETableLoad(filename, varargin)
% ETableLoad   Read tabular data from a file

text = fileread(filename);
[table, fields] = ETableParse(text, varargin{:});
