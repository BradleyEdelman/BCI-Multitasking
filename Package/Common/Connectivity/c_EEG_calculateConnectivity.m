function out = c_EEG_calculateConnectivity(varargin)

if nargin==0, testfn(); return; end

p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('method','MVGC'); % valid: mvgc, adtf
p.addParameter('data','data',@(x) ischar(x) || isnumeric(x)); % string to field in EEG struct, or data itself
p.addParameter('dataOperation','none',@ischar); % valid: none, TrialAverage, SubtractTrialAverage
p.addParameter('t',[],@(x) isvector(x) || isempty(x));
p.addParameter('epochHandlingMethod','time-varying',@ischar); % valid: time-varying, trial-varying, concat
p.addParameter('MaxModelOrder',20,@isscalar);
p.addParameter('ModelOrder','auto',@(x) ischar(x) || isscalar(x));
p.addParameter('MVGCArgs',{},@iscell);
p.addParameter('aDTFArgs',{},@iscell);
p.parse(varargin{:});
s = p.Results;

% note: epochHandlingMethod='time-varying' with epoched data performs "vertical" connectivity analysis,
%  which assumes that there is minimal inter-epoch variability, but allows for time-locked variation.
% epochHandlingMethod='trial-varying' assumes connectivity within an entire epoch is constant (i.e.
%  no time-locked variation) but does allow for variation across trials. It may be more important in this
%  case to ensure approximate stationarity of the signals within each epoch, e.g. by subtracting the ERP
%  average or other methods. 
% See MVGC paper (Barnett2014MVGC) for more comprehensive discussion.

%%

EEG = p.Results.EEG;

if ischar(s.data)
	assert(isfield(EEG,s.data));
	data = EEG.(s.data);
else
	data = s.data;
end

switch(s.dataOperation)
	case 'none'
		%do nothing
	case 'TrialAverage'
		data = mean(data,3);
	case 'SubtractTrialAverage'
		data = bsxfun(@minus,data,mean(data,3));
	otherwise
		error('Invalid data operation: %s',s.dataOperation);
end

if isempty(s.t)
	s.t = EEG.times/1e3;
end

switch(lower(s.method))
	case 'mvgc'
		out = c_MVGC_calculateConnectivity(data,...
			't',s.t,...
			'Fs',EEG.srate,...
			'MaxModelOrder',s.MaxModelOrder,...
			'ModelOrder',s.ModelOrder,...
			'epochHandlingMethod',s.epochHandlingMethod,...
			s.MVGCArgs{:});

		out.TVConn_CtoR = out.Conn_CtoR; % time-varying or trial-varying connectivity

		out.Conn_CtoR = nanmean(out.TVConn_CtoR,3);

	case 'adtf'
		out = c_ADTF_calculateConnectivity(data,...
			't',s.t,...
			'Fs',EEG.srate,...
			'MaxModelOrder',s.MaxModelOrder,...
			'ModelOrder',s.ModelOrder,...
			s.aDTFArgs{:});

		keyboard %TODO

	otherwise
		error('Invalid method: %s',s.method);
end

end

%%
function testfn_mvgc()

% from mvgc_demo_nonstationary()

ntrials   = 10;      % number of trials
nobs      = 1000;    % number of observations per trial
dnobs     = 200;     % initial observations to discard per trial

regmode   = 'OLS';   % VAR model estimation regression mode ('OLS', 'LWR' or empty for default

nlags     = 1;       % number of lags in VAR model
a         =  0.3;    % var 1 -> var 1 coefficient
b         = -0.6;    % var 2 -> var 2 coefficient
cmax      =  2.0;    % var 2 -> var 1 (causal) coefficient maximum

fs        = 1000;    % sample frequency
tr        = [5 -3];  % linear trend slopes
omega     = 2;       % "minimal VAR" X <- Y (causal) coefficient sinusoid frequency

ev        = 10;      % evaluate GC at every ev-th sample
wind      = 4;       % observation regression window size
morder    = 1;       % model order (for real-world data should be estimated)

alpha     = 0.05;    % significance level for statistical tests
mhtc      = 'SIDAK'; % multiple hypothesis test correction (see routine 'significance')

seed      = 0;       % random seed (0 for unseeded)

rng_seed(seed);

nvars = 2;

tnobs = nobs+dnobs;                 % total observations per trial for time series generation
k = 1:tnobs;                        % vector of time steps
t = (k-dnobs-1)/fs;                 % vector of times
c = cmax*sin(2*pi*omega*t);         % causal coefficient varies sinusoidally
trend = diag(tr)*repmat(t,nvars,1); % linear trend

% set up time-varying VAR parameters

AT = zeros(nvars,nvars,nlags,tnobs); % "minimal VAR" coefficients
for j = k
    AT(:,:,nlags,j) = [a c(j); 0 b];
end
SIGT = eye(nvars);                   % "minimal VAR" residuals covariance

% generate non-stationary VAR

X = var_to_tsdata_nonstat(AT,SIGT,ntrials);

% add linear trend

X = X + repmat(trend,[1 1 ntrials]);

% discard initial observations

X = X(:,dnobs+1:tnobs,:);
c = c(dnobs+1:tnobs);
trend = trend(:,dnobs+1:tnobs);
k = 1:nobs;

h = figure(); clf;
xrange = [0,nobs];

% plot causal coeffcient

subplot(3,1,1);
plot(k,c);
xlim(xrange);
title('Causal coefficient sinusoid');
xlabel('time');

% plot first 10 trial time series and trend for variable 1

subplot(3,1,2)
plot(k,squeeze(X(1,:,1:min(10,nobs)))');
hold on
plot(k,trend(1,:),'k');
hold off
xlim(xrange);
title('Time series (variable 1)');
xlabel('time');


out = c_MVGC_calculateConnectivity(X,...
	'RandSeed',1,...
	'ModelOrder',1,...
	'WinDuration',4/1000,...
	'WinDeltaT',10/1000,...
	'Fs',1000,...
	'doPlot',true,...
	'doDebug',false);


% theoretical GC 2 -> 1
D = 1+b^2 + c(out.evalIndices).^2;
F12T = log((D + sqrt(D.^2 - 4*b^2))/2)';

figure(h);

subplot(3,1,3);
plot(out.t(out.evalIndices),[F12T out.Conn_CtoR]);
xrange = extrema(out.t);
xlim(xrange);
line(xrange,[1 1]*out.ConnSigThresh,'Color','r'); % critical significance value
legend('theoretical','estimated','cval');
title('variable 2 -> variable 1 causality');
xlabel('time');

keyboard


end

%%
function testfn()

if 0
	mfilepath=fileparts(which(mfilename));
	tmp = load(fullfile(mfilepath,'../Resources/example_econnectome_ROITS2.mat'));
	EEG = tmp.ROITS;


% 	dt = 50;
% 	Nt = 500;
% 	N = size(EEG.data,2);
% 	startIndices = 1:dt:(N-Nt+1);
% 	endIndices = startIndices + Nt-1;
% 	newData = zeros(size(EEG.data,1),Nt-1,length(startIndices));
% 	for i=1:length(startIndices)
% 		newData(:,:,i) = diff(EEG.data(:,startIndices(i):endIndices(i)),1,2);
% 	end
% 	EEG.data = newData;
	out = c_EEG_calculateConnectivity(EEG,...
		'method','mvgc',...
		'MVGCArgs',{...
			'ICRegMode','OLS',...
			'doDebug',false,...
			'WinDuration',200e-3,...
			'WinDeltaT',50e-3,...
		});



	keyboard

elseif 1
	% simulated connectivity data from Abbas

	%% load data
	mfilepath=fileparts(which(mfilename));
	dataPath = fullfile(mfilepath,'../Resources/AbbasSimulatedConnectivity/');

	% x1 is from a real seizure, and x1 is always the driving node of the model.
	%
	% Conf. 1 - 1 drives 2 and 3 and 2 drives 3
	% Conf. 2 - 1 drives 2 and 3
	% Conf. 3 - 1 drives 2 and 3 and 2 and 3 drive each other back

	filesToLoad = {'x1','x_1_2','x_1_3','x_2_2','x_2_3','x_3_2','x_3_3'};
	for i=1:length(filesToLoad)
		load([dataPath filesToLoad{i} '.mat']);
	end

	ts{1} = [x1, x_1_2, x_1_3];
	ts{2} = [x1, x_2_2, x_2_3];
	ts{3} = [x1, x_3_2, x_3_3];

	%%

	for i=1:1%length(ts)

		figure;
		plot(ts{i});
		legend('1','2','3');

		data = ts{i}';
		EEG = struct('srate',1000,'times',1:size(data,2));

		out = c_EEG_calculateConnectivity(EEG,...
			'maxModelOrder',200,...
			'method','MVGC',...
			'aDTFArgs',{...
				'ModelOrder','FPE',...
				'NumShuffles',10,...
			},...
			'MVGCArgs',{...
				'ModelOrder','AIC',...
			},...
			'data',data);
	end

	keyboard

else
	testfn_mvgc();
end


end