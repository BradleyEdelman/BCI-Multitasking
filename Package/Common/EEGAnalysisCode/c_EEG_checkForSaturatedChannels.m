function [saturatedChannelNames, saturationScores] = c_EEG_checkForSaturatedChannels(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('windowLength',5,@isscalar); % s
p.addParameter('windowOverlap',0.5,@isscalar); % s
p.addParameter('method','percentAtAbsMax',@ischar);
p.addParameter('threshold',1,@isscalar);
p.addParameter('doPlot',true,@islogical);
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

channelMaxMagnitudes = nanmax(abs(EEG.data),[],2);
%TODO: check for possibly different positive and negative extrema rather than assuming they are the same for saturation on either end

windowLength = s.windowLength;
windowOverlap = s.windowOverlap; 
endIndices = ceil(windowLength*EEG.srate):round((windowLength-windowOverlap)*EEG.srate):size(EEG.data,2);
startIndices = endIndices - round(windowLength*EEG.srate)+1;

numWindows = length(startIndices);

isSaturated = false(EEG.nbchan,numWindows);

saturatedChannelNames = {};

switch(s.method)
	case 'windowMedian'
		for wi=1:numWindows
			isSaturated(:,wi) = abs(nanmedian(EEG.data(:,startIndices(wi):endIndices(wi)),2))==channelMaxMagnitudes;
		end

		numWindowsSaturated = sum(isSaturated,2);

		percentWindowsSaturated = numWindowsSaturated/numWindows*100;
		saturationScores = percentWindowsSaturated/100;

		percentThreshold = s.threshold;
		
		if any(percentWindowsSaturated > percentThreshold)
			saturatedChannelIndices = find(percentWindowsSaturated > percentThreshold);
			if s.doPlot
				figure('name','Channel saturation test result');
				bar(numWindowsSaturated/numWindows*100);
				xlabel('Channel #');
				ylabel('Percent of windows saturated');

				figure('name','Saturated channel time courses (undersampled)')
				for i=1:length(saturatedChannelIndices)
					undersampleRatio = 100;
					c_subplot(i,length(saturatedChannelIndices));
					plot(EEG.times(1:undersampleRatio:end),EEG.data(saturatedChannelIndices(i),1:undersampleRatio:end));
					str = EEG.chanlocs(saturatedChannelIndices(i)).labels;
					if isempty(str)
						str = num2str(saturatedChannelIndices(i));
					end
					title(str);
				end
			end
		end

		saturatedChannelNames = c_EEG_getChannelName(EEG,saturatedChannelIndices);

	case 'percentAtAbsMax'
		
		indicesAtExtrema = bsxfun(@eq,abs(EEG.data),channelMaxMagnitudes);
		
		percentTimeAtExtrema = sum(indicesAtExtrema,2)/size(EEG.data,2)*100;
		saturationScores = percentTimeAtExtrema / 100;
		
		saturatedIndices = percentTimeAtExtrema > s.threshold;
		
		if s.doPlot
			hf = figure('name','Channel saturation test result');
			c_subplot(1,3);
			numCh = size(EEG.data,1);
			hold on;
			bh = bar(1:numCh,percentTimeAtExtrema);
			xlim([0,numCh+1]);
			line(xlim,[s.threshold,s.threshold],'color',[1 0 0]); 
			xlabel('Channel #');
			ylabel('% time saturated');
			
			c_subplot(2,3);
			c_topoplot(percentTimeAtExtrema,EEG.chanlocs,'maplimits',[0,prctile(percentTimeAtExtrema,75)]);
			c_subplot(3,3);
			c_topoplot(percentTimeAtExtrema,EEG.chanlocs,'maplimits',[0,s.threshold]);
			
			c_fig_arrange('top-half',hf);
		end
		
		saturatedChannelNames = c_EEG_getChannelName(EEG,saturatedIndices);
		
	otherwise
		error('invalid method: %s',s.method);
end
end