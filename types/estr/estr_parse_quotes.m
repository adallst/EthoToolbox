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
%       Each element is a regular expression matching the opening of one type of
%       quote block, and must have corresponding elements in ClosePatterns and
%       EscapePatterns (even if those elements are empty '').
%   'ClosePatterns': cell array of regular expressions
%       Each element is a regular expression matching the closing of one type of
%       quote block, and must have corresponding elements in OpenPatterns and
%       EscapePatterns. The expression '\1' may be used to match the token
%       matched by OpenPattern.
%   'EscapePatterns': cell array of regular expressions
%       Each element is a regular expression matching escape patterns for the
%       closing of one type of quote block, and must have corresponding
%       elements in OpenPatterns and ClosePatterns. The expression '\1' may be
%       used to match the token matched by OpenPattern.
%
% The 'StandardFlags' and 'LineCommentPattern' options are just shorthands for
% some of the more common quote patterns. The correspondence is as follows:
%   'StandardFlags':
%       s&d         -->   OpenPatterns: '[''"]'
%       s           -->   OpenPatterns: ''''
%       d           -->   OpenPatterns: '"'
%       s|d         -->   ClosePatterns: '\1'
%       (s|d)&b&r   -->   EscapePatterns: '\1\1|\\\1'
%       (s|d)&b     -->   EscapePatterns: '\\\1'
%       (s|d)&r     -->   EscapePatterns: '\1\1'
%   'LineCommentPattern':
%       '#' --> OpenPatterns: '#', ClosePatterns: '\n|$', EscapePatterns: ''
%
% If 'StandardFlags' is set and contains s or d, or if 'LineCommentPattern' is
% set and nonempty, then entries for the resultant patterns will be appended
% to 'OpenPatterns', 'ClosePatterns', and 'EscapePatterns'.

pars = etho_parse_args({
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
    if ~isempty(patTable.escape{quoteStyle})
        escapePattern = regexprep( ...
            patTable.escape{quoteStyle}, ...
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
