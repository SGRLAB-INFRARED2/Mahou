classdef Method < handle
    
    %
    %    here are the properties that every data acq method must define
    
    %the public properties
    properties (Abstract, SetAccess = protected)
        %the final spectrum which will be saved to disk
        result;
    end
    
    properties
        %the background which is subtracted from each signal after sorting. The
        %background must match the structure of the data in <sorted>.
        background = struct('data',[],'std',[],'freq',[]);
        
        
    end
    
    %the properties not visible outside the class or subclass
    properties (Abstract, SetAccess = protected)
        %the raw data block(s) straight from ADC(s) (the FPAS for example).
        %This will probably be the same for most methods.
        sample;
        
        %the sorted data assigned to roles (signal / ref, pumped / unpumped) but still one value per laser
        %shot. This will be different for every method.
        sorted;
        
        %The chopper, IR_inteferogram, HeNe x, HeNe y, etc
        aux;
        
        %average each signal and calculate noise for each signal
        signal;
        nSignals;
        
        
        %a struct of all the parameters describing the data acquisition event
        PARAMS;
        
        %a struct array of all the sources of data used by the method
        %a name and a function handle? E.g. source.name = 'MCT-array',
        %source.fxn = @FPAS_Sample (for real data) or
        % source.fxn = @Simulate_FPAS (for fake data)
        source;
        
        %the frequency axis (eventually comes from the spectrometer)
        freq;
        
        % Number of current scan
        i_scan;
        
    end
    
    %here are the properties that all methods share.
    
    properties (GetAccess = public)
        nPixelsPerArray = 32;
        nArrays = 2;
        % NEW
        laserPD = struct('raw',[],'bkgd',945,'signal',[],'noise',0,'ind_laser',78);
        %hard coded the background value of the photodiode + gated integrator
        %dark signal for now as a starting point.
        multiChanRefMatrix = eye(32);
    end
    
    %booleans to communicate about the state of a scan. When
    properties
        ScanIsRunning = false;
        ScanIsStopping = false;
        
        %handles to the plots so we can refresh them
        hPlotMain;
        hPlotRaw;
        hPlotLaserOutput;
        
        hMainAxes;
        hParamsPanel;
        hRawDataAxes;
        hLaserOutputAxes;
        hDiagnosticsPanel;
        handles; %should be able to do this better but for now try this
        
        noiseGain = 10^5;
        
        saveData = false;
    end
    
    %These are all calculated from other data, and are not stored
    %every specific method must define a get method (no set method needed)
    properties (Abstract,Dependent, SetAccess = protected)
        Raw_data;
        %Diagnostic_data;
        Noise;
    end
    
    %
    %     here are the methods that every data acq method must define
    %
    methods (Abstract) %public
        
    end
    
    properties %(SetAccess = private)
        % FileSystem, how we record the data
        fileSystem = FileSystem.getInstance;
    end
    
    methods (Abstract, Access = protected)
        %initialize sample, signal, background, and result. Called by the class
        %constructor.
        InitializeData(obj);
        
        %read the spectrometer and set the x-axis of the plots
        InitializeFreqAxis(obj);
        
        %set up the plot for the main output. Called by the class constructor.
        InitializeMainPlot(obj,hMainAxes);
        
        %set up the uitable for external channels
        InitializeUITable(obj);
        
        %set up the ADC task(s)
        InitializeTask(obj);
        
        %initialize the data acquisition event and move motors to their
        %starting positions
        ScanInitialize(obj);
        
        %start first sample. This code is executed before the scan loop starts
        ScanFirst(obj);
        
        %This code is executed inside the scan loop. This is different from
        %ScanFirst for efficiency. It allows us to read data from ScanFirst
        %(making sure it is finished), then immediately start the second, and
        %process the first while the second is acquiring. It is also the place
        %to put code to save temporary files
        ScanMiddle(obj);
        
        %This code executes after the scan loop. It should read but not start a
        %new scan. It should save the final results.
        ScanLast(obj);
        
        %move the motors back to their zero positions. Clear the ADC tasks.
        ScanCleanup(obj);
        
        %the entire
        ProcessSampleSort(obj);
        
        ProcessSampleAvg(obj);
        
        ProcessSampleSubtBack(obj);
        
        ProcessSampleResult(obj);
        
        ProcessSampleNoise(obj);
        
        ProcessSampleBackAvg(obj);
    end
    
    %
    %     here are the methods that all data acq methods share (not
    %     abstract)
    %
    %the public
    methods
        
        function LoadBackground(obj)
            name = 'background';
            tsize = size(obj.(name));
            d = Defaults(obj);
            d.LoadDefaults(name);
        end
        
        function SaveBackground(obj)
            name = 'background';
            d = Defaults(obj);
            d.SaveDefaults(name);
        end
        
%         function LoadMultiChanRefMatrix(obj)
%             name = 'multiChanRefMatrix';
%             d = Defaults(obj);
%             d.LoadDefaults(name);
%         end
%         
%         function SaveMultiChanRefMatrix(obj)
%             name = 'multiChanRefMatrix';
%             d = Defaults(obj);
%             d.SaveDefaults(name);
%         end
        
        function ScanStop(obj)
            obj.ScanIsStopping = true;
        end
        
        %untested -- probably screwed up
        function InitializeRawDataPlot(obj)
            
            n_plots = size(obj.Raw_data,1);
            hold(obj.hRawDataAxes, 'off');
            obj.hPlotRaw = zeros(1,n_plots);
            for i = 1:n_plots
                % The Raw Data plot is the same for every method.
                obj.hPlotRaw(i) = plot(obj.hRawDataAxes, 1:obj.nPixelsPerArray, obj.Raw_data(i,:));
                set(obj.hPlotRaw(i),'Color',[mod(1-(i-1)*0.1,1) 0 0]);
                set(obj.hPlotRaw(i),'YDataSource',['obj.Raw_data(',num2str(i),',:)']);
                hold(obj.hRawDataAxes, 'on');
            end
            
            %plot noise
            i=i+1;
            obj.hPlotRaw(i) = plot(obj.hRawDataAxes, 1:obj.nPixelsPerArray, obj.Noise.*obj.noiseGain, 'b');
            set(obj.hPlotRaw(i),'YDataSource','obj.Noise.*obj.noiseGain');
            set(obj.hRawDataAxes,'XLim',[1 obj.nPixelsPerArray],'Ylim',[0 2^16*1.05]);
            
            %       % The Raw Data plot is the same for every method.
            %       hRawPlots(1) = plot(hAxesRawData, obj.freq, obj.Raw_data(1,:), 'r');
            %       set(hRawPlots(1),'XDataSource', 'obj.freq', 'YDataSource','obj.Raw_data(1,:)');
            %       hold(handles.axesRawData, 'on');
            %       hRawPlots(2) = plot(hAxesRawData, obj.freq, obj.Raw_data(2,:), 'g');
            %       set(hRawPlots(2),'XDataSource', 'obj.freq', 'YDataSource','obj.Raw_data(2,:)');
            %       hRawPlots(3) = plot(hAxesRawData, obj.freq, obj.Noise(1, :), 'b');
            %       set(hRawPlots(3),'XDataSource', 'obj.freq', 'YDataSource','obj.Noise');
            %       hold(hAxesRawData, 'off');
            %       set(hAxesRawData, 'XLim', [obj.freq(1) obj.freq(end)]);
        end
        
        function InitializeLaserOutputPlot(obj)
            obj.hPlotLaserOutput = 0;
            obj.laserPD.raw = 30000*ones(1, obj.PARAMS.nShots);
            obj.hPlotLaserOutput = plot(obj.hLaserOutputAxes, 1:obj.PARAMS.nShots, obj.laserPD.raw);
            set(obj.hPlotLaserOutput,'Color','g');
            set(obj.hPlotLaserOutput,'XDataSource','1:obj.PARAMS.nShots')
            set(obj.hPlotLaserOutput,'YDataSource','obj.laserPD.raw');
            set(obj.hLaserOutputAxes, 'YLim', [0 2^16*1.05]);
            set(obj.hLaserOutputAxes, 'XLimSpec', 'tight');
        end
        
        %untested
        function Initialize(obj)
            whichMethod = obj.handles.popupMethods;
            methodString = whichMethod.String{whichMethod.Value};
            methodString = strrep(methodString, 'Method_', '');
            methodString = strrep(methodString, '_', ' ');
            methodString = strrep(methodString, '.m', '');
            fprintf(1, '\nInitializing Method: %s ... \n', methodString)
            
            InitializeFreqAxis(obj);
            
            InitializeParameters(obj);
            
            ReadParameters(obj);
            
            InitializeData(obj);
            
            InitializeMainPlot(obj);
            
            InitializeRawDataPlot(obj);
            
            InitializeLaserOutputPlot(obj);
            
            InitializeDiagnostics(obj);
            
            InitializeUITable(obj);
            
            fprintf(1, 'Done.\n')
        end
        
        %untested
        function InitializeDiagnostics(obj)
            %setup the panel for this method
            set(obj.handles.textNoise,'String',sprintf('%5.3f',mean(obj.Noise)));
            set(obj.handles.textLaserNoise ,'String',sprintf('%5.3f',obj.laserPD.noise)); %new
        end
        
        %untested
        function UpdateDiagnostics(obj)
            %mean noise in mOD
            set(obj.handles.textNoise,'String',sprintf('%5.3f',mean(obj.Noise)));
            set(obj.handles.textLaserNoise ,'String',sprintf('%5.3f',100.*obj.laserPD.noise));
            %new
            %noise in %
        end
        
        %untested (should work for all axes that have XDataSource and
        %YDataSource properly configured
        function RefreshPlots(obj,hPlots,hAutoScaleToggle)
            refreshdata(hPlots, 'caller');
            if isa(hPlots, 'matlab.graphics.chart.primitive.Contour')
                set(hPlots, 'LevelList', linspace(-max(obj.signal.data(:,:,1), [], 'all'),...
                    max(obj.signal.data(:,:,1), [], 'all'), 12));
            end
        end
        
        %untested
        function RefreshDiagnostics(obj,hDiagnosticsUI)
            %set each text box to needed value
        end
        
        %untested
        %By defining this as ~Abstract, all data acquisition methods must
        %follow this essential recipe for acquiring their data. Each individual
        %method customizes the behavior by defining specific actions for these
        %abstract operations
        function Scan(obj)
            
            obj.InitializeMainPlot;
            
            obj.ScanIsRunning = true;
            
            ScanInitialize(obj);
            
            obj.i_scan = 1;
            
            set(obj.handles.textScanNumber,'String',sprintf('Scan # %i',obj.i_scan));
            
            drawnow;
            
            ScanFirst(obj);
            
            while obj.i_scan ~= obj.PARAMS.nScans && obj.ScanIsStopping == false
                
                ScanMiddle(obj);
                
                SaveTmpResult(obj);
                
                obj.i_scan = obj.i_scan + 1;
                
                set(obj.handles.textScanNumber,'String',sprintf('Scan # %i',obj.i_scan));
                
                drawnow;
                
            end
            
            set(obj.handles.textScanNumber,'String',sprintf('Scan # %i',obj.i_scan));
            
            drawnow;
            
            obj.ScanLast;
            
            SaveResult(obj);
            
            obj.ScanCleanup;
            
            obj.ScanIsRunning = false;
            
            if ~contains(class(obj), 'Multi_Time') || ~contains(class(obj), 'Polarization')
                obj.ScanIsStopping = false;
            end
            
        end
        
        function BackgroundReset(obj)
            obj.background.data = zeros(size(obj.background.data));
            obj.background.std = zeros(size(obj.background.std));
            obj.laserPD.bkgd = 945; %zeros(size(obj.laserPD.bkgd));
            obj.SaveBackground;
        end
        
        %acquire a background (might need to be public)
        function BackgroundAcquire(obj)
            obj.ScanIsRunning = true;
            obj.ScanIsStopping = false;
            obj.BackgroundReset;
            obj.ReadParameters;
            obj.InitializeTask;
            
            for ni_scan = 1:10            % @@@ is there some reason we can't assign obj.i_scan directly?
                obj.i_scan = ni_scan;
                set(obj.handles.textScanNumber,'String',sprintf('Scan # %i',obj.i_scan));
                drawnow;
                
                obj.source.sampler.Start;
                obj.source.gate.OpenClockGate;
                obj.sample = obj.source.sampler.Read;
                obj.source.gate.CloseClockGate;
                
                obj.ProcessSampleSort;
                obj.ProcessSampleAvg;
                obj.ProcessSampleBackAvg;
                
                obj.ProcessLaserBackAvg;
                
            end
            obj.source.sampler.ClearTask;
            obj.SaveBackground;
            obj.ScanIsRunning = false;
            
        end
        
        function BlankShotReset(obj)
            obj.multiChanRefMatrix = eye(32);
%             obj.SaveMultiChanRefMatrix;
        end
        
        function BlankShotAcquire(obj)
            obj.ScanIsRunning = true;
            obj.ScanIsStopping = false;
            
            obj.ReadParameters;
            
            init_nShots = obj.PARAMS.nShots;
            init_pos = obj.source.motors{2}.GetPosition;
            
            obj.PARAMS.nShots = 10000;
            set(obj.handles.editnShots,'String',num2str(10000));
            
            obj.source.motors{2}.MoveTo(-10000,6000,0,0);
            
%             obj.ReadParameters;
            
            obj.InitializeData;
            
            obj.InitializeTask;
            
            obj.source.sampler.Start;
            obj.source.gate.OpenClockGate;
            obj.sample = obj.source.sampler.Read;
            obj.source.gate.CloseClockGate;
            obj.source.sampler.ClearTask;
            
            obj.ProcessBlankShots;
            
            set(obj.handles.editnShots,'String',num2str(init_nShots));
            obj.PARAMS.nShots = init_nShots;
            
%             obj.SaveMultiChanRefMatrix;
            obj.ScanIsRunning = false;
            
            obj.source.motors{2}.MoveTo(init_pos,6000,0,0);
            
        end
        
        function ProcessBlankShots(obj)
            Ref = obj.sample(1:32,:);
            LO = obj.sample(33:64,:);
            
            dRef = diff(Ref, 1, 2);
            dLO = diff(LO, 1, 2);
            
            B1 = zeros(32, 32, length(dRef));
            B2 = zeros(32, 32, length(dRef));
            
            for ii = 1:length(dRef)
                B1(:,:,ii) = dRef(:,ii)*dRef(:,ii)';
                B2(:,:,ii) = dRef(:,ii)*dLO(:,ii)';
            end
            
            B1_mean = mean(B1, 3);
            B2_mean = mean(B2, 3);
            
            obj.multiChanRefMatrix = B1_mean^(-1)*B2_mean;
        end
        
        %save the current result to a MAT file for storage.
        function SaveResult(obj)
            if obj.saveData
                obj.fileSystem.Save(obj.result);
            end
        end
        
        %save intermediate results to a temp folder
        function SaveTmpResult(obj)
            if obj.saveData
                obj.fileSystem.SaveTemp(obj.result, obj.i_scan);
            end
        end
        
        
    end
    
    %private methods
    methods (Access = protected)
        %populate a pane with the appropriate UI elements and default values
        %consistent with the PARAMS for this method. Should be called by the
        %class constructor.
        function InitializeParameters(obj)
            fprintf(1, 'Initializing parameter window ... ');
            
            %get a cell array of the names of the parameters
            names = fieldnames(obj.PARAMS);
            %how many parameters are there
            n_params = length(names);
            
            temp = get(obj.hParamsPanel,'Position');
            y_origin = temp(4); %height of Panel
            
            x_pos = 2;
            y_pos = -1.5;
            width = 14; %35;
            %   height = 1.83;%25;
            height = 1.54;%21;
            x_offset = 3;
            %    y_offset = 0.25;
            y_offset = 0.21;
            
            %loop over parameters setting a text box and an edit box for each
            for i = 1:n_params
                
                %make the text box
                uicontrol('Parent', obj.hParamsPanel,...
                    'Style','text','Tag',['text' names{i}],...
                    'String',names{i},...
                    'Units','Characters',...
                    'Position',[x_pos y_pos+y_origin-i*(y_offset+height) width height])
                
                %make the edit box
                uicontrol('Parent', obj.hParamsPanel,...
                    'Style','edit','Tag',['edit' names{i}],...
                    'String',obj.PARAMS.(names{i}),... %this is a dynamic field name structure.(expression) where expression returns a string
                    'Units','Characters',...
                    'Position',[x_pos+x_offset+width y_pos+y_origin-i*(y_offset+height) width height])
                
            end
            
            %update the handles  -- @@@ Seems to be returning the wrong handle set
            %sometimes.
            obj.handles = guihandles(obj.handles.figure1);
            fprintf(1, 'Done.\n')
        end
        
        function ReadParameters(obj)
            
            field = fieldnames(obj.PARAMS);
            n_fields = length(field);
            for i = 1:n_fields
                %obj.PARAMS.(field{i}) = str2double(get(obj.handles.(['edit' field{i}]), 'String'));
                obj.PARAMS.(field{i}) = str2num(get(obj.handles.(['edit' field{i}]), 'String'));
            end
            %obj.PARAMS.nScans = str2double(get(obj.handles.editnScans, 'String'));
            %obj.PARAMS.nShots = str2double(get(obj.handles.editnShots, 'String'));
            %obj.PARAMS.start  = str2double(get(obj.handles.editStart, 'String'));
            %obj.PARAMS.stop   = str2double(get(obj.handles.editStop, 'String'));
            %obj.PARAMS.speed  = str2double(get(obj.handles.editSpeed, 'String'));
            
        end
        
        function DeleteParameters(obj)
            methodString = class(obj);
            methodString = strrep(methodString, 'Method_', '');
            methodString = strrep(methodString, '_', ' ');
            methodString = strrep(methodString, '.m', '');
            
            fprintf(1, '\nCleaning up method: %s ... ', methodString);
            
            %get a cell array of the names of the parameters
            names = fieldnames(obj.PARAMS);
            %how many parameters are there
            n_params = length(names);
            
            for i = 1:n_params
                h = findobj(obj.hParamsPanel,'tag',['text' names{i}]);
                delete(h);
            end
            for i = 1:n_params
                h = findobj(obj.hParamsPanel,'tag',['edit' names{i}]);
                delete(h);
            end
            
            h = findobj(obj.hParamsPanel, 'tag', 'pbInputButton');
            delete(h);
            
            fprintf(1, 'Done.\n');
        end
        
        function ProcessSample(obj)
            %sort data

            ProcessSampleSort(obj);

            %remove background
            ProcessSampleSubtBack(obj);
            %avg signals
            ProcessSampleAvg(obj);
            %calc result
            ProcessSampleResult(obj);
            %calc noise (at least an estimate)
            ProcessSampleNoise(obj);
            
            obj.ProcessLaserSignal;
        end
        
        function result = TimeFsToBin(time, zerobin)
            result = round(time/fringeToFs)+zerobin;
        end
        
        %process the input from the external amplifier output photodiode
        function ProcessLaserOutput(obj)
            obj.laserPD.raw = obj.sample(obj.laserPD.ind_laser,:);
        end
        
        function ProcessLaserBackAvg(obj)
            obj.ProcessLaserOutput;
            obj.laserPD.bkgd = (obj.laserPD.bkgd.*(obj.i_scan-1) ...
                + mean(obj.laserPD.raw))./obj.i_scan;
        end
        
        function ProcessLaserSignal(obj)
            obj.ProcessLaserOutput;
            obj.laserPD.signal = obj.laserPD.raw - obj.laserPD.bkgd;
            obj.laserPD.noise = std(obj.laserPD.signal)./mean(obj.laserPD.signal);
        end
    end
    
end
