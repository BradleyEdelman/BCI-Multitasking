function [indicesToReject, indicesToRejectE] = c_EEG_rejectEpochsByThreshold(varargin)
p = inputParser;
p.addRequired('EEG',@isstruct);
p.addParameter('thresholds',[-100 100],@isnumeric); %  min and max thresholds. 
	% If single element, will be assumed to be both positive and negative
	% TODO: set to NaN to autoset threshold by standard deviation
p.addParameter('timespan',[],@(x) isnumeric(x) || islogical(x)); % (min,max) in S, or indices into time array
p.addParameter('channelIndices',[],@isnumeric); % if empty, use all channels
p.addParameter('minNumSuprathresholdElectrodes',1,@isscalar); % require X electrodes to be outside of threshold in a given epoch to reject it
p.parse(varargin{:});

EEG = p.Results.EEG;

% set thresholds
if length(p.Results.thresholds)==1
	maxThreshold = abs(p.Results.thresholds);
	minThreshold = -1*maxThreshold;
elseif length(p.Results.thresholds)==2
	maxThreshold = p.Results.thresholds(2);
	minThreshold = p.Results.thresholds(1);
end

% set time indices
if isempty(p.Results.timespan)
	timeIndices = true(size(EEG.times));
elseif length(p.Results.timespan)==2
	% assume (minTime, maxTime)
	timeIndices = EEG.times >= p.Results.timespan(1) & EEG.times <= p.Results.timespan(2);
elseif length(p.Results.timespan)==length(EEG.times) && all(islogical(p.Results.timespan))
	% assume indices into time array
	timeIndices = p.Results.timespan;
else
	error('Invalid timespan');
end

% set channel indices
if isempty(p.Results.channelIndices)
	channelIndices = 1:EEG.nbchan;
else
	channelIndices = p.Results.channelIndices;
end

maxValues = max(EEG.data(channelIndices,timeIndices,:),[],2);

minValues = min(EEG.data(channelIndices,timeIndices,:),[],2);

indicesToRejectE = minValues < minThreshold | maxValues > maxThreshold;
indicesToRejectE = permute(indicesToRejectE,[1 3 2]); % get rid of time dimension

% remap electrode indices to superset
tmp = false(EEG.nbchan,EEG.trials);
tmp(channelIndices,:) = indicesToRejectE;
indicesToRejectE = tmp;

indicesToReject = sum(indicesToRejectE,1) > p.Results.minNumSuprathresholdElectrodes;

end
