Parser Combinator Functions
===========================

create_parser
ready_parser
parse

match_char = prep_char_matcher(input)
{is_match, new_pos, parse_tree} = match_char(pos)

match_literal = prep_literal_matcher(input, literal)

match_sequence = prep_sequence_matcher(input,


create_empty_parser()
create_dot_parser()
create_literal_parser(literal)
create_charset_parser(charset)
create_grouping_parser(parser, symbol)
create_optional_parser(parser)
create_kstar_parser(parser)
create_kplus_parser(parser)
create_check_parser(parser)
create_not_parser(parser)
create_sequence_parser(parser, parser)
create_choice_parser(parser, parser)

These return a parser which must be "readied" on a particular input.

---

node:
    symbol
    type
        terminal
        group
        optional
        kstar
        kplus
        check
        not
        sequence
        choice
    value
        terminal: a string
        otherwise: an array of nodes
