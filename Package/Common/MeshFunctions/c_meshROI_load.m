function ROI = c_meshROI_load(varargin)
p = inputParser();
p.addRequired('input',@ischar); %file to load from
p.parse(varargin{:});
s = p.Results;

% assume input is a filename
assert(exist(s.input,'file')>0);

[pathstr, filename, extension] = fileparts(s.input);

ROI = struct();

switch(extension)
	case '.mat'
		ROI = load(s.input);
		
	otherwise
		error('Unsupported input extension');
end

assert(c_meshROI_isValid(ROI));

end

