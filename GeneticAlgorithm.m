classdef GeneticAlgorithm < handle
    %Object to hold results and trials of the trial runs
    
    properties
        Prob_Mutation
        Generations
        Members
        
        Trials
        Track
        
        Current_Generation = 1 
    end
    
    methods
        function obj = initialise(obj)
            %Size and prealicate arrays to hold memory and speed up run time 
            obj.Track = zeros(obj.Members, obj.Generations);
            obj.Track(:,:,2) = zeros(obj.Members, obj.Generations);
            obj.Trials = zeros(obj.Members, obj.Generations);
        end
    end
end

