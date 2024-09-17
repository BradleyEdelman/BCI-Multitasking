function test_correctMeshOrientation()

% surfNiiPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\s160920084108DST131221107524367055-0029-00001-000160-01.nii';
surfNiiPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\S260_T1fs_conform.nii';
% surfNiiPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\tmp\T1fs_conform.nii';
surfPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\gm.stl';
% surfPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\tmp\gm.rh.stl';
% surfPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\S260\surf\rh.pial.fsmesh';
% surfPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\S260\surf\lh.pial.fsmesh';
% newNiiPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\s160920084108DST131221107524367055-0029-00001-000160-01.nii';
% newNiiPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\s160920084108DST131221107524367055-0029-00001-000160-01.nii';
% newNiiPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\S260_T1fs_conform.nii';
preNewNiiPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\s160920084108DST131221107524367055-0029-00001-000160-01.nii';
newNiiPath = 'N:\Data_TMSBCI\BE_160920\SPMAnalysis\f_MIME\anatomical\anatomical\ms160920084108DST131221107524367055-0029-00001-000160-01.nii';
%newSurfPath = 'N:\Data_TMSBCI\BE_160920\MRI_Processed\S260_160920\gm_realigned.off';

addpath('../MeshFunctions');
addpath('../');

oldOr = c_MRI_extractOrientation(surfNiiPath);
newOr = c_MRI_extractOrientation(newNiiPath);
oldSurf = c_mesh_load(surfPath);

preNewNiiInfo = spm_vol(preNewNiiPath);

newVolInfo = spm_vol(newNiiPath);
newVol = spm_read_vols(newVolInfo);

oldVolInfo = spm_vol(surfNiiPath);
oldVol = spm_read_vols(oldVolInfo);

% oldVolToNewVolTransf = [
% 	1 0 0 0;
% 	0 0 1 0;
% 	0 -1 0 0;
% 	0 0 0 1];

surfTransform = [];
% surfTransform = [
% 	0.9990981817,  0.0002152900837,  -0.0424595885,  54.167751  ;
% -0.0002301682422,  0.9999999372,  -0.0003455191617,  0.03472215236  ;
% 0.04245951145,  0.0003549804173,  0.9990981222,  -20.31670387  ;
% 0  0  0  1 ];
% surfTransform = pinv(surfTransform);
% surfTransform = [
% 	1     0     0     0;
%      0     0     -1     255;
%      0    1     0   0;
%      0     0     0     1];
% surfTransform = [
% 	1     0     0     0;
%      0     0     1     0;
%      0    -1     0   255;
%      0     0     0     1];
 
fs2fslTransform = [
	1 0 0 0;
	0 0 -1 255;
	0 1 0 0 ;
	0 0 0 1];

surfTransform = [
	1 0 0 128.5
	0 1 0 128.5
	0 0 1 127.5
	0 0 0 1];

% surfTransform = oldVolInfo.mat*surfTransform*diag([-1 1 1 1]); % works to map to oldVol (*T1fs_conform.nii)
 % (i.e. mapping from surface space to conform space)
% surfTransform = oldVolInfo.mat*fs2fslTransform*surfTransform*diag([-1 1 1 1]); % works to map to S260_*/s*.nii 
 % (i.e. mapping from surface space to original coordinate space of file input to mri2mesh)
surfTransform = newVolInfo.mat*pinv(preNewNiiInfo.mat)*oldVolInfo.mat*fs2fslTransform*surfTransform*diag([-1 1 1 1]); % works to map to S260_*/s*.nii
 % (i.e. mapping from surface space to original coordinate space, back to data coordinates of original MRI file, to new coordinate space of SPM coregistered image)

c_plot_visualizeQuaternionTransformation(surfTransform,'unitLength',100);

keyboard

% volTransform = [
% 	1 0 0 -128
% 	0 1 0 -128
% 	0 0 1 -128
% 	0 0 0 1];

 if ~isempty(surfTransform)
	 oldSurf.Vertices = c_pts_applyQuaternionTransformation(oldSurf.Vertices,surfTransform);
 end

% figure; c_plot_cortex(oldSurf);


% keyboard

% figure; c_plot_imageIn3D('CData',newVol(:,:,50));
% figure; c_plot_imageIn3D('CData',newVol(:,:,50),'transformation',volInfo.mat);
% set(gca,'DataAspectRatio',[1 1 1]);

% data = permute(newVol,[3 1 2]);
% data = flip(data,1); % not sure why this is necessary, but verified to match MRICron orientation after flip
% xyz = {};
% for i=1:3
% 	xyz{i} = 1:size(data,i);
% 	xyz{i} = xyz{i} - mean(xyz{i});
% 	if i~=3
% 		xyz{i} = -1*xyz{i};
% 	end
% end


out = c_GUI_visualize3DMatrix(...
	'data',newVol,...
	'labels',{'X','Y','Z'},...
	'doPlotProjections',false,...
	'doPlotSliceIn3D',true,...
	'dataAspectRatio',[1 1 1],...
	'colormap','gray',...
	'sliceIndex',100,...
	'transformation',newVolInfo.mat,...
	'title','MRI alignment'...
);

% out = c_GUI_visualize3DMatrix(...
% 	'data',oldVol,...
% 	'labels',{'X','Y','Z'},...
% 	'doPlotProjections',false,...
% 	'doPlotSliceIn3D',true,...
% 	'dataAspectRatio',[1 1 1],...
% 	'colormap','gray',...
% 	'sliceIndex',100,...
% 	'transformation',oldVolInfo.mat,...
% 	'title','MRI alignment'...
% );

% oldSurf.Vertices = c_rotatePoints(oldSurf.Vertices,[0 0 0],[0,-90,0]);
c_plot_cortex(oldSurf,'axis',out.MainAxH);

keyboard

end