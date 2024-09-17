%%  Remove ballistocardiac artifacts from EEG-fMRI
% amri_eeg_cbc()
%
% Usage
%   OUTEEG =  amri_eeg_cbc(EEG,ECG,'key1','value1' ...)
%
% Outputs
%   OUTEEG =  EEG data after removing ballistocardiac artifacts
%             stored as an EEGLAB structure
%
% Inputs
%   EEG   =   EEG data stored as an EEGLAB structure
%
% Keywords
%   'method'        =    'AAS': Average Artifact Subtraction [Allen 1998]
%                        'AAR': Average Artifact Regression
%                       'wAAS': Weighted Average Artifact Subtraction [Goldman 2000]
%                       'wAAR': Weighted Average Artifact Regression 
%                        'MAS': Median Artifact Subtraction 
%                        'MAR': Median Artifact Regression [Sijbers 2000;Ellingson 2004]
%                        'PCA': Principle Component Analysis 
%                        'ICA': runica() from EEGLAB [Benar 2003;Srivastava 2005;Mantini 2007]
%                    'ICA-AAS':   |
%                    'ICA-AAR':   |  running the same correction on each
%                   'ICA-wAAS':   |  component, instead of each channel
%                   'ICA-wAAR':   |  
%                    'ICA-MAS':   |
%                    'ICA-MAR':   |
%                    'ICA-PCA':   |
%                     {default: 'ICA-PCA'}
%   'rmarkername'   =   name of the R marker
%                       {default: 'R'}
% 
% Advanced Options
%   'wfactor'       =   weighting factor for wAAS 
%                       {default: 0.9} [Goldman 2000]
%
% See also:
%  amri_eeg_rpeak,
%  amri_sig_filtfft,
%  amri_sig_findpeaks,
%  runica,
%  amri_eeg_gac
%  mutualinfo
%  entropy
%
% Version:
%   0.24
%
% Examples:
%   N/A

%% DISCLAIMER AND CONDITIONS FOR USE:
%     This software is distributed under the terms of the GNU General Public
%     License v3, dated 2007/06/29 (see http://www.gnu.org/licenses/gpl.html).
%     Use of this software is at the user's OWN RISK. Functionality is not
%     guaranteed by creator nor modifier(s), if any. This software may be freely
%     copied and distributed. The original header MUST stay part of the file and
%     modifications MUST be reported in the 'MODIFICATION HISTORY'-section,
%     including the modification date and the name of the modifier.
%
% CREATED:
%     Oct. 21, 2009
%     Zhongming Liu, PhD
%     Advanced MRI, NINDS, NIH

%% MODIFICATION HISTORY
%
% 0.00 - 10/21/2009 - ZMLIU - R-peak detection using K-TEO [Niazy 2005; Kim 2004]
% 0.01 - 10/27/2009 - ZMLIU - Implement Average Artifact Subtraction (AAS) [Allen, 1998]
% 0.02 - 10/28/2009 - ZMLIU - Little modifications available [Ellingson 2004]
% 0.03 - 10/29/2009 - ZMLIU - Optimal Basis Set regression [Niazy 2005]
% 0.04 - 11/04/2009 - ZMLIU - Fix two bugs
% 0.05 - 11/04/2009 - ZMLIU - Estimate iri using autocorrelation 
%                           - Add 'display' and 'message' keywords to
%                             control graphic and text outputs
%                           - Add more comments
% 0.06 - 11/06/2009 - ZMLIU - Improve false positive r peak detection
%                           - Use 10~40 Hz for bandpass filter before k-TEO
%                           - Remove phase-shift from k-TEO to ECG
% 0.07 - 11/13/2009 - ZMLIU - Method loop outside channel loop
% 0.08 - 11/13/2009 - ZMLIU - Weighted Average Artifact Subtraction (wAAS) [Goldman 2000]
% 0.09 - 11/14/2009 - ZMLIU - BCG artifact epochs start before, instead of 
%                             exactly at the R peaks
% 0.10 - 11/14/2009 - ZMLIU - ICA using runica() from EEGLAB
% 0.11 - 11/16/2009 - ZMLIU - ICA with highpass filtering [Nakamura 2006]
% 0.12 - 11/17/2009 - ZMLIU - Allow output the removed artifact signals
%                           - Disable text message from runica() by default
%                           - detrend(...,'constant')
% 0.13 - 01/10/2010 - ZMLIU - Move R-peak detection to eeg_findr()
%                           - reformat the entire program
% 0.14 - 01/14/2010 - ZMLIU - Use median R-R interval as epoch length
%                           - ICA-based algorithm
% 0.15 - 01/16/2010 - ZMLIU - sub-function cbc()
%                           - refine auto selection of artifact pc
% 0.16 - 03/21/2010 - ZMLIU - shorten maxlag for autocorr computation
%                           - add optional output of performance evaluation
%                           - use mutual-information based feature selection in ICA
%                           - use ttest and mutual-information criteria for PCA
%                           - clear up program and comments
%                           - fourier shuffled mutual-information
%                           - normalize mi by entropy
% 0.17 - 03/24/2010 - ZMLIU - change discretization factor from 10 to 5 to
%                             reduce the chance of outflow the range of 'int8'
%                           - correct a "divided by zero error'
% 0.18 - 04/12/2010 - ZMLIU - rename to amri_eeg_cbc.m
% 0.19 - 04/17/2010 - ZMLIU - write convert_int8() to remove "out of range" warnings
% 0.20 - 04/23/2010 - ZMLIU - for 'ica-*' methods, compute mutual
%                             information between each IC and ECG after removing 'time-locked' 
%                             cba sigals. 
% 0.21 - 06/18/2010 - ZMLIU - use amri_sig_filtfft instead of filtfft
%                           - use amri_sig_findpeaks instead of amri_sig_findpeaks
% 0.22 - 07/07/2010 - ZMLIU - use amri_stat_iqr instead of iqr
%                           - use amri_stat_ttest instead of ttest
%                           - use varargin instead of pairs of p#,v#
% 0.23 - 02/10/2011 - ZMLIU - refine ICA component selection
%                    	    - use amri_misc_int8 instead of convert_int8
%                           - comment out mutual info computation with shuffled data
% 0.24 - 11/11/2011 - ZMLIU - clean up some comments before release
%        16/11/2011 - JAdZ  - v0.24 included in amri_eegfmri_toolbox v0.1

%%
function outeeg = amri_eeg_cbc(eeg,ecg,varargin)

if nargin<1
    eval('help amri_eeg_cbc');
    return
end

if nargin<2
    error('amri_eeg_cbc(): need at least two inputs');
end

%% ************************************************************************
% Defaults
% *************************************************************************

cbc_method = {'ICA-PCA'};

% pulse event

pulse_event.marker      =       'R';        % marker name
pulse_event.count       =       0;          % total number of pulse events
pulse_event.index       =       [];         % event index to eeg.event
pulse_event.latency     =       [];         % event latency [time point]
pulse_event.delay       =       0.21;       % time delay from r peak to maximal bcg [sec] 
pulse_event.length      =       0;          % duration of pulse event [time point]
pulse_event.interval    =       [];         % R-R interval [time point]
pulse_event.rate        =       [];         % pulse rate [pulse per minute]
pulse_event.lengthdef   =       'median';   % 'median' | 'max' | 'mean'

% moving window

moving_window.size      =       21;         % size (in number of pulse events)
moving_window.start     =       [];         % index to starting event of each window
moving_window.end       =       [];         % index to ending event of each window
moving_window.index     =       [];         % indices to all events within each window
moving_window.minsize   =       11;         % min size (in number of pulse events)

wfactor                 =       0.9;        % weighting factor used in wAAS [Goldman 2000]

pca.selection           =       'auto';     % 'auto' | 'fixed'
pca.ttest.alpha         =       0.05;       % pvalue for ttest
pca.fixedidx            =       1:3;        % fixed artifactual PC indices

ica.method              =       'infomax';  % 'info
ica.selection           =       'auto';     % 'auto' 
ica.thres.alpha         =        0.05;

checkfig.position       =       NaN;        % figure position
flag_verbose            =       0;          % 1|0, whether to print out

%% ************************************************************************
% Collect keyword-value pairs
% *************************************************************************
if (nargin>2 && rem(nargin,2)==1)
    printf('amri_eeg_cbc(): Even number of input arguments???')
    return
end

for i = 1:2:size(varargin,2) % for each Keyword
    Keyword = varargin{i};
    Value = varargin{i+1};
    if ~ischar(Keyword) 
        printf('amri_eeg_cbc(): keywords must be strings')
        return;
    end
    if strcmpi(Keyword,'method')
        if ischar(Value)
            cbc_method{1}=Value;
        elseif iscell(Value)
            cbc_method = Value;
        else
            printf('amri_eeg_cbc(): invalid value for ''method''');
        end
    elseif strcmpi(Keyword,'wfactor')
        if isnumeric(Value)
            wfactor=Value(1);
        else
            printf('amri_eeg_cbc(): ''wfactor'' has to be numeric');
        end
    else
        printf('amri_eeg_cbc(): unknown Keyword');
    end
end

%% ************************************************************************
% Find R markers
% *************************************************************************

% search eeg.event for pulse_event
is_pulse_event = zeros(length(eeg.event),1);
for ievent=1:length(eeg.event)
    if strcmpi(eeg.event(ievent).type,pulse_event.marker)
        is_pulse_event(ievent)=1;
    end
end
pulse_event.index = find(is_pulse_event);       % index to eeg.event
pulse_event.count = length(pulse_event.index);  % number of pulse events
clear is_pulse_event;

% obtain pulse_event.latency
pulse_event.latency = zeros(size(pulse_event.index));
for ibeat = 1 : length(pulse_event.index)
    ievent = pulse_event.index(ibeat);
    pulse_event.latency(ibeat) = eeg.event(ievent).latency;
end

% initialize pulse_event.delay for each channel
pulse_event.delay=ones(size(eeg.data,1),1)*round(pulse_event.delay*eeg.srate);

% at least 2 pulse events are needed
if isempty(pulse_event.latency)
    printf('amri_eeg_cbc(): no pulse event found');
elseif length(pulse_event.latency)==1
    printf('amri_eeg_cbc(): only 1 pulse event is valid');
else
    % pulse_event.interval or R-R interval
    pulse_event.interval = zeros(pulse_event.count,1);
    pulse_event.interval(1:end-1) = diff(pulse_event.latency);
    pulse_event.interval(end) = pulse_event.interval(end-1);
    pulse_event.rate = 60*eeg.srate./pulse_event.interval;

    % exclude outliers of R-R interval, and then choose the median R-R
    % interval as the pulse length. this is to ensure the pulse_length is
    % sufficient to cover the longest duration of bcg artifact
    tt = sort(pulse_event.interval,'ascend'); 
    tt_3q=tt(round(length(tt)*3/4));
    tt_1q=tt(round(length(tt)*1/4));
    outlier=pulse_event.interval>tt_3q+4*amri_stat_iqr(pulse_event.interval)|...
            pulse_event.interval<tt_1q-4*amri_stat_iqr(pulse_event.interval);
    if strcmpi(pulse_event.lengthdef,'median')
        pulse_event.length=median(pulse_event.interval(~outlier));
    elseif strcmpi(pulse_event.lengthdef,'max') || ...
           strcmpi(pulse_event.lengthdef,'maximum')
        pulse_event.length=max(pulse_event.interval(~outlier));
    elseif strcmpi(pulse_event.lengthdef,'min') || ...
           strcmpi(pulse_event.lengthdef,'minimum')
        pulse_event.length=min(pulse_event.interval(~outlier));
    elseif strcmpi(pulse_event.lengthdef,'mean') || ...
           strcmpi(pulse_event.lengthdef,'average') || ...
           strcmpi(pulse_event.lengthdef,'avg')
        pulse_event.length=mean(pulse_event.interval(~outlier));
    end
end



%% ************************************************************************
%                       moving window
% *************************************************************************

% determine moving_window.size
if isnan(moving_window.size)
    % if the size of moving window is not specified 
    % assume a global moving window that covers all pulse events
    moving_window.size = pulse_event.count;
else
    % assure moving_window.size > min_window_size but < pulse_event.count
    min_window_size = moving_window.minsize;
    if moving_window.size < min_window_size
        moving_window.size = min_window_size;
    end
    if moving_window.size > pulse_event.count
        moving_window.size = pulse_event.count;
    end
    % make moving_window.size an odd number
    if mod(moving_window.size,2)==0 && ...
       moving_window.size<pulse_event.count
        moving_window.size=moving_window.size+1;
    end
end

% set indices to the starting and ending events of each moving window
moving_window.start = ones(pulse_event.count,1) * NaN;
moving_window.end   = ones(pulse_event.count,1) * NaN;
moving_window.index = ones(pulse_event.count,moving_window.size) * NaN;

if moving_window.size == pulse_event.count
    % global window
    moving_window.start = ones(pulse_event.count,1);
    moving_window.end   = ones(pulse_event.count,1) * pulse_event.count;
    moving_window.index = repmat(1:moving_window.size, pulse_event.count, 1);
else
    % note: moving_window.size is an odd number
    half_window_size    = fix(moving_window.size/2);
    for ipulse = 1 : pulse_event.count
        moving_window.start(ipulse) = max([ipulse-half_window_size 1]);
        moving_window.end  (ipulse) = min([ipulse+half_window_size pulse_event.count]);
        if moving_window.end(ipulse)-moving_window.start(ipulse)+1<moving_window.size
            % decrease start index or increase end index
            if     moving_window.start(ipulse)==1
                % cannot decrease start index
                moving_window.end(ipulse) = min([pulse_event.count ...
                                                moving_window.end(ipulse)+...
                                                half_window_size-(ipulse-1)]);
            elseif moving_window.end  (ipulse)==pulse_event.count
                % cannot increase end index
                moving_window.start(ipulse) = max([1 ...
                                                  moving_window.start(ipulse)-...
                                                  (half_window_size-pulse_event.count+ipulse)]);
            end
        end
        moving_window.index(ipulse,:) = moving_window.start(ipulse) : moving_window.end(ipulse);
    end
end


%% ************************************************************************
% remove base line for each channel
% *************************************************************************
for ichan=1:size(eeg.data,1)
     eeg.data(ichan,:)=eeg.data(ichan,:)-mean(eeg.data(ichan,:));
end 

%% ************************************************************************
% Remove pulse artifacts using one or a sequence of multiple algorithms
% *************************************************************************
% eeg.olddata = eeg.data;

for imethod = 1 : length(cbc_method)
    
    if flag_verbose>0
        fprintf(['amri_eeg_cbc(): run ' cbc_method{imethod} ' ']);
    end
    
    % if the "current" method is a channel-wise algorithm
    % e.g. AAS,MAR,wAAS,OBS,PCA
    if strcmpi(cbc_method{imethod},'AAS') || ...
       strcmpi(cbc_method{imethod},'AAR') || ...
       strcmpi(cbc_method{imethod},'wAAS') || ...
       strcmpi(cbc_method{imethod},'wAAR') || ...
       strcmpi(cbc_method{imethod},'MAS') || ...
       strcmpi(cbc_method{imethod},'MAR') || ...
       strcmpi(cbc_method{imethod},'OBS') || ...
       strcmpi(cbc_method{imethod},'PCA')
        for ichan = 1 : size(eeg.data,1)
            if flag_verbose>0
                fprintf([int2str(ichan) ' ']);
            end
            % store all settings into a cfg struct and pass it to cbc()
            cfg.pulse_event   = pulse_event;
            cfg.moving_window = moving_window;
            cfg.wfactor       = wfactor;
            cfg.pca           = pca;
            cfg.ica           = ica;
            cfg.cbcmethod     = cbc_method{imethod};
            % run cbc() for channel-wise data
            eeg.data(ichan,:) = cbc(eeg.data(ichan,:),cfg);
        end
        if flag_verbose>0
            fprintf('\n');
        end
    
    
    elseif strncmpi(cbc_method{imethod},'ICA',3)
        
        % run ica
        if strcmpi(ica.method,'infomax')
            [eeg.icaweights,eeg.icasphere,compvars,...
                bias,signs,lrates,eeg.icaact]=...
                runica(eeg.data,'extended',1,'verbose','off');
            eeg.icawinv = inv(eeg.icaweights*eeg.icasphere);
        end

        % the total number of ICs
        ica.count = size(eeg.icawinv,1);
        ica.artifactcomp = false(ica.count,1);
        
        % discretize ecg.data and ecg.icaact as c and X respectively
        discretization_factor = 5;
        c = convert_int8(round((ecg.data-mean(ecg.data))*discretization_factor/std(ecg.data)));
        X = int8(zeros(size(eeg.icaact)));
        for icomp=1:ica.count
            X(icomp,:)=convert_int8(round((eeg.icaact(icomp,:)-mean(eeg.icaact(icomp,:)))*discretization_factor/std(eeg.icaact(icomp,:))));
        end
        
        % compute normalized mutual information between each IC and ECG
        ica.ecgmi = zeros(ica.count,1);
        for icomp=1:ica.count
            ica.ecgmi(icomp)=mutualinfo(c',X(icomp,:)')/entropy(X(icomp,:)');
        end
        
%        % mutual information between the shuffled ic time course and ecg
%        numshuffle=500;
%        ica.mishuffled=zeros(ica.count,numshuffle);
%        for icomp=1:ica.count
%            for ishuffle=1:numshuffle
%                y=amri_sig_shuffle(eeg.icaact(icomp,:),'fourier');
%                x=convert_int8(round((y-mean(y))*discretization_factor/std(y)));
%                ica.mishuffled(icomp,ishuffle)=mutualinfo(c',x')/entropy(x');
%            end
%        end

        % determine the number of artifactual components
	    beatpertrial = 20;
        candidatethres = 0.5;
        successthres = 0.8;
        if pulse_event.length>0
            timeseparator = 1:beatpertrial*round(pulse_event.length/2):size(X,2);
        else
            timeseparator = 1:beatpertrial*eeg.srate:size(X,2);
        end
        % then run a leave-one-out cross valiation test
        mi_train = zeros(ica.count,length(timeseparator)-2);
        mi_test  = zeros(ica.count,length(timeseparator)-2);    
        for isegment=1:length(timeseparator)-2
            testtimerange  = timeseparator(isegment):timeseparator(isegment+2);
            traintimerange = [1:testtimerange(1) testtimerange(end):size(X,2)];
            for icomp=1:ica.count
                y_train = c(traintimerange);
                x_train = X(icomp,traintimerange);
                y_test  = c(testtimerange);
                x_test  = X(icomp,testtimerange);
                mi_train(icomp,isegment) = mutualinfo(y_train(:),x_train(:))/entropy(x_train(:));
                mi_test(icomp,isegment)  = mutualinfo(y_test(:),x_test(:))/entropy(x_test(:));
            end
        end
    
        accuracyrate = zeros(ica.count,1);
        for numfeatures=1:ica.count
            verror = false(size(mi_test,2),1);
            for itest=1:size(mi_test,2)
                [a,ai]=sort(mi_train(:,itest),1,'descend'); %#ok<*ASGLU>
                [b,bi]=sort(mi_test(:,itest),1,'descend');
                trainfeatures=ai(1:numfeatures);
                testfeatures=bi(1:numfeatures);
                verror(itest) = any(~ismember(testfeatures,trainfeatures));
            end
            accuracyrate(numfeatures)=1-sum(verror)/length(verror);
            if accuracyrate(numfeatures)<candidatethres
                break;
            end
        end
        if any(accuracyrate>successthres)
            xxx = max(accuracyrate);
            iii = find(accuracyrate>=xxx-0.1); %#ok<MXFND>
            optnumfeatures = max(iii);
            [a,ai]=sort(ica.ecgmi,1,'descend');
            ica.artifactcomp(ai(1:optnumfeatures))=1;
        end
        
        % save the following information in the output
        eeg.icarej = ica.artifactcomp;
        eeg.icamiecg = ica.ecgmi;
       % eeg.icamishuffle = ica.mishuffled;
        
        % reject the artifactual ICs
        % or for the rest of ICs, run epoch-based correction (such as PCA)
        if strcmpi(cbc_method{imethod},'ICA')
            if ~isempty(ica.artifactcomp)
                % exclude artifactual ICs and transform back to signal space
                eeg.data = eeg.icawinv(:,~ica.artifactcomp)*...
                           eeg.icaact(~ica.artifactcomp,:);
            end
            
        elseif strcmpi(cbc_method{imethod},'ICA-AAS') || ...
               strcmpi(cbc_method{imethod},'ICA-AAR') || ...
               strcmpi(cbc_method{imethod},'ICA-wAAS') || ...
               strcmpi(cbc_method{imethod},'ICA-wAAR') || ...
               strcmpi(cbc_method{imethod},'ICA-MAS') || ...
               strcmpi(cbc_method{imethod},'ICA-MAR') || ...
               strcmpi(cbc_method{imethod},'ICA-PCA') || ...
               strcmpi(cbc_method{imethod},'ICA-OBS')
            for icomp = 1 : ica.count
                if flag_verbose>0
                    fprintf([int2str(icomp) ' ']);
                end
                cfg.pulse_event   = pulse_event;
                cfg.moving_window = moving_window;
                cfg.wfactor       = wfactor;
                cfg.pca           = pca;
                cfg.ica           = ica;
                cfg.cbcmethod     = cbc_method{imethod}(5:end);
                % run cbc() for component-wise data
                eeg.icaact(icomp,:)=cbc(eeg.icaact(icomp,:),cfg);
            end
            eeg.data = eeg.icawinv(:,~ica.artifactcomp)*...
                       eeg.icaact(~ica.artifactcomp,:);
            eeg.icarej = ica.artifactcomp;

            % discretize ecg.data and ecg.icaact as c and X respectively
            discretization_factor = 5;
            c = convert_int8(round((ecg.data-mean(ecg.data))*discretization_factor/std(ecg.data)));
            X = int8(zeros(size(eeg.icaact)));
            for icomp=1:ica.count
                X(icomp,:)=convert_int8(round((eeg.icaact(icomp,:)-mean(eeg.icaact(icomp,:)))*discretization_factor/std(eeg.icaact(icomp,:))));
            end
            % compute normalized mutual information between each IC and ECG
            eeg.icamiecgafter = zeros(ica.count,1);
            for icomp=1:ica.count
                eeg.icamiecgafter(icomp)=mutualinfo(c',X(icomp,:)')/entropy(X(icomp,:)');
            end
        end
        if flag_verbose>0
            fprintf('\n');
        end
    else
        
    end
end

outeeg = eeg;
return
% return;

%% ************************************************************************
% run time-domain ballistocardigraphic artifact correction for the time
% series of individual channel or component
% *************************************************************************

function ts_cbc = cbc(ts_orig,cfg)

if isfield(cfg,'cbcmethod'),cbcmethod = cfg.cbcmethod;end
if isfield(cfg,'pulse_event'),pulse_event=cfg.pulse_event;end
if isfield(cfg,'moving_window'),moving_window=cfg.moving_window;end
if isfield(cfg,'wfactor'),wfactor=cfg.wfactor;end
if isfield(cfg,'pca'),pca=cfg.pca;end
if isfield(cfg,'ica'),ica=cfg.ica;end %#ok<NASGU>
clear cfg;

ts_cbc = ts_orig;
% -------------------------------------------------------------
% segment data with respect to pulse markers with segment length
% equal to the inter-R-interval 
% NOTE: it is important to subtract the mean of each epoch

epochs.length = round(pulse_event.length);

% first (jj==1) epoching the time series wrt pulse markers with the
% epoch onset of zero. compute the signal power of every epoch.
% compute the median signal power across epoch. find out the
% time point of the maximum signal power. set pulse_event.delay
% to this time point. 
% 
% second (jj==2), epoching the time series again by using epoch
% onset according to pulse_event.delay. on average, the new epoch has
% maximum power at the epoch center. 

jj=1;   
while jj<=2 
    if jj==1
        % initial setting for epoching
        epochs.onset  = 0;
        epochs.data   = ones(pulse_event.count,epochs.length)*nan;            
        epochs.tstart = ones(pulse_event.count,1)*nan;
        epochs.tend   = ones(pulse_event.count,1)*nan;
    else
        % updated setting for epoching
        epochs.onset  = round(pulse_event.delay-epochs.length/2);
        epochs.data   = ones(pulse_event.count,epochs.length)*nan;
        epochs.tstart = ones(pulse_event.count,1)*nan;
        epochs.tend   = ones(pulse_event.count,1)*nan;
    end

    for ipulse = 1 : pulse_event.count
        epochs.tstart(ipulse) = pulse_event.latency(ipulse)+epochs.onset;
        epochs.tend(ipulse)   = epochs.tstart(ipulse)+epochs.length-1;
        if epochs.tstart(ipulse)<1
            % incomplete epoch at the beginning of the data
            epochs.tstart(ipulse)=1;
            newlength=epochs.tend(ipulse)-epochs.tstart(ipulse)+1;
            epochs.data(ipulse,end-newlength+1:end)=...
                ts_orig(epochs.tstart(ipulse):epochs.tend(ipulse));
        elseif epochs.tend(ipulse)>length(ts_orig)
            % incomplete epoch at the end of the data
            epochs.tend(ipulse)=length(ts_orig);
            newlength=epochs.tend(ipulse)-epochs.tstart(ipulse)+1;
            epochs.data(ipulse,1:newlength)=...
                ts_orig(epochs.tstart(ipulse):epochs.tend(ipulse));
        elseif epochs.tstart(ipulse)>=1 && epochs.tend(ipulse)<=length(ts_orig)
            % complete epoch in the middle
            epochs.data(ipulse,:)=...
                ts_orig(epochs.tstart(ipulse):epochs.tend(ipulse));
        end
        % subtract mean
        notnan = ~isnan(epochs.data(ipulse,:));
        if any(notnan)
            epochs.data(ipulse,notnan)=epochs.data(ipulse,notnan)-...
                mean(epochs.data(ipulse,notnan));
        end
    end

    if jj==1
        % estimate the optimal "delay" time from initial
        % epoching results
        tpow = epochs.data.^2;
        tpow = median(tpow(2:end-1,:));
        [itemp,imax]=max(tpow);
        pulse_event.delay=imax-1;
        clear tpow;
    end
    jj=jj+1;
end

% imagesc(epochs.data);axis xy;
% caxis([-1 1]*iqr(reshape(epochs.data,size(epochs.data,1)*size(epochs.data,2),1))*3);
epochs.count  = size(epochs.data,1);
% compute the median (across epochs)                % note that
epochs.median = median(epochs.data(2:end-1,:));     % the first and last
% compute the mean                                  % epochs are excluded
epochs.mean   = mean(epochs.data(2:end-1,:));       % since they may be incomplete

% % compute correlation with the median               % 
% epochs.cc=zeros(epochs.count,1);
% for iepoch=1:epochs.count
%     epochs.cc(iepoch)=...
%         corr(epochs.data(iepoch,~isnan(epochs.data(iepoch,:)))',...
%              epochs.median(~isnan(epochs.data(iepoch,:)))');
% end

% compute standard deviation of signal within each epoch
epochs.std=zeros(epochs.count,1);
epochs.std=std(epochs.data,0,2);
% find "global" outliers with large std
tt=sort(epochs.std,'ascend'); tt_3q=tt(round(length(tt)*3/4));
epochs.outlier = find(isnan(epochs.std)|...
                     epochs.std>tt_3q+4*amri_stat_iqr(epochs.std));
                 
% -------------------------------------------------------------

%             subplot(5,6,ichan);
%             imagesc(epochs.data);
%             axis xy;
%             iqr_temp = iqr(reshape(epochs.data,size(epochs.data,1)*size(epochs.data,2),1));
%             caxis([-1 1]*3*iqr_temp);           

% -------------------------------------------------------------

if strcmpi(cbcmethod,'AAS') || ...    
   strcmpi(cbcmethod,'AAR') || ...
   strcmpi(cbcmethod,'MAS') || ...
   strcmpi(cbcmethod,'MAR') || ...
   strcmpi(cbcmethod,'wAAS') || ...
   strcmpi(cbcmethod,'wAAR')

    % local pulse artifact template (lpat)
    lpat = ones(size(epochs.data))*nan;
    for iepoch=1:epochs.count
        % retrieve neighboring epochs covered by pre-defined
        % moving window
        iepoch_win_index=moving_window.index(iepoch,:);
        % exclude itself
        iepoch_win_index(iepoch_win_index==iepoch)=[];
        % exclude any incomplete epoch
        iepoch_win_index(isnan(epochs.data(iepoch_win_index,1)))=[];
        iepoch_win_index(isnan(epochs.data(iepoch_win_index,end)))=[];

        % do nothing if the current window is empty
        if isempty(iepoch_win_index),continue;end
        % compute local pulse artifact template
        if strcmpi(cbcmethod,'AAS') || ...
           strcmpi(cbcmethod,'AAR') 
           % exclude "global" outliers                  
           iepoch_win_index(ismember(iepoch_win_index,epochs.outlier))=[];
           % compute the sum of power for each epoch
           sumofpow = sum(epochs.data(iepoch_win_index,:).^2,2);
           % exclude the epochs whose sum of power exceed 3
           % times that of the minimum sum of power within the
           % current window
           iepoch_win_index(sumofpow>3*min(sumofpow))=[];
           lpat(iepoch,:)=mean(epochs.data(iepoch_win_index,:));
        elseif strcmpi(cbcmethod,'MAS') || ...
               strcmpi(cbcmethod,'MAR')
           % since median is relatively robust against outliers
           % no need to detect outliers
           lpat(iepoch,:)=median(epochs.data(iepoch_win_index,:));
        elseif strcmpi(cbcmethod,'wAAS') ||...
               strcmpi(cbcmethod,'wAAR')
           idxallepoch=(1:epochs.count)';
           wght=wfactor.^abs(idxallepoch-iepoch);
           wght(epochs.outlier)=0;
           wght(isnan(epochs.data(:,1)))=0;
           wght(isnan(epochs.data(:,end)))=0;
           lpat(iepoch,:)=wght(wght~=0)'...
               *epochs.data(wght~=0,:)...
               /sum(wght);
        end
    end

    % subtract or regress out template from each epoch
    ts_new = ones(size(ts_orig))*nan;
    for iepoch=1:epochs.count
        % the time range of the current epoch in the data
        globaltimerange=epochs.tstart(iepoch):epochs.tend(iepoch);
        % the current epoch length. it may differ from the
        % epochs.length since a starting or ending epoch may be
        % incomplete
        currentlength=epochs.tend(iepoch)-epochs.tstart(iepoch)+1;
        % the time range within an epoch
        if iepoch==1
            localtimerange=epochs.length-currentlength+1:epochs.length;
        elseif iepoch==epochs.count
            localtimerange=1:currentlength;
        else
            localtimerange=1:currentlength;
        end

        % subtract or regress out
        if strcmpi(cbcmethod,'AAS') || ...
           strcmpi(cbcmethod,'MAS') || ...
           strcmpi(cbcmethod,'wAAS')
            ts_new(globaltimerange)=...
                ts_orig(globaltimerange)-...
                lpat(iepoch,localtimerange);
        elseif strcmpi(cbcmethod,'AAR') || ...
               strcmpi(cbcmethod,'MAR') || ...
               strcmpi(cbcmethod,'wAAR')
            kk = epochs.data(iepoch,localtimerange)'...
                \lpat(iepoch,localtimerange)';
            ts_new(globaltimerange)=...
                ts_orig(globaltimerange)-...
                kk*lpat(iepoch,localtimerange);                        
        end
    end
    ts_cbc(~isnan(ts_new))=ts_new(~isnan(ts_new));
    % ---------------------------------------------------------

elseif strcmpi(cbcmethod,'PCA') || ...
       strcmpi(cbcmethod,'OBS')

 
   % retrieve the epoched signal
   Z = epochs.data;
   
   % exclude the first and last epochs, as well as the outliers
   Z([1;epochs.outlier;epochs.count],:) = [];
   
   % run compact svd
   [U,S,V]=svd(Z','econ');
   
   % ttest V(:,i) agains mean(V(:,i))=0
   isart_ttest=false(min(size(Z)),1);
   for i=1:min(size(Z))
       isart_ttest(i)=(amri_stat_ttest(V(:,i),0,pca.ttest.alpha/size(V,2))==1);
   end

%    % compute correlation between V(:,i) and pulserate or rrinterval
%    corr_pr   = zeros(min(size(Z)),1);
%    corr_rri  = zeros(min(size(Z)),1);
%    pcorr_pr  = zeros(min(size(Z)),1);
%    pcorr_rri = zeros(min(size(Z)),1);
%    for i=1:size(V,2)
%        [corr_pr(i),  pcorr_pr(i)]=corr(pulserate, V(:,i));
%        [corr_rri(i),pcorr_rri(i)]=corr(rrinterval,V(:,i));
%    end
%    isart_corrpr=pcorr_pr<pca.corrpr.alpha/size(V,2);
% %    isart_corrpr=(corr_pr>=0.2);

   
   if strcmpi(pca.selection,'fixed')
       basisfunc=U(:,pca.fixedidx)';
       regrcoeff=S(pca.fixedidx,pca.fixedidx)*V(:,pca.fixedidx)';
   elseif strcmpi(pca.selection,'auto')
       isartcomp=isart_ttest;
       basisfunc=U(:,isartcomp)';
       regrcoeff=S(isartcomp,isartcomp)*V(:,isartcomp)';
   else
       
   end
   clear U S V Z;
   
   if ~isempty(basisfunc)
       % regress out basisfunc from the data
       ttcoeff=ones(size(regrcoeff));
       ts_new = ones(size(ts_orig))*nan;
       for iepoch=1:epochs.count
            % the time range of the current epoch in the data
            globaltimerange=epochs.tstart(iepoch):epochs.tend(iepoch);
            % the current epoch length. it may differ from the
            % epochs.length since a starting or ending epoch may be
            % incomplete
            currentlength=epochs.tend(iepoch)-epochs.tstart(iepoch)+1;
            % the time range within an epoch
            if iepoch==1
                localtimerange=epochs.length-currentlength+1:epochs.length;
            elseif iepoch==epochs.count
                localtimerange=1:currentlength;
            else
                localtimerange=1:currentlength;
            end
            kk = pinv(basisfunc(:,localtimerange)')*...
                epochs.data(iepoch,localtimerange)';
            ttcoeff(:,iepoch)=kk;
            kk=kk';
            ts_new(globaltimerange)=...
                ts_orig(globaltimerange)-...
                kk*basisfunc(:,localtimerange);                    
       end
       ts_cbc(~isnan(ts_new))=ts_new(~isnan(ts_new));
   end
end

return

function out = convert_int8(in)

in(in>intmax('int8'))=intmax('int8');
in(in<-intmax('int8'))=-intmax('int8');
out=int8(in);
   
