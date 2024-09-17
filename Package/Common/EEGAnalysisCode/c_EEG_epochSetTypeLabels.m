function EEG = c_EEG_epochSetTypeLabels(EEG,labels)
	if length(labels) ~= length(EEG.epochs.uniqueTypes)
		warning('Number of epoch label types does not match number of epoch types');
	end
	EEG.epochs.typeLabels = labels;
end