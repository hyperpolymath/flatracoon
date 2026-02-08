-- SPDX-License-Identifier: MPL-2.0-or-later
-- FlatRacoon TUI - Main entry point

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Exceptions;
with GNAT.OS_Lib;

with FlatRacoon.Commands;
with FlatRacoon.Display;
with FlatRacoon.API_Client;

procedure FlatRacoon_TUI is
   Command : Unbounded_String;
   Args : FlatRacoon.Commands.Argument_List;
begin
   -- Display banner
   FlatRacoon.Display.Show_Banner;

   -- Check for command-line arguments
   if Ada.Command_Line.Argument_Count > 0 then
      -- Execute command from args
      Command := To_Unbounded_String (Ada.Command_Line.Argument (1));

      for I in 2 .. Ada.Command_Line.Argument_Count loop
         Args.Append (To_Unbounded_String (Ada.Command_Line.Argument (I)));
      end loop;

      FlatRacoon.Commands.Execute (Command, Args);
   else
      -- Interactive mode
      Put_Line ("Type 'help' for available commands, 'exit' to quit.");
      New_Line;

      loop
         Put ("flatracoon> ");

         declare
            Input : constant String := Get_Line;
         begin
            Command := To_Unbounded_String (Input);

            exit when Input = "exit" or Input = "quit";

            if Input /= "" then
               FlatRacoon.Commands.Parse_And_Execute (Input);
            end if;
         end;
      end loop;

      Put_Line ("Goodbye!");
   end if;

exception
   when E : others =>
      Put_Line ("Fatal error: " & Ada.Exceptions.Exception_Information (E));
      GNAT.OS_Lib.OS_Exit (1);
end FlatRacoon_TUI;
