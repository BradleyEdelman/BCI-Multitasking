
function out = c_ADTF_calculateConnectivity(varargin)
p = inputParser();
p.addRequired('data',@isnumeric);
p.addParameter('LowFreq',1,@isscalar);
p.addParameter('HighFreq',50,@isscalar);
p.addParameter('ModelOrder','SBC',@(x) ischar(x) || isscalar(x)); % valid: 'auto' (='SBC'), 'SBC', 'FPE', or scalar
p.addParameter('MaxModelOrder',20,@isscalar);
p.addParameter('Fs',1,@isscalar);
p.addParameter('t',[],@(x) isvector(x) || isempty(x));
p.addParameter('doPlot',true,@islogical);
p.addParameter('NumShuffles',1000,@isscalar); % set to 0 to not do any significant estimation with shuffling
p.addParameter('StatAlpha',0.05,@isscalar);
p.parse(varargin{:});
s = p.Results;

data = p.Results.data;

%% initialization
persistent pathModified;
if isempty(pathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../ThirdParty/FromEConnectome/tools/ADTF'));
	addpath(fullfile(mfilepath,'../ThirdParty/FromEConnectome/tools/DTFComputation'));
	addpath(fullfile(mfilepath,'../ThirdParty/FromEConnectome/tools/arfit'));
	pathModified = true;
end

if ismember('Fs',p.UsingDefaults)
	warning('Fs not specified. Assuming 1 Hz');
end

numVars = size(data,1);
numPnts = size(data,2);
numTrials = size(data,3);

if numTrials > 1
	c_saySingle('Concatenating trials into time dimension');
	data = reshape(data,[numVars, numPnts*numTrials]);
end

% eConnectome expects first dimension to be time, and second dimension to be variables
data = data';

%% Model order estimation

if ischar(s.ModelOrder)
	candidateOrders = 1:s.MaxModelOrder;

	[w,A,C,sbc,fpe,~] = arfit(data,min(candidateOrders),max(candidateOrders),lower(s.ModelOrder));

	[~,iSBC] = min(sbc);
	moSBC = candidateOrders(iSBC);

	[~,iFPE] = min(fpe);
	moFPE = candidateOrders(iFPE);


	if s.doPlot
		figure('name','Model order estimation');
		h = plot(candidateOrders,[sbc; fpe]);
		hold on;
		scatter(candidateOrders(iSBC),sbc(iSBC),[],get(h(1),'Color'));
		scatter(candidateOrders(iFPE),fpe(iFPE),[],get(h(2),'Color'));
		legend('SBC','FPE');
		title('Model order estimation');
	end

	c_saySingle('Best model order (SBC) = %d', moSBC);
	c_saySingle('Best model order (FPE) = %d', moFPE);

	switch(s.ModelOrder)
		case 'SBC'
			s.ModelOrder = moSBC;
		case 'auto'
			s.ModelOrder = moSBC;
		case 'FPE'
			s.ModelOrder = moFPE;
		otherwise
			if ~c_isinteger(s.ModelOrder)
				error('Invalid model order: %s',s.ModelOrder);
			end
			% else use pre-specified model order
	end
	c_sayDone();
end
% else use pre-specified model order

c_saySingle('Using model order of %d',s.ModelOrder);

%% Model estimation

c_say('Computing aDTF');
gamma = ADTF(data,s.LowFreq,s.HighFreq,s.ModelOrder,s.Fs);
c_sayDone();

if s.NumShuffles~=0
	%TODO: correct StatAlpha for multiple comparisons as in MVGC code

	c_say('Computing shuffled aDTF with %d shuffles',s.NumShuffles);
	shuffleGamma = ADTFsigvalues(data,s.LowFreq,s.HighFreq,s.ModelOrder,s.Fs,s.NumShuffles,s.StatAlpha,[]);
	c_sayDone();

	sigGamma = ADTFsigtest(gamma,shuffleGamma);
else
	shuffleGamma = [];
	sigGamma = [];
end

keyboard %TODO





end
