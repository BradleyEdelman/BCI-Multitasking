function str = c_nth(n)
	n = mod(n,10);
	assert(n>=0);
	assert(c_isinteger(n));
	if n==1
		suffix = 'st';
	elseif n==2
		suffix = 'nd';
	elseif n==3
		suffix = 'rd';
	else
		suffix = 'th';
	end
	str = sprintf('%d%s',n,suffix);
end