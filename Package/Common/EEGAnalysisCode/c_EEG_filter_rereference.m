function EEG = c_EEG_filter_rereference(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('channelsToExclude',{},@iscell);
p.parse(varargin{:});

EEG = p.Results.EEG;

if ~isempty(p.Results.channelsToExclude)
	channelIndicesToExclude = c_EEG_getChannelIndex(EEG,p.Results.channelsToExclude);
else
	channelIndicesToExclude = [];
end

channelIndicesToInclude = 1:EEG.nbchan;
channelIndicesToInclude(channelIndicesToExclude) = [];

% re-referencing to global mean

globalAverage = nanmean(EEG.data(channelIndicesToInclude,:,:),1);

EEG.data = bsxfun(@minus,EEG.data,globalAverage);

if isfield(EEG,'epochs') && isfield(EEG.epochs,'data')
	warning('EEG epoch data has been extracted previously, but only applying filter to raw data. Re-extract epoch data.');
end


end