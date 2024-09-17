function out = c_structArray_sort(in, fieldsToSort)

	if nargin < 2 || isempty(fieldsToSort)
		fieldsToSort = fieldnames(in(1));
	end
	
	assert(isstruct(in));
	assert(isvector(in)); %TODO: add code to handle non-vector struct arrays
	assert(~c_isEmptyStruct(in));
	assert(iscellstr(fieldsToSort));
	
	out = structArray_sort(in, fieldsToSort);

end

function out = structArray_sort(in,fieldsToSort)
	% internal function without assertion testing
	
	fieldToSort = fieldsToSort{1};
	vals = {in.(fieldToSort)};
	if iscellstr(vals)
		% do not convert
	else
		vals = cell2mat(vals);
	end
	[~,indices] = sort(vals);
	out = in(indices);
	
	if length(fieldsToSort) == 1
		return; % no more sorting to do
	end
	
	% sort equal valued items by next field (recursively)
	i = 0;
	while i < length(out) - 1
		i = i+1;
		j = i+1;
		while j <= length(out) && isequal(out(i).(fieldToSort), out(j).(fieldToSort)) 
			j = j+1;
		end
		j = j-1;
		if i ~= j
			% there was a span of equal-valued elements, so sort them by next field
			out(i:j) = structArray_sort(out(i:j), fieldsToSort(2:end));
			i = j;
		end
	end
end