function c_EEG_openEEGLabIfNeeded()
	global EEGLabOpened
	global g_EEGLab
	if isempty(EEGLabOpened) || isempty(g_EEGLab)
		if ~exist('eeglab.m','file')
			mfilepath = fileparts(which(mfilename));
			if ispc
				addpath(fullfile([getenv('HOMEDRIVE') getenv('HOMEPATH')],'Documents/MATLAB/eeglab'));
			else
				addpath(fullfile('~/','matlab/eeglab13_5_4b'));
			end
		end
		[g_EEGLab.ALLEEG, g_EEGLab.EEG, g_EEGLab.CURRENTSET] = eeglab;
		EEGLabOpened = true;
	end
	str = which('timefreq');
	if ~c_str_matchRegex(str,'ThirdParty/FromEEGLab')
		% add custom functions overriding eeglab equivalents
		mfilepath = fileparts(which(mfilename));
		addpath(genpath(fullfile(mfilepath,'../ThirdParty/FromEEGLab')),'-begin');
	end
end