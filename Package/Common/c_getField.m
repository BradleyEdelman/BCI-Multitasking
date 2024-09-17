function res = c_getField(struct,fieldName)
	assert(ischar(fieldName))
	i = find(fieldName=='.',1,'first');
	if isempty(i)
		res = struct.(fieldName);
	else
		% recursive call
		res = c_getField(struct.(fieldName(1:i-1)),fieldName(i+1:end));
	end
end