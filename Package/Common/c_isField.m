function res = c_isField(struct,field)
  % allows fields to be specified as nested strings 
	% (e.g. to check if struct.field1.field2.field3 exists, use c_isField(struct,'field1.field2.field3')
	assert(ischar(field))
	i = find(field=='.',1,'first');
	if isempty(i)
		res = isfield(struct,field);
	elseif ~isfield(struct,field(1:i-1))
		res = false;
	else
		% recursive call
		res = c_isField(struct.(field(1:i-1)),field(i+1:end));
	end
end