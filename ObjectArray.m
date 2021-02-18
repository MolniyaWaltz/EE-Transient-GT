classdef ObjectArray
    % Class to create array of objects
   properties
      Value
   end
   methods
      function obj = ObjectArray(m,n)
         if nargin ~= 0
            obj(m,n) = obj;
            for i = 1:m
               for j = 1:n
                  obj(i,j).Value = ElectricalControl();
               end
            end
         end
      end
   end
end