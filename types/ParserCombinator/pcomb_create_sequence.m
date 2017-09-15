function parser = pcomb_create_sequence(parserL, parserR)

parser = @parse_sequence;

    function result = parse_sequence(input, position)
        failure = struct( ...
            'success', false, ...
            'position', position, ...
            'tree', [] );
        tree = struct( ...
            'symbol', '', ...
            'type', 'sequence', ...
            'value', [] );
        resultL = lazy_eval(parserL, input, position);
        resultL = resultL();
        if ~resultL.success
            result = failure;
            return;
        end
        resultR = lazy_eval(parserR, input, resultL.position);
        resultR = resultR();
        if ~resultR.success
            result = failure;
            return;
        end
        if strcmp(resultL.tree.type, 'sequence')
            tree.value = [resultL.tree.value, resultR.tree];
        else
            tree.value = [resultL.tree, resultR.tree];
        end
        result = struct( ...
            'success', true, ...
            'position', resultR.position, ...
            'tree', tree);
    end
end
