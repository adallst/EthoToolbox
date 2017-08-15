function blocks = estr_parse_quotes(text, varargin)
% Parse a string into quoted and unquoted parts.
% Usage:
%   blocks = estr_parse_quotes(text, ['Parameter', value, ...])
%
% Given a string containing quoted text, parses the string into quoted and
% unquoted sections. `blocks` is an N-by-3 cell array of strings, such that
% blocks{n,1} is the opening quote of the n'th block, blocks{n,2} is the quoted
% text, and blocks{n,3} is the closing quote text. For an unquoted block,
% blocks{n,1} and blocks{n,3} are both ''.
%
% Optional parameters are:
%   'StandardFlags': set of flags in 'sdbr'
%       Default is 'sdbr'. The flags have meaning as follows:
%         s: Use single quotes '
%         d: Use double quotes "
%         b: A backslash \ preceding a quote escapes it
%         r: Reduplication '' of a quote escapes it.
%   'LineCommentPattern': regular expression
%       Default is ''. A pattern to match as the start of a line-style comment.
%   'OpenPatterns': cell array of regular expressions
%       Each element in the array is a regular expression matching the opening
%       of one type of quote block.
%   'ClosePatterns': cell array of regular expressions
%   'EscapePatterns': cell array of regular expressions

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
    'OpenPatterns',   {};
    'ClosePatterns',  {};
    'EscapePatterns', {};
    'StandardFlags', 'sdbr';
    'LineCommentPattern', '';
    }, varargin);

patTable = etho_struct_subset(pars, ...
    {'OpenPatterns','ClosePatterns','EscapePatterns'}, ...
    {'open', 'close', 'escape'} );

standardFlags = ismember('sdbr', pars.StandardFlags);
singleQuote = standardFlags(1);
doubleQuote = standardFlags(2);
backslashEscapes = standardFlags(3);
reduplicationEscapes = standardFlags(4);

useStandardStyle = singleQuote || doubleQuote;
bothQuotes = singleQuote && doubleQuote;

if useStandardStyle
    % Use one of the standard quotation/escape styles
    standardOpens = '[''"]';
    openPattern = ...
        standardOpens([bothQuotes, singleQuote, doubleQuote, bothQuotes]);
    closePattern = '\1';
    standardEscapes = {'\\\1', '\1\1'};
    escapePattern = strjoin( ...
        standardEscapes([backslashEscapes, reduplicationEscapes]),
        '|' );
    patTable.open(end+1) = {openPattern};
    patTable.close(end+1) = {closePattern};
    patTable.escape(end+1) = {escapePattern};
end

if ~isempty(pars.LineCommentPattern)
    % Use a standard line comment style, with the supplied pattern as the open
    patTable.open(end+1) = {pars.LineCommentPattern};
    patTable.close(end+1) = {'\n|$'};
    patTable.escape(end+1) = {''};
end

patterns = cell(size(patTable.open));

for i = 1:numel(patTable.open)
    openPattern = patTable.open{i};
    closePattern = patTable.close{i};
    escapePattern = patTable.escape{i};

    % Replace all instances of '\1' in the close and escape patterns with
    % '\1', '\4', '\7', etc.
    openTokenMetaPattern = '(^|(\\\\)+|[^\\])\\1';
    openTokenNumber = 3*i - 2;
    openTokenMetaReplacement = sprintf('$1\\%d', openTokenNumber);

    closePattern = regexprep(closePattern, ...
        openTokenMetaPattern, openTokenMetaReplacement);
    escapePattern = regexprep(escapePattern, ...
        openTokenMetaPattern, openTokenMetaReplacement);

    closeParts = strsplit(closePattern, '|');
    escapeParts = strsplit(escapePattern, '|');

    % If any escape pattern begins with a pattern that also matches a close
    % pattern, we need to use negative lookahead to escape it properly.
    lookaheadParts = repmat({''}, numel(escapeParts), numel(closeParts));
    needsLookahead = false(size(lookaheadParts));
    for e_i = 1:numel(escapeParts)
        for c_i = 1:numel(closeParts)
            thisEscape = escapeParts{e_i};
            thisClose = closeParts{c_i};
            n = numel(thisClose);
            if strncmp(thisEscape, thisClose, n)
                lookaheadParts{e_i,c_i} = thisEscape((n+1):end);
                needsLookahead(e_i,c_i) = true;
            end
        end
    end
    lookaheadPattern = strjoin(lookaheadParts(needsLookahead), '|');
    if ~isempty(lookaheadPattern)
        lookaheadPattern = sprintf('(?!%s)', lookaheadPattern);
    end

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
    quoteStyle = find(~cellfun(@isempty, tokens{i}(1:3:end)));
    [thisOpen, thisBlock, thisClose] = tokens{i}{3*quoteStyle + (-2:0)};

    % Replace escape patterns, if needed
    if ~isempty(quotePatterns{quoteStyle,3})
        escapePattern = regexprep( ...
            quotePatterns{quoteStyle,3}, ...
            '\\1', ...
            regexptranslate('escape', thisOpen) );
        thisBlock = regexprep(thisBlock, escapePattern, thisClose);
    end

    blocks(2*i,:) = {thisOpen, thisBlock, thisClose};
end

% Remove unquoted blocks containing no text
preserveBlock = true(size(blocks,1), 1);
preserveBlock(1:2:end) = ~cellfun(@isempty, nonquoted);

blocks = blocks(preserveBlock,:);
