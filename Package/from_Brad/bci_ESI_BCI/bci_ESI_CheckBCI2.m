function [hObject,handles]=bci_ESI_CheckBCI2(hObject,handles)

set(hObject,'userdata',1);

% Window (ms) of data to analyze at one time
analysiswindow=handles.SYSTEM.analysiswindow;
if isempty(analysiswindow)
    fprintf(2,'ANALYSIS WINDOW LENGTH NOT SET\n');
    set(hObject,'backgroundcolor','red','userdata',0);
end

% Window (ms) between new analysis windows
updatewindow=handles.SYSTEM.updatewindow;
if isempty(updatewindow)
    fprintf(2,'UPDATE WINDOW LENGTH NOT SET\n');
    set(hObject,'backgroundcolor','red','userdata',0);
end

freqtrans=handles.SYSTEM.freqtrans;
handles.BCI.param.freqtrans=freqtrans;
switch freqtrans
    case 1 % None
    case 2 % Morlet wavelet
    case {3,4} % Welch's PSD or DFT
        set(handles.noise,'value',2)
        fprintf(2,'\nNOISE ESTIMATION IN THE FREQUENCY DOMAIN REQUIRES A TIME-FREQUENCY REPRESENATION\n');
end

tempdomain=get(handles.tempdomain,'value');
switch tempdomain
    case 1 % None
    case 2 % Frequency
        TempDomainField='freq';
    case 3 % Time
        TempDomainField='time';
end
handles.BCI.param.tempdomainfield=TempDomainField;

% CHECK IF SYSTEM PARAMETERS HAVE BEEN SET
SetSystem=get(handles.SetSystem,'userdata');
if isequal(SetSystem,0)
    fprintf(2,'SYSTEM PARAMETERS HAVE NOT BEEN SET\n');
    set(hObject,'backgroundcolor','red','userdata',0)
end


spatdomainfield=handles.TRAINING.spatdomainfield;
switch spatdomainfield
    case 'Sensor'
        
%         numchan=size(handles.TRAINING.Sensor.Sparam.chanidxinclude,1);
        numchan=size(handles.SYSTEM.Electrodes.current.eLoc,2);
        labchan='ELECTRODES';
            
	case {'Source','SourceCluster'}
        
        SetESI=get(handles.SetESI,'userdata');
        if isequal(SetESI,0)
            fprintf(2,'ESI PARAMETERS HAVE NOT BEEN SET\n');
            set(hObject,'backgroundcolor','red','userdata',0)
        end

        if strcmp(spatdomainfield,'Source')
            clusterfield='NOCLUSTER';
            numchan=size(handles.ESI.vertidxinclude,2);
            labchan='DIPOLES';
        elseif strcmp(spatdomainfield,'SourceCluster')
            clusterfield='CLUSTER';
            numchan=size(handles.ESI.CLUSTER.clusters,2);
            labchan='CLUSTERS';
        end

        % CHECK FOR ESI NOISE-DEPENDENT PARAMETERS
        noise=handles.ESI.noisetype;
        switch noise
            case {1,2} % None selected or no noise modeling

                if isempty(handles.ESI.(clusterfield).inv.nomodel)
                    set(hObject,'backgroundcolor','red','userdata',0)
                    fprintf(2,'INVERSE OPERATOR (%s) DOES NOT EXIST, SET ESI PARAMETERS\n',clusterfield);
                end

            case {3,4} % Diagonal or full noise covariance

                if isempty(handles.ESI.noisecov.real)
                    set(hObject,'backgroundcolor','red','userdata',0)
                    fprintf(2,'REAL INVERSE OPERATOR (%s) DOES NOT EXIST, SET ESI PARAMETERS\n',clusterfield);
                elseif isempty(handles.ESI.noisecov.imag)
                    set(hObject,'backgroundcolor','red','userdata',0)
                    fprintf(2,'IMAGINARY INVERSE OPERATOR (%s) DOES NOT EXIST, SET ESI PARAMETERS\n',clusterfield);
                elseif isempty(handles.ESI.(clusterfield).inv.real)
                    set(hObject,'backgroundcolor','red','userdata',0)
                    fprintf(2,'REAL INVERSE OPERATOR (%s) DOES NOT EXIST, SET ESI PARAMETERS\n',clusterfield);
                elseif isempty(handles.ESI.(clusterfield).inv.imag)
                    set(hObject,'backgroundcolor','red','userdata',0)
                    fprintf(2,'IMAGINARY INVERSE OPERATOR (%s) DOES NOT EXIST, SET ESI PARAMETERS\n',clusterfield);
                end
        end
        
end
handles.BCI.param.spatdomainfield=spatdomainfield;

paradigm=get(handles.paradigm,'value');
set(handles.paradigm,'backgroundcolor','green')
if isequal(paradigm,1)
    set(hObject,'backgroundcolor','red','userdata',0)
    set(handles.paradigm,'backgroundcolor','red')
end

if isequal(get(hObject,'userdata'),1)            
    
    % DECIDE IF BOTH SMR AND SSVEP PARAMETERS NEED TO BE CHECKED
    switch paradigm
        
        case {2,3,4,5,8}
            sigtype={'SMR'};
        case 6
            sigtype={'SMR' 'SSVEP'};
        case 7
            sigtype={'SSVEP'};
    end
    
    
    userdata=zeros(3,1);
    for ii=1:size(sigtype,2)
        
        sigtypetmp=sigtype{ii};
        
        switch sigtypetmp
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %                        SMR BCI CHECK                        %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 'SMR'
    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % IDENTIFY NUMBER OF CONTROL DIMENSIONS AND THEIR DIRECTION
                % Cannot select BCI control locations unless other dimension info is complete
                userdata(1:3)=ones(3,1);

                dimensions={'1' '2' '3'};
                feattype=cell(1,3);
                for i=1:size(dimensions,2)

                    dimvar=strcat('bcidim',dimensions{i});
                    taskvar=strcat('bcitask',dimensions{i});
                    freqvar=strcat('bcifreq',dimensions{i});
                    featvar=strcat('bcifeat',dimensions{i});
                    locvar=strcat('bciloc',dimensions{i});
                    gainvar=strcat('gain',dimensions{i});
                    offsetvar=strcat('offset',dimensions{i});
                    scalevar=strcat('scale',dimensions{i});

                    dimval=get(handles.(dimvar),'value');
                    set(handles.(dimvar),'backgroundcolor','green')
                    if isequal(dimval,1)

                        fprintf(2,'\nDIMENSION %s: NOT SPECIFIED, IGNORING OTHER PARAMETERS\n',dimensions{i});
                        set(handles.(dimvar),'backgroundcolor','white');
                        [hObject,handles]=bci_ESI_ResetBCI(hObject,handles,i,'Reset');
                        userdata(i)=0;

                    else

                        % IDENTIFY TASK PAIRING
                        taskval=get(handles.(taskvar),'value');
                        set(handles.(taskvar),'backgroundcolor','green');
                        if isequal(taskval,1)

                            fprintf(2,'DIMENSION %s: TASKS NOT SPECIFIED\n',dimensions{i});
                            set(handles.(dimvar),'backgroundcolor','red')
                            set(handles.(taskvar),'backgroundcolor','red')
                            userdata(i)=0;

                        elseif isequal(taskval,2) % Custom

                            numtask=[];
                            combinations=[];
                            numcomb=[];
                            fileidx=[];

                        else % Combination

                            numtask=handles.TRAINING.(spatdomainfield).SMR.datainfo.numtask;
                            combinations=combnk(1:numtask,2);
                            numcomb=size(combinations,1);

                            if taskval-2>numcomb
                                taskoptions=cellstr(get(handles.(taskvar),'string'));
                                taskname=taskoptions{taskval};
                                taskval=str2double(regexp(taskname,'\d+','match'));
                                fileidx=1; % One-vs-rest
                            else
                                taskval=taskval-2;
                                fileidx=2; % One-vs-One
                            end

                        end

                        % IDENTIFY FREQUENCY FOR TASK ANALYSIS
                        freqval=get(handles.(freqvar),'value');
                        if isequal(freqval,1)
                            fprintf(2,'DIMENSION %s: FREQUENCY NOT SPECIFIED\n',dimensions{i});
                            set(handles.(dimvar),'backgroundcolor','red')
                            set(handles.(freqvar),'backgroundcolor','red')
                            userdata(i)=0;
                        else
                            set(handles.(freqvar),'backgroundcolor','green');
                            freqval=freqval-1;
                        end

                        % IDENTIFY SENSOR/SOURCE WEIGHT INFORMATION FOR TASK ANALYSIS
                        locval=get(handles.(locvar),'userdata');
                        set(handles.(locvar),'backgroundcolor','green');
                        if isempty(locval) || isequal(locval,0)
                            fprintf(2,'DIMENSION %s: LOCATION INFORMATION NOT SPECIFIED\n',dimensions{i});
                            set(handles.(dimvar),'backgroundcolor','red')
                            set(handles.(locvar),'backgroundcolor','red')
                            userdata(i)=0;
                        else

                            % IDENTIFY FEATURE TYPE TO BE USED
                            featval=get(handles.(featvar),'value');
                            featoptions=cellstr(get(handles.(featvar),'string'));
                            feattype{i}=featoptions{featval};
                            set(handles.(featvar),'backgroundcolor','green');

                            % CHECK IF FEATURE TYPE SELECTED
                            if isequal(featval,1)

                                fprintf(2,'DIMENSION %s: LOCATION INFORMATION NOT SPECIFIED\n',dimensions{i});
                                set(handles.(dimvar),'backgroundcolor','red')
                                set(handles.(featvar),'backgroundcolor','red')
                                userdata(i)=0;

                            elseif strcmp(feattype{i},'Custom')

                                custom=get(handles.(locvar),'userdata');
                                namenan=find(isnan(custom(:,1))==1);
                                weightnan=find(isnan(custom(:,2))==1);
                                commonnan=union(namenan,weightnan);
                                custom(commonnan,:)=[];

                                Widx=custom(:,1);
                                Wval=custom(:,2);
                                W=zeros(numchan,1);
                                W(Widx)=Wval;

                                handles.BCI.SMR.custom(i).file=[];
                                handles.BCI.SMR.custom(i).label=[];
                                handles.BCI.SMR.custom(i).freqval=freqval;
                                handles.BCI.SMR.custom(i).taskval=[];
                                handles.BCI.SMR.custom(i).Widx=Widx;
                                handles.BCI.SMR.custom(i).Wval=Wval;
                                handles.BCI.SMR.custom(i).W=W;

                                handles.BCI.SMR.custom(i).trialdatainit=[];
                                handles.BCI.SMR.custom(i).windowdatainit=[];
                                handles.BCI.SMR.custom(i).basedatainit=[];
                                handles.BCI.SMR.custom(i).runbase.data=[];
                                handles.BCI.SMR.custom(i).runbase.meandata=[];
                                handles.BCI.SMR.custom(i).runbase.stddata=[];


                            elseif strcmp(feattype{i},'Regress')

                                tmp=load(handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).regress.file{fileidx});
                                savevar=matlab.lang.makeValidName(strcat('Save',feattype{i},spatdomainfield));

                                Wtmp=get(handles.(locvar),'userdata');
                                Widx=Wtmp(:,1);
                                Wval=Wtmp(:,2);

                                if size(Widx,1)>numchan || max(Widx)>numchan
                                    fprintf(2,'REGRESSION %s EXCEED NUMBER OF CURRENT SYSTEM %s\n',labchan,labchan);
                                    set(handles.(dimvar),'backgroundcolor','red')
                                    set(handles.(locvar),'backgroundcolor','red')
                                    userdata(i)=0;
                                else
                                    W=zeros(numchan,1);
                                    W(Widx)=Wval;
                                end

                                handles.BCI.SMR.regress(i).file=handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).regress.file{fileidx};
                                handles.BCI.SMR.regress(i).label=tmp.(savevar).label;
                                handles.BCI.SMR.regress(i).freqval=freqval;
                                handles.BCI.SMR.regress(i).taskval=taskval;
                                handles.BCI.SMR.regress(i).Widx=Widx;
                                handles.BCI.SMR.regress(i).Wval=Wval;
                                handles.BCI.SMR.regress(i).W=W;

                                handles.BCI.SMR.regress(i).trialdatainit=tmp.(savevar).totdata(freqval).trialdata;
                                handles.BCI.SMR.regress(i).windowdatainit=tmp.(savevar).totdata(freqval).windata;
                                handles.BCI.SMR.regress(i).basedatainit={horzcat(tmp.(savevar).totdata(freqval).basedata{:})};
                                handles.BCI.SMR.regress(i).runbase.data=tmp.(savevar).totdata(freqval).runbasedata;
                                handles.BCI.SMR.regress(i).runbase.meandata=mean(tmp.(savevar).totdata(freqval).runbasedata,2);
                                handles.BCI.SMR.regress(i).runbase.stddata=std(tmp.(savevar).totdata(freqval).runbasedata,0,2);

                            % CHECK IF RLDA WEIGHT VECTOR SAME SIZE AS SENSORS    
                            elseif strcmp(feattype{i},'RLDA')

                                lambdaidx=get(handles.(locvar),'userdata');

                                tmp=load(handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).rlda.file{fileidx});
                                savevar=matlab.lang.makeValidName(strcat('Save',feattype{i},spatdomainfield));
                                W=tmp.(savevar).W(:,freqval,taskval,lambdaidx);
                                W0=tmp.(savevar).W0(freqval,taskval,lambdaidx);

                                if size(W,1)>numchan
                                    fprintf(2,'RLDA WEIGHT VECTOR SIZE EXCEEDS NUMBER OF CURRENT SYSTEM %s\n',labchan);
                                    set(handles.(dimvar),'backgroundcolor','red')
                                    set(handles.(locvar),'backgroundcolor','red')
                                    userdata(i)=0;
                                end

                                handles.BCI.SMR.rlda(i).file=handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).rlda.file{fileidx};
                                handles.BCI.SMR.rlda(i).label=tmp.(savevar).label;
                                handles.BCI.SMR.rlda(i).freqval=freqval;
                                handles.BCI.SMR.rlda(i).taskval=taskval;
                                handles.BCI.SMR.rlda(i).lambda=handles.TRAINING.(spatdomainfield).SMR.param.lambda(lambdaidx);
                                handles.BCI.SMR.rlda(i).W=W;
                                handles.BCI.SMR.rlda(i).W0=W0;

                                handles.BCI.SMR.rlda(i).trialdatainit=tmp.(savevar).totdata(freqval).trialdata;
                                handles.BCI.SMR.rlda(i).windowdatainit=tmp.(savevar).totdata(freqval).windata;
                                handles.BCI.SMR.rlda(i).basedatainit={horzcat(tmp.(savevar).totdata(freqval).basedata{:})};
                                handles.BCI.SMR.rlda(i).runbase.data=tmp.(savevar).totdata(freqval).runbasedata;
                                handles.BCI.SMR.rlda(i).runbase.meandata=mean(tmp.(savevar).totdata(freqval).runbasedata,2);
                                handles.BCI.SMR.rlda(i).runbase.stddata=std(tmp.(savevar).totdata(freqval).runbasedata,0,2);

                            elseif strcmp(feattype{i},'PCA')

                                tmp=load(handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).pca.file{fileidx});
                                savevar=matlab.lang.makeValidName(strcat('Save',feattype{i},spatdomainfield));

                                userdatatmp=get(handles.(locvar),'userdata');
                                PC=userdatatmp(2);
                                PCs=tmp.(savevar).U(:,1:PC,freqval,taskval);

                                lambda=userdatatmp(1);
                                pcaldaw=tmp.(savevar).W{freqval,taskval,PC}(:,lambda);
                                pcaldaw0=tmp.(savevar).W0{freqval,taskval,PC}(lambda);

                                if ~isequal(size(PCs,1),numchan)
                                    fprintf(2,'PCA WEIGHT VECTOR SIZE EXCEEDS NUMBER OF CURRENT SYSTEM %s\n',labchan);
                                    set(handles.(dimvar),'backgroundcolor','red')
                                    set(handles.(locvar),'backgroundcolor','red')
                                    userdata(i)=0;
                                end

                                handles.BCI.SMR.pca(i).file=handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).pca.file{fileidx};
                                handles.BCI.SMR.pca(i).label=tmp.(savevar).label;
                                handles.BCI.SMR.pca(i).freqval=freqval;
                                handles.BCI.SMR.pca(i).taskval=taskval;
                                handles.BCI.SMR.pca(i).pcidx=1:PC;
                                handles.BCI.SMR.pca(i).pcaw=PCs;
                                handles.BCI.SMR.pca(i).lambda=lambda;
                                handles.BCI.SMR.pca(i).pcarldaw=pcaldaw;
                                handles.BCI.SMR.pca(i).pcarldaw0=pcaldaw0;

                                handles.BCI.SMR.pca(i).trialdatainit=tmp.(savevar).totdata(freqval).trialdata;
                                handles.BCI.SMR.pca(i).windowdatainit=tmp.(savevar).totdata(freqval).windata;
                                handles.BCI.SMR.pca(i).basedatainit={horzcat(tmp.(savevar).totdata(freqval).basedata{:})};
                                handles.BCI.SMR.pca(i).runbase.data=tmp.(savevar).totdata(freqval).runbasedata;
                                handles.BCI.SMR.pca(i).runbase.meandata=mean(tmp.(savevar).totdata(freqval).runbasedata,2);
                                handles.BCI.SMR.pca(i).runbase.stddata=std(tmp.(savevar).totdata(freqval).runbasedata,0,2);

                            elseif strcmp(feattype{i},'FDA')

                                tmp=load(handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).fda.file{fileidx});
                                savevar=matlab.lang.makeValidName(strcat('Save',feattype{i},spatdomainfield));
                                W=tmp.(savevar).W(:,freqval,taskval);
                                DB=tmp.(savevar).DB(freqval,taskval);

                                if ~isequal(size(W,1),numchan)
                                    fprintf(2,'FDA WEIGHT VECTOR SIZE EXCEEDS NUMBER OF CURRENT SYSTEM %s\n',labchan);
                                    set(handles.(dimvar),'backgroundcolor','red')
                                    set(handles.(locvar),'backgroundcolor','red')
                                    userdata(i)=0;
                                end

                                handles.BCI.SMR.fda(i).file=handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).fda.file{fileidx};
                                handles.BCI.SMR.fda(i).label=tmp.(savevar).label;
                                handles.BCI.SMR.fda(i).freqval=freqval;
                                handles.BCI.SMR.fda(i).taskval=taskval;
                                handles.BCI.SMR.fda(i).W=W;
                                handles.BCI.SMR.fda(i).W0=DB;

                            elseif strcmp(feattype{i},'Mahal')

                                tmp=load(handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).mahal.file{fileidx});
                                savevar=matlab.lang.makeValidName(strcat('Save',feattype{i},spatdomainfield));
                                topfeat=1:get(handles.(locvar),'userdata');
                                topfeatidx=tmp.(savevar).BestMDidx(:,freqval,taskval);

                                if topfeatidx(topfeat)>numchan
                                    fprintf(2,'TOP MD FEATURE (%s) INDEX EXCEEDS NUMBER OF CURRENT SYSTEM %s\n',labchan,labchan);
                                    set(handles.(dimvar),'backgroundcolor','red');
                                    set(handles.(locvar),'backgroundcolor','red');
                                    userdata(i)=0;
                                end

                                handles.BCI.SMR.mahal(i).file=handles.TRAINING.(spatdomainfield).SMR.(TempDomainField).mahal.file{2};
                                handles.BCI.SMR.mahal(i).label=tmp.(savevar).label;
                                handles.BCI.SMR.mahal(i).freqval=freqval;
                                handles.BCI.SMR.mahal(i).taskval=taskval;
                                handles.BCI.SMR.mahal(i).topfeat=topfeat;
                                handles.BCI.SMR.mahal(i).topfeatidx=topfeatidx(topfeat);

                                handles.BCI.SMR.mahal(i).trialdatainit=tmp.(savevar).totdata(freqval).trialdata;
                                handles.BCI.SMR.mahal(i).windowdatainit=tmp.(savevar).totdata(freqval).windata;
                                handles.BCI.SMR.mahal(i).basedatainit={horzcat(tmp.(savevar).totdata(freqval).basedata{:})};
                                handles.BCI.SMR.mahal(i).runbase.data=tmp.(savevar).totdata(freqval).runbasedata;
                                handles.BCI.SMR.mahal(i).runbase.meandata=mean(tmp.(savevar).totdata(freqval).runbasedata,2);
                                handles.BCI.SMR.mahal(i).runbase.stddata=std(tmp.(savevar).totdata(freqval).runbasedata,0,2);

                            end  

                        end

                        gainval=str2double(get(handles.(gainvar),'string'));
                        if ~isnumeric(gainval)
                            fprintf(2,'DIMENSION %s: INVALID GAIN VALUE\n',dimensions{i});
                            set(handles.(dimvar),'backgroundcolor','red')
                            set(handles.(gainvar),'backgroundcolor','red')
                            userdata(i)=0;
                        else
                            set(handles.(gainvar),'backgroundcolor','green')
                        end

                        offsetval=str2double(get(handles.(offsetvar),'string'));
                        if ~isnumeric(offsetval)
                            fprintf(2,'DIMENSION %s: INVALID OFFSET VALUE\n',dimensions{i});
                            set(handles.(dimvar),'backgroundcolor','red');
                            set(handles.(offsetvar),'backgroundcolor','red')
                            userdata(i)=0;
                        else
                            set(handles.(offsetvar),'backgroundcolor','green')
                        end

                        scaleval=str2double(get(handles.(scalevar),'string'));
                        if ~isnumeric(scaleval)
                            fprintf(2,'DIMENSION %s: INVALID SCALE VALUE\n',dimensions{i});
                            set(handles.(dimvar),'backgroundcolor','red');
                            set(handles.(scalevar),'backgroundcolor','red');
                            userdata(i)=0;
                        else
                            set(handles.(scalevar),'backgroundcolor','green')
                        end

                    end
                end
                
                
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %                       SSVEP BCI CHECK                       %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
            case 'SSVEP'
                
                ssvepon=get(handles.ssvepon,'value'); % CHECK THAT SSVEP VS SMR CLASSIFIER HAS BEEN TRAINED
                if isequal(ssvepon,1)
        
                    userdata(end+1)=1;

                    decisionwindow=handles.SSVEP.decisionwindow;
                    if isempty(decisionwindow)
                        fprintf(2,'SSVEP DECISION WINDOW NOT DEFINED\n');
                        userdata(end)=0;
                    end

                    % IDENTIFY TASK TYPE TO BE USED
                    numtask=handles.TRAINING.(spatdomainfield).SSVEP.datainfo.numtask;
                    combinations=combnk(1:numtask,2);
                    numcomb=size(combinations,1);

                    ssveptaskval=get(handles.ssveptask,'value');
                    set(handles.ssveptask,'backgroundcolor','green')
                    if isequal(ssveptaskval,1)

                        fprintf(2,'SSVEP TASK OPTIONS NOT SET\n');
                        set(handles.ssveptask,'backgroundcolor','red')
                        userdata(end)=0;

                    else

                        taskoptions=cellstr(get(handles.ssveptask,'string'));
                        fileidx=2;
                        if ssveptaskval<size(taskoptions,1)
                            ssveptaskname=taskoptions{ssveptaskval};
                            ssveptaskval=ssveptaskval-1;
                            ssveptaskidx=ssveptaskval;
                        elseif isequal(ssveptaskval,size(taskoptions,1))
                            ssveptaskname=taskoptions{ssveptaskval};
                            ssveptaskval=ssveptaskval-1;
                            ssveptaskidx=1:numcomb;
                        end

                    end

                    % IDENTIFY FEATURE TYPE TO BE USED
                    ssvepfeatval=get(handles.ssvepfeat,'value');
                    featoptions=cellstr(get(handles.ssvepfeat,'string'));
                    ssvepfeattype=featoptions{ssvepfeatval};
                    set(handles.ssvepfeat,'backgroundcolor','green');

                    % CHECK IF FEATURE TYPE SELECTED
                    if isequal(ssvepfeatval,1)

                        fprintf(2,'SSVEP FEATURE OPTIONS NOT SET\n');
                        set(handles.ssvepfeat,'backgroundcolor','red')
                        userdata(end)=0;

                    elseif ~isequal(ssvepfeatval,1) && ~isequal(ssveptaskval,1)

                        switch ssvepfeattype
                            
                            case 'CCA'
                                
                                handles.BCI.SSVEP.cca.file=[];
                                handles.BCI.SSVEP.cca.label=ssveptaskname;
                                freqvaltmp=str2double(handles.TRAINING.(spatdomainfield).SSVEP.param.freq);
                                freqvaltmp(isnan(freqvaltmp))=[];
                                handles.BCI.SSVEP.cca.freqval=freqvaltmp;
                                handles.BCI.SSVEP.cca.taskval=ssveptaskval;

                                handles.BCI.SSVEP.cca.trialdatainit=[];
                                handles.BCI.SSVEP.cca.windowdatainit=[];
                                handles.BCI.SSVEP.cca.basedatainit=[];
                                handles.BCI.SSVEP.cca.runbase.data=[];
                                handles.BCI.SSVEP.cca.runbase.meandata=[];
                                handles.BCI.SSVEP.cca.runbase.stddata=[];
                                
                                
                            case 'Regress'

                            case 'RLDA'

                                tmp=load(handles.TRAINING.(spatdomainfield).SSVEP.(TempDomainField).rlda.file{fileidx});
                                savevar=matlab.lang.makeValidName(strcat('Save',ssvepfeattype,spatdomainfield));
                                W=tmp.(savevar).W(:,ssveptaskidx,end);
                                W0=tmp.(savevar).W0(ssveptaskidx,end);

%                                 if size(W,1)>numchan
%                                     fprintf(2,'SSVEP RLDA WEIGHT VECTOR SIZE EXCEEDS NUMBER OF CURRENT SYSTEM %s\n',labchan);
%                                     set(handles.(dimvar),'backgroundcolor','red')
%                                     set(handles.(locvar),'backgroundcolor','red')
%                                     userdata(i)=0;
%                                 end

                                handles.BCI.SSVEP.rlda.file=handles.TRAINING.(spatdomainfield).SSVEP.(TempDomainField).rlda.file{fileidx};
                                if isequal(ssveptaskval,4)
                                    handles.BCI.SSVEP.rlda.label='One-vs-One Vote';
                                else
                                    handles.BCI.SSVEP.rlda.label=tmp.(savevar).label;
                                end
                                handles.BCI.SSVEP.rlda.freqval=[];
                                handles.BCI.SSVEP.rlda.taskval=ssveptaskval;
                                handles.BCI.SSVEP.rlda.lambda=handles.TRAINING.(spatdomainfield).SSVEP.param.lambda(end);
                                handles.BCI.SSVEP.rlda.W=W;
                                handles.BCI.SSVEP.rlda.W0=W0;

                                handles.BCI.SSVEP.rlda.trialdatainit={tmp.(savevar).totdata(ssveptaskidx).trialdata};
                                handles.BCI.SSVEP.rlda.windowdatainit={tmp.(savevar).totdata(ssveptaskidx).windata};
                                handles.BCI.SSVEP.rlda.basedatainit=[];
                                handles.BCI.SSVEP.rlda.runbase.data=[];
                                handles.BCI.SSVEP.rlda.runbase.meandata=[];
                                handles.BCI.SSVEP.rlda.runbase.stddata=[];

                            case 'PCA'

                            case 'FDA'

                            case 'MI'

                        end

                    end

                end
                
        end
        
    end

end

if exist('userdata','var')

    set(hObject,'backgroundcolor','green')
    if ismember('SMR',sigtype) && isequal(sum(userdata(1:3)),0)
        set(hObject,'backgroundcolor','red')
    end
    
    if ismember('SSVEP',sigtype) && isequal(size(userdata,2),4) && isequal(userdata(4),0)
        set(hObject,'backgroundcolor','red')
    end
    
    set(hObject,'userdata',userdata);
else
    set(hObject,'backgroundcolor','red')
end






