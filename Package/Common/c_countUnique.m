function varargout = c_countUnique(vec)

	uniqueVals = unique(vec(:));
	counts = nan(1,length(uniqueVals));
	for i=1:length(uniqueVals)
		counts(i) = sum(vec(:)==uniqueVals(i));
	end

	if nargout == 0
		% print results
		for i=1:length(uniqueVals)
			c_saySingle('%4s:\t%4d',c_toString(uniqueVals(i)),counts(i));
		end
	end
	
	if nargout >= 1
		varargout{1} = counts;
	end
	
	if nargout >= 2
		varargout{2} = uniqueVals;
	end
end