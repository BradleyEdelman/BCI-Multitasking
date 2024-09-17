function EEG = c_EEG_epochConvertToEEGLab(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.parse(varargin{:});

c_say('Converting EEG epochs to EEGLab format');

EEG = p.Results.EEG;

if ~isfield(EEG,'epochs')
	error('Epochs not yet set. Use c_EEG_epoch().');
end

if ~isfield(EEG.epochs,'data')
	EEG = c_EEG_epochExtractData(EEG);
end

EEG.xmin = min(EEG.epochs.relativeTime);
EEG.xmax = max(EEG.epochs.relativeTime);
EEG.pnts = EEG.epochs.epochLength;
EEG.times = EEG.epochs.relativeTime * 1e3; % convert from s to ms
EEG.data = permute(EEG.epochs.data,[1 3 2]);

count = 1;
newevent(1) = EEG.event(1); newevent(1).epoch = 0;
for index=1:length(EEG.epochs.eventIndices)
	tmp        = EEG.event(EEG.epochs.eventIndices(index));
	tmp.epoch = index;
	tmp.latency = tmp.latency - EEG.epochs.dataStartIndices(index) + EEG.epochs.numBefore + 1 + (index-1)*EEG.epochs.epochLength;
	newevent(count) = tmp;
	count = count + 1;
end
EEG.event = newevent;
EEG.epoch = [];
c_say('Checking updated event consistency');
EEG = eeg_checkset(EEG, 'eventconsistency');
c_sayDone();

c_sayDone();

end
