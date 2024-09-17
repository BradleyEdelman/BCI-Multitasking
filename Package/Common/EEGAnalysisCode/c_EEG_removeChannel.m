function EEG = c_EEG_removeChannel(varargin)
p = inputParser;
p.addRequired('EEG',@isstruct);
p.addRequired('ChannelsToRemove',@(x) ischar(x) || isscalar(x) || iscellstr(x) || isvector(x));
p.parse(varargin{:});
EEG = p.Results.EEG;
channelsToRemove = p.Results.ChannelsToRemove;

if ischar(channelsToRemove) || iscellstr(channelsToRemove)
	channelsToRemove = c_EEG_getChannelIndex(EEG,channelsToRemove);
end

numChToRemove = length(channelsToRemove);

origDatSize = size(EEG.data);
EEG.data = reshape(EEG.data,origDatSize(1),prod(origDatSize(2:end)));

EEG.data(channelsToRemove,:) = [];
EEG.chanlocs(channelsToRemove) = [];

EEG.data = reshape(EEG.data,[origDatSize(1)-numChToRemove, origDatSize(2:end)]);

EEG.nbchan = EEG.nbchan - numChToRemove;

end