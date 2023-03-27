//=============================================================================
// wObjectCompleter
//=============================================================================
class wObjectCompleter extends Actor config(WolfCoop);
// usage - spawn this somhow and link it.
// call function string ReturnMatchingFile(string objectname) to return the file a object is from.

// or blindly:
// this.ExecFunctionStr(stringtoname("ReturnMatchingFileBlind"),"objecttofind");
// then read  
// this.output_file or this.GetPropertyText("output_file"));

Struct actor_list
{
	var() string objpack, objclass;
};

var() array<actor_list> avalibleobjectsarray;
var() array<string> files_array;
var int current_block,total_block,files_total,classes_total;
var string output_file; // you can use getproperty/class.output_file to read this, without linking it.

var() config array<string> prohibitedPackageNames;

function PostBeginPlay()
{
	//log("start obj");
	BuildsUToList();
}

function BuildsUToList()   // build the files to a array.
{
	local string hh;
	local int filesread,tempkk;
	foreach AllFiles( "u", "", hh )
	{
		hh = ReplaceStr(hh, ".u", "");  hh = caps(hh);
		//log (hh);

		if(Level.NetMode==NM_Standalone)
		{
			tempkk = Array_Size(files_array);
			Array_Insert(files_array,Array_Size(files_array),1);
			files_array[tempkk]=caps(hh);
			filesread++;
		}
		else
		{
			if(IsInPackageMap(caps(hh)))
			{
				tempkk = Array_Size(files_array);
				Array_Insert(files_array,Array_Size(files_array),1);
				files_array[tempkk]=caps(hh);
				filesread++;
			}
		}

	}
    // the total packages avalible
	// log(filesread,'classscanner');
	
	ProcessPackages();	
}


function ProcessPackages()
{
	total_block = Array_Size(files_array);
	current_block = 0;
	SetTimer(0.1,false,'ProcessOnePackage');
}


function ProcessOnePackage()
{
	local int i;
	if (current_block < total_block) // keep going
	{
		//---------------------------------------------------------------------------
		// workarounds for singleplayer natives

		for (i = 0; i < Array_Size(prohibitedPackageNames); i++)
		{
			if (InStr(caps(files_array[current_block]),caps(prohibitedPackageNames[i])) != -1)
			{
				current_block++;
				SetTimer(0.01,false,'ProcessOnePackage');
				return;
			};
		}

		// this will break out and add 1 so we pretend we procces it.
		//---------------------------------------------------------------------------

    	BuildActorTable(files_array[current_block]);
		//log("prosseccing " $ files_array[current_block]);
		current_block++;
		if(Level.NetMode==NM_Standalone)
		{ 
			// offline play, fast proccesing, no risk of time out
			SetTimer(0.01,false,'ProcessOnePackage');
		}
		else
		{ 
			// online, dont hold anything else up
			SetTimer(0.05,false,'ProcessOnePackage');
		}
	}
	else
	{
		log("List build done " $ total_block $ " packages " $ Array_Size(avalibleobjectsarray) $ " classes",'completer');
  	}
}



function BuildActorTable(string pack)
{
	local array<Object> ObjL;
	local int c,i,kk;
	local string classname;
	if ( LoadPackageContents(pack,Class'class',ObjL) )
	{
		c = Array_Size(ObjL); 
		for( i=0; i<c; ++i )
		{
			classname = string(ObjL[i]);
			kk = Array_Size(avalibleobjectsarray);
			Array_Insert(avalibleobjectsarray,Array_Size(avalibleobjectsarray),1);
			avalibleobjectsarray[kk].objpack=caps(pack);
			avalibleobjectsarray[kk].objclass=ReplaceStr(caps(classname), caps(pack)$".", "");
		};
	}
}


function string ReturnMatchingFile(string objectname)
{
	local int z;
	log("asking for " $ caps(objectname));
	for( z = 0; z < Array_Size(avalibleobjectsarray); z++ )
	{
		if (caps(avalibleobjectsarray[z].objclass) == caps(objectname))
		{
			output_file =  avalibleobjectsarray[z].objpack;
			return avalibleobjectsarray[z].objpack;
		}
	
	}

	// nothing matches anything we know. this shouldnt be possible ???
	output_file = "broken";
	return "broken";
}


//blind return, from exectu function string
function ReturnMatchingFileBlind(string objectname)
{
	local int z;
	log("asking for " $ caps(objectname));
	For( z = 0; z < Array_Size(avalibleobjectsarray); z++ )
	{
		if (caps(avalibleobjectsarray[z].objclass) == caps(objectname))
		{
			output_file =  avalibleobjectsarray[z].objpack;
			return;
		}
	}
	// nothing matches anything we know.
	output_file = "broken";// this shouldnt be possible ???
	return;
}

defaultproperties
{
	current_block=0
	total_block=0
	files_total=0
	classes_total=0
	output_file=""
	prohibitedPackageNames[0]="ALAudio"
	prohibitedPackageNames[1]="SQL"
	prohibitedPackageNames[2]="OpenGL"
	prohibitedPackageNames[3]="ecoop3"
	prohibitedPackageNames[4]="npt"
	prohibitedPackageNames[5]="NEPHTHYS"
	prohibitedPackageNames[6]="PATHLOGIC"
	prohibitedPackageNames[7]="GlitchReal"
        prohibitedPackageNames[8]="voipmod"
        prohibitedPackageNames[9]="UnrealKismet"
        prohibitedPackageNames[10]="IpDrv"
        prohibitedPackageNames[11]="MapBuilder"
        prohibitedPackageNames[12]="ssf"
