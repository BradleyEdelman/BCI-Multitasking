function outcomes = c_EEG_extractTrialOutcomes(EEG)
	%% extract vector of trial outcomes (results) from EEG struct, also inserting NaN values for aborts

	resultCodeIndices = find(ismember({EEG.event.type},'ResultCode'));
	
	outcomes = paren(cell2mat({EEG.event.position}),resultCodeIndices);
	
	abortCode = NaN;
	
	% insert abort results (if any)
	abortIndices = find(c_EEG_findAbortIndices(EEG));
	for i=1:length(abortIndices)
		outcomes = [outcomes(1:(abortIndices(i)-1)) abortCode outcomes(abortIndices(i):end)];
	end
	
end

