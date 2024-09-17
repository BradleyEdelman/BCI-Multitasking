function mesh = c_mesh_load(varargin)
p = inputParser();
p.addRequired('input',@ischar); %file to load from
p.parse(varargin{:});
s = p.Results;

% assume input is a filename
assert(exist(s.input,'file')>0);

[pathstr, filename, extension] = fileparts(s.input);

mesh = struct();

switch(extension)
	case '.off'
		c_AddIso2MeshToPath();
		[mesh.Vertices, mesh.Faces] = readoff(s.input);
		
	case '.fsmesh'
		[mesh.Vertices, mesh.Faces] = freesurfer_read_surf(s.input);
		
	case '.stl'
		if ~exist('stlread','file')
			mfilepath=fileparts(which(mfilename));
			addpath(fullfile(mfilepath,'../ThirdParty/stlread'));
		end
		
		[mesh.Vertices, mesh.Faces, mesh.FaceNormals] = import_stl_fast(s.input,1);
		if isempty(mesh.Vertices) % assume empty because stl file was not ascii format
			% try reading with stlread instead
			[mesh.Vertices, mesh.Faces, mesh.FaceNormals] = stlread(s.input);
		end
		
	case '.mat'
		mesh = load(s.input);
		assert(isfield(mesh,'Vertices'));
		assert(isfield(mesh,'Faces'));
	otherwise
		error('Unsupported input extension');
end

end
