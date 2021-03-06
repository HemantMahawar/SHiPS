﻿$testpath = Split-Path $MyInvocation.MyCommand.Path -Parent

Import-Module  SHiPS -force
Import-Module  SHiPSTest -force

Import-Module  $testpath\abc.psm1 
Import-Module  $testpath\test.psm1
Import-Module  $testpath\sampleRecursion.psm1
Import-Module  $testpath\ctor.psm1

Describe "Basic Navigation" -Tags "Feature" {

BeforeEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

AfterEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }
        
    It "New-PSdrive, expect success." {
        
       $a= new-psdrive -name abc -psprovider SHiPS -root abc#abc
       $a.Name | Should Be "abc"
         
       $b= new-psdrive -name bb -psprovider SHiPS -root abc#abc
       $b.Name | Should Be "bb"
    }
    
    It "New-PSdrive and new-psdrive again with the same drive name expect error." {
        
        $a= new-psdrive -name abc -psprovider SHiPS -root abc#abc        
        $a.Name | Should Be "abc" 

        $a= new-psdrive -name abc -psprovider SHiPS -root abc#abc -ev ev -ErrorAction SilentlyContinue
        $ev.FullyQualifiedErrorId | Should Be "DriveAlreadyExists,Microsoft.PowerShell.Commands.NewPSDriveCommand"
    }

    It "New-PSdrive and run new-psdrive again with different drive name and module, expect success." {
        
       $a= new-psdrive -name kk -psprovider SHiPS -root sampleRecursion#Root        
       $a.Name | Should Be "kk" 
        
       cd kk: 
       $b= new-psdrive -name jj -psprovider SHiPS -root Test#Root        
       $b.Name | Should Be "jj" 

       cd jj:
       $c=dir
       $c[0].Name | Should Be "Bill"
       cd Bill

       cd kk:
       $d=dir
       $d[0].Name | Should Be "Austin"
       
       cd jj:
       $e=dir
       $e[0].Name | Should Be "PowerShell"
       
    }

    It "cd to root" -Skip:($IsCoreCLR -and (-not $IsWindows)){
        
       $a= new-psdrive -name jj -psprovider SHiPS -root sampleRecursion#Root
       $a.Name | Should Be "jj"

       cd jj:\Austin\explorer1\explorer2\explorer3\
       $b=dir
       $b.Name | Should be "explorer4"

       cd \
       $c=dir
       $c[0].Name | Should be "Austin"
           
       cd Austin
       $d=dir
       $d[0].Name | Should be "explorer1"
      
       $e= new-psdrive -name kk -psprovider SHiPS -root Test#Root        
       $e.Name | Should Be "kk" 

       cd kk:\William
       $f=dir
       $f[0].Name | Should Be "Chris Jr."

       cd jj:
       cd \
       $g=dir
       $g[0].Name | Should be "Austin"

       cd kk:
       cd \
       $h=dir
       $h[0].Name | Should Be "Bill"
    }

    It "new-psdrive, cd into it and dir" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root Test#Root        
       $a.Name | Should Be "jj"

       cd jj:
       $b=dir

       $b[0].Name | Should Be "Bill"
       $b[0].SSItemMode | Should Be "+"
        
       cd Bill
       $c=dir

       $c.Count | Should Be 3
       $c[0].Name | Should Be "powershell"
    }

    It "Navigating down and up" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root sampleRecursion#Root
       $a.Name | Should Be "jj"

       cd jj:
       $b=dir

       $b.Name | Should Be "Austin"
       $b.SSItemMode | Should Be "+"
        
       cd Austin
       $c=dir

       $c[0].Name | Should Be "explorer1"
       $c[0].SSItemMode | Should Be "+"

       cd explorer1
       $d=dir

       $d[0].Name | Should Be "explorer2"
       $d[0].SSItemMode | Should Be "+"

       $e=dir -force

       $e[0].Name | Should Be "explorer2"
       $e[0].SSItemMode | Should Be "+"


       cd .\explorer2\explorer3\explorer4\
       $f=dir

       $f.Count | should be 1

       # now let's navigate back
       cd ..
       $g=dir

       $g[0].Name | Should Be "explorer4"
       $g[0].SSItemMode | Should Be "+"

       $h=dir -force

       $h[0].Name | Should Be "explorer4"
       $h[0].SSItemMode | Should Be "+"

       cd ..\..\..\..\..\..\..\..\
       $i=dir

       $i.Name | Should Be "Austin"
       $i.SSItemMode | Should Be "+"
    }

    It "Directory pushd and popd" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root sampleRecursion#Root
       $a.Name | Should Be "jj"

       cd jj:
       cd .\Austin\
       $b=dir
       $b[0].Name | Should Be "explorer1"

       pushd explorer1\explorer2\explorer3
       $c = dir
       $c[0].Name | Should Be "explorer4"     

       popd
       $e=dir
       $e[0].Name | Should Be "explorer1"
     }

    It "dir with recurse" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root Test#Root        
       $a.Name | Should Be "jj"

       cd jj:
       $b=dir -Recurse

       $b.Count | Should Be 12
       $b[0].Name | Should Be "Bill"
            
    }

    It "dir with depth" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root Test#Root        
       $a.Name | Should Be "jj"

       cd jj:

       $b=dir
       $b.Count | Should Be 2
       
       $c=dir -Depth 1  
       $c.Count | Should Be 8
             
       $d=dir -Depth 2  
       $d.Count | Should Be 9


       $e1=dir -Depth 4294967295
       $e2=dir -Recurse
       $e1.Count | Should be $e2.Count
       $e2.Count |  Should Be 12
    }

    It "dir with filter" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root Test#Root        
       $a.Name | Should Be "jj"

       cd jj:
       $b=dir pow*
       $b | Should BeNullOrEmpty

       $c=dir pow* -Recurse

       $c | Should Not BeNullOrEmpty
       $c.Count | Should be 1
       $c.Name | Should be "powershell"
          
    }
    
    It "dir with include and exclude" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root Test#Root        
       $a.Name | Should Be "jj"

       cd jj:
       $b = dir -Recurse

       $c=dir -Include pow* -Recurse
       $c | Should Not BeNullOrEmpty
       $c.Count | Should be 1
       $c.Name | Should be "powershell"
               
       $d=dir -Exclude pow* -Recurse      
       $d.Count | Should be ($b.Count - $c.Count)
    }
    
    It "Navigation with FQ Provider path" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root sampleRecursion#Root -Scope global
       $a.Name | Should Be "jj"

       cd jj: 
       $b = (dir).PSParentPath
       cd $b 
       
       $c = dir
       $c.Name | Should Be "Austin"
       $c.SSItemMode | Should Be "+"

       $d = (dir).PSPath
       cd $d
       $e = dir
       $e.Name | Should Be "explorer1"
       $e.SSItemMode | Should Be "+"

       $f=get-item (dir).PSPath
       $f.Name| Should Be "explorer1"

       cd ..\
       $g = dir
       $g.Name | Should Be "Austin"
       $g.SSItemMode | Should Be "+"

       $h=get-item .\Austin\
       $h.Name| Should Be "Austin"     
    }

    It "Get-Item" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root sampleRecursion#Root
       $a.Name | Should Be "jj"

       cd jj:

       $c=get-item  -path .\*  
       $c.Name | Should Be "Austin"
       $c.SSItemMode | Should Be "+"

       
       cd $c.Name
       $b = get-item -path .\ 
       $b.Name | Should Be "Austin"

       $e=get-item -path .\e*  
       $e.Name | Should Be "explorer1"
       $e.SSItemMode | Should Be "+"

       $f=get-item  -path .\..\..\a*
       $f.Name| Should Be "Austin"       
    }
    
    It "Run from a file - Automation Case" {

        <#
            .\automationcase.ps1 contains the following:

            new-psdrive -name kk -psprovider SHiPS -root Test#Root 
            cd kk:
            dir

        #>

        & .\automationcase.ps1
        $a=dir
        $a[0].Name | Should be "bill"
        $a[1].Name | Should be "William"
     }
     
    It "Loading module from Program files - path with spaces" {
        
        $a= new-psdrive -name jj -psprovider SHiPS -root SHiPSTest#SHiPSTest
        $a.Name | Should Be "jj"

        cd jj:
       
        $b=dir
        $b[0].Name | Should be "powershell"
        $b[1].Name | Should be "SHiPSTest"
     }
          
    It "Get-, Set-, Push-, Pop-Location, Resolve-Path" -Skip:($IsCoreCLR -and (-not $IsWindows)) {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root sampleRecursion#Root
       $a.Name | Should Be "jj"

       Set-Location jj:
       Set-Location .\Austin\
       $b=dir
       $b[0].Name | Should Be "explorer1"

       $c=Get-Location
       $c.Path | Should Be "jj:\Austin"

       pushd explorer1\explorer2\explorer3
       $d = dir
       $d[0].Name | Should Be "explorer4"     

       $e=Resolve-Path -Path ..\..\
       $e.Path | Should Be "jj:\Austin\explorer1"

       $f=Resolve-Path -Path .\explorer4\
       $f.Path | Should Be "jj:\Austin\explorer1\explorer2\explorer3\explorer4"

       popd
       $g=dir
       $g[0].Name | Should Be "explorer1"
     }
}


Describe "Basic Navigation Error Cases" -Tags "Feature"{
BeforeEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

AfterEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

       It "CannotGetModule" {
        
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root Tesdfst#root -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "CannotGetModule,Microsoft.PowerShell.Commands.NewPSDriveCommand"

       }

       It "CannotGetModule" {
        
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root Tesdfst#rootsdfsf -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "CannotGetModule,Microsoft.PowerShell.Commands.NewPSDriveCommand"

       }

       It "InvalidRootFormat" {
        
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root Test$rootsdfsf -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "InvalidRootFormat,Microsoft.PowerShell.Commands.NewPSDriveCommand"

       }

       It "InvalidRootFormat" {
        
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root Test?rootsdfsf -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "InvalidRootFormat,Microsoft.PowerShell.Commands.NewPSDriveCommand"

       }
       
       It "InvalidRootFormat" {
        
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root Test::::rootsdfsf -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "InvalidRootFormat,Microsoft.PowerShell.Commands.NewPSDriveCommand"

       }

       It "Dup entries - leaf and container. warning" {
        
        $error.Clear()

        new-psdrive -name nn -psprovider SHiPS -root Test#duptest
        cd nn:
        $a=dir
        $a.Count | should be 2

       }

       It "Dup entries Leaf only. no warning" {
        
        $error.Clear()

        new-psdrive -name nn -psprovider SHiPS -root Test#chris
        cd nn:
        $a=dir
        $a.Count | should be 3

       }
       
       It "dir bogus - expected PathNotFound" {
        $error.Clear()
        $a= new-psdrive -name jj -psprovider SHiPS -root sampleRecursion#Root
        $a.Name | Should Be "jj"

        cd jj:
        cd .\Austin\
        $b=dir
        $b[0].Name | Should Be "explorer1"

      
        Get-ChildItem foooBarrr  -ErrorAction SilentlyContinue -ErrorVariable ev     
        $ev.FullyQualifiedErrorId | Should Be "PathNotFound,Microsoft.PowerShell.Commands.GetChildItemCommand"

       }
      
       It "dir leaf node - expected PathNotFound" {
        $error.Clear()
        $a= new-psdrive -name jj -psprovider SHiPS -root test#SHiPSLeafTest
        $a.Name | Should Be "jj"

        cd jj:
       
        $b=dir .\Birch
        $b[0].Name | Should Be "Birch"

      
        cd Birch  -ErrorAction SilentlyContinue -ErrorVariable ev     
        $ev.FullyQualifiedErrorId | Should Be "PathNotFound,Microsoft.PowerShell.Commands.SetLocationCommand"

       }     

       It "dir and cd to a node which just visisted - expected PathNotFound" {
        $error.Clear()
       
        $a= new-psdrive -name jj -psprovider SHiPS -root sampleRecursion#Root
        $a.Name | Should Be "jj"

        cd jj:
        $b=dir .\Austin\
        $b[0].Name | Should Be "explorer1"
       
        cd Austin
        $c=dir
        $c[0].Name | Should Be "explorer1"

        cd Austin -ErrorAction SilentlyContinue -ErrorVariable ev            
        $ev.FullyQualifiedErrorId | Should Be "PathNotFound,Microsoft.PowerShell.Commands.SetLocationCommand"
        $error.Clear()

        dir Austin -ErrorAction SilentlyContinue -ErrorVariable ev            
        $ev.FullyQualifiedErrorId | Should Be "PathNotFound,Microsoft.PowerShell.Commands.GetChildItemCommand"
        $error.Clear()

        cd .\explorer1\explorer2\
        $d=dir
        $d[0].Name | Should Be "explorer3"
        
        cd ..\..\
        cd Austin -ErrorAction SilentlyContinue -ErrorVariable ev            
        $ev.FullyQualifiedErrorId | Should Be "PathNotFound,Microsoft.PowerShell.Commands.SetLocationCommand"
        $error.Clear()

        $e=dir .\explorer1\explorer2\explorer3\ 
        $e[0].Name | Should Be "explorer4"
  
        cd explorer1\explorer2\explorer3\explorer4\
        $f=dir
        $f | Should Be "Current iteration number is 5. I have done enough. Exiting..."

        cd explorer4 -ErrorAction SilentlyContinue -ErrorVariable ev            
        $ev.FullyQualifiedErrorId | Should Be "PathNotFound,Microsoft.PowerShell.Commands.SetLocationCommand"
        $error.Clear()

        dir explorer4 -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "PathNotFound,Microsoft.PowerShell.Commands.GetChildItemCommand"
        $error.Clear()

        cd ..
        $g=dir
        $g[0].Name | Should Be "explorer4"
       } 
    
       It "dir pipe with select -first" {
        $error.Clear()
       
        $a= new-psdrive -name jj -psprovider SHiPS -root sampleRecursion#Root
        $a.Name | Should Be "jj"

                    
        dir -ErrorVariable ev| Select -First 1 -OutVariable ov
        $ev | Should BeNullOrEmpty
        $ov.Name | Should Not BeNullOrEmpty
       }
}


Describe "Filter Test" -Tags "Feature"{
BeforeEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

AfterEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

  
    It "Dir with questionmark" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root Test#Root
       $a.Name | Should Be "jj"

       cd jj:

       $b=dir -Filter  bi?l -Recurse
       $b.Name | Should Be "Bill"
       
       $c=dir -Filter  bi?l 
       $c.Name | Should Be "Bill"

       $d=dir -Filter  bi?s -Recurse
       $d.Name | Should Be "Bits"

       $e=dir bi?s -Recurse
       $e.Name | Should Be "Bits"

       $f=dir bi?s
       $f | should BeNullOrEmpty

       $g1=dir bi?s -Recurse
       $g2=dir -Filter bi?s -Recurse
       $g1.Name | Should Be $g2.Name
       $g1.Name | Should Be "bits"


       $h1=dir -filter bil?
       $h2=dir bil?
       $h1.Name | Should Be $h2.Name
       $h1.Name | Should Be "bill"

       }
    It "Dir with asterisk" {
        
       $a0= new-psdrive -name jj -psprovider SHiPS -root Test#Root
       $a0.Name | Should Be "jj"

       cd jj:

       $a=dir -filter wil*
       $a.Name | Should Be "William"

       $b=dir -filter pil*
       $b.Name | should BeNullOrEmpty

       $c=dir wil*
       $c.Name | Should Be $a.Name
       $c.Name | Should Be "William"

       
       $d=dir bi* -Recurse 
       $d.Count | should be 7

       $e =dir -Filter  bi* -Recurse 

       $e | ?{ $_.name -eq "Bill" } | should not BeNullOrEmpty
       $e | ?{ $_.name -eq "Bits" } | should not BeNullOrEmpty

       }


    It "Get-Item with questionmark" {
        
       $a0= new-psdrive -name jj -psprovider SHiPS -root Test#Root
       $a0.Name | Should Be "jj"

       cd jj:
       $a= get-item .\ -filter bil?
       $a | should BeNullOrEmpty


       cd bill
       $b= get-item .\ -filter bil?
       $b.Name | Should Be "bill"


       $c=get-item .\bi?s
       $c.Name | Should Be "bits"

       cd jj:\

       $d= get-item .\bi?l
       $d.Name | Should Be "bill"
         
       $e= get-item .\bill\bi?s
       $e.Name | Should Be "bits"

       }
    It "Get-Item with asterisk" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root Test#Root
       $a.Name | Should Be "jj"

       cd jj:

       $b1= dir bi*
       $b2= get-item .\* -Filter bi*
       $b1.Name | should be $b2.Name
       $b1.Name | should be "Bill"


       $c= get-item .\b*
       $c.Name | should be "Bill"

       $d= get-item .\bill\* -filter po*
       $d.Name | should be "Powershell"

       }

}

Describe "Constructor" -Tags "Feature"{
BeforeEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

AfterEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

    It "Environment ctor conlision with .Net Type - Success" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root ctor#Environment 
        $a.Name | Should Be "jj"

        cd jj:

        $b= dir env*
        $b.Name | Should Be "Environment"    
       }
  
    It "RegularClass ctor not from ContainerNode" {       
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root ctor#RegularClass -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "NotContainerNode,Microsoft.PowerShell.Commands.NewPSDriveCommand"
       }
    
    It "ClassDoesnotExist" {       
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root ctor#ClassDoesnotExist -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "CannotCreateInstance,Microsoft.PowerShell.Commands.NewPSDriveCommand"
       }

    It "ClassWithNoRootNameCtor missing required ctor" {       
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root ctor#ClassWithNoRootNameCtor -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "CannotCreateInstance,Microsoft.PowerShell.Commands.NewPSDriveCommand"

       }
    It "ClassWithEmptyRootName" {       
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root ctor#ClassWithEmptyRootName -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "NodeNameIsNullOrEmpty,Microsoft.PowerShell.Commands.NewPSDriveCommand"
       }

    It "ClassWithNullName" {       
        $error.Clear()

        $a=new-psdrive -name JJ -psprovider SHiPS -root ctor#ClassWithNullName -ErrorAction SilentlyContinue -ErrorVariable ev
        $a.Name | Should Be "jj"
        
        cd jj:
        $b=dir
        $b.Name | should BeNullOrEmpty
       }

    It "ClassInheritsFromShipsLeaf" {               
        $error.Clear()

        new-psdrive -name JJ -psprovider SHiPS -root ctor#ClassInheritsFromShipsLeaf -ErrorAction SilentlyContinue -ErrorVariable ev
        $ev.FullyQualifiedErrorId | Should Be "NotContainerNode,Microsoft.PowerShell.Commands.NewPSDriveCommand"
       }
       
    It "Node name contains slash" {
        
       $a= new-psdrive -name jj -psprovider SHiPS -root test#slash
       $a.Name | Should Be "jj"

       cd jj:

       $c=get-item .\Will-iam\ 
       $c.Name | Should Be "Will-iam"
       $c.PSChildName | Should Be "Will-iam"         
        
    }   
    
    It "NewDrive 3 times - expected error" {
        $error.Clear()

        $a= new-psdrive -name jj -psprovider SHiPS -root Test#Root        
        $a.Name | Should Be "jj"

        cd jj:
        dir | Should Not BeNullOrEmpty

        New-psdrive -name jj -psprovider SHiPS -root Test#Root  -ErrorAction SilentlyContinue -ErrorVariable ev                
        $ev.FullyQualifiedErrorId | Should Be "DriveAlreadyExists,Microsoft.PowerShell.Commands.NewPSDriveCommand"

        $error.Clear()
        New-psdrive -name jj -psprovider SHiPS -root Test#Root  -ErrorAction SilentlyContinue -ErrorVariable ev2                
        $ev2.FullyQualifiedErrorId | Should Be "DriveAlreadyExists,Microsoft.PowerShell.Commands.NewPSDriveCommand"
       }     
}

Describe "Cache test" -Tags "Feature"{
BeforeEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

AfterEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

    It "GetChildItem return null or empty" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root Test#ReturnNull 
        $a.Name | Should Be "jj"

        cd jj:

        $b= dir
        $b| Should BeNullOrEmpty 
        
        
        $c= new-psdrive -name empty -psprovider SHiPS -root Test#ReturnEmpty
        $c.Name | Should Be "empty"

        cd empty:

        $d= dir
        $d| Should BeNullOrEmpty   
       }

     It "UseCacheTrueAndBuiltinProgressFalse - expect succeed" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root Test#UseCacheTrueAndBuiltinProgressFalse
        $a.Name | Should Be "jj"

        cd jj:

        dir | Should be "hi" 
       }
     
     It "WithBuiltinProgressFalseButMsg - expect succeed" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root Test#WithBuiltinProgressFalseButMsg
        $a.Name | Should Be "jj"

        cd jj:

        dir | Should be "hi" 
       }

     It "WithBuiltinProgressAndMsg - expect succeed" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root Test#WithBuiltinProgressAndMsg
        $a.Name | Should Be "jj"

        cd jj:

        dir | Should be "hi" 
       }
 }
  
Describe "Dynamic Parameters test" -Tags "Feature"{
BeforeEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }

AfterEach{
        cd $home
        $a=Get-PSDrive -PSProvider SHiPS
        $a | % {remove-psdrive $_.Name -ErrorAction Ignore}
        cd $testpath
       }


     It "DynamicParameterTest - expect succeed" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root Test#DynamicParameterTest
        $a.Name | Should Be "jj"

        cd jj:

        (dir).Name | Should be "William" 

        dir -SHiPSListAvailable | Should be "Hello DynamicParameterTest" 

        cd "William"
        (dir) | Should be "Hello DynamicParameterTest2" 

        $b=dir -SHiPSListAvailable2 -CityCapital2 seattle -flowers2 @("aa", "bb")
        $b[0] | Should be "aa"
        $b[1] | Should be "bb"

       }

     It "Calling class with Cache enabled to no cache type - expect succeed" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root Test#DynamicParameterTestWithCache
        $a.Name | Should Be "jj"

        cd jj:

        (dir).Name | Should be "William" 

        dir -SHiPSListAvailable | Should be "Hello DynamicParameterTestWithCache" 

        cd "William"
        dir | Should be "Hello DynamicParameterTest2" 

        $b=dir -SHiPSListAvailable2 -CityCapital2 seattle -flowers2 @("aa", "bb")
        $b[0] | Should be "aa"
        $b[1] | Should be "bb"

       }

     It "Calling class with No Cache  to cache enabled type - expect succeed" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root Test#DynamicParameterTestWithNoCache
        $a.Name | Should Be "jj"

        cd jj:

        (dir).Name | Should be "William" 

        dir -SHiPSListAvailable | Should be "Hello DynamicParameterTestWithNoCache" 

        cd "William"
        (dir).Name | Should be "William" 

        cd "William"
        dir | Should be "Hello DynamicParameterTest2" 

        $b=dir -SHiPSListAvailable2 -CityCapital2 seattle -flowers2 @("aa", "bb")
        $b[0] | Should be "aa"
        $b[1] | Should be "bb"

       }

       It "DynamicParameterKeyValuePairTraditional - expect succeed" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root Test#DynamicParameterKeyValuePairTraditional
        $a.Name | Should Be "jj"

        cd jj:

        dir | Should be "DynamicParameterKeyValuePairTraditional:" 

        dir -list   | Should be "DynamicParameterKeyValuePairTraditional:true" 
        dir -age 22 | Should be  "DynamicParameterKeyValuePairTraditional:22"
        dir -city seattle   | Should be  "DynamicParameterKeyValuePairTraditional:seattle"
        dir -city seattle -age 11 | Should be  "DynamicParameterKeyValuePairTraditional:11seattle"
        dir -city seattle -age 11 -list | Should be  "DynamicParameterKeyValuePairTraditional:true11seattle"

       }
      
     It "Filter - expect succeed" {       
        
        $a= new-psdrive -name JJ -psprovider SHiPS -root Test#FilterTest
        $a.Name | Should Be "jj"

        cd jj:

        (dir)| Should be "hi" 

        dir -Filter William* | Should be "William*" 

        dir -Filter William* -Recurse | Should be "William*Recurse"      

       }
       
 }
  