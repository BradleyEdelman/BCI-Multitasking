function out = c_MVGC_calculateConnectivity(varargin)
p = inputParser();
p.addRequired('data',@isnumeric);
p.addParameter('RegMode','OLS',@ischar); % valid: 'OLS','LWR', or empty for default
p.addParameter('ICRegMode','LWR',@ischar); % valid: 'OLS','LWR', or empty for default
p.addParameter('ModelOrder','AIC',@(x) ischar(x) || isscalar(x)); % valid: 'auto'(='AIC'),'AIC','BIC', or scalar
p.addParameter('MaxModelOrder',20,@isscalar);
p.addParameter('MaxAutoCovLags',[],@isscalar); % valid: [] for automatic, or scalar
p.addParameter('epochHandlingMethod','time-varying',@ischar);
	% only used if epochHandlingMethod='time-varying':
	p.addParameter('WinDuration',100e-3,@isscalar); % window duration (i.e. length), in s 
	p.addParameter('WinDeltaT',20e-3,@isscalar); % window step size, in s
	p.addParameter('t',[],@(x) isvector(x) || isempty(x));
	% only used if epochHandlingMethod='trial-varying':
	p.addParameter('NumTrialsInSlidingWindow',20,@isscalar);
	p.addParameter('SlidingWindowDelta',0.5,@(x) isscalar(x) && x > 0 && x <= 1); % fraction of NumTrialSInSlidingWindow
p.addParameter('StatTest','F',@ischar); % valid: 'F','chi2'
p.addParameter('StatAlpha',0.05,@isscalar); % threshold for significance test
p.addParameter('StatMultHypothesisCorrection','Sidak',@ischar); % multiple hypothesis test correction, valid: 'none','Bonferroni','SIDAK',...
p.addParameter('Fs',1,@isscalar);
p.addParameter('FreqRes',[],@isscalar); % frequency resolution (empty for automatic)
p.addParameter('RandSeed',0,@isscalar); % 0 for unseeded
p.addParameter('doPlot',true,@islogical);
p.addParameter('doDebug',false,@islogical);
p.addParameter('doRescaleIfNeeded',true,@islogical);
p.parse(varargin{:});
s = p.Results;

data = p.Results.data;

%% initialization
persistent pathModified;
if isempty(pathModified)
	c_say('Initializing mvgc toolbox');
	mfilepath=fileparts(which(mfilename));
	run(fullfile(mfilepath,'../../ThirdParty/mvgc/startup.m'));
	c_sayDone();
	pathModified = true;
end

rng_seed(s.RandSeed);

numVars = size(data,1);
numPnts = size(data,2);
numTrials = size(data,3);

%% rescale data to minimize numerical precision issues within MVGC toolbox
% (e.g. if data is on the order of 1e-4, some checks such as the determinant calculated during
%  automatic order selection code may be much smaller than machine precision)

%fn = @(x) max(abs(x(:)));
%fn = @(x) std(x(:));
fn = @(x) iqr(x(:));

if s.doRescaleIfNeeded && (fn(data) < 1e-1 || fn(data) > 1e3)

	prevVal = fn(data);
	multiplier = 10^(-round(log10(prevVal)));
	c_say('Multiplying all data by scalar %g to minimize numerical precision issues',multiplier)
	c_saySingle('%.3g scaled to %.3g',prevVal,prevVal*multiplier);
	data = data*multiplier;
	c_sayDone();

	out.dataPremultiplier = multiplier;

	%TODO: look into this issue more thoroughly, as data amplitude seems to have a VERY strong effect on model order selection. This is not a good sign...
end


if strcmpi(s.epochHandlingMethod,'concat')
	s.epochHandlingMethod = 'trial-varying';
	s.NumTrialsInSlidingWindow = numTrials;
	s.SlidingWindowDelta = 1.0;
end


%% Model order estimation
if ischar(s.ModelOrder)
	c_say('Estimating model order');
	[AIC,BIC,moAIC,moBIC] = tsdata_to_infocrit(data, s.MaxModelOrder, s.ICRegMode);
	%TODO: decide whether it is necessary to instead pass individual windows of data to tsdata_to_infocrit and then average results

	if all(isnan(AIC))
		error('Order estimation failed');
	end

	if s.doPlot
		figure('name','Model order estimation');
		plot_tsdata([AIC BIC]',{'AIC','BIC'},1/s.Fs);
		title('Model order estimation');
		drawnow;
	end

	c_saySingle('Best model order (AIC) = %d', moAIC);
	c_saySingle('Best model order (BIC) = %d', moBIC);

	switch(s.ModelOrder)
		case 'AIC'
			s.ModelOrder = moAIC;
		case 'auto'
			s.ModelOrder = moAIC;
		case 'BIC'
			s.ModelOrder = moBIC;
		otherwise
			if ~c_isinteger(s.ModelOrder)
				error('Invalid model order: %s',s.ModelOrder);
			end
			% else use pre-specified model order
	end
	c_sayDone();
else
	c_saySingle('Using pre-specified model order: %d',s.ModelOrder)
end


c_saySingle('Using model order of %d',s.ModelOrder);




%%

switch(s.epochHandlingMethod)
	case 'time-varying'
		%% Windowing
		
		s.WinDeltaN = round(s.WinDeltaT * s.Fs);
		s.WinLengthN = round(s.WinDuration * s.Fs);
		%TODO: check whether we need to increase effective window length by adding VAR model order, as in demo example
		%s.WinLengthN = s.WinLengthN+s.ModelOrder;

		startIndices = 1:s.WinDeltaN:(numPnts-s.WinLengthN+1);
		endIndices = startIndices + s.WinLengthN - 1;

		numWins = length(startIndices);

		if isempty(s.t)
			c_saySingle('Times not specified. Setting based sampling rate and assuming start is t=0.');
			s.t = (1:endIndices(end))/s.Fs;
		end
		
		WinEndTimes = s.t(endIndices);

		%% VAR model estimation
		c_say('Estimating VAR model(s)');

		FF = nan(numVars,numVars,numWins);
		GoodWindows = false(numWins,1);

		% estimate a model for each window
		prog = c_progress(numWins,'Window %d/%d');
		prog.start();
		for wi = 1:numWins
		% parfor wi = 1:numWins
			prog.updateStart(wi);

			if s.doDebug, c_saySingle('VAR estimation'); end;
			[A,Sig] = tsdata_to_var(data(:,startIndices(wi):endIndices(wi),:),s.ModelOrder,s.RegMode);
			if isbad(A)
				c_saySingle('VAR estimation failed for window %d, skipping.',wi);
				prog.updateEnd(wi); continue;
			end

			if s.doDebug, c_saySingle('Autocovariance estimation'); end;
			[G,info] = var_to_autocov(A,Sig);
			if s.doDebug
				var_info(info,true); % display helpful diagnostic info
			end
			if info.error
				c_saySingle('Autocovariance calculation failed for window %d, skipping.',wi);
				prog.updateEnd(wi); continue;
			end
			if info.aclags < info.acminlags
				c_saySingle('Warning: minimum %d lags required, but got %d (decay factor = %e)',...
					info.acminlags, info.aclags, realpow(info.rho,info.aclags));
				% according to mvgc demo file, this is "not a show-stopper", so use anyways
			end

			if s.doDebug, c_saySingle('GC estimation'); end;
			FF_w = autocov_to_pwcgc(G);
			if isbad(FF_w,false)
				c_saySingle('GC calculation failed for window %d, skipping.',wi);
				prog.updateEnd(wi); continue;
			end

			FF(:,:,wi) = FF_w;
			GoodWindows(wi) = true;
			prog.updateEnd(wi,'Finished %d',wi);
		end
		prog.stop();

		c_saySingle('%d/%d windows were skipped',sum(~GoodWindows),numWins);
		c_sayDone();
		
	case 'trial-varying'
		
		%% windowing
		if any(~ismember({'WinDuration','WinDeltaT'},p.UsingDefaults))
			c_saySingle('Ignoring specified WinDuration and WinDeltaT since doing trial-varying connectivity estimation');
		end
		
		% group together consecutive trials with a larger sliding "window" of trials
		s.WinLengthN = s.NumTrialsInSlidingWindow;
		s.WinDeltaN = ceil(s.NumTrialsInSlidingWindow*s.SlidingWindowDelta);
		startIndices = 1:s.WinDeltaN:(numTrials-s.WinLengthN+1);
		endIndices = startIndices + s.WinLengthN - 1;
		
		numWins = length(startIndices);
		
		%% VAR model estimation
		c_say('Estimating VAR model(s)');
		
		FF = nan(numVars,numVars,numWins);
		GoodWindows = false(1,numWins);
		
		% estimate a model for each window (group) of trials
%  		prog = c_progress(numWins,'Trial group %d/%d');
% 		prog.start();
% 		for iW = 1:numWins
		prog = c_progress(numWins,'Trial group %d/%d','isParallel',true);
 		prog.start();
		parfor iW = 1:numWins
			prog.updateStart(iW);
			if s.doDebug, c_saySingle('VAR estimation'); end;
			[A,Sig] = tsdata_to_var(data(:,:,startIndices(iW):endIndices(iW)),s.ModelOrder,s.RegMode);
			if isbad(A)
				c_saySingle('VAR estimation failed for trial group %d, skipping.',iW);
				prog.updateEnd(iW); continue;
			end
			
			if s.doDebug, c_saySingle('Autocovariance estimation'); end;
			[G,info] = var_to_autocov(A,Sig);
			if s.doDebug && info.error
				var_info(info,true); % display helpful diagnostic info
			end
			if info.error
				c_saySingle('Autocovariance calculation failed for trial group %d, skipping.',iW);
				prog.updateEnd(iW); continue;
			end
			if info.aclags < info.acminlags
				c_saySingle('Warning: minimum %d lags required, but got %d (decay factor = %e)',...
					info.acminlags, info.aclags, realpow(info.rho,info.aclags));
				% according to mvgc demo file, this is "not a show-stopper", so use anyways
			end
			
			if s.doDebug, c_saySingle('GC estimation'); end;
			FF_t = autocov_to_pwcgc(G);
			if isbad(FF_t,false)
				c_saySingle('GC calculation failed for trial group %d, skipping.',iW);
				prog.updateEnd(iW); continue;
			end
			
			FF(:,:,iW) = FF_t;
			GoodWindows(iW) = true;
			prog.updateEnd(iW,'Finished %d',iW);
		end
		prog.stop();
		
		c_saySingle('%d/%d trial groups were skipped',sum(~GoodWindows),numWins);
		
		if sum(~GoodWindows)/numTrials > 0.25
			warning('%.3g%% of trial groups were skipped',sum(~GoodWindows)/numWins*100);
			keyboard
		end
		
		c_sayDone();
		
	otherwise
		error('Invalid epochHandlingMethod: %s',s.epochHandlingMethod);
end


%% Significance testing
c_say('Calculating critical value for significance');

alpha = s.StatAlpha;

% critical GC value at significance alpha, corrected for multiple hypotheses
%numHyp = 2; % number of hypotheses (e.g. 2 for 2->1 and 1->2)
numHyp = numel(FF(:,:,1)) - size(FF,1); % number of off-diagonal elements
switch s.StatMultHypothesisCorrection
	case 'none'
		alpha = alpha;
	case 'Bonferroni'
		alpha = alpha / numHyp;
	case 'Sidak'
		alpha = 1-realpow(1-alpha,1/numHyp);
	otherwise
		error('Invalid correction method: %s',s.StatMultHypothesisCorrection);
end

c_saySingle('Using ''%s'' correction for multiple comparisons: alpha %.2g->%.2g',...
	s.StatMultHypothesisCorrection,s.StatAlpha,alpha);

%TODO: determine rational for choosing Nx and Ny parameters here. Choice of (1,1) is based 
% on demo example, but justification for this is not provided.
Fc = mvgc_cval(alpha,s.ModelOrder,s.WinLengthN,numTrials,1,1,numVars-2);

%TODO: implement other statistical testing methods (bootstrapping, permutation test, etc.)

c_saySingle('Critical value: %.3g', Fc);

%%

if s.doPlot
	
	figure('name','MVGC results');
	c_subplot(1,2);
	meanFF = nanmean(real(FF(:,:,:)),3);
	[~,tmpIndex] = max(meanFF(:));
	[i,j] = ind2sub(size(meanFF),tmpIndex);
	imagesc(meanFF);
	title('Mean connectivity');
	c_subplot(2,2);
	
	switch(s.epochHandlingMethod)
		case 'time-varying'
			plot(s.t(endIndices),squeeze(FF(1,2,:)));
			xlim(extrema(s.t));
			line(extrema(s.t),[Fc Fc],'Color','r'); % critical significance value
			xlabel('time');
			title('Variable 2 -> variable 1 causality');
		case 'trial-varying'
			plot(squeeze(FF(i,j,:)));
			line(xlim(gca),[Fc Fc],'Color','r');
			xlabel('Trial group');
			title(sprintf('Variable %d -> variable %d causality',j,i));
		otherwise
			keyboard %TODO: add plotting code for another case as needed
	end
	
end

c_sayDone();

%% output

out.ModelOrder = s.ModelOrder;
out.Conn_CtoR = FF; % connectivity from column to row (e.g. ConnC2R(2,1) is connectivity from 1->2)
out.ConnSigThresh = Fc;
out.evalIndices = endIndices;
out.GoodWindows = GoodWindows;

out.WinDuration = [];
out.WinDeltaT = [];
out.t = [];
switch(s.epochHandlingMethod)
	case 'time-varying'
		out.WinDuration = s.WinDuration;
		out.WinDeltaT = s.WinDeltaT;
		out.t = WinEndTimes; %TODO: delete, replaced by WinEndT
		out.WinEndT 
		out.isTimeVarying = true;
		out.isTrialVarying = false;
	case 'trial-varying'
		out.isTimeVarying = false;
		out.isTrialVarying = numWins > 1;
		out.WinEndT = endIndices;
	otherwise
		keyboard %TOD
end
end
