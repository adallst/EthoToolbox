function parser = pcomb_create_empty()

parser = @ready_empty

end

function parse = ready_empty(input)

    function result = parse_empty(position)
        result = {position, true, {}};
    end

end
