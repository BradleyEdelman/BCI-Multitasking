function c_digitizer_compareData()

close all

persistent pathModified;
if isempty(pathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../'));
	addpath(fullfile(mfilepath,'../MeshFunctions'));
	pathModified = true;
end

c_EEG_openEEGLabIfNeeded();

% 
% filesToLoad = {...
% 	'D:\Data\digitizer test\Sty_161214\Sty_161216_LowestTransmitter.3DD',...
% 	'D:\Data\digitizer test\Sty_161214\Sty_161216_LowerTransmitter.3DD',...
% 	'D:\Data\digitizer test\Sty_161214\Sty_161216.3DD',...
% 	'D:\Data\digitizer test\Sty_161214\Brainsight_Exported Electrodes.elp',...
% % 	'D:\Data\digitizer test\Sty_161214\Sty_161214_NoMetal_20161214_02.pos',...
% % 	'D:\Data\digitizer test\Sty_161214\Sty_161214_NoMetal_20161214_02b.pos',...
% % 	'D:\Data\digitizer test\Sty_161214\Sty_161214_Metal_20161214_03.pos',...
% };

filesToLoad = {...
	'D:\Data\digitizer test\BE_161216\BE_161216.elp',...
	'D:\Data\digitizer test\BE_161216\BE_20161216_20161216_01.pos',...
	'D:\Data\digitizer test\BE_161216\BE_20161216.3DD',...
};

d = {};
for iF = 1:length(filesToLoad)
% 	[~,d{iF}] = c_digitizer_loadData(filesToLoad{iF},'transform',transforms{iF});
	[~,d{iF}] = c_digitizer_loadData(filesToLoad{iF});
end

if 0
	figure('name','Digitizer data');
	ha = [];
	for iD = 1:length(d);
		ha(iD) = c_subplot(iD,length(d));
		c_digitizer_plotData(d{iD});
	end
	c_plot_linkViews(ha);
end

%% export files in standard format
if 0 
	for iD = 1:length(d)
		[base, name, ext] = fileparts(filesToLoad{iD});
		exportPath = fullfile(base,['Exported_' name ext '.pos']);
		c_say('Exporting %s to %s',[name ext], exportPath);
		c_digitizer_saveAsPos(d{iD},exportPath);
		c_sayDone();
	end
end

%% remove outlying electrodes
for i=1:length(d)
	d{i} = c_digitizer_removeOutliers(d{i});
end

%% try aligning other datasets to first set
fiducialsToAlign = d{1}.electrodes.fiducials;
dr = d;
for iD = 2:length(d);
	dr{iD} = c_digitizer_alignToPoints(d{iD},'fiducialsToAlign',fiducialsToAlign);
end

ha = [];
for iD = 2:length(d)
	figure('name',sprintf('Comparison of %d and %d',1,iD));
	hold on;
	c_digitizer_plotData(d{1},...
		'markerSize',0.001);
	hold on;
	c_digitizer_plotData(dr{iD},...
		'markerSize',0.001,...
		'colorFiducials',[0,0.95,0],...
		'colorElectrodes',[0.8,0,0.8],...
		'colorShapePts',[1 1 1]*0.95...
		);
	if 1 
		% draw lines between each matching electrode
		%TODO: match by label instead of index
		xyzOrig = c_struct_mapToArray(d{1}.electrodes.electrodes,{'X','Y','Z'})*1e2;
		xyzNew = c_struct_mapToArray(dr{iD}.electrodes.electrodes,{'X','Y','Z'})*1e2;
		numToDraw = min(size(xyzNew,1),size(xyzOrig,1));
		for iP = 1:numToDraw
			line([xyzOrig(iP,1), xyzNew(iP,1)], [xyzOrig(iP,2), xyzNew(iP,2)], [xyzOrig(iP,3), xyzNew(iP,3)], 'Color',[1 0 0],'LineWidth',0.5);
		end
		c_saySingle('Drawing lines');
	end
	ha(iD-1) = gca;
end
c_plot_linkViews(ha)

c_fig_arrange('tile','Comparison');

%% plot relative to subject's scalp surface
%meshPath = 


end



