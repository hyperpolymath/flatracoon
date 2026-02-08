-- SPDX-License-Identifier: MPL-2.0-or-later
-- FlatRacoon TUI - API Client implementation
-- Uses GNATCOLL.JSON for robust JSON parsing

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Exceptions; use Ada.Exceptions;
with GNAT.Sockets;
with GNATCOLL.JSON; use GNATCOLL.JSON;

package body FlatRacoon.API_Client is

   Base_URL : String (1 .. 100) := (others => ' ');
   URL_Length : Natural := 0;

   procedure Initialize (Orchestrator_URL : String := "http://localhost:4000") is
   begin
      URL_Length := Orchestrator_URL'Length;
      Base_URL (1 .. URL_Length) := Orchestrator_URL;
   end Initialize;

   function HTTP_GET (Endpoint : String) return String is
      use GNAT.Sockets;

      Address  : Sock_Addr_Type;
      Socket   : Socket_Type;
      Channel  : Stream_Access;
      Response : Ada.Strings.Unbounded.Unbounded_String;

      Host     : constant String := "localhost";
      Port     : constant Port_Type := 4000;
      Path     : constant String := Endpoint;
   begin
      -- Create socket
      Create_Socket (Socket);

      -- Set address
      Address.Addr := Addresses (Get_Host_By_Name (Host), 1);
      Address.Port := Port;

      -- Connect
      Connect_Socket (Socket, Address);
      Channel := Stream (Socket);

      -- Send HTTP request
      String'Write (Channel, "GET " & Path & " HTTP/1.1" & ASCII.CR & ASCII.LF);
      String'Write (Channel, "Host: " & Host & ASCII.CR & ASCII.LF);
      String'Write (Channel, "Connection: close" & ASCII.CR & ASCII.LF);
      String'Write (Channel, ASCII.CR & ASCII.LF);

      -- Read response
      declare
         In_Body     : Boolean := False;
         Status_Line : Unbounded_String;
         Status_Code : Integer := 0;
         Headers     : Unbounded_String;
      begin
         -- Read status line first (e.g., "HTTP/1.1 200 OK")
         loop
            declare
               Char : Character;
            begin
               Character'Read (Channel, Char);

               if Char = ASCII.LF then
                  -- Parse status code from status line
                  declare
                     Line : constant String := To_String (Status_Line);
                  begin
                     -- Extract status code (second field in "HTTP/1.1 200 OK")
                     if Line'Length >= 12 then
                        Status_Code := Integer'Value (Line (10 .. 12));
                     end if;
                  exception
                     when Constraint_Error =>
                        Status_Code := 0;  -- Failed to parse
                  end;
                  exit;
               elsif Char /= ASCII.CR then
                  Append (Status_Line, Char);
               end if;
            end;
         end loop;

         -- Check status code and raise specific errors
         case Status_Code is
            when 200 .. 299 =>
               null;  -- Success, continue reading
            when 400 =>
               Close_Socket (Socket);
               raise Program_Error with "HTTP 400 Bad Request";
            when 404 =>
               Close_Socket (Socket);
               raise Program_Error with "HTTP 404 Not Found";
            when 500 =>
               Close_Socket (Socket);
               raise Program_Error with "HTTP 500 Server Error";
            when 503 =>
               Close_Socket (Socket);
               raise Program_Error with "HTTP 503 Service Unavailable";
            when others =>
               if Status_Code >= 400 then
                  Close_Socket (Socket);
                  raise Program_Error with "HTTP error:" & Status_Code'Image;
               end if;
         end case;

         -- Read rest of response (headers and body)
         loop
            declare
               Char : Character;
            begin
               Character'Read (Channel, Char);

               -- Simple header/body separation
               if not In_Body then
                  Append (Headers, Char);
                  declare
                     Current : constant String := To_String (Headers);
                  begin
                     if Current'Length >= 4 and then
                        Current (Current'Last - 3 .. Current'Last) =
                           ASCII.CR & ASCII.LF & ASCII.CR & ASCII.LF
                     then
                        In_Body := True;
                        Response := To_Unbounded_String ("");  -- Start fresh for body
                     end if;
                  end;
               end if;

               if In_Body then
                  Append (Response, Char);
               end if;
            end;
         end loop;
      exception
         when End_Error =>
            null;  -- Normal end of stream
      end;

      -- Clean up
      Close_Socket (Socket);

      return To_String (Response);
   exception
      when E : Socket_Error =>
         begin
            Close_Socket (Socket);
         exception
            when others => null;
         end;
         raise Program_Error with "HTTP GET failed: " & Exception_Message (E);
      when E : others =>
         begin
            Close_Socket (Socket);
         exception
            when others => null;
         end;
         raise Program_Error with "HTTP GET error: " & Exception_Message (E);
   end HTTP_GET;

   procedure HTTP_POST (Endpoint : String; Request_Body : String := "") is
      use GNAT.Sockets;

      Address : Sock_Addr_Type;
      Socket  : Socket_Type;
      Channel : Stream_Access;

      Host : constant String := "localhost";
      Port : constant Port_Type := 4000;
      Path : constant String := Endpoint;
   begin
      -- Create socket
      Create_Socket (Socket);

      -- Set address
      Address.Addr := Addresses (Get_Host_By_Name (Host), 1);
      Address.Port := Port;

      -- Connect
      Connect_Socket (Socket, Address);
      Channel := Stream (Socket);

      -- Send HTTP POST request
      String'Write (Channel, "POST " & Path & " HTTP/1.1" & ASCII.CR & ASCII.LF);
      String'Write (Channel, "Host: " & Host & ASCII.CR & ASCII.LF);
      String'Write (Channel, "Content-Type: application/json" & ASCII.CR & ASCII.LF);
      String'Write (Channel, "Content-Length:" & Request_Body'Length'Image & ASCII.CR & ASCII.LF);
      String'Write (Channel, "Connection: close" & ASCII.CR & ASCII.LF);
      String'Write (Channel, ASCII.CR & ASCII.LF);

      if Request_Body'Length > 0 then
         String'Write (Channel, Request_Body);
      end if;

      -- Read and parse response status
      declare
         Status_Line : Unbounded_String;
         Status_Code : Integer := 0;
      begin
         -- Read status line (e.g., "HTTP/1.1 200 OK")
         loop
            declare
               Char : Character;
            begin
               Character'Read (Channel, Char);

               if Char = ASCII.LF then
                  -- Parse status code from status line
                  declare
                     Line : constant String := To_String (Status_Line);
                  begin
                     if Line'Length >= 12 then
                        Status_Code := Integer'Value (Line (10 .. 12));
                     end if;
                  exception
                     when Constraint_Error =>
                        Status_Code := 0;
                  end;
                  exit;
               elsif Char /= ASCII.CR then
                  Append (Status_Line, Char);
               end if;
            end;
         end loop;

         -- Check status code and raise specific errors
         case Status_Code is
            when 200 .. 299 =>
               null;  -- Success
            when 400 =>
               Close_Socket (Socket);
               raise Program_Error with "HTTP 400 Bad Request";
            when 404 =>
               Close_Socket (Socket);
               raise Program_Error with "HTTP 404 Not Found";
            when 500 =>
               Close_Socket (Socket);
               raise Program_Error with "HTTP 500 Server Error";
            when 503 =>
               Close_Socket (Socket);
               raise Program_Error with "HTTP 503 Service Unavailable";
            when others =>
               if Status_Code >= 400 then
                  Close_Socket (Socket);
                  raise Program_Error with "HTTP error:" & Status_Code'Image;
               end if;
         end case;
      exception
         when End_Error =>
            null;  -- No response from server
      end;

      -- Clean up
      Close_Socket (Socket);
   exception
      when E : Socket_Error =>
         begin
            Close_Socket (Socket);
         exception
            when others => null;
         end;
         raise Program_Error with "HTTP POST failed: " & Exception_Message (E);
      when E : others =>
         begin
            Close_Socket (Socket);
         exception
            when others => null;
         end;
         raise Program_Error with "HTTP POST error: " & Exception_Message (E);
   end HTTP_POST;

   function Get_Modules return Module_List is
      JSON_Response : constant String := HTTP_GET ("/api/modules");
   begin
      return Parse_Modules_JSON (JSON_Response);
   exception
      when E : others =>
         Put_Line ("Error getting modules: " & Exception_Message (E));
         declare
            Empty : Module_List;
         begin
            return Empty;
         end;
   end Get_Modules;

   function Get_Module (Name : String) return Module_Info is
      Modules : constant Module_List := Get_Modules;
   begin
      for M of Modules loop
         if Trim (M.Name, Ada.Strings.Right) = Name then
            return M;
         end if;
      end loop;

      raise Module_Not_Found;
   end Get_Module;

   function Get_Deployment_Order return Module_Name_List is
      JSON_Response : constant String := HTTP_GET ("/api/deployment_order");
   begin
      return Parse_Order_JSON (JSON_Response);
   exception
      when E : others =>
         Put_Line ("Error getting deployment order: " & Exception_Message (E));
         declare
            Empty : Module_Name_List (1 .. 0);
         begin
            return Empty;
         end;
   end Get_Deployment_Order;

   function Get_Health return Health_Summary is
      JSON_Response : constant String := HTTP_GET ("/api/health");
      Result : Health_Summary;
   begin
      Result := Parse_Health_JSON (JSON_Response);
      return Result;
   exception
      when E : others =>
         Put_Line ("Error getting health: " & Exception_Message (E));
         Result.All_Healthy := False;
         Result.Healthy_Count := 0;
         Result.Unhealthy_Count := 0;
         Result.Unknown_Count := 0;
         return Result;
   end Get_Health;

   procedure Deploy_All is
   begin
      HTTP_POST ("/api/deploy");
      Put_Line ("✓ Deployment initiated for all modules");
   exception
      when E : others =>
         Put_Line ("✗ Deploy all failed: " & Exception_Message (E));
   end Deploy_All;

   procedure Deploy_Module (Name : String) is
   begin
      HTTP_POST ("/api/deploy/" & Name);
      Put_Line ("✓ Deployment initiated for " & Name);
   exception
      when E : others =>
         Put_Line ("✗ Deploy failed for " & Name & ": " & Exception_Message (E));
   end Deploy_Module;

   procedure Restart_Module (Name : String) is
   begin
      HTTP_POST ("/api/restart/" & Name);
      Put_Line ("✓ Restart initiated for " & Name);
   exception
      when E : others =>
         Put_Line ("✗ Restart failed for " & Name & ": " & Exception_Message (E));
   end Restart_Module;

   procedure Stop_Module (Name : String) is
   begin
      HTTP_POST ("/api/stop/" & Name);
      Put_Line ("✓ Stop initiated for " & Name);
   exception
      when E : others =>
         Put_Line ("✗ Stop failed for " & Name & ": " & Exception_Message (E));
   end Stop_Module;

   function Get_Logs (Name : String; Lines : Positive := 50) return String is
      JSON_Response : constant String :=
         HTTP_GET ("/api/logs/" & Name & "?lines=" & Lines'Image);
      Val : JSON_Value;
   begin
      -- Parse JSON using GNATCOLL.JSON
      Val := Read (JSON_Response, "logs response");

      if Has_Field (Val, "logs") then
         return Get (Val, "logs");
      else
         return "No logs available";
      end if;
   exception
      when E : others =>
         return "Error retrieving logs: " & Exception_Message (E);
   end Get_Logs;

   -- Parse modules JSON using GNATCOLL.JSON
   function Parse_Modules_JSON (JSON : String) return Module_List is
      Result : Module_List;
      Root : JSON_Value;
      Modules_Array : JSON_Array;
   begin
      -- Parse JSON
      Root := Read (JSON, "modules response");

      -- Validate root has "modules" field
      if not Has_Field (Root, "modules") then
         Put_Line ("Warning: JSON response missing 'modules' field");
         return Result;
      end if;

      -- Get modules array
      Modules_Array := Get (Root, "modules");

      -- Parse each module
      for I in 1 .. Length (Modules_Array) loop
         declare
            Module_Obj : constant JSON_Value := Get (Modules_Array, I);
            M : Module_Info;
            Name_Str : constant String := Get (Get (Module_Obj, "manifest"), "name");
            Status_Str : constant String := Get (Module_Obj, "status");
            Layer_Str : constant String := Get (Get (Module_Obj, "manifest"), "layer");
            Version_Str : constant String := Get (Get (Module_Obj, "manifest"), "version");
         begin
            -- Fill module info
            M.Name (1 .. Integer'Min (Name_Str'Length, 50)) :=
               Name_Str (1 .. Integer'Min (Name_Str'Length, 50));

            -- Parse status
            if Status_Str = "healthy" or Status_Str = "deploying" then
               M.Status := Running;
            elsif Status_Str = "not_deployed" then
               M.Status := Stopped;
            elsif Status_Str = "degraded" then
               M.Status := Pending;
            else
               M.Status := Error;
            end if;

            M.Layer (1 .. Integer'Min (Layer_Str'Length, 20)) :=
               Layer_Str (1 .. Integer'Min (Layer_Str'Length, 20));
            M.Version (1 .. Integer'Min (Version_Str'Length, 20)) :=
               Version_Str (1 .. Integer'Min (Version_Str'Length, 20));
            M.Completion := 100;  -- Default completion

            Result.Append (M);
         exception
            when E : others =>
               Put_Line ("Warning: Failed to parse module " & I'Image & ": " & Exception_Message (E));
         end;
      end loop;

      return Result;
   exception
      when E : others =>
         Put_Line ("Error parsing modules JSON: " & Exception_Message (E));
         Result.Clear;
         return Result;
   end Parse_Modules_JSON;

   -- Parse health JSON using GNATCOLL.JSON
   function Parse_Health_JSON (JSON : String) return Health_Summary is
      Result : Health_Summary;
      Root : JSON_Value;
   begin
      -- Parse JSON
      Root := Read (JSON, "health response");

      -- Extract health fields with defaults
      if Has_Field (Root, "status") then
         declare
            Status_Val : constant Unbounded_String := Get (Root, "status");
         begin
            Result.All_Healthy := (To_String (Status_Val) = "healthy");
         end;
      else
         Result.All_Healthy := False;
      end if;

      if Has_Field (Root, "healthy_count") then
         Result.Healthy_Count := Get (Root, "healthy_count");
      else
         Result.Healthy_Count := 0;
      end if;

      if Has_Field (Root, "unhealthy_count") then
         Result.Unhealthy_Count := Get (Root, "unhealthy_count");
      else
         Result.Unhealthy_Count := 0;
      end if;

      if Has_Field (Root, "degraded_count") then
         Result.Unknown_Count := Get (Root, "degraded_count");
      else
         Result.Unknown_Count := 0;
      end if;

      return Result;
   exception
      when E : others =>
         Put_Line ("Error parsing health JSON: " & Exception_Message (E));
         Result.All_Healthy := False;
         Result.Healthy_Count := 0;
         Result.Unhealthy_Count := 0;
         Result.Unknown_Count := 0;
         return Result;
   end Parse_Health_JSON;

   -- Parse deployment order JSON using GNATCOLL.JSON
   function Parse_Order_JSON (JSON : String) return Module_Name_List is
      Root : JSON_Value;
      Order_Array : JSON_Array;
      Count : Natural := 0;
      Names : array (1 .. 20) of String (1 .. 50) := (others => (others => ' '));
   begin
      -- Parse JSON
      Root := Read (JSON, "deployment order response");

      -- Validate root has "order" field
      if not Has_Field (Root, "order") then
         declare
            Empty : Module_Name_List (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      -- Get order array
      Order_Array := Get (Root, "order");

      -- Extract module names
      for I in 1 .. Integer'Min (Length (Order_Array), 20) loop
         Count := Count + 1;
         declare
            Item : constant JSON_Value := Get (Order_Array, I);
            Name : constant String := To_String (GNATCOLL.JSON.Get (Item));
         begin
            Names (Count) (1 .. Integer'Min (Name'Length, 50)) :=
               Name (1 .. Integer'Min (Name'Length, 50));
         end;
      end loop;

      -- Return array with correct size
      declare
         Result : Module_Name_List (1 .. Count);
      begin
         for I in 1 .. Count loop
            Result (I) := Names (I);
         end loop;
         return Result;
      end;
   exception
      when E : others =>
         Put_Line ("Error parsing deployment order JSON: " & Exception_Message (E));
         declare
            Empty : Module_Name_List (1 .. 0);
         begin
            return Empty;
         end;
   end Parse_Order_JSON;

end FlatRacoon.API_Client;
