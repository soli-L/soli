
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PATCH_HIST_REPS" AUTHID CURRENT_USER as
/* $Header: adphreps.pls 115.11 2004/06/02 11:57:32 sallamse ship $ */

function get_concat_mergepatches(p_ptch_drvr_id number) return varchar2;
pragma restrict_references(get_concat_mergepatches, WNDS, WNPS);

function get_concat_minipks(p_ptch_drvr_id number) return varchar2;
pragma restrict_references(get_concat_minipks, WNDS, WNPS);

function get_level_if_one(p_app_ptch_id number) return varchar2;
pragma restrict_references(get_level_if_one, WNDS, WNPS);

function printClobOut(result IN OUT NOCOPY CLOB,line_num in number)
     return number;

function writeStrToDb(lineCounter number,
                      inStr       varchar2) return number;

function printBeginXML(line_num in number,is_patch boolean) return number;

function printEndXML(line_num in number) return number;

procedure populate_search_results
( p_query_depth       varchar2  default 1, -- PATCHES/BUGS/ACTIONS
  p_bug_num           varchar2  default NULL,
  p_bug_prod_abbr     varchar2  default NULL,
  p_end_dt_from_v     varchar2  default NULL,
  p_end_dt_to_v       varchar2  default NULL,
  p_patch_nm          varchar2  default NULL,
  p_patch_type        varchar2  default NULL,
  p_level             varchar2  default NULL,
  p_lang              varchar2  default NULL,
  p_appltop_nm        varchar2  default NULL,
  p_limit_to_forms    boolean   default FALSE,
  p_limit_to_node     boolean   default FALSE,
  p_limit_to_web      boolean   default FALSE,
  p_limit_to_admin    boolean   default FALSE,
  p_limit_to_db_drvrs boolean   default FALSE,
  p_report_format     varchar2);

end ad_patch_hist_reps;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PATCH_HIST_REPS" as
/* $Header: adphrepb.pls 115.27 2004/09/13 08:49:31 sgadag ship $ */

  maxLineLen number;

-- Function to write a text line into the teporary table

function writeStrToDb(lineCounter number,
                      inStr       varchar2)
         return number is

  -- This routine is a code simplification for the two lines that it
  -- contains. If we don't do this, we have duplicated lines throughout
  -- the program, not very efficient!

  counter number;
begin
  counter := lineCounter+1;
  insert  into ad_generic_temp (LINE_SEQUENCE,CONTENTS) values(counter,inStr);
  return counter;
end writeStrToDb;
--
function writeQueryToDb(lineCounter number,
                        sqlErr      varchar2 DEFAULT NULL,
                        qryStr      varchar2)
         return number is
   tmpQry  varchar2(4000);
   tmpStr  varchar2(4000);
   lineCnt number;
begin
   tmpQry  := qryStr;
   lineCnt := writeStrToDb(lineCounter,sqlErr||' Select String is:');
   while ( length(tmpQry) > 0 ) loop
     lineCnt := writeStrToDb(lineCnt,substr(tmpQry,1,maxLineLen));
     tmpStr  := substr(tmpQry,maxLineLen+1);
     tmpQry  := tmpStr;
   end loop;
   commit;
   return lineCnt;
end writeQueryToDb;
--
--  writes the xml output from a CLOB variable into the Global temp table
--  this function removes <ROW> </ROW> or <ROWSET> </ROWSET> from the output
--  further if the output from the CLOB variable is greater than 255 characters
--  then writes 255 characters at a time into the Global temp table.
--
function printClobOut(result IN OUT NOCOPY CLOB,line_num in number) return number is
xmlstr varchar2(32767);
line varchar2(30000);
line1 varchar2(300);
line_num_out number;
i            number;
begin
  line_num_out:=line_num;
  xmlstr := dbms_lob.SUBSTR(result,32767);
  loop
    exit when xmlstr is null;
    line := substr(xmlstr,1,instr(xmlstr,fnd_global.newline)-1);
    if instr(line,'ROW') = 0  || instr(line,'?xml version') then
      --dbms_output.put_line(line);
      if length(line) > 500 then
        i:=1;
        while i <= length(line)
        loop
          if ((i + 500) > length(line)) then
            line_num_out:=writeStrToDb(line_num_out,substr(line,i,(length(line)-i+1)));
          else
             line_num_out:=writeStrToDb(line_num_out,substr(line,i,500));
          end if;
          i:=i+500;
        end loop;
      else
        line_num_out:=writeStrToDb(line_num_out,line);
      end if;
    end if;
    xmlstr := substr(xmlstr,instr(xmlstr,fnd_global.newline)+1);
  end loop;
  return line_num_out;
end printClobOut;
--
--
--
function printBeginSearch(line_num in number) return number  is
line varchar2(20);
line_num_out number;
begin
  line :='<SEARCH_DETAILS>';
  line_num_out:=line_num;
 --dbms_output.put_line(line);
  line_num_out:=writeStrToDb(line_num_out,line);
  return line_num_out;
end printBeginSearch;
--
--
--
function printEndSearch(line_num in number) return number  is
line varchar2(20);
line_num_out number;
begin
  line :='</SEARCH_DETAILS>';
  line_num_out:=line_num;
  --dbms_output.put_line(line);
  line_num_out:=writeStrToDb(line_num_out,line);
  return line_num_out;
end printEndSearch;
--
--
--
function printBeginPatch(line_num in number) return number  is
line varchar2(20);
line_num_out number;
begin
  line :='<PATCH_DETAILS>';
  line_num_out:=line_num;
 --dbms_output.put_line(line);
  line_num_out:=writeStrToDb(line_num_out,line);
  return line_num_out;
end printBeginPatch;
--
--
--
function printEndPatch(line_num in number) return number  is
line varchar2(20);
line_num_out number;
begin
  line  :='</PATCH_DETAILS>';
  line_num_out:=line_num;
 --dbms_output.put_line(line);
  line_num_out:=writeStrToDb(line_num_out,line);
  return line_num_out;
end  printEndPatch;
--
--
--
function printBeginBug(line_num in number) return number  is
line varchar2(20);
line_num_out number;
begin
  line  :='<BUG_DETAILS>';
  line_num_out:=line_num;
 --dbms_output.put_line(line);
  line_num_out:=writeStrToDb(line_num_out,line);
  return line_num_out;
end   printBeginBug;
--
--
--
function printEndBug(line_num in number) return number  is
line varchar2(20);
line_num_out number;
begin
  line  :='</BUG_DETAILS>';
  line_num_out:=line_num;
 --dbms_output.put_line(line);
  line_num_out:=writeStrToDb(line_num_out,line);
  return line_num_out;
end  printEndBug;
--
--
--
function printBeginAction(line_num in number) return number  is
line varchar2(20);
line_num_out number;
begin
  line  :='<ACTION_DETAILS>';
  line_num_out:=line_num;
 --dbms_output.put_line(line);
  line_num_out:=writeStrToDb(line_num_out,line);
  return line_num_out;
end  printBeginAction;
--
--
--
function printEndAction(line_num in number) return number  is
line varchar2(20);
line_num_out number;
begin
  line  :='</ACTION_DETAILS>';
  line_num_out:=line_num;
 --dbms_output.put_line(line);
  line_num_out:=writeStrToDb(line_num_out,line);
  return line_num_out;
end  printEndAction;
--
--
--
function printBeginXML(line_num in number,is_patch boolean) return number  is
line1 varchar2(50);
line2 varchar2(500);
line3 varchar2(20);
line4 varchar2(500);
line_num_out number;
begin
  line1  :='<?xml version="1.0" ?>';
  line2  :='<?xml-stylesheet type="text/xsl" href="adptchrep.xsl"?>';
  line3  :='<ROWSET>';
  line4  :='<?xml-stylesheet type="text/xsl" href="adfilerep.xsl"?>';
  line_num_out:=line_num;
 --dbms_output.put_line(line1);
  line_num_out:=writeStrToDb(line_num_out,line1);
 --dbms_output.put_line(line2);
  if is_patch then
    line_num_out:=writeStrToDb(line_num_out,line2);
  else
    line_num_out:=writeStrToDb(line_num_out,line4);
  end if;
 --dbms_output.put_line(line3);
  line_num_out:=writeStrToDb(line_num_out,line3);

  return line_num_out;
end  printBeginXML;
--
--
--
function printEndXML(line_num in number) return number  is
line varchar2(20);
line_num_out number;
begin
  line :='</ROWSET>';
  line_num_out:=line_num;
 --dbms_output.put_line(line);
  line_num_out:=writeStrToDb(line_num_out,line);
  return line_num_out;
end  printEndXML;
--
--
--
function get_concat_mergepatches(p_ptch_drvr_id number)
         return varchar2 is

  l_concat_bugNumber   varchar2(30000);
  l_first_iter         boolean;          -- first iteration flag
  l_rem_space          number :=0;       -- remaining space
  l_len_till_now       number :=0;       -- length of l_concat_bugid

  cursor c1(p_patch_driver_id number) is
    select  bug_number from  ad_bugs where bug_id in (
      select bug_id     from   ad_comprising_patches
        where  patch_driver_id = p_patch_driver_id);
  begin
  l_concat_bugNumber   := null;
  l_first_iter         := TRUE;
  for c1_rec in c1(p_ptch_drvr_id) loop
    if (l_first_iter)
    then
      l_concat_bugNumber   := c1_rec.bug_number;
      l_first_iter         := FALSE;
      l_len_till_now       :=length(l_concat_bugNumber);
    else
      l_rem_space :=(30000 - l_len_till_now);

      -- 2 spaces must ALWAYS be available whenever we are about
      -- to make this determination.

      if (l_rem_space > length(c1_rec.bug_number) + 2)
      then
        l_concat_bugNumber := l_concat_bugNumber || ', '||
                            c1_rec.bug_number;
        -- Maintain l_len_till_now (Note: 2 is for the comma and space)
        l_len_till_now := l_len_till_now + 2 +
                          length(c1_rec.bug_number);
      else
        -- not enough space, show error message
           raise_application_error(-20500,'The total of merged patches exceed the displa
y limit. Contact Oracle Support group.');
        exit;
      end if;
    end if;
  end loop;
  return l_concat_bugNumber;
end get_concat_mergepatches;
--
--
--
function get_concat_minipks(p_ptch_drvr_id number)
         return varchar2 is

  l_concat_minipks varchar2(30000); /* intentionally having it 4K to handle
                                  the minipacks in Maintenance pack */
  l_first_iter     boolean;      -- first iteration flag

  l_rem_space        number :=0;  -- remaining space

  l_len_till_now       number :=0;  -- length of l_concat_minipks till now


cursor c1(p_patch_driver_id number) is
  select patch_level
  from   ad_patch_driver_minipks
  where  patch_driver_id = p_patch_driver_id;
begin
  l_concat_minipks := null;
  l_first_iter     := TRUE;

  for c1_rec in c1(p_ptch_drvr_id) loop
    if (l_first_iter)
    then
      l_concat_minipks := c1_rec.patch_level;
      l_first_iter     := FALSE;
      l_len_till_now   :=length(l_concat_minipks);
    else
      l_rem_space :=(30000 - l_len_till_now);

      -- if no space avail, we want to add ", ...". This means that
      -- 5 spaces must ALWAYS be available whenever we are about
      -- to make this determination. This implies that we
      -- always check for len(<patch-level>) + 5, even though we
      -- we only intend to append <patch-level>.

      if (l_rem_space > length(c1_rec.patch_level) + 5)
      then
        l_concat_minipks := l_concat_minipks || ', '||
                            c1_rec.patch_level;
        -- Maintain l_len_till_now (Note: 2 is for the comma and space)
        l_len_till_now := l_len_till_now + 2 +
                          length(c1_rec.patch_level);
      else
        -- not enough space, just append ", ..." and break the loop
        l_concat_minipks := l_concat_minipks || ', ...';
        exit;
      end if;
    end if;
  end loop;
  return l_concat_minipks;
end get_concat_minipks;
--
--
--
function get_level_if_one(p_app_ptch_id number)
         return varchar2 is

  l_patch_type       varchar2(30);
  l_maint_pack_level varchar(30);

cursor c1(p_patch_driver_id number) is
  select patch_level
  from   ad_patch_driver_minipks
  where  patch_driver_id = p_patch_driver_id;
begin
  select patch_type, maint_pack_level
  into   l_patch_type, l_maint_pack_level
  from   ad_applied_patches
  where  applied_patch_id = p_app_ptch_id;

  if (l_patch_type = 'MAINTENANCE-PACK')
  then
    return l_maint_pack_level;
  elsif (l_patch_type = 'ONE-OFF')
  then
    return NULL;
  else
    -- Mini Pack conditional declarations
    declare
      l_patch_driver_id number;
      l_level           varchar2(30);
      l_count           number;
    begin
      select patch_driver_id
      into   l_patch_driver_id
      from   ad_patch_drivers
      where  applied_patch_id = p_app_ptch_id
      and   driver_type_d_flag = 'Y';
      l_level := null;
      l_count := 0;

      for c1_rec in c1(l_patch_driver_id) loop
        l_count := l_count + 1;
        l_level := '*';
        exit when l_count >= 2;
        l_level := c1_rec.patch_level;
      end loop;
      return l_level;
      exception when no_data_found
      then
        return NULL;
    end;
  end if;

  return NULL;
end get_level_if_one;
--
--
--
procedure populate_search_results
( p_query_depth       varchar2  default 1, -- PATCHES/BUGS/ACTIONS
  p_bug_num           varchar2  default NULL,
  p_bug_prod_abbr     varchar2  default NULL,
  p_end_dt_from_v     varchar2  default NULL,
  p_end_dt_to_v       varchar2  default NULL,
  p_patch_nm          varchar2  default NULL,
  p_patch_type        varchar2  default NULL,
  p_level             varchar2  default NULL,
  p_lang              varchar2  default NULL,
  p_appltop_nm        varchar2  default NULL,
  p_limit_to_forms    boolean   default FALSE,
  p_limit_to_node     boolean   default FALSE,
  p_limit_to_web      boolean   default FALSE,
  p_limit_to_admin    boolean   default FALSE,
  p_limit_to_db_drvrs boolean   default FALSE,
  p_report_format     varchar2  )  is

  TYPE cur_typ IS REF CURSOR;
  cpatches            cur_typ;
  cbugs               cur_typ;
  cactions            cur_typ;

  -- Variables  for preparing the cursor
  l_select1           varchar2(400);
  l_select2           varchar2(255);
  l_select3           varchar2(255);
  l_select4           varchar2(255);
  l_select5           varchar2(255);
  l_from1             varchar2(255);
  l_from_bug          varchar(255);
  l_where1            varchar2(500);
  l_where2            varchar(500);
  l_where3            varchar(500);
  l_where_bug         varchar(255);
  l_order_by1         varchar2(255);

  --Variable to consolidate the into a single string

  query_str           varchar2(4000);
  query_str1          varchar2(4000);
  tmpQry              varchar2(4000);
  tmpStr              varchar2(4000);
  tmpCnt              number;
  --Variables which stores the Patch data fetched from the cursor

  v_patch_run_id      number;
  v_name              varchar2(50);
  v_language          varchar2(4) ;
  v_patch_name        varchar2(120);
  v_lvl               varchar2(30);
  v_minipks           varchar2(30000); /* intentionally having it 30K to handle
                                      the minipacks in Maintenance pack */
  v_comprptch         varchar2(30000);/* intentionally having it 30K to handle
                                        large number of comprising patches */
  v_start_date        varchar2(16);
  v_end_date          varchar2(16);
  v_driver_file_name  varchar2(30);
  v_driver_type       varchar2(20);
  v_patch_action_options varchar2(250);
  v_patch_top         varchar2(250);
  v_platform          varchar2(30);
  v_servertype        varchar2(20);

  old_patch_run_id    number := NULL;


  -- Variables which stores the Bug data fetched from the cursor

  v_bug_number        varchar2(30);
  v_product           varchar2(50);
  v_applied           varchar2(3);
  v_reason            varchar2(250);
  v_patch_run_bug_id  number;

  -- Variables which stores the Action data fetched from the cursor

  v_act_actioncode    varchar2(30);
  v_act_executed      varchar2(1);
  v_act_product       varchar2(50);
  v_act_subdir        varchar2(256);
  v_act_filename      varchar2(250);
  v_act_patch_ver     varchar2(150);
  v_act_patch_trlev   number;
  v_act_onsitever     varchar2(150);
  v_act_onsite_trlev  number;
  v_act_pkgverdb      varchar2(150);
  v_act_pkgdb_trlev   number;
  v_act_phase         varchar2(10);
  v_act_Modfr         varchar2(30);
  v_act_args          varchar2(2000);

  --Variables which store the formatted Action data

  queryCtx DBMS_XMLquery.ctxType;
  result CLOB;

  -- Variable to store line numbers
  v_line_num          number := 0;

  -- Flag for printing the unapplied patches
  v_printed_un_applied varchar2(1);

  -- Set up maximum values for lengths of strings
  maxPatchTopLen      number       :=  34; -- Matches f_patch_top definition
  rowdata             ad_generic_temp.contents%type;
  maxActSubDirLen     number       :=  23; -- Matches f_act_subdir
  l                   number;
  b                   number;
  i                   number;
  L_DATE_FMT constant varchar2(8)  := 'MM/DD/RR';
begin
  v_printed_un_applied := 'N';
  if ( p_report_format = 'TEXT' )
  then
    maxLineLen := 132;
  else
    maxLineLen := 500;
  end if;

  -- Do some setup for output later. We use this in two places, so define it
  -- once and use twice
  -- Note that we can't use a DECODE statement on boolean variables.

  if (p_limit_to_forms)
  then
    query_str1 := 'Y';
  else
    query_str1 := 'N';
  end if;

  if (p_limit_to_node)
  then
    query_str1 := query_str1||'/Y';
  else
    query_str1 := query_str1||'/N';
  end if;

  if (p_limit_to_web)
  then
    query_str1 := query_str1||'/Y';
  else
    query_str1 := query_str1||'/N';
  end if;

  if (p_limit_to_admin)
  then
    query_str1 := query_str1||'/Y';
  else
    query_str1 := query_str1||'/N';
  end if;

  v_line_num:=printBeginXML(v_line_num,TRUE);

  v_line_num:=printBeginSearch(v_line_num);


  query_str1:='Select '''||query_str1||''' LIMITTOFORMS  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);

  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);


  if (p_limit_to_db_drvrs)
  then
    query_str1 := 'Y';
  else
    query_str1 := 'N';
  end if;

  query_str1:='Select '''||query_str1||''' LIMITTOPATCHES  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);

  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);



  query_str1:='Select '''||NVL(p_bug_num,'ALL')||''' BUGNUMBER  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);


  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);

  query_str1:='Select '''||NVL(p_bug_prod_abbr,'ALL')||''' BUG_PRODUCT  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);


  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);



  query_str1:='Select '''||NVL(p_end_dt_from_v,'ALL')||''' END_DATE_FROM  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);


  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);

  query_str1:='Select '''||NVL(p_end_dt_to_v,'ALL')||''' END_DATE_TO  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);

  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);


  query_str1:='Select '''||NVL(p_patch_nm,'ALL')||''' PATCH_NAME  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);

  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);


  query_str1:='Select '''||NVL(p_patch_type,'ALL')||''' PATCH_TYPE  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);

  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);


  query_str1:='Select '''||NVL(p_level,'ALL')||''' PATCH_LEVEL  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);

  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);

  query_str1:='Select '''||NVL(p_lang,'ALL')||''' LANGUAGE  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);

  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);


  query_str1:='Select '''||NVL(p_appltop_nm,'ALL')||''' APPL_TOP  from dual';

  queryCtx := DBMS_XMLQuery.newContext(query_str1);

  result := DBMS_XMLQuery.getXML(queryCtx);

  DBMS_XMLQuery.closeContext(queryCtx);

  v_line_num:=printClobOut(result,v_line_num);

  v_line_num:=printEndSearch(v_line_num);


  --@@TODO: substr everything based on max allowed lengths in report output

  -- Build up the following query:

  -- select pr.patch_run_id, at.name, l.language, aap.patch_name,
  --        ad_patch_hist_reps.get_level_if_one(aap.applied_patch_id) lvl,
  --        ad_patch_hist_reps.get_concat_minipks(pd.patch_driver_id) minipks,
  --        pr.start_date, pr.end_date, pd.driver_file_name,
  --        decode(pd.driver_type_c_flag, 'Y', 'Copy', null)||
  --        decode(pd.driver_type_d_flag, 'Y',
  --        decode(pd.driver_type_c_flag, ''Y'', '',DB'', ''DB''),null)||
  --        decode(pd.driver_type_g_flag, ''Y'',
  --               decode(pd.driver_type_c_flag, ''Y'', ',Generate',
  --                      decode(pd.driver_type_d_flag, 'Y',
  --                             ,Generate', 'Generate')), null) driver_type,
  -- from ad_applied_patches aap, ad_patch_driver_langs l,
  --      ad_patch_drivers pd, ad_appl_tops at, ad_patch_runs pr
  -- where pr.appl_top_id = at.appl_top_id
  --       and pr.patch_driver_id = pd.patch_driver_id
  --       and pd.applied_patch_id = aap.applied_patch_id
  --       and pd.patch_driver_id = l.patch_driver_id
  -- order by at.name, l.language, pr.end_date desc

  -- query depth is 1 2 or 3 then

  if (p_query_depth > 0)
  then
    l_from_bug  := null;
    l_where_bug := null;
    l_where2    := null;
    l_where3    := null;
    l_select1   := 'SELECT '||
                   'pr.patch_run_id, '||
                   'at.name, '||
                   'l.language, '||
                   'aap.patch_name, '||
                   'ad_patch_hist_reps.get_level_if_one('||
                   'aap.applied_patch_id) lvl, '||
                   'ad_patch_hist_reps.get_concat_minipks('||
                   'pd.patch_driver_id) minipks, '||
                   'ad_patch_hist_reps.get_concat_mergepatches('||
                   'pd.patch_driver_id) comprptch, '||
                   'to_char(pr.start_date,''mm/dd/rr hh24:mi'') start_date,'||
                   'to_char(pr.end_date,''mm/dd/rr hh24:mi'') end_date ,'||
                   'pd.driver_file_name,';

--    dbms_output.put_line(l_select1);

    l_select2 := 'decode(pd.driver_type_c_flag,'||'''Y'',''Copy'','||
                 'null)|| '||'decode(pd.driver_type_d_flag,'||
                 '''Y'',decode(pd.driver_type_c_flag,'||
                 '''Y'',''DB'',''DB''),';

    l_select3 := 'null)|| '||'decode(pd.driver_type_g_flag,'||
                 '''Y'',decode(pd.driver_type_c_flag,'||
                 '''Y'',''Generate'','||
                 'decode(pd.driver_type_d_flag,'||
                 '''Y'',''Generate'','||
                 '''Generate'')),'||'null) driver_type,';

    l_select4 := 'pr.patch_action_options,pr.patch_top,pd.platform,';

    l_select5 := ' decode (pr.server_type_admin_flag,''Y'',''Admin'',null)||'||
                 ' decode (pr.server_type_forms_flag,''Y'',''Forms'',null)||'||
                 ' decode (pr.server_type_node_flag ,''Y'',''Node'',null)||'||
                 ' decode (pr.server_type_web_flag,''Y'',''Web'',null) '||
                 'servertype';

    l_from1   := ' FROM ad_applied_patches aap,ad_patch_driver_langs l,'||
                 'ad_patch_drivers pd,ad_appl_tops at,ad_patch_runs pr ';

    l_where1  := ' WHERE pr.appl_top_id = at.appl_top_id '||
                 'and pr.patch_driver_id = pd.patch_driver_id '||
                 'and pd.applied_patch_id = aap.applied_patch_id '||
                 'and pd.patch_driver_id = l.patch_driver_id ';

    l_order_by1:=' ORDER BY '||'at.name,l.language,pr.end_date desc';

    -- if appltop is specified
    if (p_appltop_nm IS NOT NULL)
    then
      l_where2 := l_where2 || ' and at.name ='''||p_appltop_nm||'''';
    end if;

    --Given a Target/Server Type
    if (p_limit_to_forms)
    then
      l_where2 := l_where2||' and pr.server_type_forms_flag = ''Y''';
    end if;

    if (p_limit_to_node)
    then
      l_where2 := l_where2||' and pr.server_type_node_flag = ''Y''';
    end if;

    if (p_limit_to_web)
    then
      l_where2 := l_where2||' and pr.server_type_web_flag = ''Y''';
    end if;

    if (p_limit_to_admin)
    then
      l_where2 := l_where2||' and pr.server_type_admin_flag = ''Y''';
    end if;

    -- if language is specified
    if (p_lang IS NOT NULL)
    then
      l_where2 := l_where2||' and l.language = '''||p_lang||'''';
    end if;

    -- if patch_name is specified then
    if (p_patch_nm IS NOT NULL)
    then
      l_where2 := l_where2||' and upper(aap.patch_name) = '''||p_patch_nm||'''';
    end if;

    --  if patch-type is specified but not patch-level

    if (p_patch_type IS NOT NULL) and
       (p_level IS NOT NULL)
    then
      l_where2 := l_where2||' and aap.patch_type = '''||p_patch_type||'''';
    end if;

    -- Given the PatchLevel
    if (p_level IS NOT NULL)
    then
      if (p_patch_type = 'MAINTENANCE-PACK')
      then
        --Given the PatchLevel and PatchType is 'MAINTENANCE-PACK'
        l_where2 := l_where2||' and aap.maint_pack_level = '''||
                    p_level||'''';
      elsif (p_patch_type = 'PATCH-SET')
      then
        --Given the PatchLevel and PatchType is 'PATCH-SET'
        l_where3 := l_where3||' and aap.applied_patch_id in ('||
                    'select pd2.applied_patch_id '||
                    'from ad_patch_drivers pd2 '||
                    'where pd2.patch_driver_id in ('||
                    'select mi.patch_driver_id '||
                    'from ad_patch_driver_minipks mi '||
                    'where mi.patch_level = '''||p_level||'''';
        l_where3:=l_where3||'))';
      else
        null;
        --@@ raise unexpected error
      end if;
    end if;

    --Given the ":end_date_from" component of Date Range
    if (p_end_dt_from_v IS NOT NULL)
    then
      l_where2 := l_where2||' and pr.end_date >= to_date('''||p_end_dt_from_v||
                  ''', ''';
      l_where2 := l_where2||L_DATE_FMT||''')';
    end if;

    --Given the ":end_date_to" component of Date Range
    if (p_end_dt_to_v IS NOT NULL)
    then
      l_where2 := l_where2||
                  ' and pr.end_date < trunc(to_date('''||p_end_dt_to_v||''',''';
      l_where2 := l_where2||L_DATE_FMT||''') + 1)';
    end if;

    --If "Only Patches that change the database" is YES
    if (p_limit_to_db_drvrs)
    then
      l_where2 := l_where2 || ' and pd.driver_type_d_flag = ''Y''';
    end if;

    --If bug# and/or bug-product is given, then additional tables need to be
    --joined
    if (p_bug_num IS NOT NULL) or
       (p_bug_prod_abbr IS NOT NULL)
    then
      l_from_bug  := l_from_bug ||',ad_patch_run_bugs prb, ad_bugs b';
      l_where_bug := l_where_bug||' and b.bug_id = prb.bug_id '||
                     ' and prb.patch_run_id = pr.patch_run_id ';

      if (p_bug_num IS NOT NULL)
      then
        l_where_bug := l_where_bug||' and b.bug_number ='''||p_bug_num||'''';
      end if;

      if (p_bug_prod_abbr IS NOT NULL)
      then
        l_where_bug := l_where_bug||' and upper(prb.application_short_name) '||
                       '= upper('''||p_bug_prod_abbr||''')';
      end if;
    end if;

    query_str := nvl(l_select1,' ') ||nvl(l_select2,' ')  ||nvl(l_select3,' ')||
                 nvl(l_select4,' ') ||nvl(l_select5,' ')  ||nvl(l_from1  ,' ')||
                 nvl(l_from_bug,' ')||nvl(l_where1 ,' ')  ||nvl(l_where2 ,' ')||
                 nvl(l_where3 ,' ')||nvl(l_where_bug,' ')||nvl(l_order_by1,' ');

     --debug code
     --v_line_num := writeQueryToDb(v_line_num,NULL,query_str);
    begin


      OPEN cpatches FOR query_str ;

      FETCH cpatches
      INTO v_patch_run_id,v_name      ,v_language,v_patch_name,v_lvl,
           v_minipks,v_comprptch ,v_start_date,v_end_date,v_driver_file_name,
           v_driver_type ,v_patch_action_options ,v_patch_top,
           v_platform    ,v_servertype;
      exception when others then
        --v_line_num := writeQueryToDb(v_line_num,SQLERRM,query_str);
        return;
    end;


    while cpatches%FOUND LOOP
      if (old_patch_run_id = v_patch_run_id)
      then
        goto fetch_next;
      end if;

      v_line_num:=printBeginPatch(v_line_num);

      old_patch_run_id := v_patch_run_id;

      query_str1:= 'select '''         ||
                         v_name        ||''' APPL_TOP_NAME ,'''   ||
                         v_language    ||''' LANGUAGE      ,'''   ||
                         v_patch_name  ||''' PATCH_NAME    ,'''   ||
                         v_lvl         ||''' PATCH_LEVEL   , '''   ||
                         v_minipks     ||''' MINIPACKS     ,'''   ||
                         v_comprptch   ||''' COMPRISING_PATCH,''' ||
                         v_start_date  ||''' START_DATE    , '''  ||
                         v_end_date    ||''' END_DATE      , '''  ||
                         v_driver_file_name ||''' DRIVER_NAME ,'''||
                         v_driver_type ||''' DRIVER_TYPE   , '''  ||
                         v_patch_action_options ||''' PATCH_OPTIONS , '''||
                         v_patch_top   ||''' PATCH_TOP  ,''' ||
                         v_platform    ||''' PATCH_PLATFORM , ''' ||
                         v_servertype  ||''' SERVERTYPE  from dual';


     queryCtx := DBMS_XMLQuery.newContext(query_str1);


     result := DBMS_XMLQuery.getXML(queryCtx);

     DBMS_XMLQuery.closeContext(queryCtx);
     v_line_num:=printClobOut(result,v_line_num);


      if (p_query_depth > 1)
      then
        query_str:=
         'SELECT
            bgs.BUG_NUMBER,prb.APPLICATION_SHORT_NAME,
            decode(APPLIED_FLAG,''Y'',''Yes'',''N'',''No'',''No'') APPLIED_FLAG,
            REASON_NOT_APPLIED, prb.PATCH_RUN_BUG_ID
          FROM ad_patch_run_bugs prb, ad_bugs bgs
          WHERE bgs.bug_id=prb.bug_id and prb.PATCH_RUN_ID='||v_patch_run_id;

         -- if the bug number has been passed as arguments then

         if (p_bug_num IS NOT NULL)
         then
           query_str := query_str||' and bgs.bug_number='''||p_bug_num||'''' ;
         end if;

         -- if the product has been passed as arguments then

         if (p_bug_prod_abbr IS NOT NULL)
         then
           query_str := query_str||' and prb.application_short_name='''||
                        p_bug_prod_abbr||'''' ;
         end if;

         query_str := query_str||' order by decode(APPLIED_FLAG,''N'',''Z'','||
                      'APPLIED_FLAG),bgs.bug_number';


         -- debug code
         -- v_line_num := writeQueryToDb(v_line_num,NULL,query_str);

         -- bugs loop  starts here
         begin
           OPEN cbugs FOR query_str;

           FETCH cbugs into
             v_bug_number, v_product, v_applied, v_reason, v_patch_run_bug_id;


           exception when others then
            -- v_line_num := writeQueryToDb(v_line_num,SQLERRM,query_str);
             return;
         end;

         while cbugs%found loop
           query_str1:='select '''||
                             v_bug_number||''' BUGNUMBER ,'''||
                             v_product||''' PRODUCT ,'''||
                             v_applied||''' APPLIED_FLAG ,'''||
                             v_reason ||''' REASON_NOT_APPLIED   from dual';

           v_line_num:=printBeginBug(v_line_num);
           queryCtx := DBMS_XMLQuery.newContext(query_str1);

           result := DBMS_XMLQuery.getXML(queryCtx);

           DBMS_XMLQuery.closeContext(queryCtx);

           v_line_num:=printClobOut(result,v_line_num);



           -- action loop starts here
           if (p_query_depth > 2) and (v_applied ='Yes')
           then
             query_str :=
               'SELECT cact.ACTION_CODE   Action        ,
                prba.EXECUTED_FLAG        Executed      ,
                files.APP_SHORT_NAME      Product       ,
                files.SUBDIR              Directory     ,
                files.FILENAME            Filename      ,
                nvl(pver.VERSION,''.'')     Patch_Version ,
                nvl(pver.TRANSLATION_LEVEL,0) PTrans_Level  ,
                nvl(over.VERSION,''.'')     Onsite_Version,
                nvl(over.TRANSLATION_LEVEL,0)    OTrans_Level  ,
                nvl(dver.VERSION,''.'')     DB_Version    ,
                nvl(dver.TRANSLATION_LEVEL,0)    DTrans_Level  ,
                nvl(cact.ACTION_PHASE,''.'') Phase         ,
                nvl(cact.ACTION_ARGUMENTS,''.'') Arguments  ,
                nvl(cact.ACTION_WHAT_SQL_EXEC,''.'') Modifier
                FROM ad_files files, ad_bugs bugs, ad_patch_common_actions cact,
                     ad_file_versions pver, ad_file_versions over,
                     ad_file_versions dver, ad_patch_run_bug_actions prba,
                     ad_patch_run_bugs pbug
                WHERE pbug.PATCH_RUN_BUG_ID = '||v_patch_run_bug_id||
                  ' and pbug.PATCH_RUN_BUG_ID = prba.PATCH_RUN_BUG_ID
                  and cact.COMMON_ACTION_ID = prba.COMMON_ACTION_ID
                  and pver.FILE_VERSION_ID(+) = prba.PATCH_FILE_VERSION_ID
                  and over.FILE_VERSION_ID(+) = prba.ONSITE_FILE_VERSION_ID
                  and dver.FILE_VERSION_ID(+) = prba.ONSITE_PKG_VERSION_IN_DB_ID
                  and bugs.BUG_ID = pbug.BUG_ID
                  and files.FILE_ID = prba.FILE_ID
                ORDER BY '||
                -- The below ORDER-BY decode to be in sync with the sequence
                -- of calls to adpaex() in adpmrp().
                'decode(cact.ACTION_CODE,''libout'',1,''copy'',2,
                ''forcecopy'',3,''libin'',4,''makedir'',5,''link'',6,
                ''jcopy'',7,'||
                -- sql,exec,exectier intentionally kept at same level
                '''sql'',8,''exec'',8,''exectier'',8,''genfpll'',9,
                ''genmenu'',10,''genform'',11,''genrpll'',12,''genrep'',13,
                ''gengpll'',14,''genogd'',15,''genmesg'',16,''genwfmsg'',17,50),
                cact.numeric_phase,cact.numeric_sub_phase,
                files.FILENAME,cact.ACTION_ARGUMENTS';

             -- debug code
             --v_line_num := writeQueryToDb(v_line_num,NULL,query_str);
             begin
               OPEN cactions FOR query_str;

               FETCH cactions
               INTO v_act_actioncode,v_act_executed ,v_act_product,v_act_subdir,
                    v_act_filename  ,v_act_patch_ver  ,v_act_patch_trlev   ,
                    v_act_onsitever  ,v_act_onsite_trlev  ,v_act_pkgverdb  ,
                    v_act_pkgdb_trlev ,v_act_phase ,v_act_args ,v_act_Modfr;

               exception when others then
                --v_line_num := writeQueryToDb(v_line_num,SQLERRM,query_str);
                 return;
             end;


             while cactions%found loop

    -- Bug 3396387 : When run at depth 3, this produces
    -- Null pointer eception in java. The reason is that
    -- the action arguments were being passed to the xml
    -- without converting single quote to a double quote
    -- (quote with the escape character). For example,
    -- 'FND FNDCPBWV SYSADMIN 'System Administrator' SYSADMIN'
    -- wont work. Its should be passed as
    -- FND FNDCPBWV SYSADMIN ''System Administrator'' SYSADMIN
    -- The below for loop checks 'v_act_args' and if there are single
    -- quote ('), it converts to <escape_character><quote> ('').
    -- Similarly, convert double quotes (") to <escape char>" ('").
    -- sgadag

              tmpQry := '';
              while instr(v_act_args,'''') > 0 loop
                  tmpStr := substr(v_act_args,1,instr(v_act_args,''''));
                  tmpQry := tmpQry || tmpStr || '''';
                  v_act_args := substr(v_act_args,instr(v_act_args,'''')+1);
              end loop;
              v_act_args := tmpQry || v_act_args;


              tmpQry := '';
              while instr(v_act_args,'"') > 0 loop
                  tmpStr := '';
                  if (instr(v_act_args,'"') > 1) then
                    tmpStr := substr(v_act_args,1,instr(v_act_args,'"')-1);
                  end if;
                  tmpQry := tmpQry || tmpStr || '''''"';
                  v_act_args := substr(v_act_args,instr(v_act_args,'"')+1);
               end loop;
              v_act_args := tmpQry || v_act_args;




              query_str1:='select '''||v_act_actioncode||''' ACTION, '''||
                                  v_act_executed||''' EXECUTED, '''||
                                  v_act_product||''' PRODUCT, '''||
                                  v_act_subdir||''' DIRECTORY, '''||
                                  v_act_filename||''' FILENAME, '''||
                                  v_act_patch_ver||''' PATCH_VERSION, '''||
                                  v_act_patch_trlev||''' PTRANS_LEVEL, '''||
                                  v_act_onsitever||''' ONSITE_VERSION, '''||
                                  v_act_onsite_trlev||''' OTRANS_LEVEL, '''||
                                  v_act_pkgverdb||''' PACKAGE_VERSION, '''||
                                  v_act_pkgdb_trlev||''' PKG_TRANLEVEL, '''||
                                  v_act_phase||''' ACTION_PHASE, '''||
                                  v_act_args||''' ACTION_ARGS, '''||
                                  v_act_Modfr||''' ACTION_MODIFIER  from dual';

               v_line_num:=printBeginAction(v_line_num);

               queryCtx := DBMS_XMLQuery.newContext(query_str1);

               result := DBMS_XMLQuery.getXML(queryCtx);

               DBMS_XMLQuery.closeContext(queryCtx);

               v_line_num:=printClobOut(result,v_line_num);

               v_line_num:=printEndAction(v_line_num);

               FETCH cactions
               INTO v_act_actioncode ,v_act_executed   ,v_act_product       ,
                    v_act_subdir     ,v_act_filename   ,v_act_patch_ver     ,
                    v_act_patch_trlev,v_act_onsitever  ,v_act_onsite_trlev  ,
                    v_act_pkgverdb   ,v_act_pkgdb_trlev,v_act_phase         ,
                    v_act_args, v_act_Modfr      ;

             end loop; -- End loop if cactions%found #2
             CLOSE cactions;
           end if;  --  if (p_query_depth > 2) and (v_applied ='Yes')

           FETCH cbugs
           INTO  v_bug_number,v_product,v_applied,v_reason,v_patch_run_bug_id;

        v_line_num:=printEndBug(v_line_num);

        end loop;  -- while cbugs%found loop
        CLOSE cbugs;
      end if;   -- if (p_query_depth > 1)

      --  bugs loop ends here
      <<fetch_next>>


      FETCH cpatches
      INTO v_patch_run_id        ,v_name       ,v_language  ,v_patch_name,
           v_lvl                 ,v_minipks    ,v_comprptch,v_start_date,
           v_end_date            ,v_driver_file_name    ,v_driver_type,
           v_patch_action_options,v_patch_top           ,v_platform   ,
           v_servertype;

       v_line_num:=printEndPatch(v_line_num);

    end loop; -- cpatches%FOUND LOOP
    CLOSE cpatches;
    --
    v_line_num:=printEndXML(v_line_num);
    --
  end if;   --  if query_depth is 1 ,2 or 3

  exception
    when no_data_found
    then
      null;
end populate_search_results;
--
--
--
end ad_patch_hist_reps;
