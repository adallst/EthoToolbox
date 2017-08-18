function [table, fields] = ETableParse(s, varargin)
% Parse tabular data from a string
% Usage:
%   [table, fields] = ETableParse(s, ['Parameter', value, ...])
%
% Given an input string `s` containing tabular data in a standard format
% (e.g., CSV), return the data in a desired Matlab data structure. Any column in
% the table for which all values are convertable to numbers will be converted.
% Otherwise, all values are imported as strings.
%
% Valid parameters are:
%   'FieldNameRow':  {[true] | false}
%       Whether the first row of the table gives field names instead of data.
%   'SkipLines':
%       An integer specifying a number of lines to skip before reading the
%       table. Default is 0.
%   'FieldDelimiter':
%       A regular expression pattern matching the delimiter between fields
%       within a row. The default value is ',\s*|\s+', meaning that any comma
%       (optionally followed by whitespace) or whitespace will be treated as a
%       field delimiter. Delimiters enclosed by quotes are ignored. The default
%       expression will successfully read most CSV, TSV, or WSV files. Useful
%       alternatives are:
%         For "strict" CSV: ','
%         For TSV:          '\t'
%         For WSV:          '\s+'
%         For MySQL output: '\s*\|\s*'
%   'Quote':
%       A regular expression giving the pattern that matches a quote. The
%       default value is '[''"]', meaning that both single quotes ' and double
%       quotes " are valid quote marks. The closing quote is always the same
%       as the opening quote.
%   'EscapeDoubleQuote':
%   'TableTypeOut':  {['struct'] | 'cellarray' | 'columns'}
%   'FieldTypes':
%   'MissingValues':


pars = etho_parse_args({
    'FieldNameRow', true;
    'SkipLines', 0;
    'FieldDelimiter', ',\s*|\s+';
    'QuoteStyle', 'sdrb';
    'LineComments', '#'
    %'Quote', '[''"]';
    %'EscapeDoubleQuote', true;
    'TableTypeOut', 'struct';
    'FieldTypes', 'auto';
    'MissingValues', {'NA'};
    }, varargin);

lines = strsplit(s, sprintf('\n'));
lines = lines((1+pars.SkipLines):end);
lines = lines(~cellfun(@isempty, lines));

rows = cell(size(lines));
for i=1:numel(rows)
    rows{i} = parse_row(lines{i}, pars);
end

fieldCounts = cellfun(@numel, rows);
numFields = max(fieldCounts);
if all(fieldCounts==numFields)
    % Uniform field counts
    rawTable = vertcat(rows{:});
else
    warning('EthoParseTable:nonUniformFields', ...
        'Irregular number of fields per row, short rows will be padded.');
    rawTable = cell(numel(rows), numFields);
    for i=1:numel(rows)
        rawTable(i, 1:fieldCounts(i)) = rows{i};
    end
end

if pars.FieldNameRow
    fields = rawTable(1,:);
    rawTable = rawTable(2:end,:);
else
    fields = {};
end

columns = mat2cell(rawTable, size(rawTable,1), ones(1,numFields));

% Now do numeric conversions if needed
fieldTypes = lower(cellstr(pars.FieldTypes));
if isscalar(fieldTypes)
    fieldTypes = repmat(fieldTypes, size(columns));
end
for i=1:numFields
    if isempty(fieldTypes{i}) || strcmp(fieldTypes{i}, 'auto')
        numeric_entry = str_is_number(columns{i});
        missing_entry = str_is_missing(columns{i}, pars);

        if all(numeric_entry | missing_entry)
            fieldTypes{i} = 'numeric';
        elseif any(numeric_entry)
            fieldTypes{i} = 'mixed';
        else
            fieldTypes{i} = 'text';
        end
    elseif strcmp(fieldTypes{i}, 'mixed')
        numeric_entry = str_is_number(columns{i});
    end
    switch fieldTypes{i}
    case 'numeric'
        columns{i} = str2double(columns{i});
    case 'mixed'
        columns{i}(numeric_entry) = ...
            num2cell( str2double( columns{i}(numeric_entry) ) );
    case {'text', 'string'}
        % Actually nothing to do.
    end
end

[table, fields] = EthoReformatTable(columns, pars, ...
    'FormatHint', 'columns', 'TableFields', fields);

function vals = parse_row(text, pars)

blocks = estr_parse_quotes(text, ...
    'StandardFlags', pars.QuoteStyle, ...
    'LineCommentPattern', pars.LineComments);
%[quoted, nonquoted] = extract_quoted_text(text, pars);

if numel(quoted) < numel(nonquoted)
    quoted(end+1) = {''};
end

nondelims = regexp(nonquoted, pars.FieldDelimiter, 'split');
for i=1:numel(nondelims)
    if isempty(nondelims{i}{1})
        % nonquoted section began with a field delimiter, remove the empty
        % string.
        nondelims{i} = nondelims{i}(2:end);
    end
    % Join the subsequent quoted section to the last delimited item.
    nondelims{i}{end} = strcat(nondelims{i}{end}, quoted{i});
end
%nondelims
vals = horzcat(nondelims{:});
%vals = vals(~cellfun(@isempty, vals));

function [quoted, nonquoted] = extract_quoted_text(text, pars)
% Given an input string text, return a cell array splitting up the text into
% unquoted and quoted sections. parts(1:2:end) contains the unquoted sections,
% and parts(2:2:end) contains the quoted sections.
quote_pattern = pars.Quote;
escape_pattern = '\\\1';
if pars.EscapeDoubleQuote
    escape_pattern = [escape_pattern '|\1\1'];
    lookahead_pattern = '(?!\1)';
else
    lookahead_pattern = '';
end

pattern = sprintf('(%s)((?:%s|.)*?)\\1%s', ...
    quote_pattern, escape_pattern, lookahead_pattern);

[tokens, nonquoted] = regexp(text, pattern, 'tokens', 'split');
tokens = vertcat(tokens{:});
if isempty(tokens)
    quoted = {};
else
    quotes = tokens(:,1);
    re_quotes = regexptranslate('escape', quotes);
    escaped_quotes = strcat('\\', re_quotes);
    if pars.EscapeDoubleQuote
        escaped_quotes = strcat(escaped_quotes, '|', re_quotes, re_quotes);
    end
    quoted = regexprep(tokens(:,2), escaped_quotes, quotes);
end
if isempty(nonquoted{end})
    nonquoted = nonquoted(1:end-1);
end

function tf = str_is_number(s)
standard = '[+-]?\d+[.,]?\d*(e[+-]?\d+)?';
decimal = '[+-]?[.,]\d+(e[+-]?\d+)?';
constants = '[+-]?inf|nan';
pattern = strcat('^(', strjoin({standard, decimal, constants}, '|'), ')$');

found = regexpi(s, pattern, 'once');
tf = ~cellfun(@isempty, found);

function tf = str_is_missing(s, pars)

tf = strcmp('',s) | ismember(s, cellstr(pars.MissingValues));
