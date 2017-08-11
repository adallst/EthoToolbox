function blocks = estr_parse_quotes(text, varargin)
% Parse a string into quoted and unquoted parts.
% Usage:
%   blocks = estr_parse_quotes(text, ['Parameter', value, ...])
%
% Given text containing quoted text, parses the string into quoted and unquoted
% sections. `blocks` is an N-by-3 cell array of strings, such that blocks{n,1}
% is the opening quote of the n'th block, blocks{n,2} is the quoted text, and
% blocks{n,3} is the closing quote text. For an unquoted block, blocks{n,1} and
% blocks{n,3} are both ''.
%
% Valid parameters are:
%   'SingleQuote': {[true] | false}
%   'DoubleQuote': {[true] | false}
%       Whether single quotes ' or double quotes " should be used as quote
%       marks, respectively.
%   'BackslashEscapes': {[true] | false}
%       Whether a backslash preceding a quote mark escapes it from closing the
%       block.
%   'ReduplicationEscapes': {[true] | false}
%       Whether repeating a quote mark escapes it from closing the block.
%   'LineCommentPattern': {[''] | regular expression}
%       If not empty, identifies a line-comment-style "quote" block that begins
%       with the supplied pattern and ends at the end of the line. E.g., '#' to
%       cause everything following a # on a single line to be a comment block.
%   'QuotePatterns': {Any ETable with fields 'Open', 'Close', and 'Escape'}
%       Specify quote styles directly using regular expression patterns. Each
%       row in the table corresponds to one type of quotation block, with the
%       fields as follows:
%         'Open': A regex pattern matching the opening of a quote block.
%         'Close': A regex pattern matching the close of the quote block. Can
%            use '\1' to match the string matched by the 'Open' pattern.
%         'Escape': A regex pattern matching escaped close sequences in the
%            block. E.g., '\\\1' matches a backslash followed by the quote.
%       The other parameters are just shorthands for useful patterns in this
%       table. Given the inputs for SingleQuote, DoubleQuote, BackslashEscapes,
%       and ReduplicationEscapes, the QuotePatterns table is appended with a
%       row as follows:
%
%         SQ  DQ  BE  RE  -->  Open      Close    Escape
%          t   t   t   t       '[''"]'   '\1'     '\\\1|\1\1'
%          t   t   t   f       '[''"]'   '\1'     '\\\1'
%          t   t   f   t       '[''"]'   '\1'     '\1\1'
%          t   t   f   f       '[''"]'   '\1'     ''
%          t   f   t   t       ''''      '\1'     '\\\1|\1\1'
%          t   f   x   x       ''''      '\1'     (as above)
%          f   t   t   t       '"'       '\1'     '\\\1|\1\1'
%          f   t   x   x       '"'       '\1'     (as above)
%          f   f   x   x       (no additional row is appended)
%
%       Additionally, if LineCommentPattern is not empty, the QuotePatterns
%       table is appended with a row as follows:
%
%         Open          Close    Escape
%         (LCP value)   '\n|$'   ''

pars = etho_simple_argparser({
    'QuotePatterns', struct('Open', {{}}, 'Close', {{}}, 'Escape', {{}}),
    'SingleQuote', true,
    'DoubleQuote', true,
    'BackslashEscapes', true,
    'ReduplicationEscapes', true,
    'LineCommentPattern', ''
    }, varargin);

quotePatterns = ETableConvert(pars.QuotePatterns, ...
    'TableFormat', 'cellarray', ...
    'FieldNames', {'Open','Close','Escape'});

bothQuotes = pars.SingleQuote & pars.DoubleQuote;
standardQuotePattern = '[''"]';

if pars.SingleQuote || pars.DoubleQuote
    quotePattern = standardQuotePattern(...
        [bothQuotes, pars.SingleQuote, pars.DoubleQuote, bothQuotes]);
    escapePatterns = {};
    if pars.BackslashEscapes
        escapePatterns = [escapePatterns, {'\\\1'}];
    end
    if pars.ReduplicationEscapes
        escapePatterns = [escapePatterns, {'\1\1'}];
    end
    escapePattern = strjoin(escapePatterns, '|');

    quotePatterns = [quotePatterns; {quotePattern, '\1', escapePattern}];
end

if ~isempty(pars.LineCommentPattern)
    quotePatterns = [quotePatterns; {pars.LineCommentPattern, '$|\n', ''}];
end

patterns = cell(size(quotePatterns,1),1);

for i=1:size(quotePatterns,1)
    openPattern = quotePatterns{i,1};
    closePattern = quotePatterns{i,2};
    escapePattern = quotePatterns{i,3};
    escapeParts = strsplit(escapePattern,'|');
    needsLookahead = strncmp(escapeParts, '\1', 2);
    lookaheadParts = cellfun(@(s)s(3:end), ...
        escapeParts(needsLookahead);
    lookaheadPattern = strjoin(lookaheadParts, '|');
    if ~isempty(lookaheadPattern)
        lookaheadPattern = sprintf('(?!%s)', lookaheadPattern);
    end
    openTokenNumber = (i-1)*3 + 1;
    openTokenMatcher = strcat('\', str2double(openTokenNumber));
    closePattern = strrep(closePattern, '\1', openTokenMatcher);
    escapePattern = strrep(escapePattern, '\1', openTokenMatcher);
    lookaheadPattern = strrep(lookaheadPattern, '\1', openTokenMatcher);

    if isempty(escapePattern)
        patterns{i} = sprintf('(%s)(.*?)(%s)', openPattern, closePattern);
    else
        patterns{i} = sprintf('(%s)((?:%s|.)*?)(%s)%s', ...
            openPattern, escapePattern, closePattern, lookaheadPattern);
    end
end

pattern = strjoin(patterns, '|');

[tokens, nonquoted] = regexp(text, pattern, 'tokens', 'split');
% Now `tokens` is a cell array of cell arrays of strings, such that
% tokens{i}{j} is the j'th token in the i'th match. I.e., for the i'th quoted
% block of text, and the k'th quote pattern, tokens{i}((k*3-2):(k*3)) represents
% the open quote, quoted text, and close quote, respectively, if the k'th quote
% pattern matched, and will be {'','',''} otherwise.
%
% `nonquoted` is a cell array of strings representing the unquoted blocks, such
% that nonquoted{i+1} is the nonquoted text following the i'th quoted block, and
% nonquoted{1} is the nonquoted text preceding the first quoted block. If the
% string begins or ends with a quoted block, or if two quoted blocks are in
% direct sequence, then the corresponding nonquoted element will be ''.
%
% From this we need to build an N-by-3 table representing all blocks.

blocks = cell(numel(tokens)*2+1, 3);
blocks(1:2:end, 1) = {''};
blocks(1:2:end, 2) = nonquoted;
blocks(1:2:end, 3) = {''};

for i=1:numel(tokens)
    
end


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
