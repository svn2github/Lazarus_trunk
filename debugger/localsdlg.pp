{ $Id$ }
{               ----------------------------------------------  
                 localsdlg.pp  -  Overview of local variables 
                ---------------------------------------------- 
 
 @created(Thu Mar 14st WET 2002)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.net>)                       

 This unit contains the Locals debugger dialog.
 
 
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************
}
unit LocalsDlg;

{$mode objfpc}{$H+}

interface

uses
  LResources, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Debugger, DebuggerDlg;

type
  TLocalsDlg = class(TDebuggerDlg)
    lvLocals: TListView;
  private
    FLocals: TIDELocals;
    FLocalsNotification: TIDELocalsNotification;
    procedure LocalsChanged(Sender: TObject);
    procedure SetLocals(const AValue: TIDELocals);
  protected
    procedure DoBeginUpdate; override;
    procedure DoEndUpdate; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Locals: TIDELocals read FLocals write SetLocals;
  end;


implementation

{ TLocalsDlg }

constructor TLocalsDlg.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLocalsNotification := TIDELocalsNotification.Create;
  FLocalsNotification.AddReference;
  FLocalsNotification.OnChange := @LocalsChanged;
end;

destructor TLocalsDlg.Destroy;
begin
  FLocalsNotification.OnChange := nil;
  FLocalsNotification.ReleaseReference;
  inherited Destroy;
end;

procedure TLocalsDlg.LocalsChanged(Sender: TObject);
var
  n, idx: Integer;                               
  List: TStringList;
  Item: TListItem;
  S: String;
begin                                        
  List := TStringList.Create;
  try
    BeginUpdate;
    try
      if FLocals = nil
      then begin
        lvLocals.Items.Clear;
        Exit;
      end;
    
      //Get existing items
      for n := 0 to lvLocals.Items.Count - 1 do
      begin
        Item := lvLocals.Items[n];
        S := Item.Caption;
        S := UpperCase(S);
        List.AddObject(S, Item);
      end;

      // add/update entries
      for n := 0 to FLocals.Count - 1 do
      begin
        idx := List.IndexOf(Uppercase(FLocals.Names[n]));
        if idx = -1
        then begin
          // New entry
          Item := lvLocals.Items.Add;
          Item.Caption := FLocals.Names[n];
          Item.SubItems.Add(FLocals.Values[n]);
        end
        else begin
          // Existing entry
          Item := TListItem(List.Objects[idx]);
          Item.SubItems[0] := FLocals.Values[n];
          List.Delete(idx);
        end;
      end;

      // remove obsolete entries
      for n := 0 to List.Count - 1 do
        lvLocals.Items.Delete(TListItem(List.Objects[n]).Index);

    finally
      EndUpdate;
    end;
  finally
    List.Free;
  end;
end;

procedure TLocalsDlg.SetLocals(const AValue: TIDELocals);
begin
  if FLocals = AValue then Exit;

  BeginUpdate;
  try
    if FLocals <> nil
    then begin
      FLocals.RemoveNotification(FLocalsNotification);
    end;

    FLocals := AValue;

    if FLocals <> nil
    then begin
      FLocals.AddNotification(FLocalsNotification);
    end;
    
    LocalsChanged(FLocals);
  finally
    EndUpdate;
  end;
end;

procedure TLocalsDlg.DoBeginUpdate;
begin
  lvLocals.BeginUpdate;
end;

procedure TLocalsDlg.DoEndUpdate;
begin
  lvLocals.EndUpdate;
end;

initialization
  {$I localsdlg.lrs}

end.

{
  $Log$
  Revision 1.5  2004/08/26 23:50:05  marc
  * Restructured debugger view classes
  * Fixed help

  Revision 1.4  2004/05/02 12:01:15  mattias
  removed unneeded units in uses sections

  Revision 1.3  2002/05/10 06:57:48  lazarus
  MG: updated licenses

  Revision 1.2  2002/04/24 20:42:29  lazarus
  MWE:
    + Added watches
    * Updated watches and watchproperty dialog to load as resource
    = renamed debugger resource files from *.lrc to *.lrs
    * Temporary fixed language problems on GDB (bug #508)
    * Made Debugmanager dialog handling more generic

  Revision 1.1  2002/03/23 15:54:30  lazarus
  MWE:
    + Added locals dialog
    * Modified breakpoints dialog (load as resource)
    + Added generic debuggerdlg class
    = Reorganized main.pp, all debbugger relater routines are moved
      to include/ide_debugger.inc

}
