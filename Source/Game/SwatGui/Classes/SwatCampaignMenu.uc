// ====================================================================
//  Class:  SwatGui.SwatCampaignMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatCampaignMenu extends SwatGUIPage
     ;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;


var(SWATGui) private EditInline Config GUIButton		    MyMainMenuButton;
var(SWATGui) private EditInline Config GUIButton		    MyQuitButton;
//greyed out buttons
var(SWATGui) private EditInline Config GUIButton		    CampaignTabButton;
var(SWATGui) private EditInline Config GUIButton		    MissionTabButton;
var(SWATGui) private EditInline Config GUIButton		    BriefingTabButton;
var(SWATGui) private EditInline Config GUIButton		    LoadoutTabButton;
var(SWATGui) private EditInline Config GUIButton		    StartButton;

//new campaign panel
var(SWATGui) private EditInline Config GUIEditbox		    MyNameEntry;
var(SWATGui) private EditInline Config GUIButton		    MyCreateCampaignButton;
var(SWATGui) private EditInline Config GUIComboBox			MyCampaignPathBox;
var(SWATGui) private EditInline Config GUICheckBoxButton MyCampaignPlayerPermadeathButton;
var(SWATGui) private EditInline Config GUICheckBoxButton MyCampaignOfficerPermadeathButton;

//load campaign panel
var(SWATGui) private EditInline Config GUIComboBox          MyCampaignSelectionBox;
var(SWATGui) private EditInline Config GUIButton		    MyDeleteCampaignButton;
var(SWATGui) private EditInline Config GUIButton		    MyUseCampaignButton;

var() private config localized string StringA;
var() private config localized string StringB;
var() private config localized string StringC;
var() private config localized string StringE;
var() private config localized string StringJ;
var() private config localized string StringK;
var() private config localized string StringL;
var() private config localized string StringM;
var() private config localized string StringN;
var() private config localized string StringO;

var() private config localized string DeadCampaignNotification;
var() private config localized string PlayerPermadeathNotification;
var() private config localized string KIAString;

var Campaign currentCampaign;

function InitComponent(GUIComponent MyOwner)
{
    local int index;
    local array<Campaign> TheCampaigns;

 	Super.InitComponent(MyOwner);

	// Campaign selection box
    TheCampaigns = SwatGUIController(Controller).GetCampaigns().GetCampaigns();
    MyCampaignSelectionBox.Clear();
	for(index = 0;index < TheCampaigns.length;index++)
	{
      if(TheCampaigns[index].PlayerPermadeath && TheCampaigns[index].PlayerDied) {
        MyCampaignSelectionBox.List.Add(TheCampaigns[index].StringName$KIAString,TheCampaigns[index]);
      } else {
        MyCampaignSelectionBox.List.Add(TheCampaigns[index].StringName,TheCampaigns[index]);
      }

	}
    MyCampaignSelectionBox.List.Sort();

	// Campaign path selection box
	MyCampaignPathBox.Clear();
  MyCampaignPathBox.List.Add(StringM, , , 0);	// Original Missions
	MyCampaignPathBox.List.Add(StringN, , , 1);	// SWAT 4 campaign
  MyCampaignPathBox.List.Add(StringO, , , 2); // All missions

    MyCampaignSelectionBox.OnChange=InternalOnChange;
	MyCampaignPathBox.OnChange=InternalOnChange;

    MyNameEntry.OnEntryCompleted=InternalOnClick;
    MyNameEntry.OnChange=InternalOnChange;
    MyNameEntry.OnEntryCancelled=InternalEntryCancelled;

    MyCreateCampaignButton.OnClick=InternalOnClick;
    MyUseCampaignButton.OnClick=InternalOnClick;
    MyDeleteCampaignButton.OnClick=InternalOnClick;

    CampaignTabButton.bNeverFocus=false;
}

////////////////////////////////////////////////////////////////////////////////////
// Component Management
////////////////////////////////////////////////////////////////////////////////////
private function InternalOnActivate()
{
    MyQuitButton.OnClick=InternalOnClick;
    MyMainMenuButton.OnClick=InternalOnClick;

    CampaignTabButton.Focus();
    MissionTabButton.DisableComponent();
    BriefingTabButton.DisableComponent();
    LoadoutTabButton.DisableComponent();
    StartButton.DisableComponent();

	MyCampaignPathBox.SetIndex(1);	// Use SWAT 4 missions as the default

	if( MyCampaignSelectionBox.Find(SwatGUIController(Controller).GetCampaigns().CurCampaignName) == "" )
    	MyCampaignSelectionBox.SetIndex(0);

    //can only load if one already exists
    MyCampaignSelectionBox.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
    MyUseCampaignButton.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
    MyDeleteCampaignButton.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );

    MyCreateCampaignButton.SetEnabled( IsCampaignNameValid( MyNameEntry.GetText() ) );
}

private function InternalOnFocused(GUIComponent Sender)
{
    MyNameEntry.SetText(StringK);
    MyNameEntry.Focus();
}

private function InternalOnChange(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyCampaignSelectionBox:
            //set current campaign to save to
            SetCampaign( Campaign(MyCampaignSelectionBox.GetObject()) );
            break;
		case MyNameEntry:
            MyCreateCampaignButton.SetEnabled( IsCampaignNameValid( MyNameEntry.GetText() ) );
            break;
	}
}

private function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
	    case MyQuitButton:
            Quit();
            break;
		case MyNameEntry:
		case MyCreateCampaignButton:
		    AttemptCreateCampaign( MyNameEntry.GetText(), MyCampaignPathBox.GetInt() );
			break;
		case MyUseCampaignButton:
		    //unset the pak for campaigns
        if(currentCampaign.PlayerPermadeath && currentCampaign.PlayerDied) {
          OnDlgReturned=InternalOnDlgReturned;
          OpenDlg( DeadCampaignNotification, QBTN_OK, "DeadCampaignNotification" );
        } else {
          GC.SetCustomScenarioPackData( None );
  			  Controller.OpenMenu("SwatGui.SwatMissionSetupMenu","SwatMissionSetupMenu");
        }
			break;
		case MyMainMenuButton:
            PerformClose(); break;
        case MyDeleteCampaignButton:
            OnDlgReturned=InternalOnDlgReturned;
            OpenDlg( StringJ$MyCampaignSelectionBox.Get(), QBTN_YesNo, "DeleteCampaign" );
            break;
	}
}

private function InternalEntryCancelled(GUIComponent Sender)
{
    PerformClose();
}

private function InternalOnDlgReturned( int Selection, String passback )
{
    local string campName;
	  local int campPath;
    local Campaign camp;


    switch (passback)
    {
        case "DeleteCampaign":
            if( Selection == QBTN_Yes )
            {
                camp = Campaign(MyCampaignSelectionBox.GetObject());
                campName = camp.StringName;
                DeleteCampaign(campName);

                MyCampaignSelectionBox.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
                MyUseCampaignButton.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
                MyDeleteCampaignButton.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
            }
            break;
        case "PermadeathNotice":
            if(Selection == QBTN_Yes) {
              campName = MyNameEntry.GetText();
              campPath = MyCampaignPathBox.GetInt();
              CreateCampaign(campName, campPath, MyCampaignPlayerPermadeathButton.bChecked, MyCampaignOfficerPermadeathButton.bChecked);
            }
            break;
        case "OverwriteCampaign":
            if( Selection == QBTN_Yes )
            {
                DeleteCampaign(campName);
                if(MyCampaignPlayerPermadeathButton.bChecked)
                {
                  OnDlgReturned=InternalonDlgReturned;
                  OpenDlg(PlayerPermadeathNotification, QBTN_YesNo, "PermadeathNotice");
                }
            }
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Campaign Management
////////////////////////////////////////////////////////////////////////////////////
private function SetCampaign( Campaign theCampaign )
{
    if( theCampaign == None )
        return;

    currentCampaign = theCampaign;
    SwatGuiController(Controller).UseCampaign( theCampaign.StringName );
}

private function AttemptCreateCampaign( string campName, int campPath )
{
    if( !IsCampaignNameValid( campName ) )
    {
        OnDlgReturned=InternalOnDlgReturned;
        OpenDlg( campName$StringA, QBTN_OK, "InvalidName" );
    }
    else if( SwatGuiController(Controller).CampaignExists(campName) )
    {
        OnDlgReturned=InternalOnDlgReturned;
        OpenDlg( StringC$campName$StringE, QBTN_YesNo, "OverwriteCampaign" );
    }
    else if(MyCampaignPlayerPermadeathButton.bChecked)
    {
      OnDlgReturned=InternalonDlgReturned;
      OpenDlg(PlayerPermadeathNotification, QBTN_YesNo, "PermadeathNotice");
    }
    else {
        CreateCampaign( campName, campPath, MyCampaignPlayerPermadeathButton.bChecked, MyCampaignOfficerPermadeathButton.bChecked );
    }
}

private function CreateCampaign( string campName, int campPath, bool bPlayerPermadeath, bool bOfficerPermadeath )
{
    local Campaign NewCampaign;

    //create the new campaign
    NewCampaign=SwatGuiController(Controller).AddCampaign(campName, campPath, bPlayerPermadeath, bOfficerPermadeath);
    AssertWithDescription( NewCampaign != None, "Could not create campaign with name: " $ campName );

    //... and add it to the campaign selection box
    MyCampaignSelectionBox.AddItem(NewCampaign.StringName, NewCampaign);
    //select the new one as current
    SetCampaign( NewCampaign );

    //clear the campaign name entry box
    MyNameEntry.SetText("");

    Controller.OpenMenu("SwatGui.SwatMissionSetupMenu","SwatMissionSetupMenu");
}

private function DeleteCampaign( string campName )
{
    SwatGuiController(Controller).DeleteCampaign(campName);
    MyCampaignSelectionBox.List.RemoveItem(campName);
}

private function bool IsCampaignNameValid( string Campaign )
{
    local int i;

    // 0 - length names are invalid
    if( Campaign == "" )
        return false;

    for( i = Len(Campaign) - 1; i >= 0; i-- )
    {
        // any non-space characters make the name valid
        if( Mid( Campaign, i, 1 ) != " " )
            return true;
    }

    return false;
}

defaultproperties
{
    OnFocused=InternalOnFocused
	OnActivate=InternalOnActivate

	StringA=" is not a valid campaign name."
	StringB="Campaign: "
	StringC="A campaign with the name "
	StringE=" already exists.  Do you wish to overwrite it?"
	StringJ="Are you sure that you want to delete campaign "
	StringK="Officer Default"
	StringL="Mission Set:"
	StringM="SWAT 4 + Expansion"
	StringN="Extra Missions"
  StringO="All Missions"

  DeadCampaignNotification="This campaign was killed in action (KIA). You will still be able to view its stats, but you cannot play with it."
  PlayerPermadeathNotification="You are about to start a campaign with Player Permadeath enabled. Once you die, you cannot play with this campaign again. Are you sure you want to do this?"
  KIAString=" (KIA)"
}
