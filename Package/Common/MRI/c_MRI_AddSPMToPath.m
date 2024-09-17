function c_MRI_AddSPMToPath()
persistent pathModified;
if isempty(pathModified)
	if ispc
		spmRootPath = 'C:\matlab-extra\spm12';
	else
		warning('SPM location unknown, not adding to path');
		return;
		
		%keyboard %TODO: set spmRootPath
	end
	addpath(spmRootPath);
	pathModified = true;
end
end