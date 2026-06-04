
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_OBSOLETE_PRODUCTS" AUTHID CURRENT_USER as
/* $Header: adobsprs.pls 120.5.12020000.1 2012/06/29 11:58:54 appldev ship $*/
   -- Star of Comments
   --
   -- Name
   --
   --   Package name:   AD_OBSOLETE_PRODUCTS
   --
   -- History
   --                Aug-10-05           hxue    Creation Date
   --
   --
procedure drop_synonym_list (x_appl_id in number,
                             x_app_short_name in varchar2);
   --
   -- Purpose
   --
   --   drop correspondence synonyms (in APPS) which points to the
   --   base schema objects
   --
   -- Arguments
   --
   -- Out Parameters
   --
   --   x_appl_id
   --
   -- Example
   --
   --   none
   --
   -- Notes
   --
   --   none
   --

procedure drop_synonym_all (x_appl_id in number,
                            x_app_short_name in varchar2);
   --
   -- Purpose
   --
   --   drop all synonyms(in APPS) which points to objects in base schema
   --
   -- Arguments
   --
   -- Out Parameters
   --
   --   x_appl_id
   --   x_app_short_name
   --
   -- Example
   --
   --   none
   --
   -- Notes
   --
   --   none
   --
procedure drop_apps_objects (x_appl_id in number);
   --
   -- Purpose
   --
   --   Drop objects based on application_id from .
   --   table AD_OBSOLETE_OBJECTS
   --
   -- Arguments
   --
   -- Out Parameters
   --
   --   x_appl_id
   --
   -- Example
   --
   --   none
   --
   -- Notes
   --
   --   none
   --

procedure drop_schema_objects
     (aSqlcode      IN OUT NOCOPY  NUMBER,
      aSqlerrm      IN OUT NOCOPY  VARCHAR2,
      x_appl_id     IN             NUMBER,
      x_flag        IN             VARCHAR2);

   --
   -- Purpose
   --
   --   Drop schema objects based on application_id.
   --
   -- Arguments
   --
   -- In Parameters
   --
   --   aSqlcode
   --   aSqlerrm
   --   x_appl_id
   --   x_flag
   --
   -- Example
   --
   --   none
   --
   -- Notes
   --
   --   none
   --

procedure undo_delete_object
     ( x_appl_id     in number,
       x_object_name in varchar2,
       x_object_type in varchar2);
   --
   -- Purpose
   --
   --   Do not delette the specific objects which are inserted in
   --   AD_OBSOLETE_OBJECTS table
   --
   -- Arguments
   --
   -- In Parameters
   --
   --   x_appl_id
   --   x_object_name
   --   x_object_type
   --
   -- Example
   --
   --   none
   --
   -- Notes
   --
   --   none
   --

end AD_OBSOLETE_PRODUCTS;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_OBSOLETE_PRODUCTS" as
/* $Header: adobsprb.pls 120.20.12020000.6 2015/02/27 12:42:11 asutrala ship $*/
   -- Star of Comments
   --
   -- Name
   --
   --   Package name:   AD_OBSOLETE_PRODUCTS
   --
   -- History
   --
   --                Aug-10-05         hxue    Creation Date
   --
   --  End of Comments
   --

procedure drop_synonym_list (x_appl_id in number,
                             x_app_short_name in varchar2) is
  TYPE obs_obj_type IS TABLE OF AD_OBSOLETE_OBJECTS.object_type%TYPE;
  TYPE obs_obj_name IS TABLE OF AD_OBSOLETE_OBJECTS.object_name%TYPE;
  obs_object_type obs_obj_type;
  obs_object_name obs_obj_name;
  l_drop_statement    varchar2(200);
  l_upd_statement     varchar2(200);
  l_schema_name       varchar2(50);
  l_dropped           varchar2(1);
  l_editions_enabled  varchar2(1);
begin

  -- Special cases handling
  --  GL --> SQLGL  /  AP --> SQLAP  /  SO --> SQLSO  /  FA ----> OFA

  if (UPPER(x_app_short_name)= 'SQLGL')
      then
          l_schema_name := 'GL';

  elsif (UPPER(x_app_short_name)= 'SQLAP')
     then
          l_schema_name := 'AP';

  elsif (UPPER(x_app_short_name)= 'SQLSO')
     then
          l_schema_name := 'SO';

  elsif (UPPER(x_app_short_name)= 'OFA')
     then
          l_schema_name := 'FA';

  else

          l_schema_name := x_app_short_name;
  end if;

  l_editions_enabled := ad_zd.is_editions_enabled;

  -- dbms_output.put_line('l_schema_name: ' || l_schema_name);

  -- Do a bulk collect of non table objects from AOO

  select object_name,object_type
  bulk collect into obs_object_name, obs_object_type
  from AD_OBSOLETE_OBJECTS
  where APPLICATION_ID = x_appl_id
  and object_type not in ('TABLE', 'INDEX', 'SEQUENCE')
  and (UPPER(dropped) = 'N' or upper(dropped) is null);


  -- Now loop through this list and drop the objects one by one.

  FOR n IN 1 .. obs_object_name.count LOOP

    begin

      l_drop_statement :=  'drop '|| obs_object_type(n)
                            || ' ' || '"'
                            || obs_object_name(n)
                            || '"';

      l_upd_statement :=  'update AD_OBSOLETE_OBJECTS set DROPPED = '
                         ||'''Y'''||' where APPLICATION_ID = '|| x_appl_id
                         ||' and OBJECT_NAME = '||''''||
                         obs_object_name(n)||''''||' and OBJECT_TYPE = '||
                         ''''||obs_object_type(n)||'''';

        -- dbms_output.put_line('Drop statement: ' || l_drop_statement );
        -- dbms_output.put_line('Update statement: ' || l_upd_statement );
        -- dbms_output.put_line(' ');

      if (l_editions_enabled = 'Y' and UPPER(obs_object_type(n)) = 'MATERIALIZED VIEW')
      then
          ad_zd_mview.drop_mv(null,
                           obs_object_name(n),
                           l_drop_statement,
                           l_upd_statement,
                           l_dropped);
      else
          execute immediate l_drop_statement;
          execute immediate l_upd_statement;
      end if;

    exception
      when others then
        null;
    end;

  END LOOP;



  -- Do a bulk collect of table and objects from AOO

  select object_name,object_type
  bulk collect into obs_object_name, obs_object_type
  from AD_OBSOLETE_OBJECTS
  where APPLICATION_ID = x_appl_id
  and object_type in ('TABLE', 'INDEX', 'SEQUENCE')
  and (UPPER(dropped) = 'N' or upper(dropped) is null);


  -- Now loop through this list and drop the objects one by one.

  FOR n IN 1 .. obs_object_name.count LOOP

    begin

      l_drop_statement :=  'drop '|| obs_object_type(n)
                            || ' ' || l_schema_name
                            || '."'
                            || obs_object_name(n)
                            || '"';


      l_upd_statement :=  'update AD_OBSOLETE_OBJECTS set DROPPED = '
                         ||'''Y'''||' where APPLICATION_ID = '|| x_appl_id
                         ||' and OBJECT_NAME = '||''''||
                         obs_object_name(n)||''''||' and OBJECT_TYPE = '||
                         ''''||obs_object_type(n)||'''';

        -- dbms_output.put_line('Drop statement: ' || l_drop_statement );
        -- dbms_output.put_line('Update statement: ' || l_upd_statement );
        -- dbms_output.put_line(' ');

      if (l_editions_enabled = 'Y' and UPPER(obs_object_type(n)) = 'TABLE')
      then
          ad_zd_table.drop_table(l_schema_name,
                                 obs_object_name(n),
                                 l_drop_statement,
                                 l_upd_statement,
                                 l_dropped);
      else
          execute immediate l_drop_statement;
          execute immediate l_upd_statement;
      end if;

    exception
      when others then
        null;
    end;

  END LOOP;

end drop_synonym_list;
--
--


procedure drop_synonym_all (x_appl_id in number,
                            x_app_short_name in varchar2) is
  TYPE ds_obj_name IS TABLE OF dba_synonyms.synonym_name%TYPE;
  TYPE obs_obj_type IS TABLE OF AD_OBSOLETE_OBJECTS.object_type%TYPE;
  TYPE obs_obj_name IS TABLE OF AD_OBSOLETE_OBJECTS.object_name%TYPE;

  ds_object_name ds_obj_name;
  obs_object_type obs_obj_type;
  obs_object_name obs_obj_name;

  l_schema_name            varchar2(50);
  l_insert_statement       varchar2(500);
  l_drop_statement         varchar2(500);
  l_dropped                varchar2(1);
  l_editions_enabled       varchar2(1);
begin

  -- Special cases handling
  --  GL --> SQLGL  /  AP --> SQLAP  /  SO --> SQLSO  /  FA ----> OFA

  if (UPPER(x_app_short_name)= 'SQLGL')
      then
          l_schema_name := 'GL';

  elsif (UPPER(x_app_short_name)= 'SQLAP')
     then
          l_schema_name := 'AP';

  elsif (UPPER(x_app_short_name)= 'SQLSO')
     then
          l_schema_name := 'SO';

  elsif (UPPER(x_app_short_name)= 'OFA')
     then
          l_schema_name := 'FA';

  else

          l_schema_name := x_app_short_name;
  end if;

  -- dbms_output.put_line('l_schema_name: ' || l_schema_name);

  l_editions_enabled := ad_zd.is_editions_enabled;

  -- get the list of all

 select synonym_name
 bulk collect into ds_object_name
 from dba_synonyms
 where TABLE_OWNER = l_schema_name
 and synonym_name not in
   (select object_name
    from AD_OBSOLETE_OBJECTS
    where APPLICATION_ID = x_appl_id
    and OBJECT_TYPE = 'SYNONYM'
    and (UPPER(dropped) = 'N' or upper(dropped) is null));

  -- Now loop through this list and drop the objects one by one.

  FOR n IN 1 .. ds_object_name.count LOOP

    begin

      l_drop_statement :=  'drop SYNONYM '||'"'
                            || ds_object_name(n)
                            || '"';


      l_insert_statement := 'insert into AD_OBSOLETE_OBJECTS '||
                            '(APPLICATION_ID, OBJECT_NAME, '||
                            'OBJECT_TYPE, LAST_UPDATED_BY, '||
                            ' CREATED_BY, CREATION_DATE, '||
                            'LAST_UPDATE_DATE, DROPPED) values ('||x_appl_id||
                            ', '||''''||ds_object_name(n)||''''||', '||''''||
                            'SYNONYM'||''''||', '||'1, 1, '||
                            'sysdate, sysdate, '||''''||'Y'||''''||')';

        -- dbms_output.put_line('Drop statement: ' || l_drop_statement );
        -- dbms_output.put_line('Insert statement: ' || l_insert_statement );
        -- dbms_output.put_line(' ');
      execute immediate l_drop_statement;
      execute immediate l_insert_statement;
    exception
      when others then
        --raise_application_error(-20001, 'here');
        null;
    end;

  END LOOP;

  -- then call the drop list

  drop_synonym_list(x_appl_id, x_app_short_name);


  -- Do a bulk collect

  select object_name,object_type
  bulk collect into obs_object_name, obs_object_type
  from DBA_OBJECTS DO, FND_APPLICATION fa
  where fa.APPLICATION_ID = x_appl_id
  --and fa.APPLICATION_SHORT_NAME = do.OWNER
  and do.OWNER = decode (fa.APPLICATION_SHORT_NAME,
                         'SQLGL', 'GL',
                         'SQLAP', 'AP',
                         'SQLSO', 'SO',
                         'OFA', 'FA',
                         fa.APPLICATION_SHORT_NAME)
  and do.OBJECT_TYPE <> 'LOB'
  -- ASUTRALA - 20568870, No need to collect MV container tables
  and not exists(select 'X' from dba_mviews dm where
        (do.object_type='TABLE' or do.object_type='TABLE PARTITION') and
                 dm.owner=do.owner and dm.container_name=do.object_name);


  -- Now loop through this list and drop the objects one by one.

  FOR n IN 1 .. obs_object_name.count LOOP

    begin

      l_drop_statement :=  'drop '|| obs_object_type(n)
                            || ' ' || l_schema_name
							|| '."'
                            || obs_object_name(n)
                            || '"';

      l_insert_statement := 'insert into AD_OBSOLETE_OBJECTS '||
                            '(APPLICATION_ID, OBJECT_NAME, '||
                            'OBJECT_TYPE, LAST_UPDATED_BY, '||
                            ' CREATED_BY, CREATION_DATE, '||
                            'LAST_UPDATE_DATE, DROPPED) values ('||x_appl_id||
                            ', '||''''||obs_object_name(n)||''''||', '||''''||
                            obs_object_type(n)||''''||', '||'1, 1, '||
                            'sysdate, sysdate, '||''''||'Y'||''''||')';


      -- dbms_output.put_line('Drop statement: ' || l_drop_statement );
      -- dbms_output.put_line('Insert statement: ' || l_insert_statement );

      if (l_editions_enabled = 'Y' and UPPER(obs_object_type(n)) = 'MATERIALIZED VIEW')
      then
          ad_zd_mview.drop_mv(l_schema_name,
                           obs_object_name(n),
                           l_drop_statement,
                           l_insert_statement,
                           l_dropped);
      elsif (l_editions_enabled = 'Y' and UPPER(obs_object_type(n)) = 'TABLE')
      then
          ad_zd_table.drop_table(l_schema_name,
                           obs_object_name(n),
                           l_drop_statement,
                           l_insert_statement,
                           l_dropped);
      else
          execute immediate l_drop_statement;
          execute immediate l_insert_statement;
      end if;

    exception
      when others then
        null;
	    --raise_application_error(-20001, 'here');
    end;

  END LOOP;



  -- Update FND dictionary: FND_ORACLE_USERID

  delete from FND_ORACLE_USERID
  where oracle_id =
    ( select  oracle_id from FND_PRODUCT_INSTALLATIONS where application_id = x_appl_id)
   and oracle_username = l_schema_name;


  -- Update FND dictionary: FND_PRODUCT_INSTALLATIONS

  delete from FND_PRODUCT_INSTALLATIONS where application_id = x_appl_id;


  -- Update FND dictionary: FND_PRODUCT_DEPENDENCIES

  delete from FND_PRODUCT_DEPENDENCIES where required_application_id = x_appl_id;

  --update AD_TRACKABLE_ENTITIES

  delete from AD_TRACKABLE_ENTITIES where abbreviation = l_schema_name;


end drop_synonym_all;
--
--



procedure drop_apps_objects(x_appl_id in number) is
  TYPE obs_obj_type IS TABLE OF AD_OBSOLETE_OBJECTS.object_type%TYPE;
  TYPE obs_obj_name IS TABLE OF AD_OBSOLETE_OBJECTS.object_name%TYPE;
  TYPE obs_obj_flag IS TABLE OF AD_OBSOLETE_OBJECTS.dropped%TYPE;
  obs_object_type obs_obj_type;
  obs_object_name obs_obj_name;
  obs_object_flag obs_obj_flag;
  l_drop_statement    varchar2(200);
  l_upd_statement     varchar2(200);
  l_apps_oracle_name  varchar2(30);
  l_dropped           varchar2(1);
  l_editions_enabled  varchar2(1);
begin

  -- Get APPSSchema Info

  Begin

    SELECT oracle_username
    INTO l_apps_oracle_name
    FROM fnd_oracle_userid
    WHERE oracle_id BETWEEN 900 and 999
    and read_only_flag = 'U';

    exception
       when no_data_found then
       raise_application_error(-20001,
       'oracle_username for APPS does not'
	   ||' exist in fnd_oracle_userid. ');
  end;

  -- dbms_output.put_line('l_apps_oracle_name: ' || l_apps_oracle_name);

  l_editions_enabled := ad_zd.is_editions_enabled;

  -- Do a bulk collect

  select aoo.object_name, aoo.object_type, aoo.dropped
  bulk collect into obs_object_name, obs_object_type, obs_object_flag
  from AD_OBSOLETE_OBJECTS aoo
  where aoo.APPLICATION_ID = x_appl_id
  and (UPPER(dropped) = 'N' or upper(dropped) is null)
  and aoo.object_type <> 'SYNONYM'
  and exists
       (select do.object_name from dba_objects do
        where do.owner = l_apps_oracle_name
        and do.OBJECT_NAME = aoo.OBJECT_NAME
        and do.object_type = aoo.object_type);

  -- Now loop through this list and drop the objects one by one.

  FOR n IN 1 .. obs_object_name.count LOOP

    begin

      l_drop_statement :=  'drop '|| obs_object_type(n)
                            || ' ' || '"'
                            || obs_object_name(n);

      l_drop_statement := l_drop_statement || '"';

      if (obs_object_type(n) = 'TYPE') then
         l_drop_statement := l_drop_statement || ' force';
      end if;

      -- dbms_output.put_line('Drop statement: ' || l_drop_statement );
      -- dbms_output.put_line(' ');

      if (l_editions_enabled = 'Y' and (UPPER(obs_object_type(n)) = 'TABLE' or
          UPPER(obs_object_type(n)) = 'MATERIALIZED VIEW'))
      then
          l_upd_statement := 'update AD_OBSOLETE_OBJECTS set DROPPED = '
                             ||'''Y'''||' where APPLICATION_ID = '|| x_appl_id
                             ||' and OBJECT_NAME = '||''''||
                             obs_object_name(n)||''''||' and OBJECT_TYPE = '||
                             ''''||obs_object_type(n)||'''';

          if (UPPER(obs_object_type(n)) = 'TABLE')
          then
              ad_zd_table.drop_table(null,
                                     obs_object_name(n),
                                     l_drop_statement,
                                     l_upd_statement,
                                     l_dropped);
          else
              ad_zd_mview.drop_mv(null,
                           obs_object_name(n),
                           l_drop_statement,
                           l_upd_statement,
                           l_dropped);
          end if;

          obs_object_flag(n) := l_dropped;

      else
          execute immediate l_drop_statement;
           /* If it gets this far, then the object was dropped */
          obs_object_flag(n) := 'Y';
      end if;

    exception
      when others then
        /* If we get into the exception block, then we failed */
        obs_object_flag(n) := 'N';
    end;

  END LOOP;

    /* Updates all object rows, but dropped is set to Y or N based on
       success or failure */
    FORALL n in obs_object_name.first .. obs_object_name.last
      update ad_obsolete_objects set dropped = obs_object_flag(n)
      where object_name = obs_object_name(n)
      and object_type = obs_object_type(n)
      and application_id = x_appl_id;

end drop_apps_objects;
--
--



procedure drop_schema_objects
     (aSqlcode      IN OUT NOCOPY  NUMBER,
      aSqlerrm      IN OUT NOCOPY  VARCHAR2,
      x_appl_id     IN             NUMBER,
      x_flag        IN             VARCHAR2) is

  l_app_short_name          varchar2(50);


begin

 -- get the schema name

  begin
  select APPLICATION_SHORT_NAME
  into l_app_short_name
  from FND_APPLICATION
  where APPLICATION_ID = x_appl_id;

  exception
       when no_data_found then
       raise_application_error(-20001,
       'Application ID "'|| x_appl_id
           ||'" is not registered in FND_APPLICATION. ');

  end;

  -- Verify if a  shared base schema for multiple products

  if x_appl_id= 0 or x_appl_id = 800

	then
          raise_application_error(-20001,
          'Can not drop APPLICATION "'||l_app_short_name||
		  '" with APPLICATION ID is "'||UPPER(x_appl_id)||
		  '". This is a shared base schema for multiple products.');
  end if;

  --
  -- Valid x_flag
  --

      if (UPPER(x_flag) <> 'ALL'
          AND
          UPPER(x_flag) <> 'LIST')

      then
          raise_application_error(-20001,
          'Unknown flag "'||UPPER(x_flag)||
          '". Valid object types are ALL or LIST.');
      end if;

  --
  -- based on x_flag to call different processure
  --

      if (UPPER(x_flag) = 'ALL')
         then
           drop_synonym_all (x_appl_id , l_app_short_name);
      else
           drop_synonym_list (x_appl_id, l_app_short_name);
      end if;


end drop_schema_objects;
--

procedure undo_delete_object
     ( x_appl_id     in number,
       x_object_name in varchar2,
       x_object_type in varchar2) is
  l_delete_statement       varchar2(500);
begin
      l_delete_statement := 'delete from AD_OBSOLETE_OBJECTS '||
                            'where APPLICATION_ID = '|| x_appl_id ||
                            ' and OBJECT_NAME = '''||x_object_name ||
                            ''' and OBJECT_TYPE = '''|| x_object_type
                            || '''';
      execute immediate l_delete_statement;


end undo_delete_object;

end AD_OBSOLETE_PRODUCTS;
