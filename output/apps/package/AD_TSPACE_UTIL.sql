
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_TSPACE_UTIL" AUTHID CURRENT_USER as
/* $Header: adtsutls.pls 115.9 2002/12/12 21:09:54 athies noship $*/
   -- Star of Comments
   --
   -- Name
   --
   --   Package name:   AD_TSPACE_UTIL
   --
   -- History
   --                Sept-10-02           hxue    Creation Date
   --                Dec-10-02            sgadag  Added function to accept
   --						  application_id
   --
   --
procedure is_new_ts_mode(x_ts_mode out NOCOPY varchar2);
   --
   -- Purpose
   --
   --   Check whether the database is in new tablespace management mode or not.
   --
   -- Arguments
   --
   -- Out Parameters
   --
   --   x_ts_mode     Return value of 'Y' indicates new tablespace management mode
   --                 Return value of 'N' indicates old tablespace management mode
   --
   -- Example
   --
   --   none
   --
   -- Notes
   --
   --   none
   --
procedure get_object_tablespace(x_product_short_name in varchar2,
                                x_object_name in varchar2,
                                x_object_type in varchar2,
                                x_index_lookup_flag in varchar2,
                                x_validate_ts_exists in varchar2,
                                x_is_object_registered out NOCOPY varchar2,
                                x_ts_exists out NOCOPY varchar2,
                                x_tablespace out NOCOPY varchar2);
   --
   -- Purpose
   --
   --   Returns the tablespace based on the product short name,
   --   object name, object type and index look up flag.
   --   Also return flags which indicate if the object specified has been registered in
   --   FND_OBJECT_TABLESPACES and if x_validate_ts_exists is passed an 'Y', will validate
   --   whether or not the tablespace exists in the database
   --
   -- Arguments
   --
   -- In Parameters
   --   x_product_short_name: Application Short Name that the object belongs to
   --   x_object_name: the name of object
   --	x_object_type: valid object types are TABLE, MVIEW, AQ_TABLE, IOT_TABLE and MV_LOG.
   --	x_index_lookup_flag: to get the tablespace for an index, pass the table
   --                        name on which the index is based as x_object_name,
   --                        pass 'TABLE' as x_object_type
   --                        and 'Y' as x_index_lookup_flag. Set this flag
   --                        to 'N'' if you are not looking up and index
   --	x_validate_ts_exists: 'Y': to check if the tablespace exist,
   --                         'N': do not check if the tablespace exist,
   -- Out Parameters
   --	x_is_object_registered: 'Y' indicates the object has been registered in
   --                               FND_OBJECT_TABLESPACES
   --                           'N' indicates the object has not been registered
   --	x_ts_exists:
   --                           'Y': indicates the tablespace exists
   --                           'N': indicates the tablespace does not exist
   --                           This will be Null if x_validate_ts_exists is 'N''
   --
   --	x_tablespace: the name of the(physical) tablespace
   --
   --  Example
   --
   --    none
   --
   --  Notes
   --
   --    none
   --
procedure get_tablespace_name(x_product_short_name in varchar2,
                              x_tablespace_type in varchar2,
                              x_validate_ts_exists in varchar2,
                              x_ts_exists out NOCOPY varchar2,
                              x_tablespace out NOCOPY varchar2);
   --
   -- Purpose
   --
   --   Returns a physical tablespace given a tablespace type (logical tablespace)
   --   and Application Short Name. Also returns a flag which indicates if the
   --   tablespace exists in the database
   --
   -- Arguments
   --  In Parameters
   --   x_product_short_name: Application Short Name that object belongs to
   --   x_tablespace_type: the tablespace type (logical tablespace name)
   --	x_validate_ts_exists: 'Y' to check if the tablespace exists,
   --                         'N' do not check
   -- Out Parameters
   --	x_ts_exists:          'Y': indicates the tablespace exists
   --                         'N': indicates the tablespace does not exist
   --                         This will be Null if x_validate_ts_exists is 'N'
   --
   --	x_tablespace: the name of the (physical) tablespace
   --
   -- Example
   --
   --   none
   --
   -- Notes
   --
   --   none
   --
function get_appl_id(x_product_short_name in varchar2) return number;
   -- Function to return application_short_name from FND_APPLICATION
   -- when passed application_id
function get_product_short_name(x_appl_id in number) return varchar2;
   -- Function to return application_id from FND_APPLICATION
   -- when passed application_short_name
end AD_TSPACE_UTIL;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_TSPACE_UTIL" as
/* $Header: adtsutlb.pls 120.0.12020000.2 2015/09/14 06:40:53 seetsing ship $*/
   -- Star of Comments
   --
   -- Name
   --
   --   Package name:   AD_TSPACE_UTIL
   --
   -- History
   --
   --                Sept-10-02         hxue    Creation Date
   --                Dec-10-02          sgadag  Added function to return
   --						application_short_name
   --
   --  End of Comments
   --

function get_appl_id(x_product_short_name in varchar2) return number
  is
   l_appl_id number;

   begin
    SELECT application_id
    INTO   l_appl_id
    FROM   fnd_application
    WHERE  UPPER(application_short_name) = UPPER(x_product_short_name);

    return(l_appl_id);

   exception
       when no_data_found then
       raise_application_error(-20001,
       'Application short name "'||UPPER(x_product_short_name)
       ||'" is not registered in FND_APPLICATION. ');

   end;

function get_product_short_name(x_appl_id in number) return varchar2
  is
   l_product_short_name varchar2(100);

   begin
    SELECT application_short_name
    INTO   l_product_short_name
    FROM   fnd_application
    WHERE  application_id = x_appl_id;

    return(l_product_short_name);

   exception
       when no_data_found then
       raise_application_error(-20001,
       'Application ID "'|| x_appl_id
           ||'" is not registered in FND_APPLICATION. ');

   end get_product_short_name;


procedure is_new_ts_mode(x_ts_mode out NOCOPY varchar2) is
    l_ts_mode varchar2(10);

begin

  -- Bug 20390467 - Removed the global_is_new_ts_mode
  -- variable, and calling this query every time as
  -- FND_PRODUCT_GROUPS table will always have 1 row,
  -- So, not an expensive query.

  SELECT UPPER(nvl(is_new_ts_mode, 'N'))
  INTO l_ts_mode
  FROM FND_PRODUCT_GROUPS
  WHERE PRODUCT_GROUP_ID = 1;

  x_ts_mode := l_ts_mode;

exception
  when no_data_found then
    raise_application_error(-20001,
    'is_new_ts_mode() failed. '||
    'No row with PRODUCT_GROUP_ID = 1 in FND_PRODUCT_GROUPS');

end is_new_ts_mode;


procedure get_object_tablespace(x_product_short_name in varchar2,
                                x_object_name in varchar2,
                                x_object_type in varchar2,
                                x_index_lookup_flag in varchar2,
                                x_validate_ts_exists in varchar2,
                                x_is_object_registered out NOCOPY varchar2,
                                x_ts_exists out NOCOPY varchar2,
                                x_tablespace out NOCOPY varchar2) is
    l_dummy varchar2(30);
    l_appl_id number;
    l_new_ts_mode varchar2(10);
    l_is_object_registered varchar2(30);
    l_object_name varchar2(30);
	l_object_type varchar2(30);
    l_tspace_type varchar2(30);
    l_tspace varchar2(30);


    CURSOR OBJ_INFO (c_appl_id number,
                     c_object_name in varchar2)
    is
    select upper(TABLESPACE_TYPE), upper(OBJECT_TYPE)
    from FND_OBJECT_TABLESPACES
    where UPPER(OBJECT_NAME)=UPPER(c_object_name)
    AND APPLICATION_ID = c_appl_id;

    CURSOR VALIDATE_TS (c_tspace in varchar2)
    is
    select TABLESPACE_NAME
    from DBA_TABLESPACES
    where TABLESPACE_NAME=UPPER(c_tspace);


    begin


--
-- get appl_id
--

       l_appl_id := get_appl_id(x_product_short_name);


--
-- Get is_new_ts_mode
--

       is_new_ts_mode(l_new_ts_mode); -- already  UPPER
--      dbms_output.PUT_LINE(l_ts_mode);


--
-- check mis-use case: check if user is using index name as object name
-- and index flag is Y
--

      if (UPPER(x_object_type) like '%INDEX%')

      then
          raise_application_error(-20001,
          'To get tablespace for index "'||UPPER(x_object_name)||
          '", pass TABLE NAME on which index is based, '||
          ' pass OBJECT TYPE as TABLE,'||
          ' and INDEX LOOKUP FLAG as Y.');
      end if;


--
-- Valid x_object_type
--

      if (UPPER(x_object_type) <> 'TABLE'
          AND
          UPPER(x_object_type) <> 'MVIEW'
          AND
          UPPER(x_object_type) <> 'AQ_TABLE'
          AND
          UPPER(x_object_type) <> 'IOT_TABLE'
          AND
          UPPER(x_object_type) <> 'MV_LOG')

      then
          raise_application_error(-20001,
          'Unknown object type "'||UPPER(x_object_type)||
          '". Valid object types are TABLE, MVIEW, AQ_TABLE, IOT_TABLE and MV_LOG.');
      end if;


--
-- open cursor,  get tspace type, object_type
-- and set flag x_is_object_registered
--


      open OBJ_INFO(l_appl_id, x_object_name);

      fetch OBJ_INFO
      into l_tspace_type, l_object_type;

      if OBJ_INFO%NOTFOUND then
          close OBJ_INFO;
          l_is_object_registered:='N';
          x_is_object_registered:='N';

      else
          close OBJ_INFO;
          l_is_object_registered:='Y';
          x_is_object_registered:='Y';

      end if;


--
-- get tablespace in new and old mode
--

      if (l_new_ts_mode = 'Y')  -- New mode
         then

           if (l_is_object_registered='N')
               then

              -- Object not classified, try to get default logical tablespace

               if (UPPER(x_object_type)='TABLE')
                  then
                      l_tspace_type := 'TRANSACTION_TABLES';

               elsif (UPPER(x_object_type)='MVIEW')
                  then
                      l_tspace_type := 'SUMMARY';

               elsif (UPPER(x_object_type)='AQ_TABLE')
                  then
                      l_tspace_type := 'AQ';

               elsif (UPPER(x_object_type)='IOT_TABLE')
                  then
                      l_tspace_type := 'TRANSACTION_TABLES';

               elsif (UPPER(x_object_type)='MV_LOG')
                  then
                      l_tspace_type := 'SUMMARY';

               else
                  raise_application_error(-20001,
                  'Internal error in get_object_tablespace: the passed object type "'||UPPER(x_object_type)||
                  '" is incorrect');
               end if;


	   else -- object classified in FND_OBJECT_TABLESPACES

              -- check if object type match

             if (UPPER(l_object_type) <> UPPER(x_object_type))
               then
                raise_application_error(-20001,
                 'The passed object type "'||UPPER(x_object_type)||
                 '" for "'||UPPER(x_object_name)||
                 '" does not match seeded object type "'||UPPER(l_object_type)||
                 '" in FND_OBJECT_TABLESPACES.');
             end if;

           end if; --   end if l_is_object_registered='N''


-- remap logical tspace

	     if (UPPER(x_object_type)='TABLE'
                 and
                 UPPER(x_index_lookup_flag) = 'Y'
                 and
                 UPPER(l_tspace_type) = 'TRANSACTION_TABLES')

               then

                 l_tspace_type := 'TRANSACTION_INDEXES';

	     end if; -- end remapping



-- get physical tspace

            begin
              SELECT UPPER(TABLESPACE)
              INTO l_tspace
              FROM FND_TABLESPACES
              WHERE UPPER(TABLESPACE_TYPE)=UPPER(l_tspace_type);

              x_tablespace := l_tspace;

            exception
                when NO_DATA_FOUND then
                raise_application_error(-20001,
                'TABLESPACE_TYPE  "'||
                UPPER(l_tspace_type)||
                '" is not found in FND_TABLESPACES.');
            end;


      else -- old mode

              begin


                if (UPPER(x_object_type)='MVIEW')

--get tablespace for MVIEW

                then
                  begin
                    SELECT UPPER(nvl(TABLESPACE, 'UNKNOWN'))
                    INTO l_tspace
                    FROM FND_PRODUCT_INSTALLATIONS
                    WHERE APPLICATION_ID = 191
                    AND install_group_num in (0, 1);

                    if (l_tspace = 'UNKNOWN')
                        then  raise_application_error(-20001,
                        'The tablespace value for application "BIS" is NULL '||
                        'in FND_PRODUCT_INSTALLATIONS. The default tablespace '||
                        'for MVIEW is the tablespace of "BIS".');
                    end if;

                    x_tablespace := l_tspace;

                  exception
                    when NO_DATA_FOUND then
                    raise_application_error(-20001,
                    'Application "BIS" is not registered in '||
                    'FND_PRODUCT_INSTALLATIONS. The default'||
                    ' tablespace for MVIEW is the tablespace of "BIS".');
                  end;


                elsif (UPPER(x_index_lookup_flag) = 'Y')

--get tablespace for index

                then
                  begin
                    SELECT UPPER(nvl(INDEX_TABLESPACE, 'UNKNOWN'))
                    INTO l_tspace
                    FROM FND_PRODUCT_INSTALLATIONS
                    WHERE APPLICATION_ID = l_appl_id;

                    if (l_tspace = 'UNKNOWN')
                        then  raise_application_error(-20001,
                        'The index tablespace value for application "'||
                        UPPER(x_product_short_name)||
                        '" is NULL '||
                        'in FND_PRODUCT_INSTALLATIONS');
                    end if;

                    x_tablespace := l_tspace;

                  exception
                    when NO_DATA_FOUND then
                    raise_application_error(-20001,
                    'Application "'||
                    UPPER(x_product_short_name)||
                    '" is not registered in FND_PRODUCT_INSTALLATIONS.');
                  end;


                else

-- get tablespace from FND_PRODUCT_INSTALLATIONS for
-- TABLE, AQ_TABLE, IOT_TABLE and MV_LOGs

                  begin

                    SELECT UPPER(nvl(TABLESPACE, 'UNKNOWN'))
                    INTO l_tspace
                    FROM FND_PRODUCT_INSTALLATIONS
                    WHERE APPLICATION_ID = l_appl_id;

                    if (l_tspace = 'UNKNOWN')
                        then  raise_application_error(-20001,
                        'The data tablespace value for application "'||
                        UPPER(x_product_short_name)||
                        '" is NULL '||
                        'in FND_PRODUCT_INSTALLATIONS');

                    end if;

                    x_tablespace := l_tspace;

                  exception
                    when NO_DATA_FOUND then
                    raise_application_error(-20001,
                    'Application "'||
                    UPPER(x_product_short_name)||
                    '" is not registered in FND_PRODUCT_INSTALLATIONS.');
                  end;

                end if;	-- end if (UPPER(x_index_lookup_flag) = 'Y')

             end; -- end else: old mode

         end if;-- end if new or old mode



--
-- validate tablespace exists
--

      if (UPPER(x_validate_ts_exists) = 'Y')
        then
            open VALIDATE_TS(l_tspace);

            fetch VALIDATE_TS
            into l_dummy;

              if VALIDATE_TS%NOTFOUND then
      		      -- no row matched in FND_OBJECT_TABLESPACES with given x_object_name and l_appl_id
                  close VALIDATE_TS;
                  x_ts_exists:='N';

       		  else
         		  close VALIDATE_TS;
         		  x_ts_exists:='Y';

       		  end if;

       end if;


   end get_object_tablespace;


procedure get_tablespace_name(x_product_short_name in varchar2,
                              x_tablespace_type in varchar2,
                              x_validate_ts_exists in varchar2,
                              x_ts_exists out NOCOPY varchar2,
                              x_tablespace out NOCOPY varchar2) is

    l_dummy varchar2(30);
    l_appl_id number;
    l_new_ts_mode varchar2(10);
    l_tspace varchar2(30);


    CURSOR TS_NEWMODE (c_tspace_type in varchar2)
    is
    select UPPER(TABLESPACE)
    from FND_TABLESPACES
    where UPPER(TABLESPACE_TYPE)=UPPER(c_tspace_type);


    CURSOR VALIDATE_TS (c_tspace in varchar2)
    is
    select TABLESPACE_NAME
    from DBA_TABLESPACES
    where TABLESPACE_NAME=UPPER(c_tspace);


    begin


--
-- get appl_id
--

      l_appl_id := get_appl_id(x_product_short_name);


--
-- Get is_new_ts_mode
--

      is_new_ts_mode(l_new_ts_mode); -- already  UPPER


--
-- validate tablespace type
--


      open TS_NEWMODE(x_tablespace_type);

      fetch TS_NEWMODE
      into l_tspace;

      if TS_NEWMODE%NOTFOUND then

      -- no row matched in FND_TABLESPACES with given x_tablespace_type

        close TS_NEWMODE;

        raise_application_error(-20001,
                 'TABLESPACE_TYPE  "'||
                  UPPER(x_tablespace_type)||
                 '" not found in FND_TABLESPACES.');

      else
         close TS_NEWMODE;

      end if;


--
-- get tablespace in new and old mode
--

      if (l_new_ts_mode = 'Y')  -- New mode
         then

           -- Use previous cursor to get physical tspace

              x_tablespace:=l_tspace;


      else -- old mode

              begin

                if (UPPER(x_tablespace_type) = 'TRANSACTION_INDEXES')

                --get tablespace for index

                then
                  begin
                    SELECT UPPER(nvl(INDEX_TABLESPACE, 'UNKNOWN'))
                    INTO l_tspace
                    FROM FND_PRODUCT_INSTALLATIONS
                    WHERE APPLICATION_ID = l_appl_id;

                    if (l_tspace = 'UNKNOWN')
                        then  raise_application_error(-20001,
                        'The index tablespace value for application "'||
                        UPPER(x_product_short_name)||
                        '" is NULL '||
                        'in FND_PRODUCT_INSTALLATIONS');
                    end if;

                    x_tablespace := l_tspace;

                  exception
                    when NO_DATA_FOUND then
                    raise_application_error(-20001,
                    'Application "'||
                    UPPER(x_product_short_name)||
                    '" is not registered in FND_PRODUCT_INSTALLATIONS.');
                  end;

                -- get tablespace for SUMMARY (MVIEW)
                -- same logic as AD_TABLESPACE_UTILITIES

                elsif (UPPER(x_tablespace_type) = 'SUMMARY')


                then
                  begin
                    SELECT UPPER(nvl(TABLESPACE, 'UNKNOWN'))
                    INTO l_tspace
                    FROM FND_PRODUCT_INSTALLATIONS
                    WHERE APPLICATION_ID = 191
                    AND install_group_num in (0, 1);

                    if (l_tspace = 'UNKNOWN')
                        then  raise_application_error(-20001,
                        'The tablespace value for application "BIS" is NULL '||
                        'in FND_PRODUCT_INSTALLATIONS. The default tablespace '||
                        'for SUMMARY is the tablespace of "BIS".');
                    end if;

                    x_tablespace := l_tspace;

                  exception
                    when NO_DATA_FOUND then
                    raise_application_error(-20001,
                    'Application "BIS" is not registered in '||
                    'FND_PRODUCT_INSTALLATIONS. The default'||
                    ' tablespace for SUMMARY is the tablespace of "BIS".');
                  end;

                else

                --get tablespace for TRANSACTION_TABLES, REFERENCE, INTERFACE, NOLOGGING, ARCHIVE

                  begin

                    SELECT UPPER(nvl(TABLESPACE, 'UNKNOWN'))
                    INTO l_tspace
                    FROM FND_PRODUCT_INSTALLATIONS
                    WHERE APPLICATION_ID = l_appl_id;

                    if (l_tspace = 'UNKNOWN')
                        then  raise_application_error(-20001,
                        'The data tablespace value for application "'||
                        UPPER(x_product_short_name)||
                        '" is NULL '||
                        'in FND_PRODUCT_INSTALLATIONS');

                    end if;

                    x_tablespace := l_tspace;

                  exception
                    when NO_DATA_FOUND then
                    raise_application_error(-20001,
                    'Application "'||
                    UPPER(x_product_short_name)||
                    '" is not registered in FND_PRODUCT_INSTALLATIONS.');
                  end;

                end if;	-- end if (UPPER(x_tablespace_type) = 'TRANSACTION_INDEXES')

             end; -- end else: old mode

          end if;-- end if new or old mode



--
-- validate tablespace exists
--

      if (UPPER(x_validate_ts_exists) = 'Y')
        then
            open VALIDATE_TS(l_tspace);

            fetch VALIDATE_TS
            into l_dummy;

              if VALIDATE_TS%NOTFOUND then
                  -- no row matched in FND_OBJECT_TABLESPACES
                  -- with given x_object_name and l_appl_id

                  close VALIDATE_TS;
                  x_ts_exists:='N';

              else
                  close VALIDATE_TS;
                  x_ts_exists:='Y';

              end if;

      end if;


   end get_tablespace_name;

end AD_TSPACE_UTIL;
