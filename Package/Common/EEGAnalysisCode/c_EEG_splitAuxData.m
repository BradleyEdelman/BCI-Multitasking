function EEG = c_EEG_splitAuxData(EEG)
% split aux data from EEG data after (e.g. after merging for epoching)

assert(isfield(EEG,'auxDataLabels'));

numAuxCh = length(EEG.auxDataLabels);
EEG.nbchan = EEG.nbchan - numAuxCh;
EEG.chanlocs((end-numAuxCh+1):end) = [];

if isempty(EEG.data)
	EEG.auxData = [];
else
	origSize = size(EEG.data);
	EEG.data = reshape(EEG.data,origSize(1),prod(origSize(2:end)));

	EEG.auxData = EEG.data(end-numAuxCh+1:end,:);
	EEG.auxData = reshape(EEG.auxData,[size(EEG.auxData,1), origSize(2:end)]);

	EEG.data = EEG.data(1:(end-numAuxCh),:);
	EEG.data = reshape(EEG.data,[size(EEG.data,1), origSize(2:end)]);
end
end