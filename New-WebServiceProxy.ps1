#New-WebServiceProxy
$VerbosePreference = "Continue"

#1.2$uri = "https://raw.githubusercontent.com/swagger-api/swagger-spec/master/fixtures/v1.2/helloworld/static/api-docs"
$uri = "http://4threich.ddaynormandy.com/q2rconwebapp/swagger.json"
$r = Invoke-WebRequest $uri -Verbose
$uridata = $r.Content | ConvertFrom-Json
#$uridata = Invoke-RestMethod -Uri $uri

if ($uridata.swaggerVersion -eq "1.2") # limited support for 1.2
{
    #
    write-verbose "Swagger version 1.2"
    $uridata.apis.path
    foreach ($apidoc in $uridata.apis.path)
    {
        Write-Verbose $apidoc
        #$apidata = Invoke-RestMethod -Uri $apidoc
        $apidata = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/swagger-api/swagger-spec/master/fixtures/v1.2/helloworld/static/listings/greetings"
        if ($apidata.swaggerVersion -ne "1.2") {Write-Error "Spec mismatch!"}
        $apidata.basePath
        foreach ($api in $apidata.apis)
        {
            Write-Verbose $api
            $api.path
            foreach ($operation in ($api.operations))
            {
                Write-Verbose "$($operation.method) $($apidata.basePath)$($api.path)"
                $psfriendlyuri = "$($apidata.basePath)$($api.path)".Replace("{","$").Replace("}","")
                Write-Verbose $psfriendlyuri
                Write-Verbose "Invoke-RestMethod -Uri $psfriendlyuri -Method $($operation.method)"
                $subject = "this"
                Add-Member -InputObject $operation -MemberType ScriptMethod -Name "$($operation.method)$($api.path)" -Value {
                    #$subject = "this"; 
                    $thisurl = ($psfriendlyuri).Replace("`$$((get-variable subject).name)",(get-variable subject).value)
                    write-verbose "this url: $thisurl" ; 
                    Invoke-RestMethod -Uri $thisurl -Method $($operation.method)
                } -Force
            }

        }
            
    }
}

if ($uridata.swagger -eq "2.0") 
{
    Write-Output "2.0!"
    $obj = New-Object psobject
    #$uridata | select-object host,basePath  
    foreach ($path in ($uridata.paths)) 
    {
         foreach ($resource in ($path | Get-Member -MemberType NoteProperty | Select-Object Name))
            {
                Write-Output "Resource $($resource.name)"
                foreach ($method in Invoke-Expression ('$path.''{0}''| gm -MemberType NoteProperty | Select-Object Name' -f $resource.Name)) 
                {
                    Write-Output ">> $($method.name)$($resource.name)"
                    Add-Member -InputObject $obj -MemberType ScriptMethod -Name "$($method.name)$($resource.name)"  -Value {
                        Write-Output "$($method.name)$($resource.name) output"
                        if ($($method.name) -like 'get')
                        {
                            Invoke-RestMethod -Method $method.Name -Uri "$($uridata.schemes[0])://$($uridata.host)$($uridata.basePath)$($resource.name)"
                        }
                    }

                }
            }
    }
}
