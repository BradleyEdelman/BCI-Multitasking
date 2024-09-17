function [hObject,handles]=bci_ESI_SetESI(hObject,handles)

set(hObject,'backgroundcolor',[.94 .94 .94],'userdata',0)
set(handles.senspikes,'string','');


% Reset display files
set(handles.dispfiles,'string','','value',1)

savefiledir=handles.SYSTEM.savefiledir;

CheckESI=get(handles.CheckESI,'userdata');
if isequal(CheckESI,1)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   LOAD CORTEX, LOW RESOLUTION CORTEX, COMPUTE INTERPOLATION MATRIX  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cortexfile=get(handles.cortexfile,'string');
    cortex=load(cortexfile);
    handles.ESI.cortex=cortex;
    faces=cortex.Faces; vertices=cortex.Vertices;
    
    axes(handles.axes3); cla
    set(handles.Axis3Label,'string','Cortical Activity');
    lrvizsource=get(handles.lrvizsource,'value');
    if isequal(lrvizsource,1)
        cortexlrfile=get(handles.cortexlrfile,'string');
        cortexlr=load(cortexlrfile);
        faceslr=cortexlr.Faces; verticeslr=cortexlr.Vertices;
        h=trisurf(faceslr,verticeslr(:,1),verticeslr(:,2),verticeslr(:,3),zeros(1,size(verticeslr,1)));

        NN=bci_fESI_Brain_Interp(cortex,cortexlr);
        handles.ESI.cortexlr=cortexlr;
        handles.ESI.lowresinterp=NN;
    else
        h=trisurf(faces,vertices(:,1),vertices(:,2),vertices(:,3),zeros(1,size(vertices,1)));
    end
    
    set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
    axis equal; axis off; view(-90,90)
    cmap1=jet(256);
    newcmap1=repmat([0.85 0.85 0.85],[1 1]);
    newcmap2=cmap1(1:end,:);
    cmap=[newcmap1;newcmap2];
    colormap(cmap); caxis([0 1]);
    light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %              LOAD HEADMODEL AND PREPROCESS GAIN MATRIX              %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    headmodelfile=get(handles.headmodelfile,'string');
    headmodel=load(headmodelfile);
    leadfield=headmodel.Gain;
    leadfield(handles.SYSTEM.Electrodes.chanidxexclude,:)=[];
    [chan,dip]=size(leadfield); dip=dip/3;

    % Create average reference operator
    I=eye(chan); AveRef=(I-sum(I(:))/(chan*chan));
    % Apply average reference to lead field
    leadfield=AveRef*leadfield; 

    % Compute power of lead fields for depth weighting
    R=reshape(leadfield,[chan 3 dip]);
    R=R.^2;
    R=sum(R,1);
    R=sum(R,2);
    R=squeeze(R);

    % Fix orientations of lead field sources
    leadfield=bci_ESI_bst_gain_orient(leadfield,headmodel.GridOrient); % EQ 3

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                  PROCESS NOISE COVARIANCE MATRICES                  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    noise=get(handles.noise,'value');
    handles.ESI.noisetype=noise;
    noisefile=get(handles.noisefile,'string');
    chan=size(handles.SYSTEM.Electrodes.current.eLoc,2);
    % Regularize noise covariance matrix
    reg=0.1;
    
    switch noise
        case {1,2} % None or no noise estimation
            
            % Identity matrix 
            I=eye(chan); AveRef=(I-sum(I(:))/(chan*chan));
%             NoiseCov=1.0e-10*eye(chan);
            noisecov=eye(chan);
            % Apply average reverence to noise covariance
            noisecov=AveRef*noisecov*AveRef';
            % Use diagonal covariance with no noise modeling
            variances=diag(noisecov);
            noisecov=diag(variances);
            
            % Create whitener
            noisecovrank=chan;
            whitener=bci_ESI_CalculateWhitener(noisecov,noisecovrank,0);
            handles.ESI.noisecov.nomodel=noisecov;
            handles.ESI.whitener.nomodel=whitener;

        case {3,4} % Diagonal or full noise covariance
            
            noisedatastruct=load(noisefile);
            win=size(noisedatastruct.Dat,2);
            
            for i=1:win
            
                noiseeeg=noisedatastruct.Dat(i).eeg;
                
                % Filter noisy data
                noiseeeg=filtfilt(handles.SYSTEM.filter.b,handles.SYSTEM.filter.a,double(noiseeeg'));
                noiseeeg=noiseeeg';
            
                % Mean-correct noise data
                noiseeeg=noiseeeg-repmat(mean(noiseeeg,2),[1 size(noiseeeg,2)]);
            
                tempdomain=get(handles.tempdomain,'value');
                switch tempdomain
                    case 1 % None
                    case 2 % Frequency Domain
                    
                        freqtrans=get(handles.freqtrans,'value');
                        switch freqtrans
                            case 1 % None
                            case 2 % Complex Morlet wavelet

                                mwparam=handles.SYSTEM.mwparam;
                                morwav=handles.SYSTEM.morwav;
                                dt=1/mwparam.fs;
                                Anoise=zeros(mwparam.numfreq,size(noiseeeg,2),size(noiseeeg,1));
                                for j=1:size(noiseeeg,1)
                                    for k=1:mwparam.numfreq
                                        Anoise(k,:,j)=conv2(noiseeeg(j,:),morwav{k},'same')*dt;
                                    end
                                end

                                Enoisereal=sum(real(Anoise),1);
                                Enoiseimag=sum(imag(Anoise),1);

                                Enoisereal=squeeze(Enoisereal)';
                                Enoiseimag=squeeze(Enoiseimag)';

                                C_real(:,:,i)=(Enoisereal*Enoisereal')/size(Enoisereal,2);
                                C_imag(:,:,i)=(Enoiseimag*Enoiseimag')/size(Enoiseimag,2);

                                C_real(:,:,i)=AveRef*C_real(:,:,i)*AveRef';
                                C_imag(:,:,i)=AveRef*C_imag(:,:,i)*AveRef';

                                if isequal(noise,3) % diagonal covariance
                                    C_real(:,:,i)=diag(diag(C_real(:,:,i)));
                                    C_imag(:,:,i)=diag(diag(C_imag(:,:,i)));
                                end
                                
                            case {3,4} % Welch's PSD or DFT
                        end
                        
                    case 3 % Time Domain

                        noisecov=noisedata*noisedata'/size(noisedata,1);
                        if isequal(noise,3) % diagonal covariance
                            noisecov=diag(diag(noisecov));
                        end

                        % Create whitener
                        noisecovrank=chan;
                        noisecov=noisecov+(reg*mean(diag(noisecov))*eye(chan));
                        whitener=bci_ESI_CalculateWhitener(noisecov,noisecovrank,0);
                        handles.ESI.noisecov.nomodel=noisecov;
                        handles.ESI.whitener.nomodel=whitener;
                    
                end
            end
            
            noisecovrank=chan;
            % Regularize noise covariance matrix
            C_real=mean(C_real,3);
            noisecovreal=C_real+(reg*mean(diag(C_real))*eye(chan));
            whitenerreal=bci_ESI_CalculateWhitener(noisecovreal,noisecovrank,0);
            handles.ESI.noisecov.real=noisecovreal;
            handles.ESI.whitener.real=whitenerreal;

            C_imag=mean(C_imag,3);
            noisecovimag=C_imag+(reg*mean(diag(C_imag))*eye(chan));
            whitenerimag=bci_ESI_CalculateWhitener(noisecovimag,noisecovrank,0);
            handles.ESI.noisecov.imag=noisecovimag;
            handles.ESI.whitener.imag=whitenerimag;

            whitener=(whitenerreal+whitenerimag)/2;
    end
    
    % Reciprocal of dipole power
    R=1./R;
    % Apply depth weighting
    weightlimit=10;
    weightlimit2=weightlimit.^2;
    limit=min(R)*weightlimit2;
    R(R>limit)=limit;
    weightexp=.5; % Weighting parameter (between 0 and 1)
    R=R.^weightexp;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %              LOAD FMRI PRIOR(s) AND DETERMINE WEIGHTING             %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fmrifile=get(handles.fmrifile,'string');
    if ~isempty(fmrifile)
        fmrifile=gifti(fmrifile);
        prioridx=find(fmrifile.cdata~=0);
        priorval=fmrifile.cdata(prioridx);
    else
        prioridx=[];
        priorval=[];
    end
    Jfmri=zeros(1,15002);
    Jfmri(prioridx)=priorval;
    
    % COMPUTE DIPOLE SCALING FACTOR BASED ON FMRI WEIGHT
    fmriweight=get(handles.fmriweight,'value');
    wnonfmri=1-(fmriweight/100);
    wfmri=1/wnonfmri;
    
    % Apply fmri weighting
    R(prioridx)=R(prioridx)*wfmri;
    handles.ESI.leadfieldweights=R;
    R=diag(R);
%     handles.ESI.sourcecov=R;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                   IDENTIFY ANATOMICAL CONSTRAINTS                   %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    brainregionfile=get(handles.brainregionfile,'string');
    brainregions=load(brainregionfile);
    selectbrainregions=get(handles.selectbrainregions,'userdata');
    vertidxinclude={brainregions.Scouts(selectbrainregions==1).Vertices};
    vertidxinclude=sort(horzcat(vertidxinclude{:}));
    vertidxexclude=1:dip;
    vertidxexclude(vertidxinclude)=[];
    
    handles.ESI.vertidxinclude=vertidxinclude;
    handles.ESI.vertidxexclude=vertidxexclude;
    handles.ESI.leadfield.original=leadfield;
                
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        BUILD INVERSE OPERATOR                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    parcellation=get(handles.parcellation,'value');
    data=get(handles.esifiles,'data');
    files=cellstr(data(:,2));
    idx=data(:,1);
    for i=1:size(idx,1)
        if islogical(idx{i}); idx{i}=+idx{i}; end
    end
    idx=cell2mat(idx);
    esifiles=files(idx==1);
    switch parcellation
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                         NO PARCELLATION                         %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 1 % None
            
            switch noise
                case {1,2} % None or no noise estimation

                    leadfield=whitener*leadfield;

                    % Determine lambda empirically from lead field
                    SNR=3;
                    lambdasq=trace(leadfield*R*leadfield')/(trace(noisecov)*SNR^2);
                    handles.ESI.NOCLUSTER.lambdasq.nomodel=lambdasq;

                    % Create inverse operator
                    INV=R*leadfield'/(leadfield*R*leadfield'+lambdasq*noisecov)*whitener;
                    handles.ESI.NOCLUSTER.inv.nomodel=INV;
                    handles.ESI.NOCLUSTER.sourcecov=R;

                case {3,4} % Diagonal or full noise covariance
            
                    switch tempdomain
                        case 1 % None
                        case 2 % Frequency

                            LeadFieldReal=whitenerreal*leadfield;
                            LeadFieldImag=whitenerimag*leadfield;
                            SNR=3;

                            % Create real inverse operator
                            lambdasqreal=trace(LeadFieldReal*R*LeadFieldReal')/(trace(noisecovreal)*SNR^2);
                            handles.ESI.NOCLUSTER.lambdasq.real=lambdasqreal;
                            INVreal=R*LeadFieldReal'/(LeadFieldReal*R*LeadFieldReal'+lambdasqreal*noisecovreal)*whitenerreal;
                            handles.ESI.NOCLUSTER.inv.real=INVreal;

                            % Create imaginary inverse operator
                            lambdasqimag=trace(LeadFieldImag*R*LeadFieldImag')/(trace(noisecovimag)*SNR^2);
                            handles.ESI.NOCLUSTER.lambdasq.imag=lambdasqimag;
                            INVimag=R*LeadFieldImag'/(LeadFieldImag*R*LeadFieldImag'+lambdasqimag*noisecovimag)*whitenerimag;
                            handles.ESI.NOCLUSTER.inv.imag=INVimag;

                        case 3 % Time

                            leadfield=whitener*leadfield;

                            % Determine lambda empirically from lead field
                            SNR=3;
                            lambdasq=trace(leadfield*R*leadfield')/(trace(noisecov)*SNR^2);
                            handles.ESI.NOCLUSTER.lambdasq.nomodel=lambdasq;

                            % Create inverse operator
                            INV=R*leadfield'/(leadfield*R*leadfield'+lambdasq*noisecov)*whitener;
                            handles.ESI.NOCLUSTER.inv.nomodel=INV;
                    end
            end          
            
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %         MULTIVARIATE SOURCE PRELOCALIZATION PARCELLATION        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
        case 2 % MSP
            
            analysiswindow=handles.SYSTEM.analysiswindow;
            dsfs=handles.SYSTEM.dsfs;
            
            esifiletype=char(handles.ESI.CLUSTER.esifiletype);
            switch esifiletype
                case {'.dat'}
                    
                    [TrialStruct]=bci_ESI_BCI2000ExtractParameters(esifiles);
                    [handles,TaskInfo,Data]=bci_ESI_BCI2000TaskInfo(handles,esifiles,TrialStruct);
                    [hObject,handles,baselinedata,trialdata]=...
                        bci_ESI_TrialSections(hObject,handles,TaskInfo,...
                        TrialStruct,Data,analysiswindow/1000*dsfs);
                    
                    trialdata=horzcat(trialdata{:});
                    trialdata=horzcat(trialdata{:});
                    
                case {'.mat'}
                    
                    [handles,TrialInfo]=bci_ESI_BCIESIExtractParamaters(handles,esifiles);
                    [handles,TaskInfo,Data]=bci_ESI_BCIESITaskInfo(handles,TrainFiles,TrialInfo);
                    
            end
            
            [hObject,handles]=bci_ESI_CorticalClusters(hObject,handles,trialdata);
            clusters=handles.ESI.CLUSTER.clusters;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %             PROCESS LEAD FIELD FOR EACH CLUSTER             %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Whiten lead field
            leadfield=whitener*handles.ESI.leadfield.original;
            handles.ESI.leadfield.whitened=leadfield;
            
            numCluster=size(clusters,2);
            GG=zeros(chan);
            Gk=cell(1,numCluster);
            Rk=cell(1,numCluster);
            for i=1:size(clusters,2)
                Gk{i}=leadfield(:,clusters{i});  
                Rk{i}=R(clusters{i},clusters{i});
%                 Rk{i}(Rk{i}==0)=.5;

                for j=1:size(clusters{i},2)
                    F1=find(faces(:,1)==clusters{i}(j));
                    F2=find(faces(:,2)==clusters{i}(j));
                    F3=find(faces(:,3)==clusters{i}(j));
                    Ftot=vertcat(F1,F2,F3);
                    vert=unique(faces(Ftot,:)); vert(vert==clusters{i}(j))=[];
                    vert(~ismember(vert,clusters{i}))=[];
                    
                    vertidx=find(ismember(clusters{i},clusters{i}(j))==1);
                    connectidx=find(ismember(clusters{i},vert)==1);

                    Rk{i}(repmat(vertidx,[size(connectidx,1),1]),connectidx)=.005;
                    Rk{i}(connectidx,repmat(vertidx,[size(connectidx,1),1]))=.005;
                    
                end

                % Compile Gk*Rk*Gk' for entire lead field
                GG=GG+Gk{i}*Rk{i}*Gk{i}';
                
            end
            handles.ESI.CLUSTER.clusterleadfield=Gk;
            handles.ESI.CLUSTER.sourcecov=Rk;
            handles.ESI.CLUSTER.residualsolution=GG;
            
            switch noise
                case {1,2} % None or no noise estimation
            
                    % Determine lambda empirically from total lead field
                    SNR=3;
                    lambdasq=double(trace(GG)/(trace(noisecov)*SNR^2));
                    handles.ESI.CLUSTER.lambdasq.nomodel=lambdasq;
                    
                    % Create inverse operator for each cluster
                    INV=cell(1,size(clusters,2));
                    for i=1:size(clusters,2)
                        INV{i}=Rk{i}*Gk{i}'*inv(GG+lambdasq*eye(chan))*whitener;
                    end
                    handles.ESI.CLUSTER.inv.nomodel=INV;
            
                case {3,4} % Diagonal or full noise covariance
                    
                    SNR=3;
                    % Create real inverse operator for each cluster
                    lambdasqreal=double(trace(GG)/(trace(noisecovreal)*SNR^2));
                    handles.ESI.CLUSTER.lambdasq.real=lambdasqreal;
                    
                    INVreal=cell(1,size(clusters,2));
                    for i=1:size(clusters,2)
                        INVreal{i}=Rk{i}*Gk{i}'*inv(GG+lambdasqreal*eye(chan))*whitenerreal;
                    end
                    handles.ESI.CLUSTER.inv.real=INVreal;
                    
                    % Create imaginary inverse operator for each cluster
                    lambdasqimag=double(trace(GG)/(trace(noisecovimag)*SNR^2));
                    handles.ESI.CLUSTER.lambdasq.imag=lambdasqimag;
                    
                    INVimag=cell(1,size(clusters,2));
                    for i=1:size(clusters,2)
                        INVimag{i}=Rk{i}*Gk{i}'*inv(GG+lambdasqimag*eye(chan))*whitenerimag;
                    end
                    handles.ESI.CLUSTER.inv.imag=INVimag;
            end
            
            
        case 3 % K_means
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SAVE ESI PARAMETERS TO FILE
    k=1;
    SaveESIFile=strcat(savefiledir,'\ESI_',num2str(k),'.mat');
    % Dont duplicate file (may want to load later)
    while exist(SaveESIFile,'file')
        k=k+1;
        SaveESIFile=strcat(savefiledir,'\ESI_',num2str(k),'.mat');
    end
    handles.ESI.savefile=SaveESIFile;
    SaveESI=handles.ESI;
    save(SaveESIFile,'SaveESI','-v7.3');
    
    k=1;
    SaveCortexFile=strcat(savefiledir,'\Cortex_',num2str(k),'.mat');
    % Dont duplicate file (may want to load later)
    while exist(SaveCortexFile,'file')
        k=k+1;
        SaveCortexFile=strcat(savefiledir,'\Cortex_',num2str(k),'.mat');
    end
    handles.ESI.cortexsavefile=SaveCortexFile;
    SaveCortex=handles.ESI.cortex;
    save(SaveCortexFile,'SaveCortex','-v7.3');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ADD VARIABLES TO SAVED FILE LIST FOR DISPLAY
    if isfield(handles,'ESI')
        
        disvar={'Cortex' 'Lead Field' 'Noise Covariance'...
            'Source Covariance' 'Source Prior'};
        
        for i=1:size(disvar,2)
            dispfiles=cell(get(handles.dispfiles,'string'));
            if ~ismember(disvar{i},dispfiles)
                dispfiles=sort(vertcat(dispfiles,{disvar{i}}));
                set(handles.dispfiles,'string',dispfiles);
            end
        end
        
    end
    set(hObject,'backgroundcolor','green','userdata',1);
    
    % RESET SPATIAL DOMAIN FIELD
    [hObject,handles]=bci_ESI_SpatDomain(hObject,handles);
    
elseif isequal(CheckESI,0)
    
   fprintf(2,'ESI PARAMETERS HAVE NOT BEEN CHECKED\n');
   set(hObject,'backgroundcolor','red','userdata',0);
   
end
