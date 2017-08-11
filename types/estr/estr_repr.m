function s = etho_repr(v)
% Given an input v, attempts to produce a string of Matlab code which would
% evaluate to v.

newl = sprintf('\n');

if isa(v,'double')
    s = mat2str(v);
elseif isnumeric(v) || islogical(v)
    s = mat2str(v, [], 'class');
elseif ischar(v)
    % Escape all quotes
    s = strrep(v, '''', '''''');
    if ismember(newl, s)
        % String contains newlines. Replace them and use sprintf.
        strrep(s, newl, '\n');
        s = strcat('sprintf(''', s, ''')');
    else
        % No newlines, just enclose in quotes.
        s = strcat('''', s, '''');
    end
elseif iscell(v)
    if ndims(v) > 2
        error('etho_repr:notImplemented', ...
            'Cell arrays greater than 2 dimensions not yet implemented.');
    end
    s = '{';
    for row = 1:size(v,1)
        if row ~= 1
            s = strcat(s, ';');
        end
        for col = 1:size(v,2)
            if col ~= 1
                s = strcat(s, ',');
            end
            s = strcat(s, etho_repr(v{row,col}));
        end
    end
    s = strcat(s,'}');
elseif isstruct(v)
    if ~isscalar(v)
        error('etho_repr:notImplemented', ...
            'Non-scalar structs not yet implemented.');
    end
    fields = fieldnames(v);
    s = 'struct(';
    for i = 1:numel(fields)
        if i ~= 1
            s = strcat(s, ',');
        end
        s = strcat(s, etho_repr(fields{i}), ',', etho_repr(v.(fields{i})));
    end
    s = strcat(s, ')');
else
    error('etho_repr:notImplemented', ...
        'String representation not implemented for this type.')
end
