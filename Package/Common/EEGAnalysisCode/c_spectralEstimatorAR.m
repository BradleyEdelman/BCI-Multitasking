function [pxx, f, t] = c_spectralEstimatorAR(varargin)
% attempt to emulate BCI2000's spectral estimation on a continuous dataset
p = inputParser();
p.addRequired('sig',@isnumeric); % last dimension should be time
p.addRequired('Fs',@isscalar); 
p.addParameter('modelOrder',16,@isscalar);
p.addParameter('firstBinCenter',0,@isscalar); % Hz
p.addParameter('lastBinCenter',30,@isscalar); % Hz
p.addParameter('binWidth',3,@isscalar); % Hz
p.addParameter('evaluationsPerBin',15,@isscalar);
p.addParameter('detrendType','linear',@ischar); % valid: linear, mean, none
p.addParameter('windowDuration',0.16,@isscalar); % s
p.addParameter('windowSeparation',40e-3,@isscalar); % s, equal to (windowDuration - overlapDuration)
p.addParameter('windowType','rectangular',@ischar);
p.addParameter('doFillInBetweenWindows',true,@islogical); % whether output should be same length as input, or whether there should just be one output for each window interval
p.parse(varargin{:});

%TODO: implement other windows
if ~strcmpi(p.Results.windowType,'rectangular'), error('Only rectangular window is currently supported.'); end

% conversion to legacy settings format...
s = p.Results;
x = p.Results.sig;

% collapse non-time dimensions
origSize = size(x);
x = reshape(x,[],origSize(end));

%% Break into windows

windowLength_n = round(s.windowDuration * s.Fs);
windowSeparation_n = round(s.windowSeparation * s.Fs);

startIndices = 1:windowSeparation_n:(size(x,2)-windowLength_n+1); %TODO: check for off-by-one on end index
endIndices = startIndices + windowLength_n - 1;

numBins = round((s.lastBinCenter - s.firstBinCenter + s.binWidth)/s.binWidth);
s.lastBinCenter = s.firstBinCenter + (numBins-1)*s.binWidth;
binStartIndices = 1:s.evaluationsPerBin:((numBins)*s.evaluationsPerBin);
binEndIndices = binStartIndices + s.evaluationsPerBin; %off-by-one means some overlap between bins, but preserves symmetry when center=0Hz
binCenterFrequencies = s.firstBinCenter:s.binWidth:s.lastBinCenter;

numWindows = length(startIndices);
binPowers = nan(size(x,1),numWindows,numBins);

f = (s.firstBinCenter-s.binWidth/2):(s.binWidth/s.evaluationsPerBin):(s.lastBinCenter+s.binWidth/2);

for w=1:numWindows
	xwin = x(:,startIndices(w):endIndices(w)); % could be for multiple channels
	
	[pxx, ~] = c_spectralEstimatorARWindow(xwin,s);
	
	winbinPowers = nan(size(x,1),1,numBins);
	
	for b=1:numBins
		winbinPowers(:,1,b) = sum(pxx(:,binStartIndices(b):binEndIndices(b)),2);
	end
	winbinPowers = winbinPowers * s.binWidth;
	%TODO: verify whether any other normalization is necessary besides
	%multiplying by bin widith
	
	binPowers(:,w,:) = winbinPowers;
end
	


out = 1; %TODO: delete

%% 
if s.doFillInBetweenWindows
	pxx = nan(size(x,1),size(x,2),numBins);
	
	for w=1:numWindows
		pxx(:,startIndices(w)+(1:windowSeparation_n)-1,:) = repmat(binPowers(:,w,:),1,windowSeparation_n,1);
	end
	
	t = (0:(size(x,2)-1))/s.Fs;
else
	pxx = binPowers;
	
	t = (endIndices-1)/s.Fs;
end

%f = binCenterFrequencies - s.binWidth/2;
f = binCenterFrequencies;

% un-collapse non-time dimensions
pxx = reshape(pxx,[origSize(1:(end-1)) paren(size(pxx),2:3)]);


end


function [pxx, f] = c_spectralEstimatorARWindow(xwin,s)
% spectral estimation on single window

%% Detrending
if strcmpi(s.detrendType,'linear')
	xwin = detrend(xwin')';
elseif strcmpi(s.detrendType,'mean')
	xwin = detrend(xwin','constant')';
elseif strcmpi(s.detrendType,'none')
	% do nothing
else 
	error('Unrecognized detrend type: %s',s.detrendType);
end

%% AR spectral estimation using pburg()

fin = (s.firstBinCenter-s.binWidth/2):(s.binWidth/s.evaluationsPerBin):(s.lastBinCenter+s.binWidth/2);

numChannels = size(xwin,1);
pxx = zeros(numChannels,length(fin));
for c=1:numChannels
	if any(isnan(xwin(c,:)))
		pxx(c,:) = nan;
	else
		[pxx(c,:),f] = pburg(double(xwin(c,:)),s.modelOrder,fin,s.Fs);
	end
end

end