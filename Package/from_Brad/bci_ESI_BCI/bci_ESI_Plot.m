function [plotting,varargout]=bci_ESI_Plot(action,plotting,varargin)


nargs=nargin;
if nargs<2
else
    
    %% EXTRACT INPUT ARGS
    if ~(round((nargs-2)/2) == (nargs-2)/2)
        error('Odd number of input arguments??')
    end
    
    str=cell(0); val=cell(0);
    for i=1:2:length(varargin)
        str{end+1}=varargin{i};
        val{end+1}=varargin{i+1};
    end
    
    if strcmp(action,'initiate')
    
        %% INITIATE PLOTS
        if ~ismember('handles',str)
            error('Need handles to initiate plots\n');
        else
            handles=val{strcmp(str,'handles')};
        end
        
        if ~ismember('signal',str)
            error('Need signal type to initiate plots\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        if ismember('flags',str)
            flags=val{strcmp(str,'flags')};
            if isempty(flags)
                flags=struct;
            else
                v2struct(flags)
            end
        else
            flags=struct;
        end
        
        if isempty(plotting)
            plotting=struct;
        end
        
        flags.paradigm=get(handles.paradigm,'value');
        flags.vizelec=get(handles.vizelec,'value');
        flags.vizsource=get(handles.vizsource,'value');
        flags.lrvizsource=get(handles.lrvizsource,'value');
        flags.dispcs=get(handles.dispcs,'value');
        flags.spatdomainfield=handles.TRAINING.spatdomainfield;
        v2struct(flags)
        
        if ismember('SMR',signal) || strcmp('SMR',signal)
            switch spatdomainfield

                case 'Sensor'

                    % Electrode visualization
                    if isequal(vizelec,1)

                        if ismember(paradigm,6:7)
                            set(handles.Axis2Label,'string','Scalp Activity');
                            axes(handles.axes2);
                        else
                            set(handles.Axis3Label,'string','Scalp Activity');
                            axes(handles.axes3);
                        end

                        SensorX=handles.SYSTEM.Electrodes.current.plotX(handles.SYSTEM.Electrodes.chanidxinclude);
                        SensorY=handles.SYSTEM.Electrodes.current.plotY(handles.SYSTEM.Electrodes.chanidxinclude);
                        plotting.Sensor=scatter(SensorX,SensorY,75,...
                            ones(size(handles.SYSTEM.Electrodes.current.eLoc,2),1),'filled');
                        view(-90,90); set(gca,'color',[.94 .94 .94]); axis off
                    end

                case {'Source','SourceCluster'}

                    % Electrode visualization
                    if isequal(vizelec,1)

                        if isequal(vizsource,1) || isequal(lrvizsource,1)
                            set(handles.Axis2Label,'string','Scalp Activity');
                            axes(handles.axes2);
                        else
                            set(handles.Axis3Label,'string','Scalp Activity');
                            axes(handles.axes3);
                        end

                        SensorX=handles.SYSTEM.Electrodes.current.plotX(handles.SYSTEM.Electrodes.chanidxinclude);
                        SensorY=handles.SYSTEM.Electrodes.current.plotY(handles.SYSTEM.Electrodes.chanidxinclude);
                        plotting.Sensor=scatter(SensorX,SensorY,75,...
                            ones(size(handles.SYSTEM.Electrodes.current.eLoc,2),1),'filled');
                        view(-90,90); set(gca,'color',[.94 .94 .94]); axis off
                    end

                    % Low resolution source visualization
                    if isequal(lrvizsource,1) 
                        SourceFaces=handles.ESI.cortexlr.Faces;
                        SourceVertices=handles.ESI.cortexlr.Vertices;
                        SourceX=SourceVertices(:,1);
                        SourceY=SourceVertices(:,2);
                        SourceZ=SourceVertices(:,3);
                        NN=handles.ESI.lowresinterp;
                    % Full resolution source visualization
                    else
                        SourceFaces=handles.ESI.cortex.Faces;
                        SourceVertices=handles.ESI.cortex.Vertices;
                        SourceX=SourceVertices(:,1);
                        SourceY=SourceVertices(:,2);
                        SourceZ=SourceVertices(:,3);
                    end

                    if isequal(vizsource,1) || isequal(lrvizsource,1)
                        set(handles.Axis3Label,'string','Cortical Activity');
                        axes(handles.axes3);
                        plotting.Source=trisurf(SourceFaces,SourceX,SourceY,SourceZ,...
                            zeros(1,numvert),'FaceColor','interp','EdgeColor','None',...
                            'FaceLighting','gouraud');
                        light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
                        axis equal; axis off; view(-90,90)
                        cmap=[repmat([.85 .85 .85],[3,1]);jet(256)]; colormap(cmap)
                    end

            end

            % CONTROL SIGNAL DISPLAY
            if isequal(dispcs,1)
                set(handles.Axis1Label,'string','Control Signal');
                axes(handles.axes1);
                plotting.CS(1,1)=plot(1:30,zeros(1,30),'k-.'); hold on
                plotting.CS(1,2)=plot(1:30,zeros(1,30),'r');
                plotting.CS(2,1)=plot(1:30,10+zeros(1,30),'k-.'); hold on
                plotting.CS(2,2)=plot(1:30,10+zeros(1,30),'g');
                plotting.CS(3,1)=plot(1:30,20+zeros(1,30),'k-.'); hold on
                plotting.CS(3,2)=plot(1:30,20+zeros(1,30),'b');
                hold off; axis off; ylim([-6 30])
            end
            
        end
        
        if ismember('SSVEP',signal) || strcmp('SSVEP',signal)
            
            if ismember(paradigm,6:7)

                flags.fftxplot=handles.BCI.SSVEP.fftx;
                flags.fftxidx=handles.BCI.SSVEP.fftxidx;
                flags.targetfftx=handles.BCI.SSVEP.targetfftx;
                flags.targetsssvep=handles.BCI.SSVEP.control.targets;
                flags.targetfreqssvep=handles.BCI.SSVEP.control.targetfreq;
                flags.taskorderssvep=handles.BCI.SSVEP.control.taskorder;
                v2struct(flags)
                
                axes(handles.axes3);
                set(handles.Axis3Label,'string','Average FFT');
                plotting.FFT=plot(fftxplot,zeros(1,size(fftxplot,2)));
                axis on; set(gca,'color',[.94 .94 .94]); hold on
                axis([handles.SYSTEM.lowcutoff handles.SYSTEM.highcutoff 0 1.5]);
                set(handles.axes3,'xtick',handles.SYSTEM.lowcutoff:2:handles.SYSTEM.highcutoff)

                targidx=str2double(taskorderssvep(1));
                plotting.targfreq.H1=plot(fftxplot(targetfftx(targidx))*ones(1,2),[0 2],'color',[1 .6 0],'linewidth',1.5);
                plotting.targfreq.H2=plot(2*fftxplot(targetfftx(targidx))*ones(1,2),[0 2],'color',[1 .6 0],'linewidth',1.5);
                set(handles.axes3,'xminorgrid','on','yminorgrid','on');
            end
            
        end
        
        varargout{1}=flags;
    

    elseif strcmp(action,'update')

        if ~ismember('flags',str)
            error('Need flags to update plots\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)
        
        for j=1:size(str,2)
            strtmp=str{j};
            valtmp=val{j};

            switch strtmp
                case 'Sensor'

                    if isequal(vizelec,1)
                        set(plotting.Sensor,'cdata',valtmp);
                    end

                case 'Source'

                    if isequal(vizsource,1) ||isequal(lrvizsource,1)
                        set(plotting.Source,'cdata',valtmp);
                    end

                case 'CS'

                    if isequal(dispcs,1)
                        set(plotting.CS(1,1),'XData',1:size(valtmp,2),'YData',...
                            zeros(1,size(valtmp,2)));
                        set(plotting.CS(1,2),'XData',1:size(valtmp,2),'YData',...
                            valtmp(1,:),'color','r');

                        set(plotting.CS(2,1),'XData',1:size(valtmp,2),'YData',...
                            12+zeros(1,size(valtmp,2)));
                        set(plotting.CS(2,2),'XData',1:size(valtmp,2),'YData',...
                            12+valtmp(2,:),'color','g');

                        set(plotting.CS(3,1),'XData',1:size(valtmp,2),'YData',...
                            24+zeros(1,size(valtmp,2)));
                        set(plotting.CS(3,2),'XData',1:size(valtmp,2),'YData',...
                            24+valtmp(3,:),'color','b');
                    end

                case 'FFT'

                    if ismember(paradigm,6:7)
                        set(plotting.FFT,'YData',valtmp);
                    end
                    
                case 'targetfreq'
                    
                    if ismember(paradigm,6:7)
                        stimidx=taskorderssvep{valtmp};
                        stimidx=find(strcmp(targetsssvep,stimidx));
                        set(plotting.targfreq.H1,'Xdata',fftxplot(targetfftx(stimidx))*ones(1,2));    
                        set(plotting.targfreq.H2,'Xdata',2*fftxplot(targetfftx(stimidx))*ones(1,2));
                    end
                    
            end
        end
        
    end
end

               
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

