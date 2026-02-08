-- SPDX-License-Identifier: MPL-2.0-or-later
-- FlatRacoon TUI - API Client for orchestrator

with Ada.Containers.Vectors;

package FlatRacoon.API_Client is

   -- Exception raised when module not found
   Module_Not_Found : exception;

   -- Module status types
   type Module_Status_Type is (Running, Stopped, Pending, Error);

   -- Module information
   type Module_Info is record
      Name : String (1 .. 50);
      Status : Module_Status_Type;
      Completion : Natural range 0 .. 100;
      Layer : String (1 .. 20);
      Version : String (1 .. 20);
   end record;

   package Module_Vectors is new Ada.Containers.Vectors
      (Index_Type => Positive,
       Element_Type => Module_Info);

   subtype Module_List is Module_Vectors.Vector;

   -- Module names for deployment order
   type Module_Name_Array is array (Positive range <>) of String (1 .. 50);
   subtype Module_Name_List is Module_Name_Array;

   -- Health check summary
   type Health_Summary is record
      All_Healthy : Boolean;
      Healthy_Count : Natural;
      Unhealthy_Count : Natural;
      Unknown_Count : Natural;
   end record;

   -- Initialize API client with orchestrator URL
   procedure Initialize (Orchestrator_URL : String := "http://localhost:4000");

   -- Get all modules
   function Get_Modules return Module_List;

   -- Get specific module
   function Get_Module (Name : String) return Module_Info;

   -- Get deployment order (topological sort)
   function Get_Deployment_Order return Module_Name_List;

   -- Get health summary
   function Get_Health return Health_Summary;

   -- Deploy all modules
   procedure Deploy_All;

   -- Deploy specific module
   procedure Deploy_Module (Name : String);

   -- Restart module
   procedure Restart_Module (Name : String);

   -- Stop module
   procedure Stop_Module (Name : String);

   -- Get logs for module
   function Get_Logs (Name : String; Lines : Positive := 50) return String;

private

   -- HTTP client utilities
   function HTTP_GET (Endpoint : String) return String;
   procedure HTTP_POST (Endpoint : String; Request_Body : String := "");

   -- JSON parsing helpers
   function Parse_Modules_JSON (JSON : String) return Module_List;
   function Parse_Health_JSON (JSON : String) return Health_Summary;
   function Parse_Order_JSON (JSON : String) return Module_Name_List;

end FlatRacoon.API_Client;
