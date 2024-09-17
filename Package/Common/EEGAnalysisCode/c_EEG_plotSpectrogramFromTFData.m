function c_EEG_plotSpectrogramFromTFData(varargin)
p = inputParser();
p.addRequired('tfdata',@isnumeric);
p.addParameter('t',[],@isvector); % in s
p.addParameter('f',[],@isvector); % in Hz
p.addParameter('dataAlreadyIndB',false,@islogical);
p.addParameter('tfIndicesToBlank',[],@(x) ismatrix(x) && islogical(x));
p.addParameter('blankedAlpha',0,@isscalar);
p.addParameter('baselineMethod','avg',@ischar);
p.addParameter('baselineTimespan',[-inf 0],@c_isSpan);
p.addParameter('axis',[],@ishandle);
p.addParameter('softLimsCoeff',0.1,@isscalar); % set to 0 to use hard extrema for colorlimits
p.addParameter('doForceSymmetricColorbar',true,@islogical);
p.parse(varargin{:});
s = p.Results;

if isempty(s.axis)
	s.axis = gca;
end

if ~s.dataAlreadyIndB
	% convert to dB
	s.tfdata = 20*log10(abs(s.tfdata));
end

mean_tfdata = nanmean(s.tfdata,3); % mean across epochs

%%
switch(s.baselineMethod)
	case 'avg'
		% calculate single average baseline and subtract from all trials
		timeIndices = s.t >= s.baselineTimespan(1) & s.t < s.baselineTimespan(2);
		if isempty(s.tfIndicesToBlank)
			baseline_dB = nanmean(mean_tfdata(:,timeIndices),2);
		else
			baseline_dB = nan(length(s.f),1);
			for iF = 1:length(s.f)
				baseline_dB(iF) = nanmean(mean_tfdata(iF,timeIndices & ~s.tfIndicesToBlank(iF,:)),2);
			end
		end
		
		mean_tfdata = bsxfun(@minus,mean_tfdata,baseline_dB);
			
	case 'trial'
		% calculate and subtract per-trial baseline 
		keyboard %TODO
	case 'none'
		% do nothing (no baseline subtraction)
	otherwise
		error('Invalid baselineMethod: %s',s.baselineMethod);
end
		
%%
if ~isempty(s.tfIndicesToBlank)
	imagesc(s.t*1e3,s.f,nan(size(mean_tfdata)),'parent',s.axis); % for non-white background
	hold on;
end

h = imagesc(s.t*1e3,s.f,mean_tfdata,'parent',s.axis);

if ~isempty(s.tfIndicesToBlank)
	h.AlphaData = 1-s.tfIndicesToBlank*(1-s.blankedAlpha);
end

s.axis.YDir = 'normal';
hc = colorbar;
xlabel(hc,'Power (dB)')


if isempty(s.tfIndicesToBlank)
	tmpData = mean_tfdata(:);
else
	tmpData = mean_tfdata(~s.tfIndicesToBlank);
end
lims = prctile(tmpData,[0 100]+s.softLimsCoeff*[1 -1]);

if s.doForceSymmetricColorbar
	lims = max(abs(lims))*[-1 1];
end
caxis(lims);

xlabel('Time (ms)');
ylabel('Freq (Hz)');

end