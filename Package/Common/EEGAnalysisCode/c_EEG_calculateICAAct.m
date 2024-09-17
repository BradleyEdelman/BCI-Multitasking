function EEG = c_EEG_calculateICAAct(EEG)

	assert(isstruct(EEG));

	EEG.icaact = []; % clear any previously calculated component time courses 
	
	% code taken from eeglab function eeg_getica()
	if isempty(EEG.icachansind)
        EEG.icachansind = 1:EEG.nbchan;
	end	
	comp = 1:size(EEG.icaweights,1);
    icaact = (EEG.icaweights(comp,:)*EEG.icasphere)*reshape(EEG.data(EEG.icachansind,:,:), length(EEG.icachansind), EEG.trials*EEG.pnts);
    icaact = reshape( icaact, size(icaact,1), EEG.pnts, EEG.trials);
	
	EEG.icaact = icaact;
end
