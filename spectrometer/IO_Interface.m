classdef IO_Interface < handle
    
    properties (SetAccess = private)
        dio;
        active;
    end
    
    methods
        
        function obj = IO_Interface
            fprintf(1, '\nInitializing IO interface ... ');
            obj.active = 0;
            try
                obj.dio = digitalio('nidaq', 'Dev3');
                obj.active = 1;
                addline(obj.dio, 7, 1, 'out');      % Port 1 bit 7
                fprintf(1, 'Done.\n')
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
                putvalue(obj.dio.Line(1), 1);
            end
        end
        
        function CloseClockGate(obj)
            if obj.active
                putvalue(obj.dio.Line(1), 0);
            end
        end
        
    end
    
end


