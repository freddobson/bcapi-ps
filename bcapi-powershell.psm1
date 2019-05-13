Function Connect-BcApi {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$True)]
		[string]$username="admin",
		[Parameter(Mandatory=$True)]
		[string]$script:BcURL="ninjafred.info",
		[Parameter(Mandatory=$True)]
		[string]$password,	
		[Parameter(ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName)]
		[string]$page
	
		
	)
	BEGIN {}
	PROCESS {$pageNumber = $page -as [int]
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | % {$secstr.AppendChar($_)} 
$script:cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
$script:BcApiSession =(Invoke-RestMethod -Uri "https://$BcURL/api/v2/time.json" -Method Get -Credential $cred -ContentType "application/json" -body $json) }
# | ? {$_.method -match 'Options'} 
	END {}
}




      						
Function Invoke-BcApi  {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$True)]
		[string]$BcEndPt="products",
		
		[Parameter(Mandatory=$True)]
		[string]$BcMTHD="GET",
		[string]$ContentType="json",
		[string]$BcApiCountResource="",
		
        #[Parameter(ValueFromPipeline=$True,
		#ValueFromPipelineByPropertyName)]		
		
        $id="",

		$FwdSlash="",

		$BcApiPage="",

		$lastpage="",

		$BcApiLimit="",

		$BcApiBody,

		$BcFLTR="",
		
		$TimeOut=0
	)
	BEGIN {
	if (!$cred)
	  {Connect-BcApi}
	if (($BcApiPage) -and ($BcFLTR))
		{$Symbol = "&"}
	if ((!$BcApiPage) -and ($BcFLTR))
		{$Symbol = "?"}  
	if ($ContentType -eq "json")
		{$BcExt = ".json"
		$XMLorJSON = "application/json"}
	if ($ContentType -eq "xml")
		{$BcExt = ".xml"
		$XMLorJSON = "application/xml"}
	if ($BcApiCountResource -eq $true)
	{ $BcApiCount = "count"
	  $FwdSlash = "/"}
	if ($BcApiPage) 
	  {$BcPage = "?page=$BcApiPage&limit=100"}
    if ($BcApiBody)
	  { $BodySwitch = "-body"
	    $BodyParam = "$BodySwitch $BcApiBody"}
	if ($id)
	{ 
	  $FwdSlash = "/"}
	}	
	PROCESS {
	Invoke-WebRequest -Uri "https://$BcURL/api/v2/$BcEndPt$FwdSlash$id$BcApiCount$BcExt$BcPage$Symbol$BcFLTR" -Method "$BcMTHD" -Credential $cred -ContentType "$XMLorJSON" -body $BcApiBody -TimeOutSec $TimeOut
#echo $BcApiBody
#		if (($BcApiPage) -and ($BcApiPage -le $lastpage))
#	{$BcApiPage++}
	}
	END {

	}
}

Function Get-BcApiResourceCount  {
[CmdletBinding()]
	param(
[Parameter(Mandatory=$True)]
		[string]$BcEndPt,
				$BcFLTR=""
		
		) 
	BEGIN {}
	PROCESS {
	$ResourceCount = 
	@{"BcEndPt" = "$BcEndPt";
	   "BcMTHD"="Get";
	"BcApiCountResource" = 'true';
			"BcFLTR" = "$BcFLTR"
	}

   
	Invoke-BcApi @ResourceCount | ConvertFrom-Json | select count
	
	}
	END {}
}

Function Get-BcApiResourcePagination  {
[CmdletBinding()]
	param(
[Parameter(Mandatory=$True)]
		[string]$BcEndPt,
				$BcFLTR=""
		) 
	BEGIN {}
	PROCESS {
	$ResourceCount = Get-BcApiResourceCount $BcEndPt $BcFLTR
	$ResourceCountDivideByLimit= $ResourceCount.count / 100 -as [decimal]
	$lastpage=[Math]::ceiling($ResourceCountDivideByLimit)
	echo $lastpage
	}
	END {}
}

Function Get-BcApiResourceAll  {
[CmdletBinding()]
	param(
[Parameter(Mandatory=$True)]
		[string]$BcEndPt,
				$BcFLTR=""
		) 
	BEGIN {}
	PROCESS {
   
	$lastpage = (Get-BcApiResourcePagination $BcEndPt) -as [int]
	$BcApiPage = 1 -as [int]
 do {$currentProduct = (Invoke-BcApi -BcEndPt $BcEndPt -BcMTHD Get -BcApiPage $BcApiPage -BcFLTR $BcFLTR |ConvertFrom-json);$BcApiPage++;Write-Output $currentProduct}
while ($BcApiPage -le $lastpage)
	}
	END {}
}

Function Remove-BcApiResourceAll  {
[CmdletBinding()]
	param(
[Parameter(Mandatory=$True)]
		[string]$BcEndPt,
		[int]$RemTimeOut=1,
				$BcFLTR=""
		) 
	BEGIN {}
	PROCESS {
   
	$lastpage = (Get-BcApiResourcePagination $BcEndPt) -as [int]
	$BcApiPage = $lastpage -as [int]
 do {$currentProduct = (Invoke-BcApi -BcEndPt $BcEndPt -BcMTHD Get -BcApiPage $BcApiPage -BcFLTR $BcFLTR |ConvertFrom-json);$BcApiPage--;Write-Output $currentProduct|% {Remove-BcApiResource -BcEndPt $BcEndPt -id $_.id -DelTimeOut $RemTimeOut}}
while ($BcApiPage -le $lastpage)
	}
	END {}
}

Function Get-BcApiOptions {
[CmdletBinding()]
	param(
[Parameter(Mandatory=$True)]
		[string]$BcEndPt
		) 
	BEGIN {}
	PROCESS {

	(Invoke-BcApi $BcEndPt options| ConvertFrom-json).fields


	
	}
	END {}

}

Function Get-BcApiResource {
[CmdletBinding()]
	param(
[Parameter(Mandatory=$True)]
		[string]$BcEndPt,
    [Parameter(ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName)]	
		[string]$id,
				$BcFLTR=""
		) 
	BEGIN {}
	PROCESS {

    foreach ($id in $id) {

	$CurrentProduct=(Invoke-BcApi -BcMTHD Get -BcEndPt $BcEndPt -id $id -BcFLTR $BcFLTR)
    (Write-Output $CurrentProduct | ConvertFrom-json)
	    }
    }
	END {}
}


function Test-BcResourceEmptyNames {
[cmdletBinding()]
    param(
    [Parameter(ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName)]	
      [string]$name,
    [Parameter(ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName)]	
      [string]$id
    )

begin {}
process {
            

    if ([string]::IsNullOrEmpty($_.name))
    {
echo $_.id
       }
          
      
        } 
end {}
}

function Test-BcOrphanedProducts {
[cmdletBinding()]
    param(
	    [Parameter(ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName)]	
      [object]$categories,
    [Parameter(ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName)]	
      [string]$id

    )

begin {}
process {
            

    if ([string]::IsNullOrEmpty($_.categories))
    {
echo $_.id
       }
          
      
        } 
end {}
}



function Update-BcProductsCategory {
[cmdletBinding()]
    param(
    [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$id
	)

begin {}
process {
            
Invoke-BcApi -BcEndPt products -BcMTHD put -ContentType json -id $_.id -FwdSlash "/" -BcApiBody "{`"categories`":[5246]}}"

          
      
        } 
end {}
}
function Update-BcOptionsName {
[cmdletBinding()]
    param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$id,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		$display_name
		) 

begin {}
process {
            
Invoke-BcApi -BcEndPt options -BcMTHD put -ContentType json -id $id -FwdSlash "/" -BcApiBody "{`"name`": `"$script:optionsetname $display_name`"}"

          
      
        } 
end {}
}
function Update-BcCustomersGroup {
[cmdletBinding()]
    param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$id,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		$customer_group_id
		) 

begin {}
process {
            
Invoke-BcApi -BcEndPt customers -BcMTHD put -ContentType json -id $id -FwdSlash "/" -BcApiBody "{`"customer_group_id`": $customer_group_id}"

          
      
        } 
end {}
}

function Update-BcProductsRelatedProducts {
[cmdletBinding()]
    param(
    [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$id
	)

begin {}
process {
            
Invoke-BcApi -BcEndPt products -BcMTHD put -ContentType json -id $_.id -FwdSlash "/" -BcApiBody "{`"related_products`":-1}"

          
      
        } 
end {}
}


function Update-BcCategorysLayout {
[cmdletBinding()]
    param(
    [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$id
	)

begin {}
process {
            
Invoke-BcApi -BcEndPt categories -BcMTHD put -ContentType json -id $_.id -FwdSlash "/" -BcApiBody "{`"layout_file`":`"category.html`"}"

          
      
        } 
end {}
}

function Remove-BcApiResource {
[CmdletBinding()]
	param(
[Parameter(Mandatory=$True)]
		$BcEndPt,
    [Parameter(ValueFromPipelineByPropertyName)]	
		$id,
		[int]$DelTimeOut=1
		) 

begin {}
process {       
    
Invoke-BcApi -BcEndPt "$BcEndPt" -BcMTHD "delete" -ContentType "json" -id "$id" -TimeOut $DelTimeOut


        } 
end {}
}



function New-BcApiCategory {
[cmdletBinding()]
    param(

    [Parameter(Mandatory=$True,
	    ValueFromPipelineByPropertyName)]	
      [string]$name,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$description,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      [int]$parent_id,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      $sort_order,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$page_title,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$meta_keywords,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$meta_description,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$layout_file,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$image_file,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$is_visible,
       [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$search_keywords,
	      [Parameter(ValueFromPipelineByPropertyName)]	
      [string]$url
	
	)

begin {}
process {

	$name = "`"name`":`"$name`""
		if ($description)
		{$description = ",`"description`":`"$description`""}
		if ($parent_id)
		{
		$parentid = ",`"parent_id`":$parent_id"}
		if ($sort_order)
		{

		$sortorder = ",`"sort_order`":$sort_order"}
		if ($page_title)
		{$page_title = ",`"page_title`":`"$page_title`""}
		if ($meta_keywords)
		{$meta_keywords = ",`"meta_keywords`":`"$meta_keywords`""}
		if ($meta_description)
		{$meta_description = ",`"meta_description`":`"$meta_description`""}
		if ($layout_file)
		{$layout_file = ",`"layout_file`":`"$layout_file`""}
		if ($image_file)
		{$image_file = ",`"image_file`":`"$image_file`""}
		if ($is_visible)
		{$is_visible = $is_visible.Tolower()
		$isvisible = ",`"is_visible`":$is_visible"}
		if ($search_keywords)
		{$search_keywords = ",`"search_keywords`":`"$search_keywords`""}
		if ($url)
		{$url = ",`"url`":`"$url`""}




Invoke-BcApi -BcEndPt categories -BcMTHD post -ContentType json -BcApiBody "{$name$description$parentid$sortorder$page_title$meta_keywords$meta_description$layout_file$image_file$isvisible$search_keywords$url}"
#echo $name$description$parentid$sortorder$page_title$meta_keywords$meta_description$layout_file$image_file$isvisible$search_keywords$url
       
#echo $parent_id      
        } 
end {}
}

   function New-BcApiResource {
        [CmdletBinding()]
        Param ([String]$BcEndPt)
 
        DynamicParam
        {
		

		if ($BcEndPt)
		{
            $resourceinfo = (Get-BcApiOptions $BcEndPt)
            

            $paramDictionary = new-object `
                    -Type System.Management.Automation.RuntimeDefinedParameterDictionary
		  foreach ($bcfield in $resourceinfo) {
            if ($bcfield.writable_methods -match "POST")
			{
		   
		 $attributes = new-object System.Management.Automation.ParameterAttribute
                $attributes.ParameterSetName = "__AllParameterSets"
                    if ($bcfield.required_methods -match "POST") {
                    $attributes.Mandatory = $true
                    }
                $attributes.ValueFromPipelineByPropertyName = $true
                $attributeCollection = new-object `
                    -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection.Add($attributes)
#NEED DATATYPE LOGIC
                $bcfieldname = $bcfield.name
                $dynParam = new-object `
                    -Type System.Management.Automation.RuntimeDefinedParameter("$bcfieldname",[string], $attributeCollection)
            
                
                $paramDictionary.Add("$bcfieldname", $dynParam)

               

		  }
		
}

   return $paramDictionary              
        }
    }
    begin {$BcAttribs = $paramDictionary.GetEnumerator()}
    #process {echo $paramdictionary.values.key; echo $paramdictionary.values.value}
    process {
    
        foreach ($BcAttrib in $BcAttribs)
        {
        $BcAttribKey = $BcAttrib.Key
        $BcAttribVal = $BcAttrib.Value.Value
       # $BcAttribValVal = Select-Object $BcAttribVal.Value
       #echo $BcAttribs.Value 
        if ($BcAttribVal -and ($BcAttribKey -ne "id")) {
		if ($BcBodySnippet -and $BcAttribKey -and $BcAttribVal)
		{$BcComma = ","}
       $BcBodySnippet = ($BcBodySnippet + "$BcComma`"$BcAttribKey`":`"$BcAttribVal`"")
        
 
# Invoke-BcApi -BcEndPt categories -BcMTHD post -ContentType json -BcApiBody "{$BcBodySnippet}"
    }
    }
 #echo $BcBodySnippet
 Invoke-BcApi -BcEndPt $BcEndPt -BcMTHD post -ContentType json -BcApiBody "{$BcBodySnippet}"
    }
    end {}
    }

	
	
function New-BcApiRestoreOptions {
[cmdletBinding()]
    param(

    [Parameter(Mandatory=$True,
	    ValueFromPipelineByPropertyName)]	
      [string]$name,
	      [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
      [string]$id,
	      [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
      [string]$display_name,
	      [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
      [string]$type
	  	)

begin {}
process {
$optionmap = new-object -type PSCustomObject 
$optionmap|Add-Member –MemberType NoteProperty –Name oldid -Value $id
$optionmapnew = (new-BcApiResource options -name $name -display_name $display_name -type $type).content|ConvertFrom-Json
$optionmapnewid = $optionmapnew.id
$optionmap|Add-Member –MemberType NoteProperty –Name newid -Value $optionmapnewid
echo $optionmap


}
end {}
}

function New-BcApiRestoreValuesToMappedOptions {
#Send value objects to this command and choose a corresponding options map csv file.
[cmdletBinding()]
    param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$option_id,
		    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$label,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		$value,	
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		$sort_order
		
		) 

begin {$optionmap=Get-FileName|import-csv}
process {
$id=$optionmap|where {$_.oldid -eq $option_id}|select newid 
#echo $id
#Invoke-BcApi -BcEndPt options -BcMTHD post -ContentType json -id "$id/values" -FwdSlash "/" -BcApiBody "{`"label`": `"$value`",`"sort_order`": 0,`"value`": `"$value`"}"      
new-BcApiResource "options/$($id.newid)/values" -label "$label" -value "$value" -sort_order $sort_order
#echo "options/$($id.newid)/values"
}
end {}

}

function New-BcApiRestoreOptionsets {
[cmdletBinding()]
    param(

    [Parameter(Mandatory=$True,
	    ValueFromPipelineByPropertyName)]
    [alias("option_set_name")]		
      [string]$name,
	      [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		  [alias("option_set_id")]
      [string]$id
	  	)

begin {}
process {
$optionsetmap = new-object -type PSCustomObject 
$optionsetmap|Add-Member –MemberType NoteProperty –Name oldid -Value $id
$optionsetmapnew = (new-BcApiResource optionsets -name $name).content|ConvertFrom-Json
$optionsetmapnewid = $optionsetmapnew.id
$optionsetmap|Add-Member –MemberType NoteProperty –Name newid -Value $optionsetmapnewid
echo $optionsetmap


}
end {}
}


function New-BcApiRestoreOptionsToMappedOptionsets {
#Send value objects to this command and choose a corresponding options map csv file.
[cmdletBinding()]
    param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$option_id,
		    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$display_name,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		$is_required,	
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		$sort_order,
		[Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$option_set_id
		) 

begin {$optionmap=Get-FileName|import-csv
$optionsetmap=Get-FileName|import-csv
}
process {
$optionid=$optionmap|where {$_.oldid -eq $option_id}|select newid 
$optionsetid=$optionsetmap|where {$_.oldid -eq $option_set_id}|select newid
#echo $id
#Invoke-BcApi -BcEndPt options -BcMTHD post -ContentType json -id "$id/values" -FwdSlash "/" -BcApiBody "{`"label`": `"$value`",`"sort_order`": 0,`"value`": `"$value`"}"      
new-BcApiResource "optionsets/$($optionsetid.newid)/options" -option_id $($optionid.newid) -display_name "$display_name" -sort_order $sort_order  -is_required $is_required.ToLower()
#echo "options/$($optionsetid.newid)/values  $($optionid.newid)"
}
end {}

}

	
function Update-BcApiProductsThumb {
[cmdletBinding()]
    param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		[int]$ProductID,
    [Parameter(ValueFromPipelineByPropertyName)]
		[int]$ProductImageID1,
		    [Parameter(ValueFromPipelineByPropertyName)]
		[int]$SortOrder
		) 

begin {}
process {
            if(($ProductImageID1) -and ($SortOrder -eq 0))

			{Invoke-BcApi -BcEndPt "products/$ProductID/images" -BcMTHD put -ContentType json -id $ProductImageID1 -BcApiBody "{`"is_thumbnail`":true}"}
}
          
    
end {}
}

function Remove-BcApiProductsImages {
[cmdletBinding()]
    param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		[int]$ProductID,
    [Parameter(ValueFromPipelineByPropertyName)]
		[int]$ProductImageID1,
		    [Parameter(ValueFromPipelineByPropertyName)]
		[int]$SortOrder
		) 

begin {}
process {
            if(($ProductImageID1) -and ($SortOrder -eq 0))

			{Invoke-BcApi -BcEndPt "products/$ProductID/images" -BcMTHD put -ContentType json -id $ProductImageID1 -BcApiBody "{`"is_thumbnail`":true}"}
}
          
    
end {}
}



Function Compare-ForDupeIDs  {
[CmdletBinding()]
	param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$id,
    [Parameter(ValueFromPipelineByPropertyName)]
		$payment_provider_id
		) 
    begin {}

    process {
    $script:current_provider_id = $payment_provider_id
    if ($script:current_provider_id -match $script:previous_provider_id -and $script:current_provider_id)
    {
echo $id 
       }
       	$script:previous_provider_id = $script:current_provider_id
    }
    

    
    end {}
    }

Function Compare-ForUniqueOptionNames  {
[CmdletBinding()]
	param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$id,
    [Parameter(ValueFromPipelineByPropertyName)]
		$display_name
		) 
    begin {}

    process {
    $script:current_display_name = $display_name
    if ($script:current_display_name -NotMatch $script:previous_display_name -and $script:current_display_name)
    {
echo $display_name 
       }
       	$script:previous_display_name = $script:current_display_name
    }
    

    
    end {}
    }

Function Rename-BcApiOptions {
[CmdletBinding()]
	param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$id,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		[string[]]$name
		) 
    begin {}

    process {
	ForEach-Object {
$script:optionsetname = $name
Get-BcApiResource optionsets "$id/options" | % {Get-BcApiResource options $_.option_id |Update-BcOptionsName}}
    }
    

    
    end {}
    }

Function Get-BcApiResourceAllOptionSetOptions {
	Get-BcApiResourceAll optionsets|Get-BcApiOptionsetOptions
	}
	
	
Function Get-BcApiResourceOptionValues {
[CmdletBinding()]
	param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$id
		) 
    begin {}

    process {
get-bcapiresource options "$id/values"
}
   end {}
	}
Function Get-BcApiOptionsetOptions {
[CmdletBinding()]
	param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$id,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		[string[]]$name
		) 
    begin {}

    process {
	
	ForEach-Object {
#$optioniteration = 0;
#$script:optionsetobj = @{}
#$script:optionsetobj.optionsetid = "$id"
#$script:optionsetobj.options = @{}
Get-BcApiResource optionsets "$id/options" | % {$script:currentOptionID = $_.option_id;$script:currentOptionSetID = $_.option_set_id;$script:currentIsRequired = $_.is_required;$script:currentSortOrder = $_.sort_order;$script:currentDisplayName = $_.display_name;$optionsetoption=@{"option_set_id"=$script:currentOptionSetID;"option_set_name"="$name";"option_id"=$script:currentOptionID;"is_required"=$script:currentIsRequired;"sort_order"=$script:currentSortOrder;"display_name"="$script:currentDisplayName"};$objoptionsetoption = New-Object –TypeName PSObject –Prop $optionsetoption; echo $objoptionsetoption }
#Get-BcApiResource options $_.option_id }|%{$script:optionsetobj.options.$optioniteration = @{};$script:optionsetobj.options.$optioniteration.Add("display_name","$($_.display_name)");$script:optionsetobj.options.$optioniteration.Add("type","$($_.type)");$script:optionsetobj.options.$optioniteration.Add("values","$(Get-BcApiResource options $script:currentOptionID/values)");$optioniteration++}}
}
    }
    

    
    end {}
    }

	   

Function Get-BcRequestLogs  {
[CmdletBinding()]
	param(
[Parameter(Mandatory=$True)]
		[int]$lastpage
		) 
	BEGIN {}
	PROCESS {
   
	$BcApiPage = 1 -as [int]
 do {$RequestLogOutput = (Invoke-BcApi -BcEndPt "requestlogs" -BcMTHD "Get" -BcApiPage "$BcApiPage" -BcApiLimit "250" | ConvertFrom-json);$BcApiPage++;Write-Output $RequestLogOutput}
while ($BcApiPage -le $lastpage)
	}
	END {}
}




function Update-BcOptionsValue {

[cmdletBinding()]
    param(
		
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$id,
		    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]	
		$valuesid,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
		$value
		) 

begin {}
process {
            
Invoke-BcApi -BcEndPt options -BcMTHD put -ContentType json -id "$id/values/$valuesid" -FwdSlash "/" -BcApiBody "{`"label`": `"$value`",`"sort_order`": 0,`"value`": `"$value`"}"

          
      
        } 
end {}
}








Function Get-FileName($initialDirectory)
{   
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "All files (*.*)| *.*"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
} #end function Get-FileName
