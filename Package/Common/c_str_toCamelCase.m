function str = c_str_toCamelCase(str)
	assert(ischar(str));
	
	indicesToCap = find(str==' ') + 1;
	indicesToCap(indicesToCap > length(str)) = [];
	
	str(indicesToCap) = upper(str(indicesToCap));
	
	str = strrep(str,' ','');
end