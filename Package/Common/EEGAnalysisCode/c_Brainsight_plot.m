function c_Brainsight_plot(varargin)

if nargin==0, testfn(); return; end;

%% dependencies
persistent pathModified;
if isempty(pathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../ThirdParty/arrow'));
	addpath(fullfile(mfilepath,'../ThirdParty/arrow3'));
	pathModified = true;
end

%% parsing
p = inputParser();
p.addRequired('Brainsight',@isstruct);
p.addParameter('doPlotPlannedLandmarks',true,@islogical);
p.addParameter('doPlotSessionLandmarks',true,@islogical);
p.addParameter('doPlotTargets',true,@islogical); % can be single logical or vector of indices into target list
p.addParameter('doPlotSamples',true,@islogical); % can be single logical or vector of indices into sample list
p.addParameter('doInteractiveSampleSlider',false,@islogical);
p.addParameter('doCheckForNonrigidSampleOrientations',false,@islogical);
p.addParameter('axis',[],@ishandle);
p.addParameter('meshSkin',[],@(x) isempty(x) || isstruct(x));
p.addParameter('meshCortex',[],@(x) isempty(x) || isstruct(x));
p.addParameter('doPlotOutliers',false,@islogical);
p.parse(varargin{:});
s = p.Results;
B = s.Brainsight;

%%

if isempty(s.axis)
	s.axis = gca;
end

if ~isempty(s.meshSkin)
	c_mesh_plot(s.meshSkin,'faceAlpha',0.5);
end

if ~isempty(s.meshCortex)
	c_mesh_plot(s.meshCortex);
end

axis(s.axis,'equal');
view(3);

if s.doPlotPlannedLandmarks
	pts = c_struct_mapToArray(B.planLandmarks,{'Loc_X','Loc_Y','Loc_Z'});
	c_plot_scatter3(pts,'ptColors',[0,0.5,0]);
end

if s.doPlotSessionLandmarks
	pts = c_struct_mapToArray(B.sessLandmarks,{'Loc_X','Loc_Y','Loc_Z'});
	c_plot_scatter3(pts);
end

if s.doPlotTargets
% 	pts = c_struct_mapToArray(B.targets,{'Loc_X','Loc_Y','Loc_Z'});
% 	c_plot_scatter3(pts);
	fieldMap = {...
		'm0n0','m1n0','m2n0','Loc_X';
		'm0n1','m1n1','m2n1','Loc_Y';
		'm0n2','m1n2','m2n2','Loc_Z'};
	ors = c_struct_mapToArray(B.targets,fieldMap);
	ors = cat(1,ors,repmat([0 0 0 1],1,1,size(ors,3))); % add bottom row of constants
	for iO = 1:size(ors,3)
		% plot arrow with head at orientation origin, pointing inward, with lines extending in 1 cm in each direction
		plotOrientation(s.axis,ors(:,:,iO),[0.5 0 0 ]);
	end
end

didWarnAboutOutliers = false;
if c_isFieldAndNonEmpty(B,'planLandmarks')
	pts = c_struct_mapToArray(B.planLandmarks,{'Loc_X','Loc_Y','Loc_Z'});
	headCenter = mean(pts,1);
else
	warning('Assuming head center is at [0,0,0]');
	headCenter = [0,0,0];
end

if s.doPlotSamples || s.doInteractiveSampleSlider || s.doCheckForNonrigidSampleOrientations
	fieldMap = {...
		'm0n0','m1n0','m2n0','Loc_X';
		'm0n1','m1n1','m2n1','Loc_Y';
		'm0n2','m1n2','m2n2','Loc_Z'};
	ors = c_struct_mapToArray(B.samples,fieldMap);
	ors = cat(1,ors,repmat([0 0 0 1],1,1,size(ors,3))); % add bottom row of constants

	if s.doCheckForNonrigidSampleOrientations
		c_say('Checking for non-rigid sample orientations');
		numNonRigid = 0;
		for iO = 1:size(ors,3)
			isRigid = c_quaternionTransformationIsRigid(ors(:,:,iO),...
					'relativeErrorThreshold',0.1,...
					'actionIfFalse','print',...
					'testPointScalar',1); %TODO: debug, delete
			if ~isRigid, numNonRigid = numNonRigid+1; end;
			if ~isRigid
	% 			c_plot_visualizeQuaternionTransformation(ors(:,:,iO),'unitLength',100,'doLabelLengths',true);
				keyboard
				[newQuat, correctionFactors] = c_quaternion_makeRigid(ors(:,:,iO),'unitLength',100);
				%[newQuat2, correctionFactors2] = c_quaternion_makeRigid(newQuat,'unitLength',100); % should be identical
				isRigid = c_quaternionTransformationIsRigid(newQuat,...
					'relativeErrorThreshold',0.1,...
					'actionIfFalse','warning',...
					'testPointScalar',1); %TODO: debug, delete
				ors(:,:,iO) = newQuat;
			end
		end
		if numNonRigid > 0
			c_saySingle('%d/%d orientations are not rigid transforms',numNonRigid,size(ors,3));
		end
		c_sayDone();
	end

	if s.doPlotSamples
		%for iO = 1:size(ors,3)
		if size(ors,3) > 50
			undersamplingInterval = 10;
			warning('Only plotting %.3g%% of samples to minimize plot complexity',1/undersamplingInterval*10);
		else
			undersamplingInterval = 1;
		end
		for iO = 1:undersamplingInterval:size(ors,3)

			% skip samples far away from head
			if ~s.doPlotOutliers && c_norm(ors(1:3,4,iO)'-headCenter,2,2) > 300
				if ~didWarnAboutOutliers
					warning('Not plotting some outlying samples');
					didWarnAboutOutliers = true;
				end
				continue;
			end

			% plot arrow with head at orientation origin, pointing inward, with lines extending in 1 cm in each direction
			plotOrientation(s.axis,ors(:,:,iO),[0.5 0.5 0.5]);
		end
	end
	
	if s.doInteractiveSampleSlider
		if ~isfield(B.samples,'datetime')
			B = c_Brainsight_setDateTimes(B);
		end
		
		highlightedSampleH = [];
		limitsWithoutHighlightedSample = c_struct_mapToArray(s.axis,{'XLim';'YLim';'ZLim'});
		c_plot_addSlider(...
			'callback',@updateInteractiveSample,...
			'axisHandle',s.axis,...
			'InitialValue',0,...
			'MinValue',0,...
			'MaxValue',size(ors,3),...
			'SliderStep',1,...
			'ValueToString',@(x) getSampleStr(B,round(x)));
	end
end

	function updateInteractiveSample(sliderVal, axisHandle)
		if ~isempty(highlightedSampleH)
			delete(highlightedSampleH);
			highlightedSampleH = [];
			c_array_mapToStruct(limitsWithoutHighlightedSample,{'XLim';'YLim';'ZLim'}, axisHandle);
		end
		
		sliderVal = round(sliderVal);
		
		if sliderVal == 0
			return;
		end
		
		assert(sliderVal <= size(ors,3));
		
		highlightedSampleH = plotOrientation(axisHandle,ors(:,:,sliderVal),[204 204 0]/255);
	end

end

function str = getSampleStr(B,i)
	if i==0
		str = 'No sample selected';
	else
		str = B.samples(i).Sample_Name;
		if isfield(B.samples(i),'datetime')
			str = [str,' ',c_toString(B.samples(i).datetime)];
		end
	end	
end

function h = plotOrientation(ax,or,color)
	arrowLength = 100;
	origin = or(1:3,4)';
	outerEnd = paren(or*[0 0 arrowLength/2 1]',1:3)';
	innerEnd = paren(or*[0 0 -arrowLength/2 1]',1:3)';
	lims = c_struct_mapToArray(ax,{'XLim';'YLim';'ZLim'})';
	tmp = cat(1,lims,outerEnd,innerEnd);
	newLims = extrema(tmp,[],1)';
	if ~isequal(newLims,lims)
		xlim(ax,newLims(:,1)');
		ylim(ax,newLims(:,2)');
		zlim(ax,newLims(:,3)');
	end
	h = [];
	if 0
		ht = arrow('Start',outerEnd,'Stop',origin,'FaceColor',color,'EdgeColor',color); 
		h = cat(2,h,ht);
		ht = arrow('Start',origin,'Stop',innerEnd,'FaceColor',color,'EdgeColor',color,'Ends','none');
		h = cat(2,h,ht);
	else
		prevColorOrder = ax.ColorOrder;
		ax.ColorOrder = color;
		ht = arrow3(outerEnd,origin,'o',1,1,[],1);
		h = cat(2,h,ht);
		ht = arrow3(origin,innerEnd,'o',0,0,[],1);
		h = cat(2,h,ht);
		ax.ColorOrder = prevColorOrder;
	end
end

function testfn()
% 	BrainsightPath = 'N:\Data_TMSBCI\Sty_161028b\Sty_MRI_161028_CoordNIfTI.txt';
	BrainsightPath = 'N:\Data_TMSBCI\Sty_161028b\Sty_161028_CoordMNI.txt';
% 	BrainsightPath = 'N:\Data_TMSBCI\Sty_161028b\Sty_161028_CoordBrainsight_transformed.txt';
	cortexMeshPath = 'N:\Data_TMSBCI\Sty_161028b\gm_transf.stl';
	skinMeshPath = 'N:\Data_TMSBCI\Sty_161028b\skin_transf.stl';

	Brainsight = c_loadBrainsightData(BrainsightPath);
	meshCortex = c_mesh_load(cortexMeshPath);
	meshSkin = c_mesh_load(skinMeshPath);

	figure('name',BrainsightPath);
	c_Brainsight_plot(Brainsight,...
		'meshCortex',meshCortex,...
		'meshSkin',meshSkin);
end