function relChannelLabels = c_EEG_getRelativeChannelLabelsFromAbsolute(absChannelLabels,isLeft)
	if ~iscell(absChannelLabels)
		relChannelLabels = getRelativeChannelLabel(absChannelLabels,isLeft);
	else
		for i=1:length(absChannelLabels)
			relChannelLabels{i} = getRelativeChannelLabel(absChannelLabels{i},isLeft);
		end
	end
end

function relCh = getRelativeChannelLabel(absCh,isLeft)
	chPrefix = absCh(1:end-1);
	chNumStr = absCh(end);
	if strcmp(chNumStr,'z')
		relCh = absCh;
		return;
	end
	if chNumStr >= 'a' && chNumStr <= 'z'
		% already a relative channel label, do nothing
		relCh = absCh;
		return;
	end
	chNum = str2double(chNumStr);
	if isempty(chNum)
		error('Channel label ''%s'' is invalid',absCh);
	end
	if isLeft 
		relCh = [chPrefix char('a'+chNum-1)];
	else
		relCh = [chPrefix char('a'+chNum-(2-mod(chNum,2)*2))];
	end
end
