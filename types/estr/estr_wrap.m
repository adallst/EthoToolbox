function wrapped = estr_wrap(text, width, as_lines)

if ~exist('as_lines', 'var')
    as_lines = false;
end
% The pattern below matches up to <width> non-newline characters, followed by
% a whitespace character or the end of the string.
pattern = ['([^\n]{0,' num2str(width), '}|\S+)(\n|\s+|$)'];

tokens = regexp(text, pattern, 'tokens');
tokens = vertcat(tokens{:});
lines = tokens(:,1);
if as_lines
    wrapped = lines;
else
    wrapped = strjoin(lines, sprintf('\n'));
end
