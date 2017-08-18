function s = ETableSerialize(table, varargin)
% Produce a well-formatted string representation of a table
% Usage:
%   s = ETableSerialize(table, ['Parameter', value, ...])
%
% Valid parameters are:
%   'Style': {['none'], 'csv', 'csv2', 'tsv', 'ssv', 'mysql'}
%       Serialize the table using one of several standard styles. The options
%       are:
%         'none' (default):
%           Use the other parameters to determine serialization format.
%         'csv':
%           Delimit columns with commas, `,`
%         'csv2':
%           Delimit columns with semicolons, `;`
%         'tsv':
%           Delimit columns with tabs, `\t`
%         'wsv':
%           Delimit columns with spaces, ` `
%         'mysql':
%           Delimit columns with vertical pipes, `|`, and include separator
%           lines above, below, and between header and body of table.
%           (TODO)
%   'Quote': {string}
%       The string to open and close quoted text. Usually either `"` or `'`.
%   'QuoteMode': {['auto'] | 'always' | 'never'}
%       Under what circumstances to quote text. If 'always', fields are always
%       quoted, and if 'never', they are never quoted. If 'auto', fields are
%       quoted only if they contain a field delimiter or a quote.
%   'QuoteEscapeMethod': {['repeat'] | 'backslash'}
%       If 'repeat' (default), quote marks within a field will be escaped by
%       reduplication. If 'backslash', they will be escaped by being preceded
%       with a backslash.
%   'ColumnDelimiter': {string}
%       If 'Style' is not 'none', this parameter is overridden. Otherwise, the
%       string to insert between columns.
%   'AlignColumns': {[true] | false}
%       If 'Style' is not 'none', this parameter is overridden. Otherwise,
%       determines whether to pad fields with spaces so that columns align.

pars = etho_parse_args({
    'Style', 'none';
    'Quote', '"';
    'QuoteMode', 'auto';
    'ColumnDelimiter', '  ';
    'RowOpen', '';
    'RowClose', '';
    'QuoteNeededPattern', '\s|[''",]';
    'QuoteEscapeMethod', 'repeat';
    'AlignColumns', true;
    'PrintHeader', true;
    }, varargin);

switch pars.Style
case 'csv'
    pars.ColumnDelimiter = ',';
    pars.RowOpen = '';
    pars.RowClose = '';
    pars.AlignColumns = false;
case 'csv2'
    pars.ColumnDelimiter = ';';
    pars.RowOpen = '';
    pars.RowClose = '';
    pars.AlignColumns = false;
case 'tsv'
    pars.ColumnDelimiter = '\t'
    pars.RowOpen = '';
    pars.RowClose = '';
    pars.AlignColumns = false;
case 'wsv'
    pars.ColumnDelimiter = ' ';
    pars.RowOpen = '';
    pars.RowClose = '';
    pars.AlignColumns = true;
case 'mysql'
    error('MySQL-style output not yet implemented')
case 'none'
    % Do nothing
otherwise
    error('ETableSerialize:unknownStyle', 'Unrecognized Style argument');
end

[table, names] = ETableConvert(table, pars, ...
    'TableTypeOut', 'cellarray');

entryIsNumeric = cellfun(@(t)isnumeric(t)||islogical(t), table);
table(entryIsNumeric) = cellfun(@num2str, table(entryIsNumeric), ...
    'UniformOutput', false);

if ~iscellstr(table)
    error('ETableSerialize:conversionFailed', ...
        'Unable to convert all data to string');
end

if pars.PrintHeader && ~isempty(names)
    table = vertcat(names(:)', table);
end

% Determine which entries need to be quoted
switch pars.QuoteMode
case 'auto'
    needsQuote = cellfun(@isempty, table) ...
        | ~cellfun(@isempty, regexp(table, pars.QuoteNeededPattern));
case 'always'
    needsQuote = true(size(table));
case 'never'
    needsQuote = false(size(table));
otherwise
    warning('ETableSerialize:unknownArgument', ...
        'Unknown argument for QuoteMode, treating as ''always''.');
end

switch pars.QuoteEscapeMethod
case 'repeat'
    quoteReplacePattern = '$0$0';
case {'backslash', '\'}
    quoteReplacePattern = '\\$0';
otherwise
    error('ETableSerialize:unknownArgument', ...
        'Unknown argument for QuoteEscapeMethod.');
end

table(needsQuote) = strcat( ...
    pars.Quote, ...
    regexprep(table(needsQuote), pars.Quote, quoteReplacePattern), ...
    pars.Quote );

if pars.AlignColumns
    fieldWidths = cellfun(@length, table);
    columnWidths = max(fieldWidths, [], 1);
    columnFormats = strcat('%-', strsplit(int2str(columnWidths)), 's');
else
    columnFormats = repmat({'%s'}, 1, size(table,2));
end

rowFormat = strcat(strjoin(columnFormats, pars.ColumnDelimiter), '\n');

table = table';
s = sprintf(rowFormat, table{:});
