classdef Method_Pump_Probe_Multi_Time_Point < Method_Pump_Probe & Multi_Time_Point_Method
    properties
        scanMethod = ''; % 'Scan@Method(obj)';
        colNames = {'t2', 'nScans'};
    end
    
    methods
        function obj = Method_Pump_Probe_Multi_Time_Point(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hLaserOutputAxes,hDiagnosticsPanel)
            
            obj = obj@Method_Pump_Probe(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hLaserOutputAxes,hDiagnosticsPanel);
            
            obj.LoadT2Array();
            obj.LoadnScansArray();
            
            obj.createParamsButton();
            
        end
    end
end