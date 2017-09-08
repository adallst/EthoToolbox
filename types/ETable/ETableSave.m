function ETableSave(table, file, varargin)

args = etho_parse_args({
    'Mode', 'a';
    }, varargin);

text = ETableSerialize(table, args);

etho_filewrite(file, text, args.Mode);
