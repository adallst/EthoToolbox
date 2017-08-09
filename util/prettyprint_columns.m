function s = prettyprint_columns(list, width)

if isempty(list)
    s = '';
    return;
end

if ~exist('width','var')
    sz = get(0,'CommandWindowSize');
    width = sz(1);
    if width == 0
        width = 80;
    end
end

columnBufferWidth = 4;

list = cellstr(list);

maxLength = max(cellfun(@length, list));

numCols = floor((width + columnBufferWidth)/(maxLength + columnBufferWidth));

field_format = sprintf('%%-%ds', maxLength);
buffer_str = repmat(' ', 1, columnBufferWidth);
line_fields = repmat({field_format}, 1, numCols);
line_format = strcat(strjoin(line_fields, buffer_str), '\n');

final_endline = mod(numel(list), numCols);

if nargout
    s = sprintf(line_format, list{:});
    if final_endline
        s = strcat(s, sprintf('\n'));
    end
else
    fprintf(line_format, list{:});
    if final_endline
        fprintf('\n');
    end
end
