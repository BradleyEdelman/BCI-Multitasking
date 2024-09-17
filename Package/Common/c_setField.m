function struct = c_setField(struct,fieldName,value)

assert(ischar(fieldName));
i = find(fieldName=='.',1,'first');
if isempty(i)
	struct.(fieldName) = value;
else
	% recursive call
	struct.(fieldName(1:i-1)) = c_setField(struct.(fieldName(1:i-1)),fieldName(i+1:end),value);
end
if nargout == 0
	warning('Must assign output of %s to store changes to struct',mfilename);
end

end
