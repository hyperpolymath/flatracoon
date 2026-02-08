-- SPDX-License-Identifier: MPL-2.0-or-later
-- FlatRacoon TUI - Display utilities

package FlatRacoon.Display is

   -- Show FlatRacoon banner
   procedure Show_Banner;

   -- Display module status table
   procedure Show_Module_Status;

   -- Display health check results
   procedure Show_Health_Status;

   -- Display deployment order
   procedure Show_Deployment_Order;

   -- Clear screen
   procedure Clear_Screen;

   -- Color codes for terminal output
   type Color_Code is (Reset, Red, Green, Yellow, Blue, Magenta, Cyan, White);

   -- Set terminal color
   procedure Set_Color (Color : Color_Code);

   -- Print with color
   procedure Put_Line_Colored (Text : String; Color : Color_Code);

end FlatRacoon.Display;
