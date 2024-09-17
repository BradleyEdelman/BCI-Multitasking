function isEpoched = c_EEG_isEpoched(EEG)
	isEpoched = EEG.trials > 1;
end