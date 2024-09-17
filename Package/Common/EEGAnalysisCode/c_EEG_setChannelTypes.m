function EEG = c_EEG_setChannelTypes(EEG)

if isempty(EEG.chanlocs)
	error('No channel labels specified.');
end

EEGLabels = {'Fp1','Fp2','F3','F4','C3','C4','P3','P4','O1','O2','F7','F8','T7',...
	'T8','P7','P8','Fz','Cz','Pz','Oz','FC1','FC2','CP1','CP2','FC5','FC6','CP5',...
	'CP6','TP9','TP10','POz','F1','F2','C1','C2','P1','P2','AF3','AF4','FC3',...
	'FC4','CP3','CP4','PO3','PO4','F5','F6','C5','C6','P5','P6','AF7','AF8','FT7',...
	'FT8','TP7','TP8','PO7','PO8','FT9','FT10','Fpz','CPz','Iz'};

EMGLabels = {'EMG1','EMG2','EMG3','EMG4','EMG5','EMG6','EMG7','EMG8',...
	'M1','M2','EMG'};

EOGLabels = {'HEO','VEO'};

ECGLabels = {'ECG','EKG'};

labelSets = {EEGLabels, EMGLabels, EOGLabels, ECGLabels};
labelTypes = {'EEG',	'EMG',		'EOG',		'ECG'};

for iT = 1:length(labelSets)
	% convert to lower case
	labelSets{iT} = lower(labelSets{iT});
end

% make sure there are no labels shared across multiple sets
for iT = 1:length(labelSets)
	for jT = iT+1:length(labelSets)
		assert(~any(ismember(labelSets{iT},labelSets{jT})));
	end
end

for iE = 1:length(EEG.chanlocs)
	typeSet = false;
	for iT = 1:length(labelSets)
		if ismember(lower(EEG.chanlocs(iE).labels),labelSets{iT});
			EEG.chanlocs(iE).type = labelTypes{iT};
			typeSet = true;
			break;
		end
	end
	if ~typeSet
		if 1
			error('Type of channel %s is not known',EEG.chanlocs(iE).labels);
		else
			warning('Type of channel %s is not known',EEG.chanlocs(iE).labels);
			EEG.chanlocs(iE).type = '';
		end
	end
end

end