function EEG = c_EEG_epochExtractData(EEG)

% find longest epoch, to then pad all other epochs to same length with NaNs
durations = EEG.epochs.dataEndIndices - EEG.epochs.dataStartIndices + 1 + EEG.epochs.numBefore + EEG.epochs.numAfter;
longestDuration = max(durations);

EEG.epochs.data = nan(EEG.nbchan,EEG.epochs.numEpochs,longestDuration);
EEG.epochs.epochLength = longestDuration;
EEG.epochs.epochDuration = EEG.epochs.epochLength / EEG.srate;
EEG.epochs.durations = durations / EEG.srate;
EEG.epochs.epochLongestTrialDuration = (longestDuration - EEG.epochs.numBefore - EEG.epochs.numAfter) / EEG.srate;

EEG.epochs.relativeTime = (0:(1/EEG.srate):EEG.epochs.epochDuration) - EEG.epochs.timeBefore;
EEG.epochs.relativeTime = EEG.epochs.relativeTime(1:(end-1));

%TODO: add support for padding with NaNs for if time before epoch
%extends before start of recording or after end of recording

EEG.epochs.eventTimes = nan(EEG.epochs.numEpochs,2);

for e=1:EEG.epochs.numEpochs
	startIndex = EEG.epochs.dataStartIndices(e) - EEG.epochs.numBefore;
	endIndex = EEG.epochs.dataEndIndices(e) + EEG.epochs.numAfter;
	if endIndex > size(EEG.data,2)
		durations(e) = durations(e) - (endIndex - size(EEG.data,2));
		endIndex = size(EEG.data,2);
	end
	EEG.epochs.data(:,e,1:durations(e)) = EEG.data(:,startIndex:endIndex);
	
	% record times of each event within epoch, for later time warping
% 	EEG.epochs.eventTimes(e,1) = -1*EEG.epochs.timeBefore; % start of pre-trial data
	EEG.epochs.eventTimes(e,1) = 0; % start of trial
	EEG.epochs.eventTimes(e,2) = (durations(e) - EEG.epochs.numBefore - EEG.epochs.numAfter - 1)/EEG.srate; % end of trial
% 	EEG.epochs.eventTimes(e,4) = (durations(e) - EEG.epochs.numBefore -1)*EEG.srate; % end of post-trial data
	EEG.epochs.startTimes(e) = EEG.times(startIndex)/1e3; % absolute time at relative time=0
end

end