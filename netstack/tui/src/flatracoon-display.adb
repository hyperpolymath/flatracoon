-- SPDX-License-Identifier: MPL-2.0-or-later
-- FlatRacoon TUI - Display implementation

with Ada.Text_IO; use Ada.Text_IO;
with FlatRacoon.API_Client;

package body FlatRacoon.Display is

   -- ANSI color codes
   Color_Codes : constant array (Color_Code) of String (1 .. 7) := (
      Reset   => ASCII.ESC & "[0m    ",
      Red     => ASCII.ESC & "[31m   ",
      Green   => ASCII.ESC & "[32m   ",
      Yellow  => ASCII.ESC & "[33m   ",
      Blue    => ASCII.ESC & "[34m   ",
      Magenta => ASCII.ESC & "[35m   ",
      Cyan    => ASCII.ESC & "[36m   ",
      White   => ASCII.ESC & "[37m   "
   );

   procedure Set_Color (Color : Color_Code) is
   begin
      Put (Color_Codes (Color));
   end Set_Color;

   procedure Put_Line_Colored (Text : String; Color : Color_Code) is
   begin
      Set_Color (Color);
      Put_Line (Text);
      Set_Color (Reset);
   end Put_Line_Colored;

   procedure Clear_Screen is
   begin
      Put (ASCII.ESC & "[2J" & ASCII.ESC & "[H");
   end Clear_Screen;

   procedure Show_Banner is
   begin
      Clear_Screen;
      Set_Color (Cyan);
      Put_Line ("╔═══════════════════════════════════════════════════════════╗");
      Put_Line ("║         FlatRacoon Network Stack - TUI v0.1.0            ║");
      Put_Line ("║     Modular, Declarative Network Infrastructure          ║");
      Put_Line ("╚═══════════════════════════════════════════════════════════╝");
      Set_Color (Reset);
      New_Line;
   end Show_Banner;

   procedure Show_Module_Status is
      Modules : constant FlatRacoon.API_Client.Module_List :=
         FlatRacoon.API_Client.Get_Modules;
   begin
      Put_Line_Colored ("Module Status:", Green);
      Put_Line ("─────────────────────────────────────────────────────────────");
      Put_Line ("Module                    | Status      | Completion | Layer");
      Put_Line ("─────────────────────────────────────────────────────────────");

      for Module of Modules loop
         Put (Module.Name & " ");

         case Module.Status is
            when FlatRacoon.API_Client.Running =>
               Set_Color (Green);
               Put ("✓ Running ");
            when FlatRacoon.API_Client.Stopped =>
               Set_Color (Red);
               Put ("✗ Stopped ");
            when FlatRacoon.API_Client.Pending =>
               Set_Color (Yellow);
               Put ("⧖ Pending ");
            when FlatRacoon.API_Client.Error =>
               Set_Color (Red);
               Put ("! Error   ");
         end case;

         Set_Color (Reset);
         Put_Line (Module.Completion'Image & "% | " & Module.Layer);
      end loop;

      Put_Line ("─────────────────────────────────────────────────────────────");
      New_Line;
   end Show_Module_Status;

   procedure Show_Health_Status is
      Health : constant FlatRacoon.API_Client.Health_Summary :=
         FlatRacoon.API_Client.Get_Health;
   begin
      Put_Line_Colored ("Health Check Summary:", Green);
      Put_Line ("─────────────────────────────────────────────────────────────");
      Put ("Overall Status: ");

      if Health.All_Healthy then
         Put_Line_Colored ("✓ All systems operational", Green);
      else
         Put_Line_Colored ("✗ Some systems degraded", Yellow);
      end if;

      New_Line;
      Put_Line ("Healthy:   " & Health.Healthy_Count'Image);
      Put_Line ("Unhealthy: " & Health.Unhealthy_Count'Image);
      Put_Line ("Unknown:   " & Health.Unknown_Count'Image);
      Put_Line ("─────────────────────────────────────────────────────────────");
      New_Line;
   end Show_Health_Status;

   procedure Show_Deployment_Order is
      Order : constant FlatRacoon.API_Client.Module_Name_List :=
         FlatRacoon.API_Client.Get_Deployment_Order;
   begin
      Put_Line_Colored ("Deployment Order (Topological Sort):", Green);
      Put_Line ("─────────────────────────────────────────────────────────────");

      for I in Order'Range loop
         Put (I'Image & ". ");
         Put_Line (Order (I));
      end loop;

      Put_Line ("─────────────────────────────────────────────────────────────");
      New_Line;
   end Show_Deployment_Order;

end FlatRacoon.Display;
