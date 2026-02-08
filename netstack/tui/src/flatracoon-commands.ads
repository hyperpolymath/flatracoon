-- SPDX-License-Identifier: MPL-2.0-or-later
-- FlatRacoon TUI - Command execution

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package FlatRacoon.Commands is

   package String_Vectors is new Ada.Containers.Vectors
      (Index_Type => Positive,
       Element_Type => Unbounded_String);

   subtype Argument_List is String_Vectors.Vector;

   -- Available commands
   type Command_Type is (
      Cmd_Help,
      Cmd_Status,
      Cmd_Health,
      Cmd_Deploy,
      Cmd_Order,
      Cmd_Logs,
      Cmd_Restart,
      Cmd_Stop,
      Cmd_Unknown
   );

   -- Execute command with arguments
   procedure Execute (Command : Unbounded_String; Args : Argument_List);

   -- Parse command string and execute
   procedure Parse_And_Execute (Input : String);

   -- Show help for all commands
   procedure Show_Help;

   -- Show help for specific command
   procedure Show_Command_Help (Cmd : Command_Type);

private

   -- Parse command name to type
   function Parse_Command (Name : String) return Command_Type;

   -- Command handlers
   procedure Handle_Status (Args : Argument_List);
   procedure Handle_Health (Args : Argument_List);
   procedure Handle_Deploy (Args : Argument_List);
   procedure Handle_Order (Args : Argument_List);
   procedure Handle_Logs (Args : Argument_List);
   procedure Handle_Restart (Args : Argument_List);
   procedure Handle_Stop (Args : Argument_List);

end FlatRacoon.Commands;
