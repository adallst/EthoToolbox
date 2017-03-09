classdef EthoMovie < handle
    properties
        % Externally mutable properties
        position       = []; % l,t,r,b rectangle on the screen
        rate           = 1;
        volume         = 1;
        interframeFunc = []; % Function to execute between frames
    end

    properties (Dependent, Transient)
        % Mutable playback properties
        timeIndex;
        frameIndex;
    end

    properties (SetAccess = private, Transient = true)
        % Read-only pointers for PTB Screen functions
        scnWinPtr = []; % Pointer to window for drawing
        scnMovPtr = []; % Pointer to movie
    end


    properties (SetAccess = private)
        % Immutable properties describing movie
        filename   = ''; % Movie file
        duration   = 0;  % Movie duration, in seconds
        fps        = 0;  % Frame rate
        nativeSize = []; % Native resolution of the movie, as a two-element
                         % width,height vector (in pixels)

        % Read-only properties describing playback history
        frameHistory   = []; % A list of the time indices of all frames
                             % that were drawn during this movie's playback
        drawTimes      = []; % A list of PTB's timestamps for all frame
                             % drawing events during this movie's playback
        interframeData = {}; % A list of return values from interframeFunc

        % Read-only properties describing playback
        isPlaying = false;
    end

    methods
        function obj = EthoMovie(filename, varargin)
% EthoMovie   Wrapper class for PTB movie playback
% Constructor:
%   movie = EthoMovie(filename, 'Parameter', value, ...)
%     Valid parameters are:
%     'Position':       Where on the screen to draw the movie images. Valid
%                       options are:
%                       'fullscreen' to draw full screen but at the native
%                         aspect ratio
%                       'center' (default) to draw at native resolution in
%                         the center of the screen
%                       'stretch' to draw at full screen at the screen's
%                         aspect ratio
%                       or a 4 element vector describing the left, top,
%                         right, bottom rectangle
%     'PlayRate':       Rate at which to play movie, relative to normal
%                       (default is 1)
%     'SoundVolume':    Volume of sound during playback, between 0 and 1
%                       (default is 1)
%     'InterframeFunc': Handle to a function to call after every frame is
%                       drawn (see below)
%     'Window':         Pointer to the PTB Screen window in which the movie
%                       will play. May also be set to 'auto' (default) to
%                       attempt to determine the proper window
%                       automatically, or 'none' to create an invalid
%                       player.
% The proper form for the interframe function handle is:
%   [abort, data] = @(movie)
% where abort is a logical scalar that, when set to true, tells the player
% to stop, data is any value which will be stored in a cell array in the
% field interframeData, such that interframeData{k} is the return value of
% the interframe function when called after the k'th frame drawing. movie
% is a handle to the player, allowing the interframe function to access and
% modify the movie player, to, for example, change the playback rate.
%
% Mutable properties:
%     position:        A four element vector describing the
%                      [left,top,bottom,right] rectangle in which the movie
%                      will be drawn
%     rate:            The relative speed for playing the movie, where 1 is
%                      normal speed, and -1 is reverse normal
%     volume:          The relative volume for the movie's sound, ranging
%                      between 0 (mute) and 1 (full volume)
%     interframeFunc:  A function handle to be called after every frame
%                      drawing (see above).
%     timeIndex:       The current time index of the movie.
%     frameIndex:      The current frame number of the movie.
% Read-only properties:
%     filename:        The name of the movie file from which the movie is
%                      played
%     duration:        The duration of the whole movie, in seconds
%     fps:             The native frame rate of the movie
%     nativeSize:      The native resolution of the movie, as a two-element
%                      [width,height] vector (in pixels)
%     frameHistory:    A record of the movie's playback in the form of a
%                      vector such that frameHistory(k) is the time index
%                      in the movie of the k'th frame drawn during
%                      playback.
%     drawTimes:       A record of the movie's playback in the form of a
%                      vector such that drawTimes(k) is the time in PTB's
%                      GetSecs clock at which the k'th frame was drawn
%                      during playback.
%     interframeData:  A record of return values from interframeFunc, such
%                      that interframeData{k} is the return value of
%                      interframeFunc when it was called after the k'th
%                      frame during playback.
%     isPlaying:       A logical scalar set to true if the movie is
%                      currently playing. This should only happen during a
%                      call to the interframeFunc.
% Methods:
%     Fullscreen:      Set position such that the movie occupies as much of
%                      the screen as possible while retaining its original
%                      aspect ratio.
%     Center:          Set position such that the movie is played at its
%                      native resolution, centered in the middle of the
%                      screen.
%     Stretch:         Set position such that the movie occupies the entire
%                      screen, without preserving its original aspect
%                      ratio.
%     Play:            Play the movie.
%     GetHistory:      Return a struct that clones the data from the fields
%                      filename, duration, fps, nativeSize, frameHistory,
%                      drawTimes, and interframeData.
%     ClearHistory:    Reset the frameHistory, drawTimes, and
%                      interframeData fields.
%     GetCurrentFrame: Retrieve a texture for the frame at the current time
%                      index.
%     Close:           Close the movie and render the player invalid.
%                      Invalid players will generate errors when methods or
%                      properties are accessed that are associated with an
%                      active player (e.g., Play, or rate), but their
%                      historical read-only properites can still be
%                      accessed.
            p = inputParser;
            p.FunctionName = 'EthoMovie';
            p.addParamValue('Position', 'center');
            p.addParamValue('PlayRate', 1);
            p.addParamValue('SoundVolume', 1);
            p.addParamValue('InterframeFunc', [], ...
                @(x)(isempty(x) || isa(x,'function_handle')) );
            p.addParamValue('Window', 'auto');
            p.parse(varargin{:});

            if ischar(p.Results.Window)
                switch p.Results.Window
                    case 'auto'
                        winPtr = Screen('Windows');
                        winPtr = winPtr(Screen(winPtr,'WindowKind')==1);
                        if isscalar(winPtr)
                            obj.scnWinPtr = winPtr;
                        elseif isempty(winPtr)
                            error('EthoMovie:noWindows', ['No window ' ...
                                'currently open for movie display.']);
                        else
                            error('EthoMovie:windowPointer', ['Unable ' ...
                                'to determine display window ' ...
                                'automatically.']);
                        end
                    case 'none'
                        % Create an invalid movie player
                    otherwise
                        error('EthoMovie:badParameter', ...
                            'Invalid option for "Window"');
                end
            else
                obj.scnWinPtr = p.Results.Window;
            end

            obj.filename = filename;
            [obj.scnMovPtr, obj.duration, obj.fps, width, height] = ...
                Screen('OpenMovie', winPtr, filename);
            obj.nativeSize = [width height];

            if ischar(p.Results.Position)
                switch p.Results.Position
                    case 'fullscreen'
                        obj.Fullscreen;
                    case 'stretch'
                        obj.Stretch;
                    case 'center'
                        obj.Center;
                    otherwise
                        error('EthoMovie:badParameter', ...
                            'Invalid option for "Position"');
                end
            else
                obj.position = p.Results.Position;
            end
            obj.rate = p.Results.PlayRate;
            obj.volume = p.Results.SoundVolume;
            obj.interframeFunc = p.Results.InterframeFunc;
        end

        function Fullscreen(obj)
            if isempty(obj.scnWinPtr)
                return;
            end
            winRect = Screen('Rect', obj.scnWinPtr);
            winSize = winRect(3:4) - winRect(1:2);
            sizeScale = min(winSize ./ obj.nativeSize);
            movieSize = sizeScale * obj.nativeSize;
            center = floor((winRect(3:4) - winRect(1:2))/2);
            movieRect = floor([-movieSize movieSize] / 2);
            obj.position = movieRect + [center center];
        end

        function Center(obj)
            if isempty(obj.scnWinPtr)
                return;
            end
            winRect = Screen('Rect', obj.scnWinPtr);
            winCenter = ceil(winRect(3:4)/2);
            movCenter = ceil(obj.nativeSize/2);
            shift = winCenter - movCenter;
            obj.position = [0 0 obj.nativeSize] + [shift shift];
        end

        function Stretch(obj)
            if isempty(obj.scnWinPtr)
                return;
            end
            winRect = Screen('Rect', obj.scnWinPtr);
            obj.position = winRect;
        end

% %         function Play(obj, clip)
% %             if obj.isPlaying
% %                 Screen('PlayMovie', obj.scnMovPtr, 0);
% %                 obj.isPlaying = false;
% %                 error('EthoMovie:alreadyPlaying', ...
% %                     'Movie was already playing!');
% %             end
% %             if obj.rate == 0
% %                 return
% %             end
% %             if nargin < 2 || isempty(clip)
% %                 if obj.rate > 0
% %                     stopTime = Inf;
% %                 else
% %                     stopTime = 0;
% %                 end
% %             elseif isscalar(clip)
% %                 Screen('SetMovieTimeIndex', obj.scnMovPtr, clip);
% %                 if obj.rate > 0
% %                     stopTime = Inf;
% %                 else
% %                     stopTime = 0;
% %                 end
% %             else
% %                 Screen('SetMovieTimeIndex', obj.scnMovPtr, clip(1));
% %                 stopTime = clip(2);
% %             end
% %
% %             Screen('PlayMovie', obj.scnMovPtr, obj.rate, 0, obj.volume);
% %             while obj.rate ~= 0
% %                 [texPtr, nextFrameTime] = Screen('GetMovieImage', ...
% %                     obj.scnWinPtr, obj.scnMovPtr);
% %                 if texPtr <= 0
% %                     break;
% %                 end
% %                 if (obj.rate > 0 && nextFrameTime > stopTime) ...
% %                         || (obj.rate < 0 && nextFrameTime < stopTime)
% %                     Screen('Close', texPtr);
% %                     break;
% %                 end
% %                 Screen('DrawTexture', obj.scnWinPtr, texPtr, [], ...
% %                     obj.position);
% %                 [VBLts, drawTime] = ...
% %                     Screen('Flip', obj.scnWinPtr);
% %                 Screen('Close', texPtr);
% %                 obj.frameHistory(end+1) = nextFrameTime;
% %                 obj.drawTimes(end+1) = drawTime;
% %
% %                 if ~isempty(obj.interframeFunc)
% %                     [abort, newData] = obj.interframeFunc(obj);
% %                     obj.interframeData{end+1} = newData;
% %                     if abort
% %                         break;
% %                     end
% %                 end
% %             end
% %             Screen('PlayMovie', obj.scnMovPtr, 0);
% %         end
% %
        function Play2(obj, clip)
            if obj.isPlaying
                Screen('PlayMovie', obj.scnMovPtr, 0);
                obj.isPlaying = false;
                error('EthoMovie:alreadyPlaying', ...
                    'Movie was already playing!');
            end
            if obj.rate == 0
                return
            end
            if nargin < 2 || isempty(clip)
                if obj.rate > 0
                    stopTime = Inf;
                else
                    stopTime = 0;
                end
            elseif isscalar(clip)
                Screen('SetMovieTimeIndex', obj.scnMovPtr, clip);
                if obj.rate > 0
                    stopTime = Inf;
                else
                    stopTime = 0;
                end
            else
                Screen('SetMovieTimeIndex', obj.scnMovPtr, clip(1));
                stopTime = clip(2);
            end
            Play2(obj,[randStart randStart + 5]);

            screenData = Screen('Resolution', obj.scnWinPtr);
            halfUpdate = 0.5/screenData.hz;

            % For improved performance here, Play2 will ignore rate and
            % volume.  Playback rate is 1, volume is 0.
            %Screen('PlayMovie', obj.scnMovPtr, obj.rate, 0, obj.volume);
            [texPtr, firstFrameTime] = Screen('GetMovieImage', ...
                obj.scnWinPtr, obj.scnMovPtr);
            if texPtr > 0
                Screen('DrawTexture', obj.scnWinPtr, texPtr, [], ...
                    obj.position);
                [firstVBLTime, drawTime] = Screen('Flip', obj.scnWinPtr);
                obj.frameHistory(end+1) = firstFrameTime;
                obj.drawTimes(end+1) = drawTime;
            end
            while texPtr > 0
                [texPtr, nextFrameTime] = Screen('GetMovieImage', ...
                    obj.scnWinPtr, obj.scnMovPtr);
                if texPtr <= 0
                    break;
                end
                if nextFrameTime > stopTime
                    Screen('Close', texPtr);
                    break;
                end
                Screen('DrawTexture', obj.scnWinPtr, texPtr, [], ...
                    obj.position);
                timeToDraw = firstVBLTime + nextFrameTime ...
                    - firstFrameTime - halfUpdate;
                [VBLts, drawTime] = ...
                    Screen('Flip', obj.scnWinPtr, timeToDraw);
                Screen('Close', texPtr);
                obj.frameHistory(end+1) = nextFrameTime;
                obj.drawTimes(end+1) = drawTime;
            end
        end

        function hist = GetHistory(obj)
            hist.filename = obj.filename;
            hist.duration = obj.duration;
            hist.fps = obj.fps;
            hist.nativeSize = obj.nativeSize;
            hist.frameHistory = obj.frameHistory;
            hist.drawTimes = obj.drawTimes;
            hist.interframeData = obj.interframeData;
        end

        function ClearHistory(obj)
            obj.frameHistory = [];
            obj.drawTimes = [];
            obj.interframeData = {};
        end

        function time = get.timeIndex(obj)
            time = Screen('GetMovieTimeIndex', obj.scnMovPtr);
        end

        function set.timeIndex(obj, time)
            Screen('SetMovieTimeIndex', obj.scnMovPtr, time);
        end

        function frameInd = get.frameIndex(obj)
            time = Screen('GetMovieTimeIndex', obj.scnMovPtr);
            frameInd = round(time * obj.fps);
        end

        function set.frameIndex(obj, frameInd)
            time = (frameInd - 0.5) / obj.fps;
            Screen('SetMovieTimeIndex', obj.scnMovPtr, time);
        end

        function set.rate(obj, newRate)
            obj.rate = newRate;
            if obj.isPlaying
                Screen('PlayMovie', obj.scnMovPtr, newRate);
            end
        end

        function set.volume(obj, newVolume)
            obj.volume = newVolume;
            if obj.isPlaying
                Screen('PlayMovie', obj.scnMovPtr, obj.rate, 0, newVolume);
            end
        end

        function [frameTexPtr, timeIndex] = GetCurrentFrame(obj)
            [frameTexPtr, timeIndex] = ...
                Screen('GetMovieImage', obj.scnWinPtr, obj.scnMovPtr);
        end

        function Close(obj)
            try %#ok<TRYNC>
                Screen('CloseMovie', obj.scnMovPtr);
            end
            obj.scnMovPtr = [];
        end

        function delete(obj)
            obj.Close;
        end
    end
end
