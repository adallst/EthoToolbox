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
    'IgnoreTrailingWhitespace', true;
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
        numeric_entry = estr_is_number(columns{i});
        missing_entry = str_is_missing(columns{i}, pars);

        if all(numeric_entry | missing_entry)
            fieldTypes{i} = 'numeric';
        elseif any(numeric_entry)
            fieldTypes{i} = 'mixed';
        else
            fieldTypes{i} = 'text';
        end
    elseif strcmp(fieldTypes{i}, 'mixed')
        numeric_entry = estr_is_number(columns{i});
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

[table, fields] = ETableConvert(columns, pars, ...
    'TableTypeIn', 'columns', 'TableNames', fields);



function vals = parse_row(text, pars)

if pars.IgnoreTrailingWhitespace
    text = deblank(text);
    line_comment_pattern = ['\s*(' pars.LineComments ')'];
else
    line_comment_pattern = pars.LineComments;
end

if isempty(text)
    vals = {};
    return;
end

blocks = estr_parse_quotes(text, ...
    'StandardFlags', pars.QuoteStyle, ...
    'LineCommentPattern', line_comment_pattern);

% If the block ends with a line comment, discard that block.
if ~isempty(regexp(blocks{end,1}, pars.LineComments))
    blocks = blocks(1:end-1,:);
end

num_blocks = size(blocks,1);
row_parts = cell(1, num_blocks);

for i=1:num_blocks
    if isempty(blocks{i,1})
        % This is an unquoted block, parse delimiters
        tokens = regexp(blocks{i,2}, pars.FieldDelimiter, 'split');

        % Every unquoted block except for the very first one on the line should
        % begin with a delimiter separating it from the previous block,
        % producing a spurious empty token. Likewise, each unquoted block should
        % end with a delimiter except for the final one on the line.

        if isempty(tokens{1}) && i~=1
            % The block started with a delimiter, and this is not the first
            % block, therefore the empty first token is an artifact of following
            % a quoted block. Remove it.
            tokens = tokens(2:end);
        end
        if isempty(tokens{end}) && i~=num_blocks
            % The block ended with a delimiter, and this is not the final block,
            % therefore the empty final token is an artifact of preceding a
            % quoted block. Remove it.
            tokens = tokens(1:end-1);
        end
        row_parts{i} = tokens;
    else
        % This is a quoted block, do not parse delimiters
        row_parts{i} = {blocks{i,2}};
    end
end

vals = horzcat(row_parts{:});

function tf = str_is_missing(s, pars)

tf = strcmp('',s) | ismember(s, cellstr(pars.MissingValues));
