function EEG = c_EEG_embedCursorPosition(varargin)
%% embed trial-wise cursor positions (input in continuous form) as CursorPos events in EEG data
% (for use, for example, after offline simulation of new cursor trajectories)

p = inputParser;
p.addRequired('EEG',@isstruct);
p.addRequired('cursorPositions',@isnumeric);
p.addRequired('cursorPositionTimes',@isnumeric);
p.parse(varargin{:});

EEG = p.Results.EEG;

%TODO: continue

error('function incomplete');

end

