classdef Method_2d_quasiphase_Multi_Time_Polarization < Method_2d_quasiphase_Polarization & Multi_Time_Point_Method
    
    properties
        scanMethod = 'Scan@Polarization_Method(obj)';
        colNames = {'t2', 'nScans_Para', 'nScans_Perp'};
    end
    
    methods % Constructor Method
        function obj = Method_2d_quasiphase_Multi_Time_Polarization(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hLaserOutputAxes,hDiagnosticsPanel)
            
            obj = obj@Method_2d_quasiphase_Polarization(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hLaserOutputAxes,hDiagnosticsPanel);
            
            obj.LoadT2Array();
            obj.LoadnScansArray();
            
            obj.createParamsButton();
        end
    end
end