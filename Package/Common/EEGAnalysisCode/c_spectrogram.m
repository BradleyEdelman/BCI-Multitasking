function [P,F,T] = c_spectrogram(varargin)

	p = inputParser();
	p.addRequired('sig',@isnumeric); % last dimension should be time
	p.addRequired('Fs',@isscalar);
	p.addParameter('timeDimension',2,@isscalar);
	p.addParameter('FLim',[],@isvector);
	p.addParameter('window',0.2,@isvector); % if scalar, is window duration (in s). If vector, treated as raw window weights.
	p.addParameter('windowOverlapRatio',0.5,@isscalar);
	p.addParameter('NFFT',0,@isscalar); % if 0, set to 2^nextpow2(length(sig))
	p.addParameter('method','spectrogram',@ischar); % valid: spectrogram, c_spectralEstimatorAR
	p.addParameter('ARArgs',{},@iscell);
	p.addParameter('doPlot',false,@islogical);
	p.parse(varargin{:});

	sig = p.Results.sig;
	
	window = p.Results.window;
	if length(window) == 1
		windowLength = round(window*p.Results.Fs);
	else
		windowLength = length(window);
	end
	overlap = round(windowLength * p.Results.windowOverlapRatio);
	
	
	%% 
	
	% reshape signal into 2d matrix, with time in last dimension
	originalSigSize = size(sig);
	reshape(sig,[],originalSigSize(end));
	
	if strcmp(s.method,'spectrogram')
		if size(sig,1) ~= 1
			error('Non-vector signals not currently supported for spectrogram method');
			%TODO
		end
		[~,F,T,P] = spectrogram(double(sig),window,overlap,p.Results.NFFT,p.Results.Fs);
	elseif strcmp(s.method,'c_spectralEstimatorAR')
		ARArgs = {};
		if ~isempty(p.Results.FLim)
			ARArgs = [ARArgs, ...
				'firstBinCenter', p.Results.FLim(1), ...
				'lastBinCenter', p.Results.FLim(2)];
		end
		if ~isscalar(window)
			error('scalar window length only supported (currently)');
		end
		ARArgs = [ARArgs,...
			'windowDuration',window,...
			'windowSeparation',window*(1-p.Results.windowOverlapRatio),...
			p.Results.ArArgs];
		
		[P,F,T] = c_spectralEstimatorAR(sig,p.Results.Fs,ARArgs{:});
		
		P = permute(P,[3,2,1]);
	else
		error('Unrecognized spectral estimation method');
	end
	
	if originalSigSize ~= size(sig)
		%TODO: reshape outputs into expected dimensions (i.e. unfolding non-time dimensions)
		keyboard
	end
	
	if ~isempty(s.Flim)
		% frequency limits specified
		indices = F >= s.Flim(1) & F <=s.Flim(end);
		P = P(indices,:);
		F = F(indices);
	end

	if s.doPlot || nargout == 0
		surf(T,F,10*log10(P_mean),'edgecolor','none');
		axis tight;
		view(0,90);
		xlabel('Time (s)'); ylabel('Hz');
	end
	
end