function Vpp = c_EEG_calculateVpp(varargin)
%% c_EEG_calculateVpp calculate peak-to-peak values for a span of EEG data
% 
% If data is epoched, computes a Vpp value for each trial
% If no channelNum is specified, will default to first channel.

p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('timespan',[],@(x) isempty(x) || (isnumeric(x) && length(x)==2)); % in s
p.addParameter('channelNum',1,@isscalar);
p.addParameter('channelName','',@(x) ischar(x) || (iscell(x) && length(x)==1));
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

if ~isempty(s.channelName) 
	if ~ismember(p.UsingDefaults,'channelNum')
		error('Only one of channelNum and channelStr should be specified');
	end
	s.channelNum = c_EEG_getChannelIndex(EEG,s.channelName);
end



if isempty(s.timespan)
	indices = 1:length(EEG.times);
	assert(~isempty(indices));
else
	indices = EEG.times*1e-3 >= s.timespan(1) & EEG.times*1e-3 < s.timespan(2);
	assert(sum(indices)>0);
end

% Vpp = nan(1,EEG.trials);
% for i=1:EEG.trials
% 	Vpp = abs(diff(extrema(EEG.data(s.channelNum,indices,i))));
% end
Vpp = abs(diff(extrema(EEG.data(s.channelNum,indices,:),[],2),1,2));

end