function [channelIndices, channelNames] = c_EEG_findMissingChannels(EEG,refEEG)
	channelsInA = {EEG.chanlocs.labels};
	channelsInB = {refEEG.chanlocs.labels};
	
	channelIndices = find(~ismember(channelsInB,channelsInA));
	
	if nargout > 1
		channelNames = c_EEG_getChannelName(refEEG,channelIndices);
	end
end