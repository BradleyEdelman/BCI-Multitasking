function [hObject,handles]=bci_ESI_RunBCI_20170502(hObject,handles)

clear buffer
paradigm=get(handles.paradigm,'value');

switch paradigm
    case {2,3,4,5,8} % DT Cursor, CP Cursor, DT HM, CP HM, DT Cursor - SSVEP
        sigtype={'SMR'};
    case 6 % DT Cursor + SSVEP
        sigtype={'SMR' 'SSVEP'};
    case 7 % SSVEP
        sigtype={'SSVEP'};
end

%% INITIATE REAL TIME PROCESSING VARIABLES
if isequal(get(handles.SetBCI,'userdata'),1)
    
    %% RESET GUI
    set(hObject,'backgroundcolor','green','userdata',1)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,{'Stop'},[]);
    
    %% CONFIGURE STIMULUS WINDOW
    [stimulus,flags]=bci_ESI_Stimulus('initiate',[],'handles',handles);

    %% INITIATE DISPLAY VARIABLES
    [plotting,flags]=bci_ESI_Plot('initiate',[],'handles',handles,'signal',sigtype,'flags',flags);
    
    %% EXTRACT FREQUENCY TRANSFORM PARAMETERS
    [freq,flags]=bci_ESI_FrequencyAnalysis('initiate',[],'handles',handles,'flags',flags);
    
    %% INITIATE EEG STRUCTURE
    eeg=bci_ESI_EEG('initiate',[],'handles',handles,'signal',sigtype);
    v2struct(eeg.general)
    
    %% INITIATE PERFORMANCE STRUCTURE
    [performance,flags]=bci_ESI_Performance('initiate',[],'handles',handles,'signal',sigtype,'flags',flags);
    
    %% INITIATE AND UNPACK TRANSIENT ONLINE PARAMTERS/STRUCTURES
    runparam=bci_ESI_OnlineVar(handles);
    v2struct(runparam);
    
    %% INITIATE BASELINE STRUCTURE
    [baseline,flags]=bci_ESI_Baseline('initiate',[],'handles',handles,'signal',sigtype,'flags',flags);
    
    %% EXTRACT SOURCE IMAGING VARIABLES
    [esi,flags]=bci_ESI_ESI('initiate',[],'handles',handles,'flags',flags);
    
    %% CONTROL SIGNAL
    [control,flags]=bci_ESI_ControlSignal('initiate',[],'handles',handles,'flags',flags);
    
    %% SMR SPECIFIC VARIABLES 
    if ismember('SMR',sigtype)
        
        % BUFFER
        [bufferbci,flags]=bci_ESI_ModBuffer('initiate',[],'handles',handles,'flags',flags);
        trial.SMR.prevsample=-eeg.SMR.updatewindowextract+1;
        event.dimused=flags.dimused;
        cursorpos=zeros(1,2); targetpos=zeros(1,2);
        
        v2struct(eeg.SMR)
    end
    
    %% SSVEP SPECIFIC VARIABLES - EYE TRACKER, STIMULUS
    if ismember('SSVEP',sigtype)
        
        ssvepidx.target=1;
        ssvepidx.result=1;
        ssvepidx.trial='off';
        ssvepidx.targetprev=[];
        v2struct(eeg.SSVEP)
        
    end
    
    [triggers,flags]=bci_ESI_Triggers('initiate',[],'handles',handles,'signal',sigtype,'flags',flags);
    tempdomain=get(handles.tempdomain,'value');
    
    %% ESTABLISH CONNECTION TO BCI2000
    filename='buffer://localhost:1972';
    hdr=ft_read_header(filename,'cache',true);
    
    %% UNPACK FLAGS
    v2struct(flags);
   
    %% START REAL-TIME PROCESSING
	while isequal(get(hObject,'userdata'),1)
            
        if trial.SMR.null<300 && trial.SSVEP.null<7500 && isequal(get(handles.Stop,'userdata'),0)
            
            % Determine number of samples available in buffer
            hdr=ft_read_header2(filename,'cache',true);
            newsamples=(hdr.nSamples*hdr.nTrials-trial.SMR.endsample);
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % SMR/CURSOR CONTROL PROCESSING %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for ii=1
            if ismember('SMR',sigtype)
                tic1=tic;
                % Check buffer for new samples
                if  trial.SMR.win==1 && newsamples<eeg.SMR.analysiswindowextract+2*eeg.SMR.updatewindowextract ||...
                        trial.SMR.win>1 && newsamples<eeg.SMR.updatewindowextract
                    
                    event.BCI2Event=ft_read_event(filename,'header',hdr);
                    event=bci_ESI_BCIEvent(event,handles);
                    trial.SMR.targetidx(trial.SMR.win+1)=event.targetval;
                    trial.SMR.feedback(trial.SMR.win+1)=event.feedbackval;
                    trial.SMR.baseline(trial.SMR.win+1)=event.baselineval;
                    trial.SMR.null=trial.SMR.null+1;
                    
                elseif trial.SMR.win>1 && newsamples>=eeg.SMR.updatewindowextract ||...
                        trial.SMR.win==1 && newsamples>=eeg.SMR.analysiswindowextract+2*eeg.SMR.updatewindowextract
                    
                    % Read event from BCI2000
                    event.BCI2Event=ft_read_event(filename,'header',hdr);
                    % Sort events
                    event=bci_ESI_BCIEvent(event,handles);
                    trial.SMR.targetidx(trial.SMR.win+1)=event.targetval;
                    trial.SMR.feedback(trial.SMR.win+1)=event.feedbackval;
                    trial.SMR.baseline(trial.SMR.win+1)=event.baselineval;

%                     [trial.SMR.feedback(trial.SMR.win) trial.SMR.baseline(trial.SMR.win) trial.SMR.targetidx(trial.SMR.win)]
                    
                    if ismember(paradigm,[3,5])
                        event.targetpos.win(end+1,:)=event.targetpos.current;
                        event.cursorpos.win(end+1,:)=event.cursorpos.current;
                    end
                    
                    if isequal(paradigm,3)
                        if ~isequal(event.targetpos.orig,-1*ones(1,2))
                            cursorpos(trial.SMR.win+1,:)=event.cursorpos.current;
                            targetpos(trial.SMR.win+1,:)=event.targetpos.current;
                            figure(2); cla; hold on
                            scatter(targetpos(trial.SMR.win+1,1),targetpos(trial.SMR.win+1,2),1600*pi,[0 0 0],'filled');
                            scatter(cursorpos(trial.SMR.win+1,1),cursorpos(trial.SMR.win+1,2),100*pi,[1 0 0],'filled');
                            axis([0 event.targetpos.orig(1)*2 0 event.targetpos.orig(2)*2]);
                            hold off
                        end
                    end
                    
                    % Determine samples to extract for the current window
                    trial.SMR.begsample=trial.SMR.prevsample+eeg.SMR.updatewindowextract;
                    trial.SMR.endsample=trial.SMR.begsample+eeg.SMR.analysiswindowextract-1;
                    trial.SMR.endsample=trial.SMR.endsample+2*eeg.general.analysiswindowpaddingextract;
                    trial.SMR.prevsample=trial.SMR.begsample;

                    eeg.SMR.data=ft_read_data(filename,'header',hdr,'begsample',...
                        trial.SMR.begsample,'endsample',trial.SMR.endsample,'chanindx',chanidxextract);

                    eeg.SMR.targetidx=event.targetval;
                    eeg.SMR.feedback=trial.SMR.feedback(trial.SMR.win+1);
                    eeg.SMR.startidx=trial.SMR.begsample;
                    eeg.SMR.endidx=trial.SMR.endsample;
                    
                    %% Send triggers if needed
                    triggers=bci_ESI_Triggers('send',triggers,'flags',flags,'signal','SMR','trial',trial);
                    
                    if ~isempty(eeg.SMR.data)
                        %% Process Raw Data
                        tic
                        eeg=bci_ESI_EEG('preprocess',eeg,'signal','SMR');
                        TOC.SMR.eegpreprocess(trial.SMR.win)=toc;
                        
                        %% Store eeg data
                        tic
                        dat.SMR.eeg.start{trial.SMR.win}=single(eeg.SMR.startidx);
                        dat.SMR.eeg.end{trial.SMR.win}=single(eeg.SMR.endidx);
                        dat.SMR.eeg.window{trial.SMR.win}=eeg.SMR.data;
                        dat.SMR.eeg.targetidx{trial.SMR.win}=single(eeg.SMR.targetidx);
                        dat.SMR.eeg.feedback{trial.SMR.win}=single(eeg.SMR.feedback);
                        TOC.SMR.storeeeg(trial.SMR.win)=toc;
                        
                        %% Time/freq domain analysis
                        switch tempdomain
                            case 1 % None
                            case 2 % Frequency domain
                                tic
                                [Save,dataselect]=bci_ESI_FrequencyAnalysis('process',freq,'eeg',eeg,'esi',esi,'signal','SMR','flags',flags,'bci',bci);
                                TOC.SMR.freqprocess(trial.SMR.win)=toc;
                                % Always store sensor info
                                tic
                                dat.SMR.psd.Sensor.window{trial.SMR.win}=Save.Sensor;
                                dat.SMR.psd.Sensor.start{trial.SMR.win}=single(eeg.SMR.startidx+eeg.general.analysiswindowpaddingextract);
                                dat.SMR.psd.Sensor.end{trial.SMR.win}=single(eeg.SMR.endidx-eeg.general.analysiswindowpaddingextract);
                                dat.SMR.psd.Sensor.targetidx{trial.SMR.win}=single(eeg.SMR.targetidx);
                                dat.SMR.psd.Sensor.feedback{trial.SMR.win}=single(eeg.SMR.feedback);
                                
                                dat.SMR.psd.(spatdomainfield).window{trial.SMR.win}=Save.(spatdomainfield);
                                dat.SMR.psd.(spatdomainfield).start{trial.SMR.win}=single(eeg.SMR.startidx+eeg.general.analysiswindowpaddingextract);
                                dat.SMR.psd.(spatdomainfield).end{trial.SMR.win}=single(eeg.SMR.endidx-eeg.general.analysiswindowpaddingextract);
                                dat.SMR.psd.(spatdomainfield).targetidx{trial.SMR.win}=single(eeg.SMR.targetidx);
                                dat.SMR.psd.(spatdomainfield).feedback{trial.SMR.win}=single(eeg.SMR.feedback);
                                TOC.SMR.storepsd(trial.SMR.win)=toc;
                            case 3 % Time domain
                                
                        end
                        
                        %% Baseline normalization
                        tic
                        if isequal(trial.SMR.baseline(trial.SMR.win+1),0) &&...
                                isequal(trial.SMR.baseline(trial.SMR.win),1) % End of Baseline
                            baseline=bci_ESI_Baseline('update',baseline,'flags',flags,'signal','SMR');
                        elseif isequal(trial.SMR.baseline(trial.SMR.win+1),1) % During baseline
                            baseline=bci_ESI_Baseline('store',baseline,'flags',flags,'signal','SMR','data',dataselect);
                        end
                        [baseline,datanorm]=bci_ESI_Baseline('normalize',baseline,'flags',flags,'signal','SMR','data',dataselect);
                        TOC.SMR.normdata(trial.SMR.win)=toc;
                        
                        %% Extract raw control signal
                        tic
                        control=bci_ESI_ControlSignal('raw',control,'data',datanorm,'bci',bci);
                        TOC.SMR.ctrlraw(trial.SMR.win)=toc;
                        
                        %% Update Buffers
                        tic
                        if ismember(paradigm,[2 4 6 8])
                            
                            if isequal(trial.SMR.feedback(trial.SMR.win+1),0) &&...
                                isequal(trial.SMR.feedback(trial.SMR.win),1) % End of trial
                            
                                [bufferbci,trial,bci]=bci_ESI_Buffer('update',bufferbci,'flags',flags,...
                                    'trial',trial,'signal','SMR','event',event,'bci',bci);
                                
                                % Update performance record
                                performance=bci_ESI_Performance('update',performance,...
                                    'flags',flags,'signal','SMR','event',event,'trial',trial);
                                
                            elseif isequal(trial.SMR.feedback(trial.SMR.win+1),1) % During trial
                                [bufferbci,trial]=bci_ESI_Buffer('store',bufferbci,'flags',flags,...
                                    'trial',trial,'signal','SMR','event',event,'data',datanorm,'control',control);
                            end
                            
                        elseif ismember(paradigm,[3 5])
                            
                            if isequal(trial.SMR.feedback(trial.SMR.win+1),1) &&...
                                    ~isequal(sum(trial.SMR.trialwin(:)>bufferlength),0) % End of cycle
                                
                                [bufferbci,trial,bci]=bci_ESI_Buffer('update',bufferbci,'flags',flags,...
                                    'trial',trial,'signal','SMR','event',event,'bci',bci);
                                
                            elseif isequal(trial.SMR.feedback(trial.SMR.win+1),1) % During cycle
                                
                                [bufferbci,trial]=bci_ESI_Buffer('store',bufferbci,'flags',flags,...
                                    'trial',trial,'signal','SMR','event',event,'data',datanorm,'control',control);
                                
                            end
                        end 
                        TOC.SMR.buffer(trial.SMR.win)=toc;
                         
                    end
                    
                    %% Normalizer calibration check
                    Go=bci_ESI_CheckNormCalibration(bufferbci,flags);
                    
                    %% Process control signal and stimulus
                    tic
                    if isequal(Go,1)
                        % Normalized control signal
                        control=bci_ESI_ControlSignal('norm',control,'bufferbci',bufferbci,'flags',flags);
                        % Filter control signal
                        control=bci_ESI_ControlSignal('filt',control);
                        % Convert control signal into stimulus
                        control=bci_ESI_ControlSignal('stim',control,'flags',flags,'event',event);
                    else
                        control.norm(:,trial.SMR.win)=zeros(3,1);
                        control.filt=zeros(3,1);
                        control.stim=zeros(3,1);
                    end
                    TOC.SMR.ctrlprocess(trial.SMR.win)=toc;
                    
                    % Display (linear) control signal
                    tic
                    control=bci_ESI_ControlSignal('disp',control);
                    plotting=bci_ESI_Plot('update',plotting,'flags',flags,'CS',control.disp);
                    TOC.SMR.ctrlplot(trial.SMR.win)=toc;
                    
                    %% Update Stimulus
                    tic
                    [stimulus,event]=bci_ESI_Stimulus('update',stimulus,'signal','SMR','trial',trial,...
                        'event',event,'control',control,'flags',flags);
                    TOC.SMR.stimulus(trial.SMR.win)=toc;
                    %% Prepare and send control signal to BCI2000
                    control=bci_ESI_ControlSignal('send',control,'flags',flags);
                    
                    % Only send control signal during cursor control (feedback)
                    if isequal(trial.SMR.feedback(trial.SMR.win+1),1)
                        event2bci.value=control.send;
                        ft_write_event(filename,event2bci);
                    end
                    
                    % UPDATE WINDOW COUNT
                    trial.SMR.win=trial.SMR.win+1; trial.SMR.null=0;
                    
                else
                    trial.SMR.null=trial.SMR.null+1;
                end
                
                TOC.SMR.total(trial.SMR.win)=toc(tic1);
            end
            end
            
            %%
            %%%%%%%%%%%%%%%%%%%%
            % SSVEP PROCESSING %
            %%%%%%%%%%%%%%%%%%%%
            for ii=1
            if ismember('SSVEP',sigtype)
                tic2=tic;
                % Check every 50 ms - looking for beginning of trial to
                % start extracting SSVEP time period of interest
                newsamplesssvepcheck=(hdr.nSamples*hdr.nTrials-trial.SSVEP.endsample);
                if newsamplesssvepcheck>=round(50/1000*fsprocess*dsfactor)
                    trial.SSVEP.endsample=trial.SSVEP.endsample+round(50/1000*fsprocess*dsfactor);
                    
                    % Read events from BCI2000
                    event.BCI2Event=ft_read_event(filename,'header',hdr);
                    event=bci_ESI_BCIEvent(event,handles);
                    
                    trial.SSVEP.targetidx(trial.SSVEP.win+1)=event.targetval;
                    trial.SSVEP.feedback(trial.SSVEP.win+1)=event.feedbackval;
                    trial.SSVEP.baseline(trial.SSVEP.win+1)=event.baselineval;
                    
                    %% Update stimulus
                    if ~exist('image','var')
                        stimidx=taskorderssvep{ssvepidx.target};
                        stimidx=find(strcmp(targetsssvep,stimidx));
                        image=imagessvep{stimidx};
                    end
                    [stimulus,image]=bci_ESI_Stimulus('update',stimulus,'signal','SSVEP','trial',trial,...
                        'image',image,'flags',flags);
                    
                    %% Send triggers
                    [trigger,ssvepidx]=bci_ESI_Triggers('send',triggers,'flags',flags,'signal','SSVEP','trial',trial,'ssvepidx',ssvepidx);
                    
                    %% Determine samples to extract for the current window
                    if size(event.BCI2Event,2)>0
                        if strcmp(event.eventtype(end),'Feedback') && ismember(cell2mat(event.eventvalue(end)),[0 1]) ||...
                                strcmp(event.eventtype(end),'CursorPosX') || strcmp(event.eventtype(end),'CursorPosY')
                            if ~exist('begsampletmp','var') && ~exist('endsampletmp','var')
                                begsampletmp=cell2mat(event.eventlatency(end));
                                endsampletmp=begsampletmp+decisionwindowextract+gazewindowprocess;
                                trial.SSVEP.begsample=begsampletmp-eeg.general.analysiswindowpaddingextract;
                                trial.SSVEP.endsampleextract=endsampletmp+analysiswindowpaddingextract;
                            elseif isequal(extract,1)
                                trial.SSVEP.begsample=trial.SSVEP.begsample+decisionwindowextract+gazewindowprocess;
                                trial.SSVEP.endsampleextract=trial.SSVEP.endsampleextract+decisionwindowextract+gazewindowprocess;
                                extract=0;
                            end
                        else
                            if exist('begsampletmp','var') && exist('endsampletmp','var')
                                clear begsampletmp endsampletmp
                            end
                            trial.SSVEP.endsampleextract=1e10;
                        end
                    end
                    
                    if (hdr.nSamples*hdr.nTrials)>trial.SSVEP.endsampleextract
                        ssvepidx.trial='off';
                        
                        %% Extract and preprocess data
                        eeg.SSVEP.data=ft_read_data(filename,'header',hdr,'begsample',...
                            trial.SSVEP.begsample,'endsample',trial.SSVEP.endsampleextract,'chanindx',chanidxextract);
                        
                        tic
                        eeg=bci_ESI_EEG('preprocess',eeg,'signal','SSVEP');
                        TOC.SSVEP.eegpreprocess(trial.SSVEP.win)=toc;
                        tmp=analysiswindowpaddingprocess+1+ceil(gazewindowprocess/dsfactor);
                        eeg.SSVEP.data=eeg.SSVEP.data(:,tmp:end-analysiswindowpaddingprocess);
                        
                        %% Classify current SSVEP
                        tic
                        [ssvepidx,winner]=bci_ESI_SSVEPClass(handles,eeg.SSVEP,ssvepidx);
                        TOC.SSVEP.classify(trial.SSVEP.win)=toc;
                        
                        % Update performance record
                        [performance,ssvepidx,image]=bci_ESI_Performance('update',performance,'flags',flags,...
                            'signal','SSVEP','trialidx',ssvepidx,'winner',winner);
                        
                        %% Display power spectrum
                        tic
                        FFT=[];
                        nfft=1024;
                        for i=1:size(eeg.SSVEP.chanidxinclude,1)
                            X=fft(eeg.SSVEP.data(i,:),1024);
                            X=X(:,1:nfft/2);
                            X=(1/(fsprocess*nfft))*abs(X).^2;
                            X(2:end-1)=2*X(2:end-1);
                            FFT(i,:)=X;
                        end
                        FFT2=mean(FFT,1);
                        plotting=bci_ESI_Plot('update',plotting,'flags',flags,'FFT',FFT2(fftxidx));
                        plotting=bci_ESI_Plot('update',plotting,'flags',flags,'targetfreq',ssvepidx.target);
                        TOC.SSVEP.fftplot(trial.SSVEP.win)=toc;
                        
                        %% Store time and frequency data
                        tic
                        dat.SSVEP.eeg.window{ssvepidx.result-1}=eeg.SSVEP.data;
                        dat.SSVEP.eeg.targetidx{ssvepidx.result-1}=performance.SSVEP{ssvepidx.result-1,1};
                        dat.SSVEP.eeg.resultidx{ssvepidx.result-1}=performance.SSVEP{ssvepidx.result-1,2};
                        dat.SSVEP.eeg.start{ssvepidx.result-1}=trial.SSVEP.begsample;
                        dat.SSVEP.eeg.end{ssvepidx.result-1}=trial.SSVEP.endsampleextract;
                        TOC.SSVEP.storeeeg(trial.SSVEP.win)=toc;
                        
                        tic
                        dat.SSVEP.psd.window{ssvepidx.result-1}=FFT;
                        dat.SSVEP.psd.targetidx{ssvepidx.result-1}=performance.SSVEP{ssvepidx.result-1,1};
                        dat.SSVEP.psd.resultidx{ssvepidx.result-1}=performance.SSVEP{ssvepidx.result-1,2};
                        dat.SSVEP.psd.start{ssvepidx.result-1}=trial.SSVEP.begsample+gazewindowprocess+analysiswindowpaddingextract;
                        dat.SSVEP.psd.end{ssvepidx.result-1}=trial.SSVEP.endsampleextract-analysiswindowpaddingextract;
                        TOC.SSVEP.storepsd(trial.SSVEP.win)=toc;
                        
                        trial.SSVEP.null=0;
                        extract=1;
                        
                    else
                        trial.SSVEP.null=trial.SSVEP.null+1;
                        extract=0;
                    end
                    
                    trial.SSVEP.win=trial.SSVEP.win+1; 
                else
                    
                    trial.SSVEP.null=trial.SSVEP.null+1;
                    
                end
                TOC.SSVEP.total(trial.SSVEP.win)=toc(tic2);
            end
            end
            drawnow
            
        else
            %% SAVE PARAMETERS/DATA IF BUFFER CONTAINS NO NEW DATA - END RUN
            for i=11
            %% Close eye tracker if needed
            bci_ESI_Triggers('end',triggers,'flags',flags);

            %% Restore neutral/default stimulus
            bci_ESI_Stimulus('reset',stimulus,'flags',flags,'handles',handles)
            
            %% Display performance results in command window
            bci_ESI_Performance('display',performance,'flags',flags,'signal',sigtype);
            
            if ismember('SMR',sigtype)
                %% Reset buffer initial data/conditions
                [bufferbci,handles]=bci_ESI_ModBuffer('reset',bufferbci,'handles',handles,...
                    'signal',sigtype,'bci',bci,'flags',flags);
                
                %% Reset normalized - update values from current run
                [control,handles]=bci_ESI_ControlSignal('reset',control,'handles',handles,'flags',flags);
                
            end
            
            if ismember('SSVEP',sigtype)
                %% Create new SSVEP order
                targets=handles.BCI.SSVEP.control.targets;
                [taskorder,taskhit]=bci_ESI_SSVEPTaskOrder2(180,4,targets);
                handles.BCI.SSVEP.control.taskorder=taskorder;
                handles.BCI.SSVEP.control.taskhit=taskhit;
            end
              
            set(hObject,'backgroundcolor','red','userdata',0)
            set(handles.Stop,'backgroundcolor','red')
            drawnow
            
            %% Save run info
            fprintf(2,'\n     SAVING .MAT FILE FOR CURRENT RUN, PLEASE WAIT...\n');
            
            tic
            % SAVE DATA
            save(Parameters.SYSTEM.savefile,'dat','-v7.3');
            % SAVE PARAMETERS
            saveparam=bci_ESI_Save('flags',flags,'signal',sigtype,'eeg',eeg,'trial',trial,...
                'bci',bci,'esi',esi,'control',control,'freq',freq,'performance',performance,'TOC',TOC);
            SaveFile=strcat(Parameters.SYSTEM.rundir,'\',Parameters.SYSTEM.runid,'Param.mat');
            save(SaveFile,'-struct','saveparam','-v7.3');
            
            fprintf(2,'\n     FINISHED - Time elapsed: %.2f seconds\n\n',toc);
            set(hObject,'backgroundcolor',[.94 .94 .94])

            %% Update run number in GUI (and for saving later)
            run=str2double(Parameters.SYSTEM.run);
            run=run+1;
            Length=size(num2str(run),2);
            if Length<2
                run=strcat('0',num2str(run));
            else
                run=num2str(run);
            end
            set(handles.run,'string',run)
            
            guidata(hObject,handles);
            set(handles.Stop,'userdata',0)
            clear buffer
            
%             figure; 
%             subplot(2,5,1); plot(TOC.SMR.eegpreprocess); title('eeg preprocessing'); set(gca,'ylim',[0 .03])
%             subplot(2,5,2); plot(TOC.SMR.storeeeg); title('store eeg'); set(gca,'ylim',[0 .03])
%             subplot(2,5,3); plot(TOC.SMR.freqprocess); title('frequency processing'); set(gca,'ylim',[0 .03])
%             subplot(2,5,4); plot(TOC.SMR.storepsd); title('store psd'); set(gca,'ylim',[0 .03])
%             subplot(2,5,5); plot(TOC.SMR.normdata); title('normalizing data'); set(gca,'ylim',[0 .03])
%             subplot(2,5,6); plot(TOC.SMR.ctrlraw); title('raw control signal'); set(gca,'ylim',[0 .03])
%             subplot(2,5,7); plot(TOC.SMR.buffer); title('buffer update'); set(gca,'ylim',[0 .03])
%             subplot(2,5,8); plot(TOC.SMR.ctrlprocess); title('process control signal'); set(gca,'ylim',[0 .03])
%             subplot(2,5,9); plot(TOC.SMR.ctrlplot); title('plot control signal'); set(gca,'ylim',[0 .03])
%             subplot(2,5,10); plot(TOC.SMR.stimulus); title('stimulus update'); set(gca,'ylim',[0 .03])
%              
%             figure; 
%             subplot(2,3,1); plot(TOC.SSVEP.eegpreprocess); title('eeg preprocessing'); set(gca,'ylim',[0 .03])
%             subplot(2,3,2); plot(TOC.SSVEP.classify); title('classify'); set(gca,'ylim',[0 .03])
%             subplot(2,3,3); plot(TOC.SSVEP.fftplot); title('fft plot'); set(gca,'ylim',[0 .03])
%             subplot(2,3,4); plot(TOC.SSVEP.storeeeg); title('store eeg'); set(gca,'ylim',[0 .03])
%             subplot(2,3,5); plot(TOC.SSVEP.storepsd); title('store psd'); set(gca,'ylim',[0 .03])
%             
%             figure;
%             subplot(1,2,1); plot(TOC.SMR.total);
%             subplot(1,2,2); plot(TOC.SSVEP.total);
            
            end
            
        end
        
	end
    
elseif isequal(get(handles.SetBCI,'userdata'),0)
    
    fprintf(2,'PARAMETERS HAVE NOT BEEN SET\n');
    set(hObject,'backgroundcolor','red','userdata',0)
    
end

    
    
    
    