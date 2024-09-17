function vals = c_EEG_calculateAmplitudesAtTimes(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addRequired('times',@isvector); % in s
p.addParameter('channels',{},@iscell);
p.addParameter('localTimespan',[],@isvector);
p.addParameter('localOperation',@(x,dim) mean(x,dim),@(x) isa(x,'function_handle'));
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

allChannels = {EEG.chanlocs.labels};
if isempty(s.channels)
	s.channels = allChannels;
	s.channelIndices = 1:EEG.nbchan;
else
	s.channelIndices = c_EEG_getChannelIndex(EEG,s.channels);
end

vals = nan(length(s.channels), length(s.times), EEG.trials);
for iT = 1:length(s.times)
	assert(s.times(iT) >= EEG.xmin && s.times(iT) <= EEG.xmax);
	if isempty(s.localTimespan)
		[~,timeIndex] = min(abs(EEG.times/1e3 - s.times(iT)));
		vals(:,iT,:) = EEG.data(s.channelIndices,timeIndex,:);
	else
		% option for taking max/min/mean/etc. in timespan around time point of interest to calculate final value
		assert(length(s.localTimespan)==2 && s.localTimespan(1) < s.localTimespan(2)); 
		startTime = max(s.times(iT) + s.localTimespan(1),EEG.xmin);
		endTime = min(s.times(iT) + s.localTimespan(2),EEG.xmax);
		[~,startIndex] = min(abs(EEG.times/1e3 - startTime));
		[~,endIndex] = min(abs(EEG.times/1e3 - endTime));
		vals(:,iT,:) = s.localOperation(EEG.data(s.channelIndices,startIndex:endIndex,:),2);
	end
end

end