function a = c_str_cellArrayToArray(c)
	% convert cell array of strings to padded array of strings (i.e. a character matrix)
	assert(size(c,2)==1); 
	assert(iscellstr(c));
	maxLength = max(cellfun(@length,c));
		
	a = repmat(' ',size(c,1),maxLength);
	for i=1:length(c)
		a(i,1:length(c{i})) = c{i};
	end
end