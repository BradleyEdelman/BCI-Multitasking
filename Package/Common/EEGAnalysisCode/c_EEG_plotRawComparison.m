function c_EEG_plotRawComparison(varargin)
p = inputParser();
p.addRequired('EEGs',@(x) iscell(x) && length(x)==2);
p.addParameter('descriptors',{'1','2'},@(x) length(x)==2 && iscellstr(x)); % string labels, one for each dataset
p.addParameter('eegplotArgs',{},@iscell);
p.addParameter('showEventsFrom',1,@isscalar);
p.parse(varargin{:});
s = p.Results;

EEG1 = s.EEGs{1};
EEG2 = s.EEGs{2};

assert(isequal(size(EEG1.data),size(EEG2.data)));
sharedFields = {'srate','nbchan','trials','pnts','times'};
for iF = 1:length(sharedFields)
	if isscalar(EEG1.(sharedFields{iF}))
		assert(isequal(EEG1.(sharedFields{iF}),EEG2.(sharedFields{iF})));
	else
		% allow tolerance
		a = EEG1.(sharedFields{iF});
		b = EEG2.(sharedFields{iF});
		assert(length(a)==length(b));
		assert(all(abs(a-b)<eps*1e3));
	end
end

eegplot(EEG1.data,...
	'data2',EEG2.data,...
	'srate',EEG1.srate,...
	'events',s.EEGs{s.showEventsFrom}.event,...
	'eloc_file',s.EEGs{1}.chanlocs,...
	'title',sprintf('Comparison: Black = %s, Red = %s',s.descriptors{1},s.descriptors{2}),...
	'limits',[EEG1.xmin, EEG1.xmax]*1e3,...
	s.eegplotArgs{:});
	
end