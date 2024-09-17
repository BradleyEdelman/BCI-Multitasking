function EEG = c_EEG_filter_laplacian(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('method','CSD',@ischar); %valid: 'CSD','simple'
p.addParameter('channelsToKeep',{},@(x) iscell(x) || ischar(x));
p.addParameter('montage','10-10',@ischar); %valid: '10-10'
p.parse(varargin{:});

persistent PathModified;
if isempty(PathModified)
	%TODO: only make this a dependency if using CSDtoolbox method
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../ThirdParty/CSDtoolbox/func'));
	PathModified = true;
end

EEG = p.Results.EEG;
channelsToKeep = p.Results.channelsToKeep;

newData = EEG.data;

if ischar(channelsToKeep) && strcmpi(channelsToKeep,'auto')
	% 'auto' -> keep as many channels as we can calculate valid laplacian values for
	doErrorOnMissingChannel = false;
	channelsToKeep = {EEG.chanlocs.labels};
else
	doErrorOnMissingChannel = true;
end

if ~isempty(channelsToKeep)
	channelIndicesToKeep = c_EEG_getChannelIndex(EEG,channelsToKeep);
end

switch p.Results.method
	case 'simple'
		assert(~isempty(channelsToKeep));
		invalidChannels = false(1,length(channelsToKeep));
		for c=1:length(channelsToKeep)
			chStr = channelsToKeep{c};
			switch(p.Results.montage)
				case '10-10'
					weights = [4 -1 -1 -1 -1]';
					switch(upper(chStr))
						case 'C1'
							surround = {'FC1','Cz','CP1','C3'};
						case 'C2'
							surround = {'FC2','Cz','CP2','C4'};
						case 'C3'
							surround = {'FC3','C1','CP3','C5'};
						case 'C4'
							surround = {'FC4','C2','CP4','C6'};
						case 'C5'
							surround = {'FC5','C3','CP5','T7'};
						case 'C6'
							surround = {'FC6','C4','CP6','T8'};
						case 'CP3'
							surround = {'C3','CP1','P3','CP5'};
						case 'CP4'
							surround = {'C4','CP2','P4','CP6'};
						case 'PZ'
							surround = {'CPZ','POZ','P1','P2'};
						case 'CPZ'
							surround = {'CZ','CP1','CP2','PZ'};
						otherwise
							if doErrorOnMissingChannel
								error('Laplacian for channel %s not yet supported', chStr);
							else
								% just silently skip channel
								invalidChannels(c) = true;
								continue;
							end
					end
				otherwise
					error('invalid montage: %s',p.Results.montage);
			end

			channelIndices = c_EEG_getChannelIndex(EEG,[chStr, surround]);

			newData(channelIndicesToKeep(c),:) = sum(bsxfun(@times,EEG.data(channelIndices,:),weights),1);
		end
		
		channelsToKeep = channelsToKeep(~invalidChannels);
		% (invalid data will be removed by c_EEG_reduceChannelData below)
		
	case 'CSD'
		% convert EEGlab montage to CSD toolbax montage
		if 1 % electrode positions from chanlocs 
			[Montage, radius] = c_EEG_getCSDMontage(EEG);
		else % electrode positions from standard template
			radius = 10;
			mfilepath=fileparts(which(mfilename));
			montagePath = fullfile(mfilepath,'../ThirdParty/CSDtoolbox/resource/10-5-System_Mastoids_EGI129.csd');
			Montage = ExtractMontage(montagePath,{EEG.chanlocs.labels}');
		end
		% generate transfer matrix
		[G,H] = GetGH(Montage);
		lambda = 1.0e-5; % default
		% calculate CSD
		numEpochs = EEG.trials;
		if numEpochs < 8
			newData = CSD(EEG.data,G,H,lambda,radius);
		else
			newData = EEG.data;
			parfor e=1:numEpochs
				newData(:,:,e) = CSD(newData(:,:,e),G,H,lambda,radius);
			end
		end
		
	otherwise
		error('Invalid method: %s',p.Results.method);
end

if isfield(EEG,'epochs') && isfield(EEG.epochs,'data')
	warning('EEG epoch data has been extracted previously, but only applying filter to raw data. Re-extract epoch data.');
end

EEG.data = newData;

if ~isempty(channelsToKeep)
	EEG = c_EEG_reduceChannelData(EEG,channelsToKeep);
end

end


function [Montage, radius] = c_EEG_getCSDMontage(EEG)
	% convert EEGLab chanlocs to CSD chanlocs montage
		
% 	locs = convertlocs(EEG.chanlocs,'sph2sphbesa');
	locs = EEG.chanlocs;
	
	% based on CSD 'ExtractMontage' fn
	phi = cell2mat({locs.sph_phi});
	theta = cell2mat({locs.sph_theta})+90;
	radii = cell2mat({locs.sph_radius});
	
	phiT = 90 - phi;
	theta2 = (2*pi*theta)/360;
	phi2 = (2*pi*phiT)/360;
	[x,y] = pol2cart(theta2,phi2);
	xy = [x; y];
	xy = xy/max(max(xy));
	xy = xy/2+0.5; % adjust to range 0-1
	
	Montage.lab = {locs.labels}';
	Montage.theta = theta';
	Montage.phi = phi';
	Montage.xy = xy';
	
	radius = mean(radii);
	radius = radius / 1e2; % convert from mm to cm, as expected by CSD
	
	if 0 
		% for testing 
		figure('name','eeglab electrode positions')
		plotchans3d([cell2mat({EEG.chanlocs.X})', cell2mat({EEG.chanlocs.Y})', cell2mat({EEG.chanlocs.Z})'],{EEG.chanlocs.labels});

		MapMontage(Montage)
	end
end