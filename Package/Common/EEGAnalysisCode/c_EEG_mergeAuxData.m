function EEG = c_EEG_mergeAuxData(EEG)
% combine aux data into EEG data for other processing (e.g. epoching)

assert(isfield(EEG,'auxData'));
assert(isfield(EEG,'auxDataLabels'));
assert(length(EEG.auxDataLabels)==size(EEG.auxData,1));
assert(ndims(EEG.auxData)==ndims(EEG.data));
origSize = size(EEG.data);
origAuxSize = size(EEG.auxData);
assert(all(origSize(2:end)==origAuxSize(2:end)));

EEG.data = cat(1,EEG.data,EEG.auxData);
for i=1:length(EEG.auxDataLabels)
	EEG.chanlocs(EEG.nbchan+i).labels = EEG.auxDataLabels{i};
end
EEG.nbchan = EEG.nbchan + length(EEG.auxDataLabels);

EEG.auxData = [];
% leave auxDataLabels in place to determine number of aux channels later when splitting

end