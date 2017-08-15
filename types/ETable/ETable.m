function [table, fields] = ETable(fields, format)
% ETable: Tabular data management for EthoToolbox
%
% For help text on the full set of ETable functions, run `ETable help`, or see
% README.md in the ETable folder.
%
% Usage:
%   ETable help
%   [table, fields] = ETable(fields, format)
%
% The help usage displays the contents of the README.md file for ETable.
% Normal usage creates a new table with named fields in the specified format,
% containing no data.
% Valid format options are 'struct', 'cellarray', and 'columns'.
% If not supplied, the default format is 'struct'.

if ischar(fields) && strcmp(fields, 'help')
    myDirectory = fileparts(mfilename);
    myReadme = fullfile(myDirectory, 'README.md');
    helptext = fileread(myReadme);
    fprintf('%s', helptext);
    clear fields;
    return;
end

if ~exist('format', 'var')
    format = 'struct';
end
if ~exist('fields', 'var')
    fields = {};
end

structArgs = cell(1, 2*numel(fields));
structArgs(1:2:end) = fields;
structArgs(2:2:end) = {[]};

table = struct(structArgs{:});
[table, fields] = ETableConvert(table, 'TableOutput', format)
