function logicalAbortIndices = c_EEG_findAbortIndices(EEG)
	% After importing BCI2000 data into EEGlab, aborts are not specifically marked with events. Rather, they are
	%  just trials without a ResultCode event. Find these trials.
	
	feedbackIndices = find(ismember({EEG.event.type},'Feedback'));
	resultCodeIndices = find(ismember({EEG.event.type},'ResultCode'));
	
	if length(feedbackIndices) == length(resultCodeIndices)
		% no aborts
		logicalAbortIndices = zeros(1,length(feedbackIndices));
		return;
	end
	
	eventTimes = cell2mat({EEG.event.latency});
	feedbackEventTimes = eventTimes(feedbackIndices);
	resultEventTimes = eventTimes(resultCodeIndices);
	
	% find where there are two feedback events in a row, without a result event in between 
	resultCounter = 1;
	logicalAbortIndices = false(1,length(feedbackIndices));
	for feedbackCounter=1:(length(feedbackIndices)-1)
		nextFeedbackTime = feedbackEventTimes(feedbackCounter+1);
		if resultCounter <= length(resultEventTimes) && resultEventTimes(resultCounter) < nextFeedbackTime
			resultCounter = resultCounter + 1;
			logicalAbortIndices(feedbackCounter) = false;
		else
			logicalAbortIndices(feedbackCounter) = true;
		end
	end
	
	if resultEventTimes(end) < feedbackEventTimes(end)
		% last trial was an abort
		logicalAbortIndices(end) = true;
	end
end

