function mesh = c_MRI_extractSkinMesh(varargin)
if nargin==0, testfn(); return; end;
p = inputParser();
p.addRequired('MRI',@ischar);
p.parse(varargin{:});
s = p.Results;

%% dependencies
persistent pathModified;
if isempty(pathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../'));
	addpath(fullfile(mfilepath,'../EEGAnalysisCode')); % for loadBCI2000Data
	addpath(fullfile(mfilepath,'../MeshFunctions'));
	addpath(fullfile(mfilepath,'../ThirdParty/iso2mesh'));
	c_MRI_AddSPMToPath();
	pathModified = true;
end

%% load MRI

assert(exist(s.MRI,'file')>0);

meta = spm_vol(s.MRI);
MRI = spm_read_vols(meta);

%% plot

c_GUI_visualize3DMatrix('data',MRI,'transformation',meta.mat)

%% volumetric pre-processing

minThreshold = prctile(MRI(randperm(numel(MRI),ceil(numel(MRI)/10))),85);
binData = MRI > minThreshold;
c_GUI_visualize3DMatrix('data',binData,'transformation',meta.mat);

tmp = deislands3d(binData,10);

islands = bwislands(tmp);

% just keep largest island
[~,index] = max(cellfun(@length,islands));
finalData = false(size(binData));
finalData(islands{index}) = true;

c_GUI_visualize3DMatrix('data',finalData,'transformation',meta.mat);

keyboard

binData = finalData;

%% extract mesh

opt = struct(...
	'radbound',10,...
	'distbound',10,...
	'keepratio',0.2,...
	'maxsurf',1);

[node, elem, regions, holes] = vol2surf(binData,1:size(MRI,1),1:size(MRI,2),1:size(MRI,3),opt,1,'simplify',0.5);
mesh = struct(...
	'Vertices',node,...
	'Faces',elem(:,1:3),...
	'Regions',elem(:,4));
figure;
c_mesh_plot(mesh);

%% apply spatial transformation to get mesh in "real" coordinates

newMesh = c_mesh_applyTransform(mesh,'quaternion',meta.mat);
mesh = newMesh;

%% smooth

alpha = 0.01; 
newMesh = mesh;
newMesh.Vertices = sms(mesh.Vertices, mesh.Faces,10,alpha,'laplacianhc');
figure;
c_mesh_plot(newMesh);

keyboard

mesh = newMesh;

%% resample (to reduce number of elements)

newMesh = mesh;
resampleRatio = 0.25;
[newMesh.Vertices, newMesh.Faces] = meshresample(mesh.Vertices, mesh.Faces,resampleRatio);
figure('name','Resampling mesh');
h = [];
h(1) = c_subplot(1,2);
c_mesh_plot(mesh,'EdgeColor',[0,0,0]);
title('Original');
h(2) = c_subplot(2,2);
c_mesh_plot(newMesh,'EdgeColor',[0,0,0]);
title('Resampled');
c_plot_linkViews(h);

keyboard

mesh = newMesh;

end


function testfn()


% baseDir = 'N:\MontageGenerator\mni_colin27_2008_nifti';
% mriPath = fullfile(baseDir,'colin27_t1_tal_hires.nii');
% outputPath = fullfile(baseDir,'colin27_t1_tal_hires_ExtractedSkin_Resampled');
baseDir = 'D:\Data_TMSBCI\CCC_170203\ProcessedMRI\ScalpExtraction';
mriPath = fullfile(baseDir,'orig_nu.nii');
outputPath = fullfile(baseDir,'CC_scalp');


mesh = c_MRI_extractSkinMesh(mriPath);



save(outputPath,'-struct','mesh');

end