classdef c_DigitizedMontage < handle & matlab.mixin.Copyable
	properties
		fiducials
		electrodes
		shapePoints
		distUnit
		templateFiducial = struct(...
			'label','',...
			'X','',...
			'Y','',...
			'Z','');
		templateElectrode = struct(...
			'label','',...
			'type','',...
			'X','',...
			'Y','',...
			'Z','');
		templateShapePoint = struct(...
			'X','',...
			'Y','',...
			'Z','');
			
	end
	
	properties(Access=protected)
		
	end
	
	properties(Dependent, SetAccess=protected)
		numElectrodes
		numFiducials
		numShapePoints
		fiducialLabels
		electrodeTypes
		electrodeLabels
	end
	
	methods
		%% constructor
		function o = c_DigitizedMontage(varargin)
			p = inputParser();
			p.addParameter('fiducials',[],@isstruct);
			p.addParameter('electrodes',[],@isstruct);
			p.addParameter('shapePoints',[],@isstruct);
			p.addParameter('distUnit',NaN,@isDistUnit); % 1 for m, 0.01 for cm, 0.001 for mm
			p.addParameter('initFromFile','',@ischar);
			p.addParameter('initFromXYZ',[],@ismatrix);
			p.addParameter('initFromMontageName','',@ischar);
			p.addParameter('initFromChanlocs',[],@isstruct);
			p.addParameter('electrodeTypes',{},@iscell);
			p.addParameter('doTest',false,@islogical);
			p.parse(varargin{:});
			s = p.Results;
			
			if s.doTest
				testfn();
				return;
			end
			
			paramsToCopy = {'fiducials','electrodes','shapePoints','distUnit'};
			for iP = 1:length(paramsToCopy)
				o.(paramsToCopy{iP}) = p.Results.(paramsToCopy{iP});
			end
			
			% handle special init params
			% note that behavior is undefined if more than one initFrom* is specified
			if ~isempty(s.initFromFile)
				o = o.initFromFile(s.initFromFile);
			elseif ~isempty(s.initFromXYZ)
				o = o.initFromXYZ(s.initFromXYZ);
			elseif ~isempty(s.initFromMontageName)
				o = o.initFromMontageName(s.initFromMontageName);
			elseif ~isempty(s.initFromChanlocs)
				o = o.initFromChanlocs(s.initFromChanlocs);
			end
			
			if isnan(s.distUnit)
				% if not set, try to infer dist unit
				if o.numElectrodes > 0 || o.numFiducials > 0
					o.autosetDistUnit();
				else
					% if no electrodes, just assume units of m
					o.distUnit = 1;
				end
			end
			
			if ~isempty(s.electrodeTypes)
				o.electrodeTypes = s.electrodeTypes;
			end
		end
		
		%% import
		function o = initFromFile(o,filepath)
			assert(exist(filepath,'file')>0);
			[~,~,ext] = fileparts(filepath);
			switch(lower(ext))
				case '.pos'
					raw = c_digitizer_loadPolhemus(filepath);
					o.initFromRaw(raw);
				case '.elp'
					[~,raw] = c_loadBrainsightDigitizerData(filepath);
					o.initFromRaw(raw);
				case '.3dd'
					raw = c_digitizer_load3DD(filepath);
					o.initFromRaw(raw);
				case '.txt'
					raw = c_digitizer_loadTxt(filepath);
					o.initFromRaw(raw);
				case '.bvef'
					chanlocs = c_digitizer_loadBVEF(filepath);
					o.initFromChanlocs(chanlocs);
				case '.mat'
					tmp = load(filepath); 
					o = tmp.o; % assume was saved as class instance
				otherwise
					error('Unsupported extension: %s');
			end
		end
		
		function o = initFromRaw(o,raw)
			if c_isFieldAndNonEmpty(raw,'electrodes.electrodes')
				o.electrodes = raw.electrodes.electrodes;
				% make sure that all fields that are in template are in electrodes
				fields = fieldnames(o.templateElectrode);
				for iF = 1:length(fields)
					if ~isfield(o.electrodes,fields{iF})
						[o.electrodes.(fields{iF})] = deal('');
					end
				end
				% make sure that all fields that are in electrodes are in template
				o.updateTemplateElectrode();
			else
				o.electrodes = [];
			end
			
			if c_isFieldAndNonEmpty(raw,'electrodes.fiducials')
				% if both are specified, default to using fiducials from electrodes struct rather than shape struct
				o.fiducials = raw.electrodes.fiducials;
			elseif c_isField(raw,'shape.fiducials')
				o.fiducials = raw.shape.fiducials;
			else
				o.fiducials = [];
			end
			
			if c_isField(raw,'shape.points')
				o.shapePoints = raw.shape.points;
			end
		end
		
		function o = initFromXYZ(o,XYZ)
			assert(size(XYZ,2)==3);
			numElectrodes = size(XYZ,1);
			for iE = 1:numElectrodes
				if iE==1
					o.electrodes = o.templateElectrode;
				else
					o.electrodes(iE) = o.templateElectrode;
				end
				o.electrodes(iE).label = sprintf('Ch%d',iE);
			end
			o.electrodes = c_array_mapToStruct(XYZ,{'X','Y','Z'},o.electrodes);
		end
		
		function o = initFromMontageName(o,montageName)
			c_EEG_openEEGLabIfNeeded();
			
			EEG = struct();
			EEG = c_EEG_setChannelLabelsFromMontage(EEG,montageName);
			EEG = c_EEG_setChannelLocationsFromMontage(EEG,montageName);
			
			raw = convertChanlocsToRaw(EEG.chanlocs);
			
			o = o.initFromRaw(raw);
		end
		
		function o = initFromChanlocs(o,chanlocs)
			c_EEG_openEEGLabIfNeeded();
			
			raw = convertChanlocsToRaw(chanlocs);
			
			o = o.initFromRaw(raw);
		end
		
		%% export
		function raw = asRawDigitizedData(o,varargin)
			p = inputParser();
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			raw = struct();
			if ~isempty(o.electrodes)
				raw.electrodes = struct();
				raw.electrodes.electrodes = o.electrodes;
			end
			
			if ~isempty(o.shapePoints)
				raw.shape = struct();
				raw.shape.points = o.shapePoints;
			end
			
			if ~isempty(o.fiducials)
				if ~isfield(raw,'electrodes') && ~isfield(raw,'shape')
					raw.electrodes = struct();
				end
				if isfield(raw,'electrodes')
					raw.electrodes.fiducials = o.fiducials;
				end
				if isfield(raw,'shape');
					raw.shape.fiducials = o.fiducials;
				end
			end
			
			scaleFactor = c_convertValuesFromUnitToUnit(1,o.distUnit,s.distUnit);
			if scaleFactor ~= 1
				raw = scaleRawDistances(raw,scaleFactor);
			end
		end
		
		function chanlocs = asChanlocs(o,varargin)
			assert(isempty(varargin)); % no input args (for now)
			
			raw = o.asRawDigitizedData;
			chanlocs = convertRawToChanlocs(raw);
		end
		
		function [XYZ, electrodeTypes] = getElectrodesAsXYZ(o,varargin)
			p = inputParser();
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			XYZ = c_struct_mapToArray(o.electrodes,{'X','Y','Z'});
			
			scaleFactor = c_convertValuesFromUnitToUnit(1,o.distUnit,s.distUnit);
			XYZ = scaleFactor*XYZ;
			
			if nargout > 1
				electrodeTypes = o.electrodeTypes;
			end
		end
		
		function XYZ = getFiducialsAsXYZ(o,varargin)
			p = inputParser();
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			XYZ = c_struct_mapToArray(o.fiducials,{'X','Y','Z'});
			
			scaleFactor = c_convertValuesFromUnitToUnit(1,o.distUnit,s.distUnit);
			XYZ = scaleFactor*XYZ;
		end
		
		function [RTP, centerXYZ] = getElectrodesAsSphericalRTP(o,varargin)
			% getElectrodesAsSphericalRTP: get electrode locations in (radius, theta, phi) spherical coordinates
			p = inputParser();
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.addParameter('doCenter',true,@islogical);
			p.parse(varargin{:});
			s = p.Results;
			
			XYZ = o.getElectrodesAsXYZ('distUnit',s.distUnit);
			
			if s.doCenter
				centerXYZ = nanmean(XYZ,1);
				XYZ = bsxfun(@minus,XYZ,centerXYZ);
			else
				centerXYZ = [0 0 0];
			end
			
			% based on https://en.wikipedia.org/wiki/Spherical_coordinate_system
			% (same as in c_mesh_calculateSphericalVertices)
			
			RTP = nan(size(XYZ));
			RTP(:,1) = c_norm(XYZ,2,2); % radius
			RTP(:,2) = acosd(XYZ(:,3)./RTP(:,1)); % inclination angle in degrees
			RTP(:,3) = atan2d(XYZ(:,2),XYZ(:,1)); % azimuthal angle in degrees
		end
		
		function saveToFile(o,filepath)
			[~,~,ext] = fileparts(filepath);
			switch(lower(ext))
				case '.pos'
					raw = o.asRawDigitizedData('distUnit',1);
					c_digitizer_saveAsPos(raw,filepath);
				case '.mat'
					save(filepath,'o');
				otherwise
					error('Unsupported output format');
			end
		end
		
		%% edit
		
		function setFiducial(o,varargin)
			p = inputParser();
			p.addRequired('fiducialLabel',@ischar);
			p.addParameter('XYZ',[],@isvector);
			%TODO: add other possible methods of specifying position (e.g. polar coordinates)
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;

			if ~isempty(s.XYZ)
				index = [];
				if ~isempty(o.fiducials)
					index = find(ismember({o.fiducials.label},s.fiducialLabel),1,'first');
				end
				if isempty(index)
					index = length(o.fiducials)+1;
				end
				if isempty(o.fiducials) && index==1
					o.fiducials = o.templateFiducial;
				else
					o.fiducials(index) = o.templateFiducial;
				end
				
				s.XYZ = c_convertValuesFromUnitToUnit(s.XYZ,s.distUnit,o.distUnit);
				
				o.fiducials(index) = c_array_mapToStruct(s.XYZ,{'X','Y','Z'},o.fiducials(index));
				o.fiducials(index).label = s.fiducialLabel;
			else
				error('Must specify coordinates');
			end
		end
		
		function setElectrode(o,varargin)
			p = inputParser();
			p.addRequired('electrodeLabel',@ischar);
			p.addParameter('XYZ',[],@isvector);
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			if ~isempty(s.XYZ)
				index = [];
				if ~isempty(o.electrodes)
					index = find(ismember({o.electrodes.label},s.electrodeLabel),1,'first');
				end
				if isempty(index)
					index = length(o.electrodes)+1;
				end
				if isempty(o.electrodes) && index==1
					o.electrodes = o.templateElectrode;
				else
					o.electrodes(index) = o.templateElectrode;
				end
				
				s.XYZ = c_convertValuesFromUnitToUnit(s.XYZ,s.distUnit,o.distUnit);
				
				o.electrodes(index) = c_array_mapToStruct(s.XYZ,{'X','Y','Z'},o.electrodes(index));
				o.electrodes(index).label = s.electrodeLabel;
			else
				error('Must specify coordinates');
			end
		end
		
		function setShapePoint(o,varargin)
			p = inputParser();
			p.addRequired('ptIndex',@isscalar);
			p.addParameter('XYZ',[],@isvector);
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			assert(s.ptIndex > 0 && s.ptIndex <= o.numShapePoints+1);
				
			if ~isempty(s.XYZ)
				if isempty(o.shapePoints) && s.ptIndex==1
					o.shapePoints = o.templateShapePoint;
				else
					o.shapePoints(s.ptIndex) = o.templateShapePoint;
				end
				
				s.XYZ = c_convertValuesFromUnitToUnit(s.XYZ,s.distUnit,o.distUnit);
				
				o.shapePoints(s.ptIndex) = c_array_mapToStruct(s.XYZ,{'X','Y','Z'},o.shapePoints(s.ptIndex));
			else
				error('Must specify coordinates');
			end
		end
		
		function addElectrodes(o,varargin)
			p = inputParser();
			p.addParameter('XYZ',[],@ismatrix);
			p.addParameter('labels',{},@iscell);
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			scaleFactor = c_convertValuesFromUnitToUnit(1,s.distUnit,o.distUnit);
			
			if ~isempty(s.XYZ)
				assert(size(s.XYZ,2)==3);
				numElectrodesToAdd = size(s.XYZ,1);
				if ~isempty(s.labels), assert(length(s.labels)==numElectrodesToAdd); end;
				for iE = 1:numElectrodesToAdd
					newE = o.templateElectrode;
					if ~isempty(s.labels)
						newE.label = s.labels{iE};
					else
						newE.label = sprintf('Ch%d',o.numElectrodes+iE);
						%TODO: check to make sure another channel with this label doesn't already exist
					end
					newE = c_array_mapToStruct(s.XYZ(iE,:)*scaleFactor,{'X','Y','Z'},newE);
					if isempty(o.electrodes)
						o.electrodes = newE;
					else
						o.electrodes(o.numElectrodes+1) = newE;
					end
				end
			else
				% (set up this way to allow other methods of specifying electrode location in the future)
				error('Must specify coordinates');
			end
		end
		
		function addShapePoints(o,varargin)
			p = inputParser();
			p.addParameter('XYZ',[],@ismatrix);
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			scaleFactor = c_convertValuesFromUnitToUnit(1,s.distUnit,o.distUnit);
			
			if ~isempty(s.XYZ)
				assert(size(s.XYZ,2)==3);
				numPtsToAdd = size(s.XYZ,1);
				for iP = 1:numPtsToAdd
					newPt = o.templateShapePoint;
					newPt = c_array_mapToStruct(s.XYZ(iP,:)*scaleFactor,{'X','Y','Z'},newPt);
					if isempty(o.shapePoints)
						o.shapePoints = newPt;
					else
						o.shapePoints(o.numShapePoints+1) = newPt;
					end
				end
			else
				error('Must specify coordinates');
			end
		end
			
		function deleteElectrodes(o,varargin)
			p = inputParser();
			p.addParameter('byIndex',[],@isvector);
			p.addParameter('byXYZ',[],@ismatrix);
			p.addParameter('byLabel',{},@(x) ischar(x) || iscell(x));
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			if ~isempty(s.byIndex)
				indicesToRemove = s.byIndex;
				if islogical(indicesToRemove)
					assert(length(indicesToRemove)==o.numElectrodes);
				else
					assert(max(indicesToRemove) <= o.numElectrodes);
				end
				o.electrodes(indicesToRemove) = [];
			elseif ~isempty(s.byXYZ)
				assert(size(s.byXYZ,2)==3);
				ptsToRemove = s.byXYZ;
				% find electrodes closest to each XYZ point and remove them
				% (note that one electrode may be the closest to more than one input, so
				%  number of electrodes deleted may be less than number of points specified)
				electrodeXYZ = o.getElectrodesAsXYZ('distUnit',s.distUnit);
				closestElectrodeIndex = nan(1,size(ptsToRemove,1));
				for iP = 1:size(ptsToRemove,1)
					dists = c_norm(bsxfun(@minus,electrodeXYZ,ptsToRemove(iP,:)),2,2);
					[~,closestElectrodeIndex(iP)] = min(dists);
				end
				indicesToRemove = unique(closestElectrodeIndex);
				o.electrodes(indicesToRemove) = [];
			elseif ~isempty(s.byLabel)
				if ischar(s.byLabel)
					s.byLabel = {s.byLabel};
				end
				for iE = 1:length(s.byLabel)
					labelToRemove = s.byLabel{iE};
					index = find(ismember({o.electrodes.label},labelToRemove));
					if isempty(index)
						warning('Label %s not found, not removing.');
						continue;
					end
					c_saySingle('Removing %s',c_toString(o.electrodes(index)));
					o.electrodes(index) = [];
				end
			else
				error('No electrodes to remove specified');
			end
		end
			
			
		function aligningTransform = alignTo(o,otherMontage)
			if c_isEmptyOrEmptyStruct(otherMontage.fiducials)
				error('No fiducials in other montage with which to align');
			end
			
			prevDistUnit = o.distUnit;
			o.changeDistUnit(otherMontage.distUnit);
			
			selfRaw = o.asRawDigitizedData();
			
			%TODO: add support for aligning to other fields (e.g. head shape or electrodes)
			[selfRawAligned, aligningTransform] = c_digitizer_alignToPoints(selfRaw,...
				'fiducialsToAlign',otherMontage.fiducials);
			
			o = o.initFromRaw(selfRawAligned);
			
			o.changeDistUnit(prevDistUnit);
		end
		
		function transform(o,varargin)
			p = inputParser();
			p.addRequired('transform',@ismatrix);
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			prevDistUnit = o.distUnit;
			o.changeDistUnit(s.distUnit);
			
			if ~c_isEmptyOrEmptyStruct(o.fiducials)
				o.fiducials = transformStructXYZVals(o.fiducials,s.transform);
			end
			if ~c_isEmptyOrEmptyStruct(o.electrodes)
				o.electrodes = transformStructXYZVals(o.electrodes,s.transform);
			end
			if ~c_isEmptyOrEmptyStruct(o.shapePoints)
				o.shapePoints = transformStructXYZVals(o.shapePoints,s.transform);
			end
			
			o.changeDistUnit(prevDistUnit);
		end
		
		function changeDistUnit(o,newDistUnit)
			% change distUnit with automatic conversion of previously stored distances 
			
			if o.distUnit == newDistUnit
				% do nothing
				return;
			end
			
			if isempty(o.distUnit) 
				o.distUnit = newDistUnit;
			else
% 				c_saySingle('Changing distUnit from %.3g to %.3g',o.distUnit,newDistUnit);
				scaleFactor = c_convertValuesFromUnitToUnit(1,o.distUnit,newDistUnit);
				if ~c_isEmptyOrEmptyStruct(o.fiducials)
					o.fiducials = scaleStructXYZVals(o.fiducials,scaleFactor);
				end
				if ~c_isEmptyOrEmptyStruct(o.electrodes)
					o.electrodes = scaleStructXYZVals(o.electrodes,scaleFactor);
				end
				if ~c_isEmptyOrEmptyStruct(o.shapePoints)
					o.shapePoints = scaleStructXYZVals(o.shapePoints,scaleFactor);
				end
				o.distUnit = newDistUnit;
			end
		end
		
		function autosetDistUnit(o)
			% try to infer distUnit based on electrode locations
			if o.numElectrodes == 0 && o.numFiducials == 0
				error('No electrodes or fiducials from which to infer distUnit');
			end
			if o.numElectrodes > 0
				electrodesRTP = o.getElectrodesAsSphericalRTP('doCenter',o.numElectrodes>5);
				medianR = nanmedian(abs(electrodesRTP(:,1)));
				if medianR < 0.05
					error('Unexpected unit'); % larger unit than m
				elseif medianR < 0.2
					o.distUnit = 1; % m
				elseif medianR < 2
					error('Unexpected unit'); % decimeters?
				elseif medianR < 20
					o.distUnit = 1e-2; % cm
				elseif medianR < 200
					o.distUnit = 1e-3; % mm
				else
					error('Unexpected unit'); % smaller unit than mm
				end
			elseif o.numFiducials > 0
				XYZ = o.getFiducialsAsXYZ();
				doCenter = o.numFiducials > 1;
				if doCenter
					center = mean(XYZ,1);
					XYZ = bsxfun(@minus,XYZ,center);
				end
				dists = [];
				for i = 1:o.numFiducials
					for j = 1:o.numFiducials
						if i==j, continue; end;
						dists = [dists, c_norm(XYZ(i,:)-XYZ(j,:),2)];
					end
				end
				dist = median(dists);
				if dist < 0.05
					error('Unexpected unit');
				elseif dist < 0.2
					o.distUnit = 1; % m
				elseif dist < 2
					error('Unexpected unit');
				elseif dist < 20
					o.distUnit = 1e-2;
				elseif dist < 200
					o.distUnit = 1e-3;
				else
					error('Unexpected unit');
				end
			end
		end
		
		function moveElectrodesToMesh(o,varargin)
			p = inputParser();
			p.addRequired('mesh',@c_mesh_isValid);
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.parse(varargin{:});
			s = p.Results;
			
			prevDistUnit = o.distUnit;
			o.changeDistUnit(s.distUnit);
			
			elecPts = c_struct_mapToArray(o.electrodes,{'X','Y','Z'});
			meshPts = s.mesh.Vertices;
			
			meshScale = c_norm(diff(extrema(meshPts,[],1),1,2),2);
			
			for iE = 1:o.numElectrodes
				if all(isnan(elecPts(iE,:)))
					% if all nan, don't move electrode to mesh (e.g. an ECG electrode)
					continue;
				end
				[minDist,index] = min(c_norm(bsxfun(@minus,meshPts,elecPts(iE,:)),2,2));
				if minDist > meshScale*0.05
					warning('Closest point on mesh is more than %.3g away from electrode',minDist);
					pause(0.1);
				end
				elecPts(iE,:) = meshPts(index,:);
			end
			
			o.electrodes = c_array_mapToStruct(elecPts,{'X','Y','Z'},o.electrodes);
			
			o.changeDistUnit(prevDistUnit);
		end
		
		function reorderElectrodesByNumber(o,varargin)
			p = inputParser();
			p.addParameter('doPruneUnnumbered',true);
			p.addParameter('doPruneZeros',false);
			p.parse(varargin{:});
			s = p.Results;
			
			if ~isfield(o.electrodes,'number')
				warning('No electrode numbers available, not reordering.');
				return;
			end
			
			electrodesToPrune = false(1,o.numElectrodes);
			for iE = 1:o.numElectrodes
				if isempty(o.electrodes(iE).number) || isnan(o.electrodes(iE).number)
					if s.doPruneUnnumbered
						electrodesToPrune(iE) = true;
					else
						o.electrodes(iE).number = NaN; % force NaN instead of empty for cell2mat below
					end
				end
				if s.doPruneZeros && o.electrodes(iE).number==0
					electrodesToPrune(iE) = true;
					continue;
				end
			end
			if any(electrodesToPrune)
				o.deleteElectrodes('byIndex',electrodesToPrune);
			end
			
			electrodeNumbers = cell2mat({o.electrodes.number});
			
			[sortedNums, isort] = sort(electrodeNumbers);
			
			o.electrodes = o.electrodes(isort);
			
			for iE = 1:o.numElectrodes-1
				if sortedNums(iE)==sortedNums(iE+1)
					warning('Duplicate electrode numbers for ''%s'' and ''%s''',...
						o.electrodes(iE).label,...
						o.electrodes(iE+1).label);
				elseif sortedNums(iE) ~= sortedNums(iE+1)-1 && ~isnan(sortedNums(iE+1))
					warning('Electrode number skipped between ''%s'' (%d) and ''%s'' (%d)',...
						o.electrodes(iE).label,o.electrodes(iE).number,...
						o.electrodes(iE+1).label,o.electrodes(iE+1).number);
				end
			end
		end
		
		
		%% plot
		function handles = plot(o,varargin)
			p = inputParser();
			p.addParameter('doPlotFiducials',true,@islogical); % if available
			p.addParameter('doLabelFiducials',false,@islogical);
			p.addParameter('doPlotElectrodes',true,@islogical);
			p.addParameter('doLabelElectrodes',false,@islogical);
			p.addParameter('doNumberElectrodes',false,@islogical);
			p.addParameter('doPlotInterelectrodeDistancesLessThan',0,@isscalar);
			p.addParameter('plotInterelectrodeDistancesBetweenTypes',...
				{'','EEG',{'','EEG'},{'OptSrc','OptDet'},{'OptSrc','OptProxDet'}},@iscell);
			p.addParameter('IED_doVaryLineThickness',true,@islogical); % whether to vary line thickness propertional to interelectrode distances
			p.addParameter('IED_doVaryLineColor',true,@islogical); % whether to vary line color proportional to interelectrode distances
			p.addParameter('doPlotHeadshape',true,@islogical); % if available
			p.addParameter('axis',[],@ishandle);
			p.addParameter('view',[3],@(x) isempty(x) || isvector(x));
			p.addParameter('colorFiducials',[0 0.5 0],@isnumeric);
			p.addParameter('colorElectrodes','by type',@isnumeric);
			p.addParameter('colorShapePts',[1 1 1]*0.8,@isnumeric);
			p.addParameter('markerSize',0.005,@isscalar);
			p.addParameter('distUnit',o.distUnit,@isDistUnit);
			p.addParameter('mesh',[],@c_mesh_isValid);
			p.addParameter('transformation',[],@ismatrix);
			p.parse(varargin{:});
			s = p.Results;
			
			if isempty(s.axis)
				s.axis = gca;
			end
			
			if ~isempty(s.mesh)
				c_mesh_plot(s.mesh,...
					'axis',s.axis,...
					'view',s.view);
			end

			axis(s.axis,'equal');
			if ~isempty(s.view)
				view(s.view);
			end

			if ~isempty(s.transformation)
				s.data = c_digitizer_applyTransform(s.data,s.transformation);
			end

			sizeScalar = c_convertValuesFromUnitToUnit(1,o.distUnit,s.distUnit);
			scatterArgs = {...
				'ptSizes',s.markerSize/s.distUnit,...
				'axis',s.axis,...
			};
		
			handles = [];

			% plot fiducials
			if s.doPlotFiducials && ~c_isEmptyOrEmptyStruct(o.fiducials)
				pts = c_struct_mapToArray(o.fiducials,{'X','Y','Z'});
				ptLabels = {o.fiducials.label};
				h = c_plot_scatter3(pts*sizeScalar,...
					'ptColors',s.colorFiducials,...
					'ptLabels',ptLabels,...
					'doPlotLabels',s.doLabelFiducials,...
					scatterArgs{:});
				handles = cat(2,handles,h);
			end

			% plot electrodes
			if s.doPlotElectrodes && ~c_isEmptyOrEmptyStruct(o.electrodes)
				
				if strcmpi(s.colorElectrodes,'by type')
					% color each electrode type differently
					electrodeTypes = o.electrodeTypes;
					uniqueElectrodeTypes = unique(electrodeTypes);
					numElectrodeTypes = length(uniqueElectrodeTypes);
					if numElectrodeTypes <= 1
						s.colorElectrodes = [0 0 0.7];
					else
						s.colorElectrodes = c_getColors(numElectrodeTypes);

						% convert colors by type to color for each electrode
						typeIndices = nan(1,length(electrodeTypes));
						for iT = 1:length(uniqueElectrodeTypes)
							typeIndices(ismember(electrodeTypes,uniqueElectrodeTypes{iT})) = iT;
						end
						s.colorElectrodes = s.colorElectrodes(typeIndices,:);
					end
				end
				
				pts = c_struct_mapToArray(o.electrodes,{'X','Y','Z'});
				ptLabels = {o.electrodes.label};
				if s.doNumberElectrodes
					electrodeNumbers = [];
					for iE = 1:length(o.electrodes)
						if c_isFieldAndNonEmpty(o.electrodes(iE),'number')
							electrodeNumbers(iE) = o.electrodes(iE).number;
						else
							electrodeNumbers(iE) = iE;
						end
					end
					if s.doLabelElectrodes
						ptLabels = {};
						for iE = 1:length(o.electrodes)
							ptLabels{iE} = sprintf('%d-%s',electrodeNumbers(iE),o.electrodes(iE).label);
						end
					else
						ptLabels = arrayfun(@(x) sprintf('%d'),electrodeNumbers,'UniformOutput',false);
					end
				end
				h = c_plot_scatter3(pts*sizeScalar,...
					'ptColors',s.colorElectrodes,...
					'ptLabels',ptLabels,...
					'doPlotLabels',s.doLabelElectrodes || s.doNumberElectrodes,...
					scatterArgs{:});
				handles = cat(2,handles,h);
			end
			
			% plot interelectrode distances
			if s.doPlotInterelectrodeDistancesLessThan > 0 && ~c_isEmptyOrEmptyStruct(o.electrodes)
				[electrodeXYZ, electrodeTypes] = o.getElectrodesAsXYZ();
				electrodeXYZ = electrodeXYZ*sizeScalar;
				
				interElectrodeDists = nan(o.numElectrodes,o.numElectrodes);
				for iE = 1:o.numElectrodes
					iEOther = [1:iE-1,iE+1:o.numElectrodes];
					interElectrodeDists(iEOther,iE) = c_norm(bsxfun(@minus,electrodeXYZ(iEOther,:), electrodeXYZ(iE,:)),2,2);
				end
				
				for iE = 1:o.numElectrodes
					distIndicesToPlot = find(interElectrodeDists(:,iE) < s.doPlotInterelectrodeDistancesLessThan);
					linegrp = hggroup('parent',s.axis);
					for iE2 = distIndicesToPlot'
						coords = electrodeXYZ([iE, iE2],:);
						
						if ~isempty(s.plotInterelectrodeDistancesBetweenTypes)
							% check that types of two electrodes match criterion for plotting
							singleStrIndices = cellfun(@ischar,s.plotInterelectrodeDistancesBetweenTypes);
							meetsCriterion = false;
							type1 = electrodeTypes(iE);
							type2 = electrodeTypes(iE2);
							if strcmpi(type1,type2) && ismember(type1,s.plotInterelectrodeDistancesBetweenTypes(singleStrIndices))
								% single string in cell indicates should plot connections between electrodes of that same type
								% (e.g. 'EEG' -> connections between EEG and EEG)
								meetsCriterion = true;
							else
								% assume non-single str indices are pairs of types to plot connections between
								typePairs = s.plotInterelectrodeDistancesBetweenTypes(~singleStrIndices);
								for iTp = 1:length(typePairs)
									if strcmpi(type1,typePairs{iTp}{1}) && strcmpi(type2,typePairs{iTp}{2}) || ...
											strcmpi(type1,typePairs{iTp}{2}) && strcmpi(type2,typePairs{iTp}{1})
										meetsCriterion = true;
										break;
									end
								end
							end
							if ~meetsCriterion
								% criterion for plotting not met, skip plotting this pair
								continue;
							end
						end
						
						args = c_mat_sliceToCell(coords,2);
						lineWidth = 1.5;
						if s.IED_doVaryLineThickness
							lineWidth = 2*lineWidth *...
								(s.doPlotInterelectrodeDistancesLessThan - interElectrodeDists(iE2,iE))/...
								s.doPlotInterelectrodeDistancesLessThan;
						end
						if s.IED_doVaryLineColor
							lineColorIntensity = interElectrodeDists(iE2,iE);
						else
							lineColorIntensity = 0;
						end
						h = c_plot_lineUsingColormap(args{:},...
							lineColorIntensity,...
							'LineWidth',lineWidth,...
							'parent',linegrp);
						handles = cat(2,handles,h);
					end
				end
				
				
				
			end

			% plot head points
			if s.doPlotHeadshape && ~c_isEmptyOrEmptyStruct(o.shapePoints)
				pts = c_struct_mapToArray(o.shapePoints,{'X','Y','Z'});
				h = c_plot_scatter3(pts*sizeScalar,...
					'ptColors',s.colorShapePts,...
					scatterArgs{:});
				handles = cat(2,handles,h);
			end			
		end
		
		%% getters/setters
		function num = get.numElectrodes(o)
			if c_isEmptyOrEmptyStruct(o.electrodes)
				num = 0;
			else
				num = length(o.electrodes);
			end
		end
		
		function num = get.numFiducials(o)
			if c_isEmptyOrEmptyStruct(o.fiducials)
				num = 0;
			else
				num = length(o.fiducials);
			end
		end
		
		function num = get.numShapePoints(o)
			if c_isEmptyOrEmptyStruct(o.shapePoints)
				num = 0;
			else
				num = length(o.shapePoints);
			end
		end
		
		function labels = get.electrodeLabels(o)
			if o.numElectrodes == 0,
				labels = {};
			else
				labels = {o.electrodes.label};
			end
		end
		function set.electrodeLabels(o,labels)
			assert(length(labels)==o.numElectrodes);
			for iE = 1:o.numElectrodes
				o.electrodes(iE).label = labels{iE};
			end
		end
		
		function labels = get.fiducialLabels(o)
			if o.numFiducials == 0,
				labels = {};
			else
				labels = {o.fiducials.label};
			end
		end
		function set.fiducialLabels(o,labels)
			keyboard %TODO
		end
		
		function types = get.electrodeTypes(o)
			if o.numElectrodes == 0,
				types = {};
			else
				types = {o.electrodes.type};
			end
		end
		function set.electrodeTypes(o,types)
			assert(length(types)==o.numElectrodes);
			for iE = 1:o.numElectrodes
				o.electrodes(iE).type = types{iE};
			end
		end
	end
	
	%%
	methods(Access=protected)
		function updateTemplateElectrode(o)
			if o.numElectrodes == 0
				% nothing to update
				return;
			end
			newTemplateFields = fieldnames(o.electrodes);
			for iF = 1:length(newTemplateFields)
				if ~isfield(o.templateElectrode,newTemplateFields{iF})
					o.templateElectrode.(newTemplateFields{iF}) = '';
				end
			end
		end
		
		function splitElectrodeLabelsToTypeAndLabel(o)
			% assume type and name are stored together in electrode name field as "(Type)Name"
			for iE = 1:o.numElectrodes
				e = o.electrodes(iE);
				if isempty(e.label)
					continue;
				end
				if ~strcmp(e.label(1),'(')
					continue;
				end
				loc = find(e.label==')',1,'first');
				if isempty(loc)
					continue;
				end
				typeStr = e.label(2:loc-1);
				labelStr = e.label(loc+1:end);
				o.electrodes(iE).label = labelStr;
				o.electrodes(iE).type = typeStr;
			end
		end
	end
	
	%% Static methods
	methods(Static)
		
		function exportPredefinedMontageToFile(montageName,outputPath)
			
			if nargin < 1
				montageName = 'BrainProductsTMS64';
			end
			
			m = c_DigitizedMontage('initFromMontageName',montageName);
			
			if nargin < 2
				outputPath = fullfile('.',[montageName '.pos']);
			end
			
			m.saveToFile(outputPath);
			
			c_saySingle('Exported predefined montage to %s',outputPath);
		end
	end
	
end

%% helper fn.s 

function raw = scaleRawDistances(raw,scaleFactor)
	if c_isFieldAndNonEmpty(raw,'electrodes.electrodes')
		raw.electrodes.electrodes = scaleStructXYZVals(raw.electrodes.electrodes,scaleFactor);
	end
	if c_isFieldAndNonEmpty(raw,'electrodes.fiducials')
		raw.electrodes.fiducials = scaleStructXYZVals(raw.electrodes.fiducials,scaleFactor);
	end
	if c_isFieldAndNonEmpty(raw,'shape.points')
		raw.shape.points = scaleStructXYZVals(raw.shape.points,scaleFactor);
	end
	if c_isFieldAndNonEmpty(raw,'shape.fiducials')
		raw.shape.fiducials = scaleStructXYZVals(raw.shape.fiducials,scaleFactor);
	end
end


function structWithXYZ = scaleStructXYZVals(structWithXYZ, scaleFactor)
	xyz = c_struct_mapToArray(structWithXYZ,{'X','Y','Z'});
	xyz = xyz*scaleFactor;
	structWithXYZ = c_array_mapToStruct(xyz,{'X','Y','Z'},structWithXYZ);
end

function structWithXYZ = transformStructXYZVals(structWithXYZ,transform)
	xyz = c_struct_mapToArray(structWithXYZ,{'X','Y','Z'});
	xyz = c_pts_applyQuaternionTransformation(xyz,transform);
	structWithXYZ = c_array_mapToStruct(xyz,{'X','Y','Z'},structWithXYZ);
end
	
function name = mapFiducialNameToStandard(name)
	if iscell(name)
		for j=1:length(name)
			name{j} = mapFiducialNameToStandard(name{j});
		end
		return;
	end

	correspondingNames = {...
		{'Nasion','NA','X+'},...
		{'LPA','Y+','Left'},...
		{'RPA','Y-','Right'},...
	};
	for i=1:length(correspondingNames)
		if ismember(name,correspondingNames{i})
			name = correspondingNames{i}{1};
			return;
		end
	end
	% if here, name was not recognized
	% (in this case, don't modify name)
end

function isValid = isDistUnit(x)
	isValid = ischar(x) || isscalar(x);
end


function chanlocs = convertRawToChanlocs(raw)
	
	c_EEG_openEEGLabIfNeeded();

	%TODO: handle 'number' field in raw and 'urchan' field in chanlocs correctly
	
	for i=1:length(raw.electrodes.electrodes)
		newE = raw.electrodes.electrodes(i);
		newE.type = '';
		if isfield(newE,'label')
			newE.labels = newE.label;
			rmfield(newE,'label');
		end
		for j='XYZ'
			newE.(j) = newE.(j)*1e3; % convert from m to mm
		end
		newE.urchan = i; 
		chanlocs(i) = newE;
	end

	% use EEGLab to add other coordinate system values
	chanlocs = convertlocs(chanlocs,'cart2all');
	
end


function raw = convertChanlocsToRaw(chanlocs)
raw = struct();
raw.electrodes = struct();
raw.electrodes.electrodes = struct(...
	'label',{},...
	'X',{},....
	'Y',{},....
	'Z',{});

unitScaleFactor = 10; % correct factor to get correct units 

for iE = 1:length(chanlocs)
	newE = struct(...
		'label',chanlocs(iE).labels,...
		'X',chanlocs(iE).X/unitScaleFactor,...
		'Y',chanlocs(iE).Y/unitScaleFactor,...
		'Z',chanlocs(iE).Z/unitScaleFactor);
	raw.electrodes.electrodes(iE) = newE;
end

% try to estimate landmarks from channel names
xyz = c_struct_mapToArray(chanlocs,{'X','Y','Z'});
xyz = xyz / unitScaleFactor;

indices = ismember(lower({chanlocs.labels}),lower({'FT9','TP9'}));
if sum(indices)<2
	return;
end
LPAxyz = mean(xyz(indices,:),1);
indices = ismember(lower({chanlocs.labels}),lower({'FT10','TP10'}));
if sum(indices)<2
	return;
end
RPAxyz = mean(xyz(indices,:),1);
indices = ismember(lower({chanlocs.labels}),lower({'FPZ'}));
if sum(indices)<1
	return;
end
NASxyz = mean(xyz(indices,:),1);
indices = ismember(lower({chanlocs.labels}),lower({'FZ'}));
if sum(indices)<1
	return;
end
FZxyz = mean(xyz(indices,:),1);
NASxyz(3) = NASxyz(3) - (FZxyz(3) - NASxyz(3))/2;

raw.electrodes.fiducials = struct(...
	'label',{'LPA','RPA','NAS'},...
	'X',{LPAxyz(1), RPAxyz(1), NASxyz(1)},...
	'Y',{LPAxyz(2), RPAxyz(2), NASxyz(2)},...
	'Z',{LPAxyz(3), RPAxyz(3), NASxyz(3)});

end

%%



function testfn()

	dm = c_DigitizedMontage('initFromFile','./TemplateMontage.pos');
	
	keyboard

end