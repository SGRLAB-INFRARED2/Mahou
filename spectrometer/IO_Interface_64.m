
classdef IO_Interface_64 < handle
    
    properties (SetAccess = private)
        dio;
        active;
    end
    
    methods
        
        function obj = IO_Interface_64
            fprintf(1, '\nInitializing IO interface ... ');
            obj.active = 0;
            warning('off', 'daq:Session:onDemandOnlyChannelsAdded')
            try
                %                 obj.dio = digitalio('nidaq', 'Dev2');
                obj.dio = daq.createSession('ni');
                addDigitalChannel(obj.dio,'Dev3','Port1/Line7','OutputOnly');
                obj.active = 1;
                fprintf(1, 'Done.\n');
            catch err
                fprintf(1, '\n')
                warning('Spectrometer:DIO', ['Digital I/O module not found.  Entering simulation mode\n', 'Error Message: ', err.message]);
            end
        end
        
        function delete(obj)
            fprintf(1, 'Cleaning up IO Interface ... ')
            CloseClockGate(obj);
            if obj.active
                delete(obj.dio);
            end
            fprintf(1, 'Done.\n')
        end
        
        function OpenClockGate(obj)
            if obj.active
                outputSingleScan(obj.dio, 1)
                %                 putvalue(obj.dio.Line(1), 1);
            end
        end
        
        function CloseClockGate(obj)
            if obj.active
                outputSingleScan(obj.dio, 0)
                %                 putvalue(obj.dio.Line(1), 0);
            end
        end
        
    end
    
end


