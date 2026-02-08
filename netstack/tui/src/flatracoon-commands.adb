-- SPDX-License-Identifier: MPL-2.0-or-later
-- FlatRacoon TUI - Command implementation

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Ada.Characters.Handling;
with FlatRacoon.Display;
with FlatRacoon.API_Client;

package body FlatRacoon.Commands is

   function Parse_Command (Name : String) return Command_Type is
      Lower_Name : constant String := Ada.Characters.Handling.To_Lower (Name);
   begin
      if Lower_Name = "help" or Lower_Name = "h" then
         return Cmd_Help;
      elsif Lower_Name = "status" or Lower_Name = "st" then
         return Cmd_Status;
      elsif Lower_Name = "health" or Lower_Name = "hc" then
         return Cmd_Health;
      elsif Lower_Name = "deploy" or Lower_Name = "d" then
         return Cmd_Deploy;
      elsif Lower_Name = "order" or Lower_Name = "o" then
         return Cmd_Order;
      elsif Lower_Name = "logs" or Lower_Name = "l" then
         return Cmd_Logs;
      elsif Lower_Name = "restart" or Lower_Name = "r" then
         return Cmd_Restart;
      elsif Lower_Name = "stop" or Lower_Name = "s" then
         return Cmd_Stop;
      else
         return Cmd_Unknown;
      end if;
   end Parse_Command;

   procedure Execute (Command : Unbounded_String; Args : Argument_List) is
      Cmd : constant Command_Type := Parse_Command (To_String (Command));
   begin
      case Cmd is
         when Cmd_Help =>
            Show_Help;
         when Cmd_Status =>
            Handle_Status (Args);
         when Cmd_Health =>
            Handle_Health (Args);
         when Cmd_Deploy =>
            Handle_Deploy (Args);
         when Cmd_Order =>
            Handle_Order (Args);
         when Cmd_Logs =>
            Handle_Logs (Args);
         when Cmd_Restart =>
            Handle_Restart (Args);
         when Cmd_Stop =>
            Handle_Stop (Args);
         when Cmd_Unknown =>
            Put_Line ("Unknown command: " & To_String (Command));
            Put_Line ("Type 'help' for available commands.");
      end case;
   end Execute;

   procedure Parse_And_Execute (Input : String) is
      Tokens : Argument_List;
      First : Positive := Input'First;
      Last : Natural;
   begin
      -- Split input into tokens
      while First <= Input'Last loop
         Ada.Strings.Fixed.Find_Token (Input, Ada.Strings.Maps.To_Set (' '),
                                       First, Ada.Strings.Inside, First, Last);
         exit when Last = 0;
         Tokens.Append (To_Unbounded_String (Input (First .. Last)));
         First := Last + 1;
      end loop;

      if not Tokens.Is_Empty then
         declare
            Command : constant Unbounded_String := Tokens.First_Element;
            Args : Argument_List;
         begin
            for I in 2 .. Integer (Tokens.Length) loop
               Args.Append (Tokens.Element (I));
            end loop;
            Execute (Command, Args);
         end;
      end if;
   end Parse_And_Execute;

   procedure Show_Help is
   begin
      FlatRacoon.Display.Put_Line_Colored ("Available Commands:", FlatRacoon.Display.Green);
      New_Line;
      Put_Line ("  help, h              - Show this help message");
      Put_Line ("  status, st [module]  - Show module status (all or specific)");
      Put_Line ("  health, hc           - Show health check summary");
      Put_Line ("  deploy, d [module]   - Deploy module(s)");
      Put_Line ("  order, o             - Show deployment order");
      Put_Line ("  logs, l <module>     - Show logs for module");
      Put_Line ("  restart, r <module>  - Restart module");
      Put_Line ("  stop, s <module>     - Stop module");
      Put_Line ("  exit, quit           - Exit TUI");
      New_Line;
   end Show_Help;

   procedure Show_Command_Help (Cmd : Command_Type) is
   begin
      case Cmd is
         when Cmd_Status =>
            Put_Line ("Usage: status [module]");
            Put_Line ("Show status of all modules or a specific module");
         when Cmd_Health =>
            Put_Line ("Usage: health");
            Put_Line ("Show aggregated health check summary");
         when Cmd_Deploy =>
            Put_Line ("Usage: deploy [module]");
            Put_Line ("Deploy all modules or a specific module");
         when Cmd_Order =>
            Put_Line ("Usage: order");
            Put_Line ("Show topological deployment order");
         when Cmd_Logs =>
            Put_Line ("Usage: logs <module>");
            Put_Line ("Show logs for specified module");
         when Cmd_Restart =>
            Put_Line ("Usage: restart <module>");
            Put_Line ("Restart specified module");
         when Cmd_Stop =>
            Put_Line ("Usage: stop <module>");
            Put_Line ("Stop specified module");
         when others =>
            null;
      end case;
   end Show_Command_Help;

   procedure Handle_Status (Args : Argument_List) is
   begin
      if Args.Is_Empty then
         FlatRacoon.Display.Show_Module_Status;
      else
         -- Show specific module status
         declare
            Module_Name : constant String := To_String (Args.First_Element);
            Module : constant FlatRacoon.API_Client.Module_Info :=
               FlatRacoon.API_Client.Get_Module (Module_Name);
         begin
            Put_Line ("Module: " & Module_Name);
            Put_Line ("Status: " & Module.Status'Image);
            Put_Line ("Completion: " & Module.Completion'Image & "%");
            Put_Line ("Layer: " & Module.Layer);
         end;
      end if;
   exception
      when FlatRacoon.API_Client.Module_Not_Found =>
         Put_Line ("Module not found: " & To_String (Args.First_Element));
   end Handle_Status;

   procedure Handle_Health (Args : Argument_List) is
   begin
      FlatRacoon.Display.Show_Health_Status;
   end Handle_Health;

   procedure Handle_Deploy (Args : Argument_List) is
   begin
      if Args.Is_Empty then
         Put_Line ("Deploying all modules in topological order...");
         FlatRacoon.API_Client.Deploy_All;
         Put_Line ("Deployment initiated. Check status for progress.");
      else
         declare
            Module_Name : constant String := To_String (Args.First_Element);
         begin
            Put_Line ("Deploying " & Module_Name & "...");
            FlatRacoon.API_Client.Deploy_Module (Module_Name);
            Put_Line ("Deployment initiated for " & Module_Name);
         end;
      end if;
   exception
      when FlatRacoon.API_Client.Module_Not_Found =>
         Put_Line ("Module not found: " & To_String (Args.First_Element));
   end Handle_Deploy;

   procedure Handle_Order (Args : Argument_List) is
   begin
      FlatRacoon.Display.Show_Deployment_Order;
   end Handle_Order;

   procedure Handle_Logs (Args : Argument_List) is
   begin
      if Args.Is_Empty then
         Put_Line ("Error: Module name required");
         Put_Line ("Usage: logs <module>");
         return;
      end if;

      declare
         Module_Name : constant String := To_String (Args.First_Element);
         Logs : constant String := FlatRacoon.API_Client.Get_Logs (Module_Name);
      begin
         Put_Line ("Logs for " & Module_Name & ":");
         Put_Line ("─────────────────────────────────────────────────────────────");
         Put_Line (Logs);
      end;
   exception
      when FlatRacoon.API_Client.Module_Not_Found =>
         Put_Line ("Module not found: " & To_String (Args.First_Element));
   end Handle_Logs;

   procedure Handle_Restart (Args : Argument_List) is
   begin
      if Args.Is_Empty then
         Put_Line ("Error: Module name required");
         Put_Line ("Usage: restart <module>");
         return;
      end if;

      declare
         Module_Name : constant String := To_String (Args.First_Element);
      begin
         Put_Line ("Restarting " & Module_Name & "...");
         FlatRacoon.API_Client.Restart_Module (Module_Name);
         Put_Line ("Restart initiated for " & Module_Name);
      end;
   exception
      when FlatRacoon.API_Client.Module_Not_Found =>
         Put_Line ("Module not found: " & To_String (Args.First_Element));
   end Handle_Restart;

   procedure Handle_Stop (Args : Argument_List) is
   begin
      if Args.Is_Empty then
         Put_Line ("Error: Module name required");
         Put_Line ("Usage: stop <module>");
         return;
      end if;

      declare
         Module_Name : constant String := To_String (Args.First_Element);
      begin
         Put_Line ("Stopping " & Module_Name & "...");
         FlatRacoon.API_Client.Stop_Module (Module_Name);
         Put_Line ("Stop initiated for " & Module_Name);
      end;
   exception
      when FlatRacoon.API_Client.Module_Not_Found =>
         Put_Line ("Module not found: " & To_String (Args.First_Element));
   end Handle_Stop;

end FlatRacoon.Commands;
