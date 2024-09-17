function argout1 = bst_get_MatlabVersion()

	if ~exist('version','builtin')
		Version = 601;
	else
		% Get version number
		str_vers = version();
		vers = sscanf(str_vers, '%d.%d%*s');
		if isempty(vers) || any(~isnumeric(vers)) || any(isnan(vers))
			vers = 0;
		end
		Version = 100 * vers(1) + vers(2);
		% Get release name
		ipar = [find(str_vers == '('), find(str_vers == ')')];
	end
	argout1 = Version;
		
end