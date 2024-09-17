function c_initializeBrainstorm()

	if ~(exist('bst_get','file')>0) || isempty(bst_get('isGUI')) || ~bst_get('isGUI')
		c_say('Launching Brainstorm');
		c_FigurePrinter.initialize(); % some of these dependencies cannot be added after Brainstorm starts,
		% so add them now just in case they will be used later.
		
		origPath = pwd();
		machineStr = c_getMachineIdentifier();
		switch(machineStr)
			case 'bme-he6104cc'
				brainstormPath = 'C:/brainstorm/brainstorm3/';
			case 'bme-he6112cc'
				brainstormPath = 'C:/matlab-extra/brainstorm3/';
			case 'ater-arca'
				brainstormPath = 'C:/matlab-extra/brainstorm3/';
			case 'hippocampus'
				brainstormPath = '~/brainstorm/brainstorm3/';
			otherwise
				error('Unrecognized machineStr: %s',machineStr);
		end
		%changePathOnCleanup = onCleanup(@() cd(origPath));
		assert(exist(brainstormPath,'dir')>0);
		cd(brainstormPath);
		brainstorm
		cd(origPath);
		c_sayDone();
	end
	
	% add custom replacements to override Brainstorm functions
	str = which('bst_nearest');
	if ~c_str_matchRegex(str,'ThirdParty/FromBrainstorm')
		mfilepath = fileparts(which(mfilename));
		addpath(fullfile(mfilepath,'../ThirdParty/FromBrainstorm/math'));
	end
end