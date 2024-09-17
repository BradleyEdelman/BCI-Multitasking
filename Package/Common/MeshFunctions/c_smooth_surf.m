function surfStruct = c_smooth_surf(varargin)

persistent PathModified;
if isempty(PathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../ThirdParty/FromBrainstorm/anatomy')); % requires brainstorm's tess_smooth function
	PathModified = true;
end

p = inputParser();
p.addRequired('surfStruct',@isstruct);
p.addParameter('smoothingScalar',1,@isscalar);
p.addParameter('numIterations',20,@isscalar);
p.addParameter('doKeepSize',true,@islogical);
p.parse(varargin{:});

surf = p.Results.surfStruct;

assert(isfield(surf,'Vertices'));
if ~isfield(surf,'VertConn')
	assert(isfield(surf,'Faces'));
	surf.VertConn = tess_vertconn(surf.Vertices,surf.Faces);
end

surf.Vertices = tess_smooth(surf.Vertices,...
	p.Results.smoothingScalar,p.Results.numIterations,surf.VertConn,p.Results.doKeepSize);

surfStruct = surf;

end
