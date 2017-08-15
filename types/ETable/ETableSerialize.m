function s = ETableSerialize(table, varargin)

pars = etho_simple_argparser({
    'Quote', '''';
    'QuoteMode', 'auto';
    'FieldDelimiter', '  ';
    'QuoteNeededPattern', '\s|[''",]';
    'QuoteEscapeMethod', 'repeat';
    'AlignColumns', true;
    'TableFields', {};
    'FieldNameRow', true;
    }, varargin);

[table, fields] = ETableConvert(table, pars, ...
    'TableTypeOut', 'cellarray');

entryIsNumeric = cellfun(@(t)isnumeric(t)||islogical(t), table);
table(entryIsNumeric) = cellfun(@num2str, table(entryIsNumeric), ...
    'UniformOutput', false);

if ~iscellstr(table)
    error('ETableSerialize:conversionFailed', ...
        'Unable to convert all data to string');
end

if pars.FieldNameRow && ~isempty(fields)
    table = vertcat(fields(:)', table);
end

% Determine which entries need to be quoted
switch pars.QuoteMode
case 'auto'
    needsQuote = ~cellfun(@isempty, regexp(table, pars.QuoteNeededPattern));
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

rowFormat = strcat(strjoin(columnFormats, pars.FieldDelimiter), '\n');

table = table';
s = sprintf(rowFormat, table{:});
