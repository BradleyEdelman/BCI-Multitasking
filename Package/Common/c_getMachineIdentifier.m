function str = c_getMachineIdentifier(varargin)

persistent p_str;

if ~isempty(p_str)
	str = p_str;
	return;
end

[~, hostname] = system('hostname');

hostname = strtrim(hostname);

switch(hostname)
	case 'bme-he6104cc'
		str = hostname;
	case 'bme-he6112cc'
		str = hostname;
	case 'ater-arca'
		str = hostname;
	case 'hippocampus'
		str = hostname;
	otherwise
		str = hostname;
		%error('Unrecognized machine: %s',hostname);
end

p_str = str;

end