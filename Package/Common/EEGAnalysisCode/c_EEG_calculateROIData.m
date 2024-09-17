function [roiData, EEG, ROISrc] = c_EEG_calculateROIData(varargin)
	p = inputParser();
	p.addRequired('EEG',@isstruct);
	p.addParameter('ROIs',[],@(x) isstruct(x) || isempty(x)); % if empty, try to pull from EEG.src.ROIs
	p.addParameter('fn','mean',@ischar); % function for combining points within ROI
	p.addParameter('doMinimizeMemUse',true,@islogical);
	p.parse(varargin{:});
	s = p.Results;
	
	EEG = s.EEG;
	assert(c_isFieldAndNonEmpty(EEG,'src') ...
		&& c_isFieldAndNonEmpty(EEG.src,'kernel') ...
		&& c_isFieldAndNonEmpty(EEG.src,'meshCortex'));
	
	if isempty(s.ROIs)
		ROIs = EEG.src.ROIs;
	else
		ROIs = s.ROIs;
	end
	
	numROIs = length(ROIs);
	
	doUseSparseMatrix = false;
	if ~c_isFieldAndNonEmpty(EEG.src,'data') || nargout >= 3
		doUseSparseMatrix = s.doMinimizeMemUse || nargout >= 3;
		c_say('No source data found, calculating from sensor data');
		if ~doUseSparseMatrix
			EEG.src.data = c_mtimes(EEG.src.kernel,EEG.data);
		else
			% optimization to only compute dipoles that are needed in specified ROIs (could be a small subset of entire data)
			tmp = {ROIs.Vertices};
			ROISrc.Vertices = c_union(tmp{:});
			ramNeeded = length(ROISrc.Vertices)*prod(paren(size(EEG.data),2:3))*4/1e9; % approx RAM in GB needed for this operation
			if ramNeeded > 32
				% calculate individual dipole data and then mean (or other fn) for each ROI separately to conserve memory
				% (this will be slower)
				roiData = nan([numROIs,paren(size(EEG.data),2:3)]);
				prog = c_progress(numROIs,'ROI %d/%d','waitToPrint',10);
				prog.start('Calculating srcs separately for each ROI due to memory constraints');
				for iR = 1:numROIs
					prog.update(iR);
					c_sayStartSilence();
					roiData(iR,:,:) = c_EEG_calculateROIData(EEG,varargin{2:end},'ROIs',ROIs(iR));
					c_sayEndSilence();
				end
				prog.stop();
				if nargout >= 2
					EEG.src.ROIData = roiData;
				end
				ROISrc = [];
				return;
			else
				ROISrc.data = c_mtimes(EEG.src.kernel(ROISrc.Vertices,:),EEG.data); 
			end
		end
		c_sayDone();
	end
	
	
	% collapse extra dimensions
	if ~doUseSparseMatrix
		origSize = size(EEG.src.data);
		EEG.src.data = reshape(EEG.src.data,[origSize(1) prod(origSize(2:end))]);
	else
		origSize = size(ROISrc.data);
		ROISrc.data = reshape(ROISrc.data,[origSize(1) prod(origSize(2:end))]);
	end
	
	switch(s.fn);
		case 'mean'
			roiData = nan(numROIs,prod(origSize(2:end)));
			for r=1:numROIs
				if ~doUseSparseMatrix
					memberIndices = ROIs(r).Vertices;
					roiData(r,:) = mean(EEG.src.data(memberIndices,:),1);
				else
					memberIndices = ROIs(r).Vertices;
					roiData(r,:) = mean(ROISrc.data(ismember(ROISrc.Vertices,memberIndices),:),1);
				end
			end
			
		%TODO: try using BST function that corrects orientations instead
		otherwise
			error('unsupported: %s',s.fn);
	end	
	
	% restore extra dimensions
	roiData = reshape(roiData,[numROIs, origSize(2:end)]);
	
	if nargout >= 2	
		if ~doUseSparseMatrix
			EEG.src.data = reshape(EEG.src.data,origSize);
		end
		EEG.src.ROIData = roiData;
	end
	
	if nargout >= 3
		% allow optional output of individual source data calculated only within ROIs
		ROISrc.data = reshape(ROISrc.data,origSize);
	end
end