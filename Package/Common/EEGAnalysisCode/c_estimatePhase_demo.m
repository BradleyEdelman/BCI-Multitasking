function c_estimatePhase_Demo()

%% Simple pure sinusoid with constant envelope
if 0
clear all;

Fs = 1000;
tmin = -1;
tmax = 1;
t = tmin:1/Fs:tmax;

f0 = 10; % Hz, fundamental frequency

cleanSig = sin(2*pi*f0*t);

phaseEstimateArgs = {...
	'morlet_Fc',f0,...
	'inputTime',t,...
	'outputTime',t};

figure('name','Pure sinusoid');
c_subplot(2,1,1);
plot(t,cleanSig);
xlabel('Time (s)');
ylabel('Amplitude');

cleanPhase = angle(hilbert(cleanSig));

c_subplot(2,1,2);
plot(t,cleanPhase);
if 0 
	cleanPhase2 = c_estimatePhase(cleanSig,Fs,...
		phaseEstimateArgs{:});

	hold on;
	plot(t,cleanPhase2); %TODO: debug, delete
end
xlabel('Time (s)');
ylabel('Phase (radians)');



%% adding noise

noiseStd = 1;
noisySig = cleanSig + randn(1,length(cleanSig))*noiseStd;

noisyPhase = c_estimatePhase(noisySig,Fs,...
	phaseEstimateArgs{:});

figure;
c_subplot(2,1,1);
plot(t,noisySig);
hold on;
plot(t,cleanSig);
legend('Noisy','Clean');

c_subplot(2,1,2);
plot(t,noisyPhase);
hold on;
plot(t,cleanPhase);
legend('Noisy','Clean');

end

%% multiple frequency components requiring filtering

clear all; close all

 set(0,'defaultlinelinewidth',2)

numRows = 4;

Fs = 1000;
tmin = -1.5;
tmax = 1.5;
t = tmin:1/Fs:tmax;

tPlotLim = [-1 1];

f0 = 10; % Hz, fundamental frequency
f1 = 3;
f2 = 25; 

tSubsetIndices = t < -0.1;

alpha = 1;
beta = 1;

cleanSig = sin(2*pi*f0*t + pi/4);
cleanPhase = angle(hilbert(cleanSig));

noisySig = cleanSig + alpha*sin(2*pi*f1*t) + beta*sin(2*pi*f2*t);
noiseStd = 0.5;
noisySig = noisySig + randn(1,length(noisySig))*noiseStd;
inputSig = noisySig(tSubsetIndices);

% set up plots
figure;
c_fig_arrange('right-half',gcf,'monitor',2)

ha = c_subplot(numRows,1,1);
xlim(tPlotLim);
ylim([-4 4]);
ha.XTickLabel = [];
ylabel('Amplitude');
hold on;

ha = c_subplot(numRows,1,2);
xlim(tPlotLim);
ylim([-4 4]);
ha.XTickLabel = [];
ylabel('Amplitude');
hold on;

ha = c_subplot(numRows,1,3);
xlim(tPlotLim);
ylim([-pi pi]*1.3);
ha.XTickLabel = [];
ylabel('Phase (radians)');
hold on;

ha = c_subplot(numRows,1,4);
xlim(tPlotLim);
ylim([-2 1]);
xlabel('Time (s)');
ylabel('Phase error (radians)');
hold on;

c_subplot(numRows,1,1);
plot(t,noisySig);
legend('Full input signal');
xlim(tPlotLim);

c_subplot(numRows,1,2);
plot(t,cleanSig);
xlim(tPlotLim);
legend('Ground truth signal');

c_subplot(numRows,1,3);
plot(t,cleanPhase);
xlim(tPlotLim);
legend('Ground truth phase');

c_FigurePrinter.copyToClipboard()
keyboard

c_subplot(numRows,1,1);
plot(t(tSubsetIndices),inputSig);
legend('Full input signal','Partial input signal');
xlim(tPlotLim);

c_FigurePrinter.copyToClipboard()
keyboard

% construct filter
Fc1 = f0*0.8;
Fc2 = f0*1.2;
filtOrder = min(Fs/f0*5, 0.2*Fs); % order is at least 5 periods at frequency of interest, or at most 0.2 s
b = fir1(filtOrder, [Fc1 Fc2]/(Fs/2), 'bandpass', kaiser(filtOrder+1, 0.5), 'scale');

filtNoisySig = filtfilt(b,1,noisySig);

c_subplot(numRows,1,2);
filtInputSig = filtfilt(b,1,inputSig);
plot(t(tSubsetIndices),filtInputSig);
xlim(tPlotLim);
legend('Ground truth signal','Filtered signal');

estimatedPhase = angle(hilbert(filtInputSig));

c_subplot(numRows,1,3);
plot(t(tSubsetIndices), estimatedPhase)
xlim(tPlotLim);
legend('Ground truth phase','Estimated phase');

ha = c_subplot(numRows,1,4);
hold on;
ha.ColorOrderIndex = 2;
plot(t(tSubsetIndices),c_wrapToPi(estimatedPhase - cleanPhase(tSubsetIndices)));
legend('Phase estimate error');
xlim(tPlotLim);

c_FigurePrinter.copyToClipboard()
keyboard

c_subplot(numRows,1,1);
modelOrder = 200;
extrapSig = c_extrapolateSignal(inputSig,length(b)*2,modelOrder);
addedIndices = paren(find(~tSubsetIndices),1:length(extrapSig)-length(inputSig));
extendedIndices = [find(tSubsetIndices) addedIndices];
plot(t(addedIndices),extrapSig(addedIndices));
legend('Full input signal','Partial input signal','Extrapolated signal');

c_FigurePrinter.copyToClipboard()
keyboard

filtExtrapSig = filtfilt(b,1,extrapSig);

c_subplot(numRows,1,2);
plot(t(extendedIndices), filtExtrapSig);
legend('Ground truth signal','Filtered signal','Filtered extrapolated signal');

c_subplot(numRows,1,3);
estimatedPhase = angle(hilbert(filtExtrapSig));
plot(t(extendedIndices), estimatedPhase);
legend('Ground truth phase','Estimated phase w/o extrapolation','Estimated phase w/ extrapolation');

c_subplot(numRows,1,4);
plot(t(extendedIndices), c_wrapToPi(estimatedPhase - cleanPhase(extendedIndices)));
legend('Estimated phase error w/o extrapolation','Estimated phase error w/ extrapolation');

c_FigurePrinter.copyToClipboard()
keyboard




end


function extrapSig = c_extrapolateSignal(sig,numAddedPts,modelOrder)
	if nargin < 3
		modelOrder = floor(length(sig)-1);
	end
	
	modelCoeff = arburg(sig,modelOrder);
	
	extrapSig = zeros(1, length(sig) + numAddedPts);
	
	extrapSig(1:length(sig)) = sig; % do not extrapolate what we already know
	
	[~,zf] = filter(-[0 modelCoeff(2:end)], 1, sig);
	extrapSig((length(sig)+1):end) = filter([0 0], -modelCoeff, zeros(1, length(extrapSig)-length(sig)), zf);
	
end







