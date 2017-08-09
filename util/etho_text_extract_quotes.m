function blocks = etho_text_extract_quotes(text, varargin)
% Parse a string into quoted and unquoted parts.
% Usage:
%   blocks = etho_text_extract_quotes(text,)
% Rationale:
%
% Approach:
%

pars = etho_simple_argparser({
    'QuotePatterns', struct('Open', {{}}, 'Close', {{}}, 'Escape', {{}}),
    'SingleQuote', true,
    'DoubleQuote', true,
    'BackslashEscapes', true,
    'ReduplicationEscapes', true,
    'LineCommentPattern', ''
    }, varargin);

quotePatterns = EthoReformatTable(pars.QuotePatterns, ...
    'FieldNames', {'Open','Close','Escape'});

standardPatterns = {'','',''};
if pars.SingleQuote
    if pars.DoubleQuote
        standardPatterns{1} = '[''"]';
    else
        standardPatterns{1} = '''';
    end
    standardPatterns{2} = '\1';
elseif pars.DoubleQuote
    standardPatterns{1} = '"';
    standardPatterns{2} = '\1';
end
escapePatterns = {};
if pars.BackslashEscapes
    escapePatterns(end+1) = {'\\\1'};
end
if pars.ReduplicationEscapes
    escapePatterns(end+1) = {'\1\1'};
end
standardPatterns{3} = strjoin(escapePatterns, '|');

if ~isempty(pars.LineCommentPattern)

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
