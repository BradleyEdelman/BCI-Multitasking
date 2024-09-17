function out = c_structArray_unique(in)

	assert(isvector(in)); %TODO: add code to handle non-vector cases

	indicesToRemove = false(1,length(in));
	
	out = c_structArray_sort(in);
	
	i = 0;
	while i < length(out) - 1
		i = i+1;
		j = i+1;
		while j <= length(out) && isequal(out(i),out(j))
			j = j+1;
		end
		j = j-1;
		if i~=j
			indicesToRemove(i+1:j) = true;
			i = j;
		end
	end
	
	out = out(~indicesToRemove);
end


