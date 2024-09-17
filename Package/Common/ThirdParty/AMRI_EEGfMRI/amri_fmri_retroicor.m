%%
% amri_fmri_retroicor 
%    retrospective correction of cardiac and respiratory motion effects.
%
% Usage
%    [odata,regr,info] = amri_fmri_retroicor(idata,card,resp,tr,nsli,nvol);
%
% Inputs
%    idata: 4-D input data matrix [nx,ny,nz,nt]
%     card: 1-D ECG trace 
%     resp: 1-D Respiratory trace
%       tr: in seconds
%     nsli: number of slices
%     nvol: number of volumes
%
% Outputs
%    odata: 4-D output data matrix [nx,ny,nz,nt]
%     regr: a structure whose fields contain physiological regressors
%           .retroicor: include both cardiac and resp. regressors
%           .cardiac(1:nvol,1,1:nsli) = cos(phi_c)
%           .cardiac(1:nvol,2,1:nsli) = sin(phi_c)
%           .cardiac(1:nvol,3,1:nsli) = cos(2*phi_c)
%           .cardiac(1:nvol,4,1:nsli) = sin(2*phi_c)
%           .respiration(1:nvol,1,1:nsli) = cos(phi_r)
%           .respiration(1:nvol,2,1:nsli) = sin(phi_r)
%           .respiration(1:nvol,3,1:nsli) = cos(2*phi_r)
%           .respiration(1:nvol,4,1:nsli) = sin(2*phi_r)
%     info: additional information as below
%           .ecgpeaktime: indices to R peaks in input ECG 
%           .exppeaktime: indices to expiration peaks in input resp.
%           .inspeaktime: indices to inspiration peaks in input resp.
%           .cardphase: [nvol,nsli] cardiac phase for each slice at each TR
%           .respphase: [nvol,nsli] respiratory phase for each slice at each TR
%           .rvt: respiration volume per time unit sampled at respfs
%           .hr: heart rate sampled at cardfs 
%
% Keywords
%       physfs: sampling frequency for both cardiac and respiration 
%       respfs: sampling frequency (Hz) of respiration trace {default: 50}
%       cardfs: sampling frequency (Hz) of cardiac trace {default: 50}
%     cardtype: 'wave'|'trig' data type of cardiac signal {default: 'wave'}
%  sliceorient: direction of slice acquisition 1|2|3 or -1|-2|-3
%               a negative value means the reverse direction {default: 3}
%  interleaved: 1|0 or true|false {default:0}
%   sliceorder: 1-vector specifying a customized slice order 
%
% Example
%    card = load('ecg.1D');
%    resp = load('resp.1D');
%    % only extract retroicor regressors from card and resp
%    % here tr=1.5; 15 slices; 400 volumes
%    [~,regr,info]=amri_fmri_retroicor([],card,resp,1.5,30,400);
%    % the above line assumes slices are acquired along the 3rd dimension
%    % it is equivalent to use
%    [~,regr,info]=amri_fmri_retroicor([],card,resp,1.5,30,400,'sliceorient',3);
%    % if reversed direction (the last slice is acquired first)
%    [~,regr,info]=amri_fmri_retroicor([],card,resp,1.5,30,400,'sliceorient',-3);
%    % if interleaved
%    [~,regr,info]=amri_fmri_retroicor([],card,resp,1.5,30,400,'sliceorient',-3,'interleaved',1);
%
% Reference
%    [1] Glover, Li, Ress. Image-based method for retrospective correction 
%        of physiological motion effects in fMRI. MRM 44:162-167, 2000.
%    [2] Birn et al. Separating respiratory-variation-related fluctuations
%        from neuronal-activity-related fluctuations in fMRI. NeuroImage
%        31(4):1536-1548, 2006.
%    [3] Shmueli et al. Low-frequency fluctuations in the cardiac rate as a
%        source of variance in the resting-state fMRI BOLD signal.
%        NeuroImage 38(2):306-320, 2007.
%
% See also
%    amri_fmri_nvr, amri_sig_findpeaks, amri_sig_filtfft, amri_sig_xcorr
%
% Version
%    0.10

%% HISTORY
% 0.00 - 06/18/2010 - ZMLIU - create the original file
%                           - implement retroicor
% 0.01 - 06/19/2010 - ZMLIU - extract RVT and store RVT in info
% 0.02 - 06/20/2010 - ZMLIU - extract cardiac rate regressor
%                           - more options to specify slice timing
% 0.03 - 07/20/2010 - ZMLIU - add 'cardtype' keyword to specify the card
%                             file only including triggers
%                           - use varargin
% 0.04 - 08/13/2010 - ZMLIU - fix a (major) bug
% 0.05 - 08/19/2010 - ZMLIU - fix a (minor) bug wrt ecg peak detection
% 0.06 - 11/17/2010 - ZMLIU - improve ecg r peak detection
% 0.07 - 12/01/2010 - ZMLIU - minor change in ecg r peak detection
% 0.08 - 12/14/2010 - ZMLIU - refine resp peak detection
% 0.09 - 12/19/2011 - ZMLIU - fix a bug with 'size(varargin,2)'
% 0.10 - 02/14/2012 - ZMLIU - release this code

function [odata,regr,info] = amri_fmri_retroicor(idata,card,resp,tr,nsli,nvol,varargin)

if nargin<1
    eval('help amri_fmri_retroicor');
    return
end

if nargin<6
    error('amri_fmri_retroicor(): requires at least 6 inputs');
end
if nargin>6 && rem(nargin,2)==1
    error('amri_fmri_retoricor(): cannot have an odd number of inputs');
end

% defaults

flag.verbose = 0;

ecg.type  = 'wave'; % 'wave' means ecg trace, 'trig' means the r peaks
ecg.lcut  = 0.2;    % low cutoff frequency
ecg.hcut  = 20;     % high cutoff frequency
ecg.srate = 50;     % sampling frequency
ecg.minhr = 40;     % min heart rate (per minute)
ecg.maxhr = 120;    % max heart rate (per minute)

rsp.srate = 50;     % sampling frequency
rsp.minbr = 6;      % min breathing rate (per minute)
rsp.maxbr = 30;     % max breathing rate (per minute)

slice.orient = 3;   % slice acquisition direction
slice.interl = 0;   % interleaved? 1 yes; 0 no. 

% use double-precision for card, resp, tr, nsli, nvol
card = double(card);
resp = double(resp);
tr   = double(tr);
nsli = double(nsli);
nvol = double(nvol);

% Keywords

for i=1:2:size(varargin,2)
    Keyword = varargin{i};
    Value   = varargin{i+1};
    if ~ischar(Keyword) 
        fprintf('amri_fmri_retroicor(): WARNING keywords must be string\n')
        continue;
    end
    if strcmpi(Keyword,'sliceorient')
        switch Value,
            case 1,    slice.orient=1;
            case 2,    slice.orient=2;
            case 3,    slice.orient=3;
            case 'x',  slice.orient=1;
            case 'y',  slice.orient=2;
            case 'z',  slice.orient=3;
            case -1,   slice.orient=-1;
            case -2,   slice.orient=-2;
            case -3,   slice.orient=-3;
            case '-x', slice.orient=-1;
            case '-y', slice.orient=-2;
            case '-z', slice.orient=-3;
        end
    elseif strcmpi(Keyword,'interleaved') || strcmpi(Keyword,'alternative')
        if isnumeric(Value)
            if Value(1)~=0
                slice.interl=1;
            else
                slice.interl=0;
            end
        elseif islogical(Value)
            if Value(1)
                slice.interl=1;
            else
                slice.interl=0;
            end
        elseif ischar(Value)
            if strcmpi(Value,'y') || strcmpi(Value,'yes')
                slice.interl=1;
            else
                slice.interl=0;
            end
        end
    elseif strcmpi(Keyword,'sliceorder')
        slice.order = Value(:);
    elseif strcmpi(Keyword,'physfs') && isnumeric(Value)
        ecg.srate = Value(1);
        rsp.srate = Value(1);
    elseif strcmpi(Keyword,'cardfs') && isnumeric(Value)
        ecg.srate = Value(1);
    elseif strcmpi(Keyword,'respfs') && isnumeric(Value)
        rsp.srate = Value(1);
    elseif strcmpi(Keyword,'cardtype')
        switch lower(Value)
            case {'wave','waveform','timeseries','data'}
                ecg.type='wave';
            case {'trig','trigger'}
                ecg.type='trig';
        end
    else
        fprintf(['amri_fmri_retroicor(): WARNING unknown keyword ' Keyword ' \n']);
    end
end

%% SLICE TIMING IN SECONDS 

% if idata is given and sliceorient is specified 
% check whether nsli is consistent with the corresponding dimension length
if ~isempty(idata)
    if size(idata,abs(slice.orient))~=nsli
        error('amri_fmri_retroicor(): sliceorient is incorrect. since "nsli" is not consistent with "idata"');
    end
end

if isfield(slice,'order')
    % if sliceorder is specified, then use it
    if any(slice.order<1)
        error('amri_fmri_retroicor(): sliceorder must be positive');
    end
    if any(slice.order>nsli)
        error('amri_fmri_retroicor(): sliceorder cannot be larger than nsli');
    end
else
    % otherwise, if sliceorder is not specified, then derive it from
    % slice.orient and slice.interl.
    if slice.interl==0
        % sequential acquisition
        if sign(slice.orient)==1
            slice.order=1:1:nsli;   
        else
            slice.order=nsli:-1:1;  
        end
    else
        % interleaved acquisition
        if sign(slice.orient)==1
            oddslices = 1:2:nsli;
            evenslices= 2:2:nsli;
        else
            oddslices =nsli:-2:1;
            evenslices=nsli-1:-2:1;
        end
        slice.order(oddslices)=1:length(oddslices);
        slice.order(evenslices)=length(oddslices)+1:nsli;
        slice.order=slice.order(:);
    end
end

vol_tr = double(tr);
sli_tr = double(vol_tr)/double(nsli);

slice_timing = zeros(nvol,nsli);
for islice=1:nsli
    iacq = slice.order(islice);
    ast = (iacq-0.5)*sli_tr:vol_tr:vol_tr*nvol;
    ast = ast(:);
    slice_timing(:,islice)=ast;
end


%% CARDIAC REGRESSOR
if ~isempty(card)
    
    ecg.data = card(:);
    if strcmpi(ecg.type,'trig')
        r_peaks=zeros(length(card),1);
        r_peaks(card>0)=1;
    else
    	r_peaks = findecgpeak(ecg,flag);
    end
    r_peaks_time = find(r_peaks==1);
%    plot(ecg.data);hold on;plot(r_peaks_time,ecg.data(r_peaks_time),'or');
%    return
    cardiac_phase = ones(size(slice_timing))*nan;
    for isli=1:size(slice_timing,2)
        for ivol=1:size(slice_timing,1)
            t = slice_timing(ivol,isli)*ecg.srate;
            tmp1=r_peaks_time(r_peaks_time<t);
            tmp2=r_peaks_time(r_peaks_time>t);
            if isempty(tmp1) && isempty(tmp2)
                error('amri_fmri_retroicor(): error in cardiac phase calculation');
            elseif isempty(tmp1) && ~isempty(tmp2)
                t2 = min(tmp2);
                t1 = t2-(min(tmp2(tmp2>t2))-t2);
            elseif ~isempty(tmp1) && isempty(tmp2)
                t1 = max(tmp1);
                t2 = t1+(t1-max(tmp1(tmp1<t1)));
            else
                t1 = max(tmp1);
                t2 = min(tmp2);
            end
            cardiac_phase(ivol,isli)=2*pi*(t-t1)/(t2-t1);
        end
    end

    if flag.verbose>0
        fprintf('amri_fmri_retroicor(): compute cardiac phase\n');
    end

    regr.cardiac = zeros(nvol,4,nsli);

    regr.cardiac(:,1,:)=reshape(cos(cardiac_phase),nvol,1,nsli);
    regr.cardiac(:,2,:)=reshape(sin(cardiac_phase),nvol,1,nsli);
    regr.cardiac(:,3,:)=reshape(cos(cardiac_phase*2),nvol,1,nsli);
    regr.cardiac(:,4,:)=reshape(sin(cardiac_phase*2),nvol,1,nsli);
    
    info.ecgpeaktime=r_peaks_time;
    info.cardphase=cardiac_phase;
end

%% RESPIRATORY REGRESSORS
if ~isempty(resp)
    
    rsp.data = resp(:);
    
    [r_peaks, n_peaks] = findresppeak(rsp,flag);

    r_peaks_time = find(r_peaks>0);
    n_peaks_time = find(n_peaks<0);
    
    % normalize rsp.data
    Rmin = min(rsp.data);
    Rmax = max(rsp.data);
    rsp.data = (rsp.data-Rmin)/(Rmax-Rmin);
    H=hist(rsp.data,100);
    H=H(:);

    % compute polarity
    polarity = zeros(length(rsp.data),1);

    all_peaks = n_peaks+r_peaks;
    all_peaks_time = find(all_peaks~=0);
    for t=1:length(rsp.data)
        if ~any(all_peaks_time<=t) && ~any(all_peaks_time>=t)
            fprintf('amri_fmri_retroicor(): unexpected error\n');
        elseif ~any(all_peaks_time<=t) && any(all_peaks_time>t)
            if all_peaks(min(all_peaks_time(all_peaks_time>t)))==-1
                polarity(t)=-1;
            elseif all_peaks(min(all_peaks_time(all_peaks_time>t)))==1
                polarity(t)=1;
            else
                fprintf('amri_fmri_retroicor(): unexpected error\n');
            end
        elseif any(all_peaks_time<=t) && ~any(all_peaks_time>t)
            if all_peaks(max(all_peaks_time(all_peaks_time<=t)))==-1
                polarity(t)=1;
            elseif all_peaks(max(all_peaks_time(all_peaks_time<=t)))==1
                polarity(t)=-1;
            else
                fprintf('amri_fmri_retroicor(): unexpected error\n');
            end
        elseif any(all_peaks_time<=t) && any(all_peaks_time>t)
            apeak = all_peaks(max(all_peaks_time(all_peaks_time<=t)));
            a_amp = rsp.data(max(all_peaks_time(all_peaks_time<=t)));
            bpeak = all_peaks(min(all_peaks_time(all_peaks_time>t)));
            b_amp = rsp.data(min(all_peaks_time(all_peaks_time>t)));
            if apeak==-1 && bpeak==1
                polarity(t)=1;
            elseif apeak==1 && bpeak==-1
                polarity(t)=-1;
            else
                fprintf('amri_fmri_retroicor(): unexpected error\n');
            end
        else
            fprintf('amri_fmri_retroicor(): unexpected error\n');
        end    
    end
    if flag.verbose
        fprintf('amri_fmri_retroicor(): compute respiratory phase polarity\n');
    end
    % compute respiratory phase
    respiratory_phase = ones(size(slice_timing))*nan;
    for isli=1:size(slice_timing,2)
        for ivol=1:size(slice_timing,1)
            t = round(slice_timing(ivol,isli)*rsp.srate);
            if t>length(rsp.data)
                t=length(rsp.data);
            end
            Rt = rsp.data(t);
            nbin = round(Rt*100);
            phi=pi*sum(H(1:nbin))/sum(H);
            respiratory_phase(ivol,isli)=phi*polarity(t);
        end
    end
    
    regr.respiration = ones(nvol,4,nsli);
    regr.respiration(:,1,:)=reshape(cos(respiratory_phase),nvol,1,nsli);
    regr.respiration(:,2,:)=reshape(sin(respiratory_phase),nvol,1,nsli);
    regr.respiration(:,3,:)=reshape(cos(respiratory_phase*2),nvol,1,nsli);
    regr.respiration(:,4,:)=reshape(sin(respiratory_phase*2),nvol,1,nsli);
    
    info.exppeaktime = r_peaks_time;
    info.inspeaktime = n_peaks_time;
    info.respphase = respiratory_phase;
end

%% COMBINE CARDIAC AND RESPIRATORY REGRESSORS and REGRESS THEM OUT
if flag.verbose>0
    fprintf('amri_fmri_retroicor(): combine respiratory and cardiac regressors\n');
end
if isfield(regr,'cardiac') || isfield(regr,'respiration')
    if isfield(regr,'cardiac') && isfield(regr,'respiration')
        regr.retroicor=zeros(nvol,size(regr.cardiac,2)+size(regr.respiration,2),nsli);
        regr.retroicor(:,1:size(regr.cardiac,2),:)=regr.cardiac;
        regr.retroicor(:,size(regr.cardiac,2)+1:end,:)=regr.respiration;
    elseif ~isfield(regr,'cardiac') && isfield(regr,'respiration')
        regr.retroicor=zeros(nvol,size(regr.respiration,2),nsli);
        regr.retroicor=regr.respiration;
    elseif isfield(regr,'cardiac') && ~isfield(regr,'respiration')
        regr.retroicor=zeros(nvol,size(regr.cardiac,2),nsli);
        regr.retroicor=regr.cardiac;
    end
end

if flag.verbose>0
  fprintf('amri_fmri_retroicor(): slice ');
end
if ~isempty(idata) && isfield(regr,'retroicor')
    for islice = 1 : size(idata,abs(slice.orient))
        switch abs(slice.orient),
            case 1
                idata(islice,:,:,:) = amri_fmri_nvr(idata(islice,:,:,:),regr.retroicor(:,:,islice));
            case 2 
                idata(:,islice,:,:) = amri_fmri_nvr(idata(:,islice,:,:),regr.retroicor(:,:,islice));
            case 3 
                idata(:,:,islice,:) = amri_fmri_nvr(idata(:,:,islice,:),regr.retroicor(:,:,islice));
        end
        if flag.verbose>0
            fprintf([num2str(islice) ' ']);
        end
    end
    if flag.verbose>0
        fprintf('\n');
    end
end
    
%% RVT
if ~isempty(resp)
    
    rsp.data = resp(:);
    
    % extract RVT
    rvt = zeros(length(info.exppeaktime),1);
    for i=1:length(info.exppeaktime)
        pptime = info.exppeaktime(i);
        if i==1
            nptime = min(info.inspeaktime(info.inspeaktime>pptime));
        elseif i==length(info.exppeaktime)
            nptime = max(info.inspeaktime(info.inspeaktime<pptime));
        else
            nptime = max(info.inspeaktime(info.inspeaktime<pptime));
        end
        rvt(i) = rsp.data(pptime)-rsp.data(nptime);
    end
    ppduration = diff(info.exppeaktime);
    ppduration = [ppduration(1);ppduration];
    rvt = rvt./ppduration;
    % interpolate
    rvt = interp1(info.exppeaktime,rvt,1:length(rsp.data),'spline');
    rvt = rvt(:);
    % extrapolation using the "nearest" 
    rvt(1:info.exppeaktime(1))=rvt(info.exppeaktime(1));
    rvt(info.exppeaktime(end):end)=rvt(info.exppeaktime(end));
    % output rvt
    info.rvt =rvt;
end

%% Heart Rate
if ~isempty(card)
    ecg.data = card(:);
    tt = diff(info.ecgpeaktime);
    tt = [tt(1);tt(:)];
    for i=1:length(tt)
        ti_from = max([1 i-2]);
        ti_to   = min([length(tt) i+2]);
        tt(i)   = mean(tt(ti_from:ti_to));
    end
    hr = 1./tt;
    % interpolate
    hr = interp1(info.ecgpeaktime,hr,1:length(ecg.data),'spline');
    hr(1:info.ecgpeaktime(1))=hr(info.ecgpeaktime(1));
    hr(info.ecgpeaktime(end):end)=hr(info.ecgpeaktime(end));
    % output
    info.hr=hr(:);
end

%% OUTPUT CORRECTED DATA
odata = idata;

function r_peaks = findecgpeak(ecg,flag)

    if flag.verbose>0
        fprintf('amri_fmri_retroicor(): detect ECG peaks\n');
    end

    % *************************************************************************
    % bandpass filtering
    % *************************************************************************
    ecg.data = amri_sig_filtfft(ecg.data,ecg.srate,ecg.lcut,ecg.hcut);
    if flag.verbose>0
        fprintf(['amri_fmri_retroicor(): filter ecg (' num2str(ecg.lcut) '~' num2str(ecg.hcut) ' Hz)\n']);
    end

    % *************************************************************************
    % find the average r-r interval through autocorrelation with 3s maxlag
    % *************************************************************************
    acorr = amri_sig_xcorr(ecg.data,ecg.data,'maxlag',ecg.srate*3);
    peaks = amri_sig_findpeaks(acorr);                               % find peaks

    timerange = -fix(length(acorr)/2):fix(length(acorr)/2); % in time points
    timerange = timerange/ecg.srate;                        % in sec

    % timerangepr is the range defined by maximal and minimal pulse rate (per minute)
    timerangepr =timerange(timerange>60/ecg.maxhr&timerange<60/ecg.minhr);
    % acorrrangepr is the autocorrelation within timerangepr
    acorrrangepr=acorr(timerange>60/ecg.maxhr&timerange<60/ecg.minhr);
    % find the maximal autocorrelation within timerangepr
    [acorrmax,imax]=max(acorrrangepr);
    % the time of the maximal autocorrelation is the iri (in sec)
    irisec=timerangepr(imax);                            % iri in sec
    iri=round(irisec*ecg.srate);                         % iri in time points

    % % update ecg.minhr and ecg.maxhr to be more precise
    % % the updated pulse range should cover 3*FWHM of the autocorr function
    % old_min_pr = ecg.minhr;
    % old_max_pr = ecg.maxhr;
    % [temp,itemp]=min(abs(acorrrangepr(imax+1:end)-acorrmax/2));
    % itemp=round(itemp*3+imax);
    % itemp=min([length(timerangepr) itemp]);
    % ecg.minhr=60/timerangepr(itemp);
    % 
    % [temp,itemp]=min(abs(acorrrangepr(1:imax-1)-acorrmax/2));
    % itemp=round(imax-(imax-itemp)*3);
    % itemp=max([itemp 1]);
    % ecg.maxhr=60/timerangepr(itemp);

    if flag.verbose>0
        fprintf(['amri_fmri_retroicor(): the average r-r interval is ' num2str(iri/ecg.srate) 's \n']);
    end

    % *************************************************************************

    Y=ecg.data;

    % *************************************************************************
    % compute the median and standard deviation of R-peak height
    % *************************************************************************
    r_heights = zeros(1,round(length(Y)/2/iri));
    for i = 1 : length(r_heights)
        r_heights(i) = max(Y((i-1)*2*iri+1:min([i*2*iri,length(Y)])));
    end
    median_r_height = median(r_heights);
    std_r_height = std(r_heights);
    iqr_r_height = amri_stat_iqr(r_heights);
    if flag.verbose>0
        fprintf(['amri_fmri_retroicor(): the median r peak height is ' num2str(median_r_height') '\n']);
    end

    % *************************************************************************
    % get a template for a single heart beat
    % *************************************************************************
    % first, try to find a segment, with a length of 5*iri, that contains 
    % no outlier typically resulting from huge residual of gradient artifact
    for i=1:fix(length(Y)/(5*iri))
        timerange = iri*5*(i-1)+iri+1: min([iri*5*i+iri length(Y)]);
        % an outlier differs from median_r_height by 3*std_r_height
        outliers = find(Y(timerange)>median_r_height+3*std_r_height);
        % if no outlier is found in the current time range
        % jump out of search loop, because this is the time range 
        % we want to find a template of cardiac cycle. 
        if isempty(outliers)
            break;
        else
            if i==fix(length(Y)/(5*iri)) 
                % if outlier exists even after reaching the last segment
                % exclude the outlier time points in the last segment
                fprintf('amri_fmri_retroicor(): no template is found\n');
                timerange(outliers)=[];
            end
        end
    end

    if flag.verbose>0
        fprintf('amri_fmri_retroicor(): find a ECG template\n');
    end

    % after identifying a 5*iri segment as the base period for template
    % search. (Note that this base period is most typically located close 
    % to the beginning of the data)
    % find the maximal value in this time range. The time point of the
    % maximum is the r peak location of the template. Then we define a
    % template segment centered at the r peak with a length of iri (if
    % possible).
    [~,temp_i]=max(Y(timerange));

    template_center = timerange(temp_i);
    template_before = max([1 template_center-round(iri/2)+1]);
    template_after  = min([length(Y) template_center+round(iri/2)-1]);
    template_length = template_after-template_before+1;
    template_peak_local = template_center-template_before+1;
    template = Y(template_before:template_after);

    % ************************************************************************
    % identify r peaks for all heart beats by combining peak detection 
    % and cross correlation
    % initial r-peak detection, BEGIN


    % peak detection based on amplitude
    amppeaktimes = amri_sig_findpeaks(Y,'pos');
    amppeaks=zeros(size(Y));
    amppeaks(amppeaktimes>0)=Y(amppeaktimes>0); 
%    plot(Y);hold on;plot(find(amppeaktimes>0),Y(find(amppeaktimes>0)),'or');
    % exclude outliers
    amppeaktimes(amppeaks-median_r_height>10*iqr_r_height)=0;
%    plot(Y);hold on;plot(find(amppeaktimes>0),Y(find(amppeaktimes>0)),'or');
    % using fisher linear distrimant to separate R peaks from other peaks
    tmp=Y(amppeaktimes>0);
    [N,X]=hist(tmp,100);
    fc=zeros(length(X),1);
    for i=1:100
        thres =X(i);
        class1 = tmp(tmp<thres);
        class2 = tmp(tmp>=thres);
        btw=(length(class1)*(mean(class1)-mean(tmp))^2+length(class2)*(mean(class2)-mean(tmp))^2)/length(tmp);
        wti=(length(class1)*var(class1)+length(class2)*var(class2))/length(tmp);
        fc(i)=btw/wti;
    end
    threshold = X(round(mean(find(fc==max(fc)))));
    % figure;plot(X,N);disp(threshold);pause;
    amppeaktimes(Y<threshold)=0;
    if flag.verbose>0
        fprintf(['amri_fmri_retroicor(): find ' num2str(sum(amppeaktimes)) ' ecg amplitude peaks\n']);
    end
%    plot(Y);hold on;plot(find(amppeaktimes>0),Y(find(amppeaktimes>0)),'or');
    % peak detection based on cross correlation 
    % (this is relatively a time consuming process)
    if flag.verbose>0
        fprintf('amri_fmri_retroicor(): compute the correlation to the ecg template\n');
    end
    ccorr = ones(size(Y))*nan;
    for i=1:length(Y)
        asegment_center = i;
        asegment_before = asegment_center-(template_center-template_before);
        asegment_after  = asegment_center+(template_after-template_center);
        if asegment_before<1 % data beginning
            asegment = Y(1:asegment_after);
            tt = template(1-asegment_before+1:end);
            cc=corrcoef(asegment(:),tt(:));
            ccorr(i)=cc(1,2);
        elseif asegment_after>length(Y)
            asegment = Y(asegment_before:end);
            tt = template(1:length(asegment));
            cc=corrcoef(asegment(:),tt(:));
            ccorr(i)=cc(1,2);
            continue;
        else
            asegment = Y(asegment_before:asegment_after);
            tt=template;
            cc=corrcoef(asegment(:),tt(:));
            ccorr(i)=cc(1,2);
        end
    end
    ccpeaktimes = amri_sig_findpeaks(ccorr,'pos');
    ccpeaktimes = ccpeaktimes & ccorr>0.5;
    if flag.verbose>0
        fprintf(['amri_fmri_retroicor(): find ' num2str(sum(ccpeaktimes)) ' ecg correlation peaks\n']);
    end

    % identify a time point as an r peak, if satisfying both the amplitude
    % and correaltion criteria
    r_peaks = ccpeaktimes; 
    indices = find(r_peaks>0);
    peakuncertainty=round(0.04*ecg.srate);
    for i=1:length(indices)
        ti=indices(i);
        if amppeaktimes(ti)==0
            r_peaks(ti)=0;
            ti_from = max([ti-peakuncertainty 1]);
            ti_to   = min([ti+peakuncertainty length(Y)]);
            ti_range = ti_from:ti_to;
            if any(amppeaktimes(ti_range)>0)
                [~,junk_i] = max(Y(ti_range));
                ti=ti_range(junk_i);
                r_peaks(ti)=1;
            end
        end
    end
%    plot(Y);hold on;plot(find(r_peaks>0),Y(find(r_peaks>0)),'or');pause;
    % The first and last peak might not be accurate because of likely
    % incomplete cycle
    r_peaks_time=find(r_peaks==1);
    if length(r_peaks_time)>3
        if 2*r_peaks_time(2)-r_peaks_time(3)<0
            r_peaks(r_peaks_time(1))=0;
        end
        if 2*r_peaks_time(end-1)-r_peaks_time(end-2)>length(ecg.data)
            r_peaks(r_peaks_time(end))=0;
        end
    end
    if flag.verbose>0
        old_r_peaks_num = sum(r_peaks);
        fprintf(['amri_fmri_retroicor(): find ' num2str(sum(r_peaks)) ' initial R peaks\n']);
    end

    % ---------------------------------------------------------------------
    % correct false positive or negative 
    % false correction, BEGIN

    r_peaks_time = find(r_peaks==1);
    r_peaks_interval = diff(r_peaks_time);

    % remove false positive until no false positive is found or search for
    % false positives has been done 5 times
    num_lp = 1;
    max_loop = 5;
    while num_lp<=max_loop
        for i=2:length(r_peaks_time)
            rrint = r_peaks_time(i)-r_peaks_time(i-1);
            if rrint<round(60/ecg.maxhr*ecg.srate);
                % if a false positive is detected
                % then remove both the previous and current r peaks
                % set a new r peak at the time point of maximal correlation
                r_peaks(r_peaks_time(i-1))=0;
                r_peaks(r_peaks_time(i))=0;
                timerange=r_peaks_time(i-1):r_peaks_time(i);
                [ymax,imax]=max(ccorr(timerange));
                r_peaks(timerange(imax))=1;
            end
        end
        r_peaks_time = find(r_peaks>=1);
        if ~sum(diff(r_peaks_time)<round(60/ecg.maxhr*ecg.srate))
            break;
        end
        num_lp=num_lp+1;
    end

    r_peaks_time = find(r_peaks==1);
    r_peaks_interval = diff(r_peaks_time);

    if flag.verbose
        fprintf(['amri_fmri_retroicor(): remove ' num2str(old_r_peaks_num-sum(r_peaks)) ' false positives\n']);
        old_r_peaks_num = sum(r_peaks);
    end

    % an estimate of the standard deviation of r-r interval
    iri_std = round(std(r_peaks_interval(r_peaks_interval<60/ecg.minhr*ecg.srate)));
    % new_r_peaks will contain the positions of the new r peaks that need to be inserted
    new_r_peaks = [];

    for i=2:length(r_peaks_time);
        rrint = r_peaks_time(i)-r_peaks_time(i-1);
        if rrint>round(60/ecg.minhr*ecg.srate);
            % if one or more false negatives are detected
            % first estimate how many r peaks were missed for the time
            % range between the previous and current r peaks
            fnn = round(rrint/iri)-1;
            if fnn>=1                
                add_r_peaks = zeros(1,fnn);
                rough_iri = round(rrint/(fnn+1));
                if rough_iri>round(60/ecg.minhr*ecg.srate) || ...
                   rough_iri<round(60/ecg.maxhr*ecg.srate)
                    rought_iri=iri;
                end
                for jj=1:fnn
                    % compute a tentative "new" r peak position
                    t_r_peak = r_peaks_time(i-1)+rough_iri*jj;
                    % since the tentative r peak should be very close to be
                    % accurate, the real r peak is determined as the
                    % time point of the maximum of the "weighted" ccorr within 
                    % a narrow range around the tentative r peak position. 
                    anarrowrange=t_r_peak-3*iri_std:t_r_peak+3*iri_std;
                    anarrowrange=anarrowrange(:);
                    weights = 1/sqrt(2*pi)/iri_std*exp(-(anarrowrange-t_r_peak).^2/(2*iri_std^2));
                   [ymax,imax]=max(weights.*ccorr(anarrowrange));
                    add_r_peaks(jj)=anarrowrange(imax);
                end
                new_r_peaks = [new_r_peaks add_r_peaks];
            end
        end
    end

    r_peaks(new_r_peaks)=1;

    if flag.verbose>0
        fprintf(['amri_fmri_retroicor(): add ' num2str(sum(r_peaks)-old_r_peaks_num) ' false negatives\n']);
        fprintf(['amri_fmri_retroicor(): confirm ' num2str(sum(r_peaks)) ' R peaks\n']);
    end

    % false correction, END
    % ---------------------------------------------------------------------
%    plot(Y);hold on;plot(find(r_peaks>0),Y(find(r_peaks>0)),'or');pause;

function [r_peaks,n_peaks]=findresppeak(rsp,flag)

% find inter-breath-interval ibi
acc = amri_sig_xcorr(rsp.data,rsp.data,'maxlag',round(60/rsp.minbr*rsp.srate));
acc=acc(floor(length(acc)/2)+2:end);
timerange=round(60/rsp.maxbr*rsp.srate):round(60/rsp.minbr*rsp.srate);
[~,i]=max(acc(timerange));
ibi=timerange(i);

% **************************************************************

Y=rsp.data;
Y=Y-min(Y);
Y=amri_sig_filtfft(Y,rsp.srate,0,1);

% compute the respiratory peak amplitude
r_heights = zeros(1,round(length(Y)/2/ibi));
for i = 1 : length(r_heights)
    r_heights(i) = max(Y((i-1)*2*ibi+1:min([i*2*ibi,length(Y)])));
end
median_r_height = median(r_heights);
std_r_height = std(r_heights);
iqr_r_height = amri_stat_iqr(r_heights);

% first, try to find a segment, with a length of 5*ibi, that contains 
% no outlier typically resulting from huge residual of gradient artifact
for i=1:fix(length(Y)/(5*ibi))
    timerange = ibi*5*(i-1)+ibi+1: min([ibi*5*i+ibi length(Y)]);
    % an outlier differs from median_r_height by 3*std_r_height
    outliers = find(Y(timerange)>median_r_height+3*std_r_height);
    % if no outlier is found in the current time range
    % jump out of search loop, because this is the time range 
    % we want to find a template of cardiac cycle. 
    if isempty(outliers)
        break;
    else
        if i==fix(length(Y)/(5*ibi)) 
            % if outlier exists even after reaching the last segment
            % exclude the outlier time points in the last segment
            fprintf('amri_fmri_retroicor(): no template is found\n');
            timerange(outliers)=[];
        end
    end
end

if flag.verbose>0
    fprintf('amri_fmri_retroicor(): find a respiratory template\n');
end

% after identifying a 5*ibi segment as the base period for template
% search. (Note that this base period is most typically located close 
% to the beginning of the data)
% find the maximal value in this time range. The time point of the
% maximum is the r peak location of the template. Then we define a
% template segment centered at the r peak with a length of ibi (if
% possible).
[~,temp_i]=max(Y(timerange));

template_center = timerange(temp_i);
template_before = max([1 template_center-round(ibi/2)+1]);
template_after  = min([length(Y) template_center+round(ibi/2)-1]);
template_length = template_after-template_before+1;
template_peak_local = template_center-template_before+1;
template = Y(template_before:template_after);

% peak detection based on amplitude
amppeaktimes = amri_sig_findpeaks(Y,'pos');
amppeaks=zeros(size(Y));
amppeaks(amppeaktimes>0)=Y(amppeaktimes>0); 
if flag.verbose>0
    fprintf(['amri_fmri_retroicor(): find ' num2str(sum(amppeaktimes)) ' respiratory amplitude peaks\n']);
end

% peak detection based on cross correlation 
% (this is relatively a time consuming process)
if flag.verbose>0
    fprintf('amri_fmri_retroicor(): compute the correlation to the respiratory template\n');
end

ccorr = ones(size(Y))*nan;
for i=1:length(Y)
    asegment_center = i;
    asegment_before = asegment_center-(template_center-template_before);
    asegment_after  = asegment_center+(template_after-template_center);
    if asegment_before<1 % data beginning
        asegment = Y(1:asegment_after);
        tt = template(1-asegment_before+1:end);
        cc=corrcoef(asegment(:),tt(:));
        ccorr(i)=cc(1,2);
    elseif asegment_after>length(Y)
        asegment = Y(asegment_before:end);
        tt = template(1:length(asegment));
        cc=corrcoef(asegment(:),tt(:));
        ccorr(i)=cc(1,2);
        continue;
    else
        asegment = Y(asegment_before:asegment_after);
        tt=template;
        cc=corrcoef(asegment(:),tt(:));
        ccorr(i)=cc(1,2);
    end
end
ccpeaktimes = amri_sig_findpeaks(ccorr,'pos');
ccpeaktimes = ccpeaktimes & ccorr>0.5;
if flag.verbose>0
    fprintf(['amri_fmri_retroicor(): find ' num2str(sum(ccpeaktimes)) ' respiratory correlation peaks\n']);
end

% identify a time point as an r peak, if satisfying both the amplitude
% and correaltion criteria
r_peaks = ccpeaktimes; 
indices = find(r_peaks>0);
peakuncertainty=round(min([ibi/2,1.5*rsp.srate]));
for i=1:length(indices)
    ti=indices(i);
    if amppeaktimes(ti)==0
        r_peaks(ti)=0;
        ti_from = max([ti-peakuncertainty 1]);
        ti_to   = min([ti+peakuncertainty length(Y)]);
        ti_range = ti_from:ti_to;
        if any(amppeaktimes(ti_range)>0)
            [~,junk_i] = max(Y(ti_range));
            ti=ti_range(junk_i);
            r_peaks(ti)=1;
        elseif ccorr(ti)>0.8
            r_peaks(ti)=1;
        end
    end
end

r_peaks_time = find(r_peaks>0);

% remove false positive until no false positive is found or search for
% false positives has been done 5 times
num_lp = 1;
max_loop = 5;
while num_lp<=max_loop
    for i=2:length(r_peaks_time)
        rrint = r_peaks_time(i)-r_peaks_time(i-1);
        if rrint<round(1*rsp.srate);
            % if a false positive is detected
            % then remove both the previous and current r peaks
            % set a new r peak at the time point of maximal correlation
            r_peaks(r_peaks_time(i-1))=0;
            r_peaks(r_peaks_time(i))=0;
            timerange=r_peaks_time(i-1):r_peaks_time(i);
            [~,imax]=max(ccorr(timerange));
            r_peaks(timerange(imax))=1;
        end
    end
    r_peaks_time = find(r_peaks>=1);
    if ~sum(diff(r_peaks_time)<round(1*rsp.srate))
        break;
    end
    num_lp=num_lp+1;
end

for i=1:length(r_peaks_time)
    ti = r_peaks_time(i);
    ti_err = round(0.1 * rsp.srate);
    ti_from = max([ti-ti_err 1]);
    ti_to   = min([ti+ti_err length(Y)]);
    ti_range = ti_from:ti_to;
    [~,junk_i]=max(rsp.data(ti_range));
    new_ti=ti_range(junk_i);
    if new_ti~=ti
        r_peaks_time(i)=new_ti;
    end
end
r_peaks = zeros(length(Y),1);
r_peaks(r_peaks_time)=1;

if flag.verbose>0
    fprintf(['amri_fmri_retroicor(): confirm ' num2str(sum(r_peaks)) ' respiratory peaks\n']);
end

% negative peaks
n_peaks = amri_sig_findpeaks(rsp.data,'neg');
new_n_peaks = zeros(length(rsp.data),1);
% ensure only one negative peak between two positive peaks
bad_r_peaks_time=false(length(r_peaks_time),1);
for p = 1 : length(r_peaks_time)-1
    arange = r_peaks_time(p):r_peaks_time(p+1);
    if ~any(n_peaks(arange)==-1)
        bad_r_peaks_time(p+1)=true;
        continue;
    end
    tmp=arange(n_peaks(arange)==-1);
    [~,j]=min(rsp.data(tmp));
    new_n_peaks(tmp(j))=-1;
end
r_peaks_time(bad_r_peaks_time)=[];
r_peaks = zeros(length(Y),1);
r_peaks(r_peaks_time)=1;

arange = 1:r_peaks_time(1);
tmp=arange(n_peaks(arange)==-1);
if ~isempty(tmp)
    [~,j]=min(rsp.data(tmp));
    new_n_peaks(tmp(j))=-1;        
end
arange = r_peaks_time(end):length(rsp.data);
tmp=arange(n_peaks(arange)==-1);
if ~isempty(tmp)
    [~,j]=min(rsp.data(tmp));
    if rsp.data(tmp(j))<rsp.data(end)
        new_n_peaks(tmp(j))=-1;        
    else
        new_n_peaks(length(rsp.data))=-1;
    end
end
n_peaks = new_n_peaks;
clear new_n_peaks;
% n_peaks_time = find(n_peaks<0);

