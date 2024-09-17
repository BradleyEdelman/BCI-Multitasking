function absChannelLabels = c_EEG_getAbsoluteChannelLabelsFromRelative(relChannelLabels,isLeft)
	if ~iscell(relChannelLabels)
		absChannelLabels = getAbsoluteChannelLabel(relChannelLabels,isLeft);
	else
		for i=1:length(relChannelLabels)
			absChannelLabels{i} = getAbsoluteChannelLabel(relChannelLabels{i},isLeft);
		end
	end
end

function absCh = getAbsoluteChannelLabel(relCh,isLeft)
	chPrefix = relCh(1:end-1);
	chNumStr = relCh(end);
	if strcmp(chNumStr,'z')
		absCh = relCh;
		return;
	end
	if chNumStr >= '1' && chNumStr <= '9'
		% already an absolute channel label, do nothing
		absCh = relCh;
		return;
	end
	if chNumStr > 'j' || chNumStr < 'a'
		error('Channel label ''%s'' is invalid',relCh);
	end
	chNum = chNumStr - 'a' + 1;
	if isLeft 
		absCh = [chPrefix num2str(chNum)];
	else
		absCh = [chPrefix num2str(chNum-1+mod(chNum,2)*2)];
	end
end
