function c_EEG_plotTrialData(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('title','EEG trials',@ischar);
p.addParameter('sliceChannel','C3',@ischar);
p.addParameter('clim',[nan nan],@isnumeric);
p.parse(varargin{:});
s = p.Results;
EEG = p.Results.EEG;

assert(c_EEG_isEpoched(EEG));

permuteOrder = [2 3 1];

c_GUI_visualize3DMatrix(...
	'data',permute(EEG.data,permuteOrder),...
	'axisData',paren({(1:EEG.nbchan), EEG.times, (1:EEG.trials)},permuteOrder),...
	'labels',paren({'EEG channel','Time (ms)','Trial #'},permuteOrder),...
	'sliceIndex',c_EEG_getChannelIndex(EEG,s.sliceChannel),...
	'sliceAxis',permuteOrder(2),...
	'clim',s.clim,...
	'title',s.title);



end