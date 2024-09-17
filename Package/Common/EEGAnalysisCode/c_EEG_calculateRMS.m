function RMS = c_EEG_calculateRMS(varargin)
%% c_EEG_calculateRMS calculate RMS values for a span of EEG data
% 
% If data is epoched, computes a RMS value for each trial
% If no channelNum is specified, will default to first channel.

p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('timespan',[],@(x) isempty(x) || (isnumeric(x) && length(x)==2)); % in s
p.addParameter('channelNum',1,@isscalar);
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;


if isempty(s.timespan)
	indices = 1:length(EEG.times);
	assert(~isempty(indices));
else
	indices = EEG.times*1e-3 >= s.timespan(1) & EEG.times*1e-3 < s.timespan(2);
	assert(sum(indices)>0);
end

RMS = sqrt(mean((EEG.data(s.channelNum,indices,:)).^2,2));

end