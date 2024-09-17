function ROI = c_meshROI_loadFromBSAtlas(varargin)
% load ROI(s) from BrainStorm atlas file
p = inputParser();
p.addRequired('input',@ischar); %file to load from
p.parse(varargin{:});
s = p.Results;

% assume input is a filename
assert(exist(s.input,'file')>0);

[pathstr, filename, extension] = fileparts(s.input);

atlas = struct();

switch(extension)
	case '.mat'
		atlas= load(s.input);
		
	otherwise
		error('Unsupported input extension');
end

assert(isfield(atlas,'Name'));
assert(isfield(atlas,'Scouts'));
assert(isfield(atlas,'TessNbVertices'));

ROI = atlas.Scouts;

assert(c_meshROI_isValid(ROI));

end

