module namespace page = 'http://basex.org/modules/web-page';

(:Import other namespaces.  :)
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";
import module namespace csd_mcs = "https://github.com/openhie/openinfoman/csd_mcs";

declare namespace csd = "urn:ihe:iti:csd:2013";


declare function page:is_dhis($search_name) {
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $ufunction := csr_proc:get_updating_function_definition($csd_webconf:db,$search_name)
  let $ext := $function//csd:extension[  @urn='urn:openhie.org:openinfoman:adapter' and @type='dhis2']
  let $uext := $ufunction//csd:extension[  @urn='urn:openhie.org:openinfoman:adapter' and @type='dhis2']
  return (count($uext) + count($ext) > 0) 
};


declare function page:get_actions($search_name) {
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $ufunction := csr_proc:get_updating_function_definition($csd_webconf:db,$search_name)
  return 
    (
    for $act in $function//csd:extension[  @urn='urn:openhie.org:openinfoman:adapter:dhis2:action']/@type
    return string($act)
    ,for $act in $ufunction//csd:extension[  @urn='urn:openhie.org:openinfoman:adapter:dhis2:action']/@type
    return string($act)
  )
};

declare
  %rest:path("/CSD/adapter/dhis2/{$search_name}")
  %output:method("xhtml")
  function page:show_endpoints($search_name) 
{  
    if (not(page:is_dhis($search_name)))
      then ("Not a DHIS2 function")
    else 
      let 
	$contents :=
	  <div>
	    <h2>DHIS2 Documents</h2>
            <ul>
              {
  		for $doc_name in csd_dm:registered_documents($csd_webconf:db)      
		return
  		<li>
		  <a href="{$csd_webconf:baseurl}CSD/adapter/dhis2/{$search_name}/{$doc_name}">{string($doc_name)}</a>
		</li>
	      }
	    </ul>
	  </div>
       return csd_webconf:wrapper($contents)

 
};



declare
  %rest:path("/CSD/adapter/dhis2/{$search_name}/{$doc_name}")
  %output:method("xhtml")
  function page:show_endpoints($search_name,$doc_name) 
{  
    if (not(page:is_dhis($search_name)) ) 
      then ('Not a DHIS2 Compatible stored function'    )
    else 
      let $actions := page:get_actions($search_name)
      let $contents := 
      <div>
        <h2>DHIS Operations on {$doc_name}</h2>
        { 
          if ($actions = 'createDXF')  
	  then
	   <span>
             <h3>Aggregate Health Worker Data</h3>
	     {
	       let $url := concat($csd_webconf:baseurl, "CSD/adapter/dhis2/",$search_name, "/", $doc_name, "/createDXF")
	       return <a href="{$url}">Get DXF</a>
	     }
	   </span>
	  else ()
	}
        { 
          if ($actions = 'upload')  
	  then
	   <span>
             <h3>Upload DXF Document</h3>
	     {
	       let $url := concat($csd_webconf:baseurl, "CSD/adapter/dhis2/",$search_name, "/", $doc_name, "/upload")
	       return 
	         <form action="{$url}" method="POST" enctype="multipart/form-data">
		   <label for='dxf'>DXF File</label>
		   <input type='file' name='dxf'/>
		   <input type='submit' value='Upload'/>
		 </form>
	     }
	   </span>
	  else ()
	}
      </div>
      return csd_webconf:wrapper($contents)
};


 
declare
  %rest:path("/CSD/adapter/dhis2/{$search_name}/{$doc_name}/createDXF")
  function page:execute2($search_name,$doc_name) 
{
  if (not(page:is_dhis($search_name)) ) 
    then ('Not a DHIS2 Compatible stored function'    )
  else 
    let $doc :=  csd_dm:open_document($csd_webconf:db,$doc_name)
    let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
    let $assName := "dhis.org:orgid"
    let $careServicesRequest := 
      <csd:careServicesRequest>
       <csd:function urn="{$search_name}" resource="{$doc_name}" base_url="{$csd_webconf:baseurl}">
         <csd:requestParams >
           <assigningAuthorityName>{$assName}</assigningAuthorityName>
         </csd:requestParams>
       </csd:function>
      </csd:careServicesRequest>
    return csr_proc:process_CSR_stored_results($csd_webconf:db, $doc,$careServicesRequest)
};

declare updating
  %rest:path("/CSD/adapter/dhis2/{$search_name}/{$doc_name}/upload")   
  %rest:POST
  %rest:form-param("dxf", "{$dxf}")
  function page:update_doc($search_name,$doc_name,$dxf) 
{
  if (not(page:is_dhis($search_name)) ) then
    db:output(<restxq:redirect>{$csd_webconf:baseurl}CSD/bad</restxq:redirect>)
  else 
    let $function := csr_proc:get_updating_function_definition($csd_webconf:db,$search_name)
    let $urn := string($function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter:dhis2:action:uploadDXF:urn']/@type)
    let $oid := string($function/csd:extension[@urn='urn:openhie.org:openinfoman:adapter:dhis2:action:uploadDXF:oid']/@type)
    let $name :=  map:keys($dxf)[1]
    let $content := parse-xml(convert:binary-to-string($dxf($name)))

    let $careServicesRequest := 
      <csd:careServicesRequest>
       <csd:function urn="{$search_name}" resource="{$doc_name}" base_url="{$csd_webconf:baseurl}">
         <csd:requestParams >
           <dxf>{$content}</dxf>
           <oid>{$oid}</oid>
           <urn>{$urn}</urn>
         </csd:requestParams>
       </csd:function>
      </csd:careServicesRequest>
    return 
       (
        csr_proc:process_updating_CSR_results($csd_webconf:db, $careServicesRequest)
        ,db:output(<restxq:redirect>{$csd_webconf:baseurl}CSD</restxq:redirect>)
       )
};
