%% --------------------------ROBOT---------------------------------------
%{
Alonso Vega 
December 12, 2020


%}

%% Class Definition 
classdef Robot
    %% PROPERTIES
    properties(GetAccess=public)
        initalTime               {mustBeNumeric}
        finalTime                {mustBeNumeric}
        timeResolution           {mustBeNumeric}
        config                   {mustBeNumeric}
        currentStep              {mustBeNumeric}
        trajectory               {mustBeNumeric}
        controlTrajectory        {mustBeNumeric}
        referenceTrajectory      {mustBeNumeric}
        timeSpace                {mustBeNumeric}
    end
    properties(Constant)
        tireDiameter = 0.15;
        tireWidth    = 0.065;
        wheelBase    = 0.40;
        track        = 0.25; 
        uMAX         = [2.0;...
                        deg2rad(20)]
        uMIN         = -[2.0;...
                         deg2rad(20)]
    end
    
    %% METHODS
    methods
        %% Constructor 
        function robot_object = Robot(q_0, t_initial, t_final, time_step)
            if nargin == 4
                robot_object.initalTime        = t_initial;
                robot_object.finalTime         = t_final;
                robot_object.timeResolution    = time_step;
                robot_object.config            = q_0;
                robot_object.currentStep       = 0;
                robot_object.timeSpace         = [t_initial : time_step : t_final]';
                robot_object.controlTrajectory = zeros(length(robot_object.timeSpace), 2);
                robot_object.trajectory        = zeros(length(robot_object.timeSpace), 3);
            else
                error('ERROR: Robot Constructor: Need 4 input arguments.');
                exit;
            end
        end
        
        %% Solve for State Trajectory
        function obj = solve(obj)
            
            for k = 1: length(obj.timeSpace)
                obj.trajectory(k,:) = obj.config;
                obj                 = obj.kin_transition(obj.controlTrajectory(k,:)');
            end 
        end
        
        %% Controller
        function obj = controller(obj)
            q_ref_k = obj.referenceTrajectory(k,:);
            q_k     = obj.trajectory(k,:);
            
            
        end
        
        %% Transition Equation
        function obj = kin_transition(obj, u_k)
            %% Access Variables and Constants
            q_k = obj.config;
            
            x_k     = q_k(1);
            y_k     = q_k(2);
            theta_k = q_k(3);
            
            v_k   = u_k(1);
            phi_k = u_k(2);
            
            L       = obj.wheelBase;
            delta_t = obj.timeResolution;
            
            %% Update
            S_k      = [cos(theta_k) sin(theta_k) tan(phi_k)/L ;...
                             zeros(1,3)                   ];
            q_kPlus1 = q_k + delta_t*S_k'*u_k;
            
            obj.config        = q_kPlus1;
            obj.currentStep   = obj.currentStep + 1; 
        end
        
        %% Clip Trajectory 
        function [obj, new_uTilda] = sat_control(obj, uTilda)
            phi_Max = obj.uMAX(2);
            phi_Min = obj.uMIN(2);
            v_Max   = obj.uMAX(1);
            v_Min   = obj.uMIN(1);
            
            vTilda   = uTilda(:,1);
            phiTilda = uTilda(:,2);
            
            %% clip speed
            clip_Max = vTilda > v_Max;
            clip_Min = vTilda < v_Min;
            
            vTilda(clip_Max) = v_Max;
            vTilda(clip_Min) = v_Min;
            
            %% clip steering
            clip_Max = phiTilda > phi_Max;
            clip_Min = phiTilda < phi_Min;
            
            phiTilda(clip_Max) = phi_Max;
            phiTilda(clip_Min) = phi_Min;
            
            %% O/P
            new_uTilda = [vTilda, phiTilda];
           
        end
        
        %% Control I/P
        function obj = set_control(obj, input)
            if sum(size(obj.controlTrajectory) == size(input)) == 2
                [~, input] = obj.sat_control(input);
                obj.controlTrajectory = input;  
            else
                error('ERROR: invalid input trajectory.');
                exit;
            end
        end 
        
    end
end 
%%