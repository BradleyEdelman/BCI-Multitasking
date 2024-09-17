function [cursorPositions, cursorPositionTimes] = c_EEG_extractCursorPosition(varargin)
	%% extract trial-wise cursor positions, with NaNs for unknown positions
	% output format depends on parameter doReturnPaddedMatrix. If true, returns 3d fixed length matrix padded with NaNs.
	%  If false, returns cell array of matrices, with each element of the cell array corresponding to
	%  a single trial (of variable length)
	%
	% cursorPositionTimes are returned in seconds.

	if nargin == 0
		% for testing
		c_sayResetLevel;
		c_say('No input parameters, running test...');
		testPath = 'D:/BCIYoga/SubjectData/JMP/JMP_LRt_20141017001/JMP_LRt_20141017S001R01.dat';
		eeglab;
		EEG = c_loadBCI2000Data(testPath);
		if 0
			[pos, posTimes] = c_EEG_extractCursorPosition(EEG,'doReturnPaddedMatrix',false);
			dimToPlot = 1;
			figure;
			for i=1:length(pos)
				relativeTimes = posTimes{i} - posTimes{i}(1);
				plot(relativeTimes, pos{i}(dimToPlot,:));
				hold on;
			end
		else
			[pos, posTimes] = c_EEG_extractCursorPosition(EEG,'doReturnPaddedMatrix',true);
			dimToPlot = 1;
			figure;
			for i=1:size(pos,1)
				relativeTimes = posTimes(i,:) - posTimes(i,1);
				plot(relativeTimes, squeeze(pos(i,dimToPlot,:)));
				hold on;
			end
		end
		c_sayDone();
		
		keyboard
	end
	
	p = inputParser;
	p.addRequired('EEG',@isstruct);
	p.addParameter('doReturnPaddedMatrix',true,@islogical);
	p.addParameter('trialStartPosition',[2050 2050 2050],@isnumeric);
	p.parse(varargin{:});
	
	EEG = p.Results.EEG;
	
	% extract cursor positions separately for each trial
	feedbackEventIndices = find(ismember({EEG.event.type},'Feedback'));
	
	eventTimes = cell2mat({EEG.event.latency})/1e3;
	
	trialStartTimes = eventTimes(feedbackEventIndices);
	trialDurations = paren(cell2mat({EEG.event.duration}),feedbackEventIndices)/1e3;
	trialEndTimes = trialStartTimes + trialDurations;
	
	dt = 40e-3; % s
	
	positionEventTypes = {'CursorPosX','CursorPosY','CursorPosZ'};
	for i=1:length(positionEventTypes) % for each cursor dimension
		positionEventIndices{i} = find(ismember({EEG.event.type},positionEventTypes{i}));
		positionEventTimes{i} = eventTimes(positionEventIndices{i});
		
		% assume that position updates are all multiples of 40 ms apart.
		% check assumption
		tmp = mod(diff(positionEventTimes{i}),dt);
		if any(tmp>1e5*eps & tmp<(dt-1e5*eps))
			error('Position updates not at multiples of %d ms apart',dt);
		end
	end
	
	if isempty(p.Results.trialStartPosition)
	% 	startingPositions = nan(length(positionEventTypes),1);
		startingPositions = nan(length(positionEventTypes),1);
	else
		startingPositions = reshape(p.Results.trialStartPosition,[],1);
	end
	
	for j=1:length(trialStartTimes) % for each trial
		cursorPositionTimes{j} = (trialStartTimes(j):dt:trialEndTimes(j));
		numFrames = length(cursorPositionTimes{j});
		cursorPositions{j} = repmat(startingPositions,1,numFrames);
		
		for i=1:length(positionEventTypes) % for each cursor dimension
			for k=1:length(positionEventTimes{i}) % for each position update
				if positionEventTimes{i}(k) < cursorPositionTimes{j}(1)
					continue; % haven't yet gotten to beginning of trial
				end
				if positionEventTimes{i}(k) > cursorPositionTimes{j}(end)
					break; % reached end of trial
				end
				i_t_start = c_indexInAClosestToB(cursorPositionTimes{j}, positionEventTimes{i}(k));
				i_t_end = length(cursorPositionTimes{j}); % always write to end of trial (a little inefficient, but simple)
				newPosition = EEG.event(positionEventIndices{i}(k)).position;
				cursorPositions{j}(i,i_t_start:i_t_end) = newPosition;
				if isempty(p.Results.trialStartPosition)
					startingPositions(i) = newPosition; % for the next trial
				end
			end
		end
	end
	
	% convert from cell array of 2d matrices of variable length to 3d matrix padded to fixed length
	if p.Results.doReturnPaddedMatrix
		
		maxTrialLength = 0;
		numTrials = length(cursorPositionTimes);
		for j=1:numTrials
			trialLength = length(cursorPositionTimes{j});
			if trialLength > maxTrialLength, maxTrialLength = trialLength; end
		end
		
		paddedCursorPositions = nan(numTrials,length(positionEventTypes),maxTrialLength);
		paddedCursorTimes = nan(numTrials,maxTrialLength);
		for j=1:numTrials
			numFrames = size(cursorPositions{j},2);
			paddedCursorPositions(j,:,1:numFrames) = cursorPositions{j};
			paddedCursorTimes(j,1:numFrames) = cursorPositionTimes{j};
		end
		
		cursorPositionTimes = paddedCursorTimes;
		cursorPositions = paddedCursorPositions;
	end
end

