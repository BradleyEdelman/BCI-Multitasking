function varargout = c_mat_deal(array)
	tmp = c_mat_sliceToCell(array);
	if length(tmp) < nargout
		error('Number of output arguments (%d) exceed number of elements in input (%d)',nargout,length(tmp));
	end
	varargout = tmp;
end