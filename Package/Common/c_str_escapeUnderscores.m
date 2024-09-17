function str = c_str_escapeUnderscores(str)
	if iscellstr(str)
		for i=1:length(str)
			str{i} = c_str_escapeUnderscores(str{i});
		end
		return;
	end
	
	assert(ischar(str));
	str = strrep(str,'_','\_');
end