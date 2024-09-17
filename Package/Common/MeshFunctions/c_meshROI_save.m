function c_meshROI_save(varargin)
p = inputParser();
p.addRequired('output',@ischar); % file to save to
p.addRequired('ROI',@c_meshROI_isValid); % mesh to save 
p.parse(varargin{:});
s = p.Results;

[pathstr, filename, extension] = fileparts(s.output);

ROI = s.ROI;

switch(extension)
	case '.mat'
		save(s.output,'-struct','ROI');
		
	otherwise
		error('Unsupported output extension');
end


end