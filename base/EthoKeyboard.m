function KbControlGKA(cmd)
% KbControlGKA   General setup controller for getting key presses
% Usage:
%     KbControlGKA('Start')
%         Start listening for key presses
%     KbControlGKA('Stop')
%         Stop listening for key presses; must be called as many times as
%         KbControlGKA('Start') has been called
%     KbControlGKA('Reset')
%         Stop listening for key presses, irrespective of how many times
%         KbControlGKA('Start') has been called
% KbControlGKA calls KbQueueCreate, KbQueueStart, KbQueueStop, and
% KbQueueRelease as necessary such that calls to KbQueueCheck between the
% 'Start' and 'Stop' commands will work. If the 'Start' command is called
% twice without 'Stop' being called between them, the second call to
% 'Start' has no effect, and two calls to 'Stop' are required to really
% stop listening for keypresses. This allows subfunctions to call 'Start'
% and 'Stop' without generating errors due to KbQueueCreate, etc, being
% called too many times. In case errors are generated so that a script
% exits without 'Stop' being called enough times, the 'Reset' command will
% reset the function.

persistent callDepth
if isempty(callDepth)
    callDepth = 0;
end

switch cmd
    case 'Start'
        if callDepth==0
            fprintf('%s: Beginning to listen for keypresses.\n', mfilename);
            fprintf('%s: If your script exits and MATLAB is unresponsive to keypresses,\n', mfilename);
            fprintf('%s: press CTRL-C or <a href="matlab:KbControlGKA(''Reset'')">click here</a>.\n', mfilename);
            KbName('UnifyKeyNames');
            KbQueueCreate;
            KbQueueStart;
            ListenChar(2);
        end
        callDepth = callDepth + 1;
    case 'Stop'
        if callDepth==1
            KbQueueStop;
            KbQueueRelease;
            ListenChar(0);
        end
        if callDepth > 0
            callDepth = callDepth - 1;
        end
    case 'Reset'
        callDepth = 0;
        ListenChar(0);
        try %#ok<TRYNC>
            KbQueueStop;
            KbQueueRelease;
        end
    otherwise
        warning('KbControlGKA:badCmd', ...
            'KbControlGKA: Unrecognized command "%s"', cmd);
end

    
    