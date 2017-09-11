function tf = estr_is_number(s)

standard = '[+-]?\d+[.,]?\d*(e[+-]?\d+)?';
decimal = '[+-]?[.,]\d+(e[+-]?\d+)?';
constants = '[+-]?inf|nan';
pattern = strcat('^(', strjoin({standard, decimal, constants}, '|'), ')$');

found = regexpi(s, pattern, 'once');
tf = ~cellfun(@isempty, found);
