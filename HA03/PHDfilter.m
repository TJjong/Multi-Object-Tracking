classdef PHDfilter
    %PHDFILTER is a class containing necessary functions to implement the
    %PHD filter 
    %Model structures need to be called:
    %    sensormodel: a structure which specifies the sensor parameters
    %           P_D: object detection probability --- scalar
    %           lambda_c: average number of clutter measurements per time scan, 
    %                     Poisson distributed --- scalar
    %           pdf_c: value of clutter pdf --- scalar
    %           intensity_c: Poisson clutter intensity --- scalar
    %       motionmodel: a structure which specifies the motion model parameters
    %           d: object state dimension --- scalar
    %           F: function handle return transition/Jacobian matrix
    %           f: function handle return predicted object state
    %           Q: motion noise covariance matrix
    %       measmodel: a structure which specifies the measurement model parameters
    %           d: measurement dimension --- scalar
    %           H: function handle return transition/Jacobian matrix
    %           h: function handle return the observation of the target state
    %           R: measurement noise covariance matrix
    %       birthmodel: a structure array which specifies the birth model (Gaussian
    %       mixture density) parameters --- (1 x number of birth components)
    %           w: weights of mixture components (in logarithm domain)
    %           x: mean of mixture components
    %           P: covariance of mixture components
    
    properties
        density %density class handle
        paras   %parameters specify a PPP
    end
    
    methods
        function obj = initialize(obj,density_class_handle,birthmodel)
            %INITIATOR initializes PHDfilter class
            %INPUT: density_class_handle: density class handle
            %OUTPUT:obj.density: density class handle
            %       obj.paras.w: weights of mixture components --- vector
            %                    of size (number of mixture components x 1)
            %       obj.paras.states: parameters of mixture components ---
            %                    struct array of size (number of mixture
            %                    components x 1) 
            
            obj.density = density_class_handle;
            obj.paras.w = [birthmodel.w]';
            obj.paras.states = rmfield(birthmodel,'w')';
        end
        
        function obj = predict(obj,motionmodel,P_S,birthmodel)
            %PREDICT performs PPP prediction step
            %INPUT: P_S: object survival probability
           
        end
        
        function obj = update(obj,z,measmodel,intensity_c,P_D,gating)
            %UPDATE performs PPP update step and PPP approximation
            %INPUT: z: measurements --- matrix of size (measurement dimension 
            %          x number of measurements)
            %       intensity_c: Poisson clutter intensity --- scalar
            %       P_D: object detection probability --- scalar
            %       gating: a struct with two fields: P_G, size, used to
            %               specify the gating parameters
            
        end
        
        function obj = componentReduction(obj,reduction)
            %COMPONENTREDUCTION approximates the PPP by representing its
            %intensity with fewer parameters
            
            %Pruning
            [obj.paras.w, obj.paras.states] = hypothesisReduction.prune(obj.paras.w, obj.paras.states, reduction.w_min);
            %Merging
            if length(obj.paras.w) > 1
                [obj.paras.w, obj.paras.states] = hypothesisReduction.merge(obj.paras.w, obj.paras.states, reduction.merging_threshold, obj.density);
            end
            %Capping
            [obj.paras.w, obj.paras.states] = hypothesisReduction.cap(obj.paras.w, obj.paras.states, reduction.M);
        end
        
        function estimates = PHD_estimator(obj)
            %PHD_ESTIMATOR performs object state estimation in the GMPHD filter
            %OUTPUT:estimates: estimated object states in matrix form of
            %                  size (object state dimension) x (number of
            %                  objects) 
            
            estimates = [];

        end
        
    end
    
end


% %Choose object detection probability
% P_D = 0.98;
% %Choose clutter rate
% lambda_c = 5;
% %Choose object survival probability
% P_S = 0.99;
% 
% %Create sensor model
% range_c = [-1000 1000;-1000 1000];
% sensor_model = modelgen.sensormodel(P_D,lambda_c,range_c);
%         
% %Create linear motion model
% T = 1;
% sigma_q = 5;
% motion_model = motionmodel.cvmodel(T,sigma_q);
%         
% %Create linear measurement model
% sigma_r = 10;
% meas_model = measmodel.cvmeasmodel(sigma_r);
% 
% %Create ground truth model
% nbirths = 12;
% K = 100;
% tbirth = zeros(nbirths,1);
% tdeath = zeros(nbirths,1);
%         
% initial_state(1).x  = [ 0; 0; 0; -10 ];            tbirth(1)  = 1;     tdeath(1)  = 70;
% initial_state(2).x  = [ 400; -600; -10; 5 ];       tbirth(2)  = 1;     tdeath(2)  = K+1;
% initial_state(3).x  = [ -800; -200; 20; -5 ];      tbirth(3)  = 1;     tdeath(3)  = 70;
% initial_state(4).x  = [ 400; -600; -7; -4 ];       tbirth(4)  = 20;    tdeath(4)  = K+1;
% initial_state(5).x  = [ 400; -600; -2.5; 10 ];     tbirth(5)  = 20;    tdeath(5)  = K+1;
% initial_state(6).x  = [ 0; 0; 7.5; -5 ];           tbirth(6)  = 20;    tdeath(6)  = K+1;
% initial_state(7).x  = [ -800; -200; 12; 7 ];       tbirth(7)  = 40;    tdeath(7)  = K+1;
% initial_state(8).x  = [ -200; 800; 15; -10 ];      tbirth(8)  = 40;    tdeath(8)  = K+1;
% initial_state(9).x  = [ -800; -200; 3; 15 ];       tbirth(9)   = 60;   tdeath(9)  = K+1;
% initial_state(10).x  = [ -200; 800; -3; -15 ];     tbirth(10)  = 60;   tdeath(10) = K+1;
% initial_state(11).x  = [ 0; 0; -20; -15 ];         tbirth(11)  = 80;   tdeath(11) = K+1;
% initial_state(12).x  = [ -200; 800; 15; -5 ];      tbirth(12)  = 80;   tdeath(12) = K+1;
%         
% birth_model = repmat(struct('w',log(0.03),'x',[],'P',400*eye(motion_model.d)),[1,4]);
% birth_model(1).x = [ 0; 0; 0; 0];
% birth_model(2).x = [ 400; -600; 0; 0];
% birth_model(3).x = [ -800; -200; 0; 0 ];
% birth_model(4).x = [ -200; 800; 0; 0 ];
% 
% %Generate true object data (noisy or noiseless) and measurement data
% ground_truth = modelgen.groundtruth(nbirths,[initial_state.x],tbirth,tdeath,K);
% ifnoisy = 0;
% objectdata = objectdatagen(ground_truth,motion_model,ifnoisy);
% measdata = measdatagen(objectdata,sensor_model,meas_model);
% 
% %Object tracker parameter setting
% P_G = 0.999;            %gating size in percentage
% w_min = 1e-3;           %hypothesis pruning threshold
% merging_threshold = 4;  %hypothesis merging threshold
% M = 100;                %maximum number of hypotheses kept in PHD
% density_class_handle = feval(@GaussianDensity);    %density class handle
% 
% %Please check the provided script multiobjectracker_HA3 for details of the function multiobjectracker
% tracker = multiobjectracker();
% tracker = tracker.initialize(density_class_handle,P_S,P_G,meas_model.d,w_min,merging_threshold,M);
% 
% %GM-PHD filter
% GMPHDestimates = GMPHDfilter(tracker, birth_model, measdata, sensor_model, motion_model, meas_model);
% 
% %Trajectory plot
% true_state = cell2mat(objectdata.X');
% GMPHD_estimated_state = cell2mat(GMPHDestimates');
% 
% figure
% hold on
% grid on
% 
% h1 = plot(true_state(1,:), true_state(2,:), 'bo', 'Linewidth', 1);
% h2 = plot(GMPHD_estimated_state(1,:), GMPHD_estimated_state(2,:), 'r+', 'Linewidth', 1);
% 
% xlabel('x (m)'); ylabel('y (m)')
% legend([h1 h2],'Ground Truth','PHD Estimates', 'Location', 'best')
% set(gca,'FontSize',12) 