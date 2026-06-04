
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."ADI_BINARY_FILE" AUTHID CURRENT_USER AS
/* $Header: frmdimgs.pls 120.0.12000000.3 2007/03/01 20:12:42 ghooker ship $ */
--------------------------------------------------------------------------------
--  PACKAGE:      ADI_Image                                                   --
--                                                                            --
--  DESCRIPTION:  Displays an image embedded within an HTML file.  Images     --
--                will be displayed as part of the HTML file, whilst Xcel     --
--                files, word documents, etc will be downloaded onto the      --
--                file system (if the link is clicked on).                    --
--                                                                            --
--  MODIFICATION HISTORY                                                      --
--  Date       Username  Description                                          --
--  23-JUN-99  CCLYDE    Initial Creation                                     --
--  16-FEB-00  CCLYDE    Added Package_Revision procedure to see if we can    --
--                       capture the revision number of the package during    --
--                       runtime.          (Task:  3858)                      --
--  16-MAY-00  GSANAP    Moved the $Header comment from the top to under the  --
--                       CREATE OR REPLACE PACKAGE stmt.                      --
--  13-NOV-02  GHOOKER   Bugs 2279439, 2618782 Images not displayed in RM8.   --
--  28-JUN-06  GHOOKER   Stubbed out GetFileListenerAddress                   --
--------------------------------------------------------------------------------
   PROCEDURE Show (p_documentId IN  NUMBER DEFAULT 0,
                   p_file  IN  VARCHAR2 DEFAULT '');
   PROCEDURE PackageRevision (p_showOwner IN VARCHAR2 DEFAULT '');
END ADI_Binary_File;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."ADI_BINARY_FILE" AS
/* $Header: frmdimgb.pls 120.2.12020000.2 2015/12/04 21:07:37 amgonzal ship $ */
--------------------------------------------------------------------------------
--  PACKAGE:      ADI_Image                                                   --
--                                                                            --
--  DESCRIPTION:  Displays an image embedded within an HTML file.  Images     --
--                will be displayed as part of the HTML file, whilst Xcel     --
--                files, word documents, etc will be downloaded onto the      --
--                file system (if the link is clicked on).                    --
--                                                                            --
--  MODIFICATION HISTORY                                                      --
--  Date       Username  Description                                          --
--  23-JUN-99  CCLYDE    Initial Creation                                     --
--  07-AUG-99  CCLYDE    Added Function GetFileListenerAddress                --
--  28-AUG-99  CCLYDE    Added Exception clauses to all procedures which      --
--                       contained a SQL statement.   (Task: 3275)            --
--  22-NOV-99  CCLYDE    Added a test for the trailing '/' at the end of the  --
--                       File Listener declaration.   (Task: 3757)            --
--                            (GetFileListenerAddress)                        --
--  16-FEB-00   CCLYDE     Added Package_Revision procedure to see if we can  --
--                         capture the revision number of the package during  --
--                         runtime.          (Task:  3858)                    --
--  12-Mar-00  DJANCIS   Modified SHOW to get data from fnd_lobs table in     --
--                       addition to the fnd_document_long_raw table.         --
--                       (TASK: 3769 )                                        --
--  16-MAY-00  GSANAP    Moved the $Header comment from the top to under      --
--                       the CREATE OR REPLACE PACKAGE stmt.                  --
--  29-JUN-00  GSANAP    Modified Debug statements to include package names   --
--                       Task 4425                                            --
--  13-NOV-02  GHOOKER   Bugs 2279439, 2618782 Images not displayed in RM8    --
--  09-MAY-02  GHOOKER   SQL Bind Compliance - update Show Procedure          --
--  28-JUN-06  GHOOKER   Stubbed out GetFileListenerAddress                   --
--  04-Dec-15  amgonzal  22293890 Fwd Port: 22249895: DOS IN ADI_BINARY_FILE                      --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  PROCEDURE:    Show                                                        --
--                                                                            --
--  DESCRIPTION:  Displays an image embedded within an HTML file.  Images     --
--                will be displayed as part of the HTML file, whilst Xcel     --
--                files, word documents, etc will be downloaded onto the      --
--                file system (if the link is clicked on).                    --
--                                                                            --
--  PARAMETERS:   Media Id     Unique identified from FND_DOCUMENT_LONG_RAW   --
--                File         File name stored in FND_DOCUMENTS_TL.file_name --
--                             (potentially, there may be multiple files with --
--                             the same file name, so calling ADI_Image with  --
--                             the file name is not a good idea.  If multiple --
--                             files exist, the procedure will only display   --
--                             the first retrieved file, based on update      --
--                             date).                                         --
--                                                                            --
--  MODIFICATION HISTORY                                                      --
--  Date       Username  Description                                          --
--  23-JUN-99  CCLYDE    Initial Creation                                     --
--  12-Mar-00  DJANCIS   Modified to get data from fnd_lobs table in          --
--                       addition to the fnd_document_long_raw table.         --
--                       (Task: 3769 )                                        --
--  29-JUN-00  GSANAP    Modified Debug statements to include package names   --
--                       Task 4425                                            --
--  14-NOV-02  GHOOKER   Bugs 2279439, 2618782 Images not displayed RM8       --
--  27-JUN-06  GHOOKER   Bug 5127461 Sec Updates in 11.5.10                   --
--------------------------------------------------------------------------------
PROCEDURE Show (p_documentId IN  NUMBER DEFAULT 0,
                p_file  IN  VARCHAR2 DEFAULT '') IS
   v_query         VARCHAR2 (3000);
   v_cursor        NUMBER;
   v_dummy         NUMBER;
   v_file          VARCHAR2(350);
   v_media_id      NUMBER;
   v_datatype_id   NUMBER;
   v_descr         VARCHAR2(255);
   v_file_name     VARCHAR2(2048);
   v_cat_appid     NUMBER;
   v_cat_name      VARCHAR2(255);
   v_display_flag  BOOLEAN;
   v_function_name VARCHAR2(255);
   v_access        NUMBER;

BEGIN
   v_query := '';
   v_query := v_query || 'SELECT DOCS.DOCUMENT_ID || ''_'' || DOCS.FILE_NAME ';
   v_query := v_query || ', MEDIA_ID, DATATYPE_ID  ';
   v_query := v_query || ', DESCRIPTION, FILE_NAME  ';
   v_query := v_query || ', CATEGORY_APPLICATION_ID, CATEGORY_DESCRIPTION  ';
   v_query := v_query || 'FROM   FND_DOCUMENTS_VL DOCS ';

   IF (p_file IS NOT NULL) THEN
      v_query := v_query || 'WHERE LOWER (DOCS.FILE_NAME) = LOWER (:pfile) ';
   ELSE
      v_query := v_query || 'WHERE DOCS.DOCUMENT_ID = :docId ';
   END IF;
   v_cursor := DBMS_SQL.OPEN_CURSOR;
   DBMS_SQL.PARSE (v_cursor, v_query, DBMS_SQL.NATIVE);
   -- G HOOKER 09-May-2003 SQL Bind Compliance
   IF (p_file IS NOT NULL) THEN
      DBMS_SQL.BIND_VARIABLE(v_cursor, ':pfile', P_FILE);
   ELSE
      DBMS_SQL.BIND_VARIABLE(v_cursor, ':docId', P_DOCUMENTID);
   END IF;

   DBMS_SQL.DEFINE_COLUMN (v_cursor, 1, v_file, 350);
   DBMS_SQL.DEFINE_COLUMN (v_cursor, 2, v_media_id);
   DBMS_SQL.DEFINE_COLUMN (v_cursor, 3, v_datatype_id);
   DBMS_SQL.DEFINE_COLUMN (v_cursor, 4, v_descr, 255);
   DBMS_SQL.DEFINE_COLUMN (v_cursor, 5, v_file_name, 2048);
   DBMS_SQL.DEFINE_COLUMN (v_cursor, 6, v_cat_appid);
   DBMS_SQL.DEFINE_COLUMN (v_cursor, 7, v_cat_name, 255);

   v_dummy := DBMS_SQL.EXECUTE (v_cursor);
   v_dummy := DBMS_SQL.fetch_rows (v_cursor);
   DBMS_SQL.column_value (v_cursor, 1, v_file);

   -- Added items for fnd_lobs changes
   DBMS_SQL.column_value (v_cursor, 2, v_media_id);
   DBMS_SQL.column_value (v_cursor, 3, v_datatype_id);
   DBMS_SQL.column_value (v_cursor, 4, v_descr);
   DBMS_SQL.column_value (v_cursor, 5, v_file_name);
   DBMS_SQL.column_value (v_cursor, 6, v_cat_appid);
   DBMS_SQL.column_value (v_cursor, 7, v_cat_name);

   DBMS_SQL.close_cursor(v_cursor);

 if (icx_sec.validateSession) then
   if (v_datatype_id = 6) then
      v_display_flag := FALSE;
      -- ghooker 27-JUN-06 Bug 5127461
      -- adding our extra checks here only.
      if ((v_cat_appid = 265) AND (v_cat_name = 'ADI Kiosk Image')) then
         if (v_descr = 'image/gif') then
            -- file is a seeded gif file and can be displayed without further
            -- checks.
            v_display_flag := TRUE;
         else
            -- now we go and retrieve the function name from the file_name
            -- test if it is an xls file, then do the function security check.
               if (v_descr = 'application/vnd.ms-excel') then
                 v_function_name := substr(v_file_name, 1, instr(v_file_name, '_', 1, 1) -1);
				 if (v_function_name is NULL) then
				   v_function_name := v_file_name;
				 end if;
			   else
			     -- ghooker 26-FEB-07 bug 5873313
           -- now it is possible that this is a 3rd party file upload and we still have a form
           -- funtions to enable us to display the file.
			     v_function_name := v_file_name;
			   end if;
			   -- ghooker 26-FEB-07 bug 5873313
			   if (fnd_function.test(v_function_name)) then
                 v_display_flag := TRUE;
               end if;
            end if;
      end if;
      if (v_display_flag) then
         v_access := fnd_gfm.authorize(v_media_id);
         fnd_gfm.download(v_media_id, v_access);
      else
         -- using -1 to force a access denied error message to be returned to
         -- calling page.
         v_access := fnd_gfm.authorize(-1);
         fnd_gfm.download(v_media_id, v_access);
      end if;
   else
     -- -- ghooker 26-FEB-07 bug 5873313
     -- As all this is for 11i and abover all files should be coming from
	 -- fnd_lobs in ADI and RM we will fail any file that does not meet
	 -- the criteria above.
     -- using -1 to force a access denied error message to be returned to
     -- calling page.
     v_access := fnd_gfm.authorize(-1);
     fnd_gfm.download(v_media_id, v_access);
   end if;

 end if;
EXCEPTION
   WHEN OTHERS THEN
      IF DBMS_SQL.IS_OPEN (v_cursor) THEN
         DBMS_SQL.CLOSE_CURSOR( v_cursor);
      END IF;
      ICX_UTIL.Add_Error ('ADI_Binary_File.Show - ' || SQLERRM);
      ICX_ADMIN_SIG.Error_Screen ('ADI_Binary_File.Show - ' || SQLERRM);
END Show;

--------------------------------------------------------------------------------
--  PROCEDURE:    PackageRevision                                             --
--                                                                            --
--  DESCRIPTION:  Checks the revision number of the package during runtime.   --
--                                                                            --
--  Modification History                                                      --
--  Date        Username   Description                                        --
--  16-FEB-00   CCLYDE     Initial Creation                                   --
--------------------------------------------------------------------------------
PROCEDURE PackageRevision (p_showOwner IN VARCHAR2 DEFAULT '') IS
   v_revisionDetails    VARCHAR2(100);
   v_firstDelimLoc      NUMBER;
   v_secondDelimLoc     NUMBER;
   v_packageName        VARCHAR2(40) DEFAULT 'ADI_Binary_File';
   v_fileName           VARCHAR2(20);
   v_versionNumber      NUMBER;
   v_dateCheckedIn      VARCHAR2(30);
   v_shipStatus         VARCHAR2(10);
   v_developer          VARCHAR2(15);
   v_testRevision       VARCHAR2(30);
BEGIN
   v_testRevision    := '$Revision: 120.2.12020000.2 $';
   v_revisionDetails := '$Header: frmdimgb.pls 120.2.12020000.2 2015/12/04 21:07:37 amgonzal ship $';

   --  Retrieving the filename
   v_firstDelimLoc  := INSTR (v_revisionDetails, ' ', 1, 1);
   v_secondDelimLoc := INSTR (v_revisionDetails, ' ', 1, 2);
   v_fileName       := SUBSTR (v_revisionDetails, (v_firstDelimLoc + 1), ((v_secondDelimLoc)-(v_firstDelimLoc + 1)));

   --  Retrieving the version number
   v_firstDelimLoc  := INSTR (v_revisionDetails, ' ', 1, 2);
   v_secondDelimLoc := INSTR (v_revisionDetails, ' ', 1, 3);
   v_versionNumber  := SUBSTR (v_revisionDetails, (v_firstDelimLoc + 1), ((v_secondDelimLoc)-(v_firstDelimLoc + 1)));

   --  Retrieving the Checked in Date
   v_firstDelimLoc  := INSTR (v_revisionDetails, ' ', 1, 3);
   v_secondDelimLoc := INSTR (v_revisionDetails, ' ', 1, 5);
   v_dateCheckedIn  := SUBSTR (v_revisionDetails, (v_firstDelimLoc + 1), ((v_secondDelimLoc)-(v_firstDelimLoc + 1)));

   --  Retrieving Shipped Status
   v_firstDelimLoc  := INSTR (v_revisionDetails, ' ', 1, 5);
   v_secondDelimLoc := INSTR (v_revisionDetails, ' ', 1, 6);
   v_developer      := SUBSTR (v_revisionDetails, (v_firstDelimLoc + 1), ((v_secondDelimLoc)-(v_firstDelimLoc + 1)));

   --  Retrieving Shipped Status
   v_firstDelimLoc  := INSTR (v_revisionDetails, ' ', 1, 6);
   v_secondDelimLoc := INSTR (v_revisionDetails, ' ', 1, 7);
   v_shipStatus     := SUBSTR (v_revisionDetails, (v_firstDelimLoc + 1), ((v_secondDelimLoc)-(v_firstDelimLoc + 1)));

   --  Building the table of revision information
   htp.htmlOpen;
--   ADI_Header_Footer.htmlhead ('Revision: ' || v_packageName);
   htp.bodyOpen;
--   ADI_Header_Footer.pagebanner ('Package Revision Details', 'WEBR.REVI');
   htp.para;

   htp.tableOpen ('BORDER=1', null, null, null, 'CELLPADDING=6');

   htp.tableRowOpen;
   htp.tableHeader ('<FONT COLOR=#FFFFFF> Package Revision Details <FONT>', 'CENTER', null, 'NOWRAP', null, 2, 'BGCOLOR=#336699');
   htp.tableRowClose;

   htp.tableRowOpen;
      htp.tableData (htf.strong ('Filename'), 'LEFT', null, 'NOWRAP', null, null, null);
      htp.tableData (v_fileName, 'LEFT', null, 'NOWRAP', null, null, null);
   htp.tableRowClose;

   htp.tableRowOpen;
      htp.tableData (htf.strong ('Package'), 'LEFT', null, 'NOWRAP', null, null, null);
      htp.tableData (v_packageName, 'LEFT', null, 'NOWRAP', null, null, null);
   htp.tableRowClose;

   htp.tableRowOpen;
      htp.tableData (htf.strong ('Version'), 'LEFT', null, 'NOWRAP', null, null, null);
      htp.tableData (v_versionNumber, 'LEFT', null, 'NOWRAP', null, null, null);
   htp.tableRowClose;

   htp.tableRowOpen;
      htp.tableData (htf.strong ('Checked In'), 'LEFT', null, 'NOWRAP', null, null, null);
      htp.tableData (v_dateCheckedIn, 'LEFT', null, 'NOWRAP', null, null, null);
   htp.tableRowClose;

   htp.tableRowOpen;
      htp.tableData (htf.strong ('Ship Status'), 'LEFT', null, 'NOWRAP', null, null, null);
      htp.tableData (v_shipStatus, 'LEFT', null, 'NOWRAP', null, null, null);
   htp.tableRowClose;

   IF (LOWER (p_showOwner) = 'big_cheese') THEN
      htp.tableRowOpen;
         htp.tableData (htf.strong ('Developer'), 'LEFT', null, 'NOWRAP', null, null, null);
         htp.tableData (v_developer, 'LEFT', null, 'NOWRAP', null, null, null);
      htp.tableRowClose;
   END IF;

   htp.tableClose;

--   ADI_Header_Footer.pagefoot;

END PackageRevision;

---------------------------------------------------------------------------
END ADI_Binary_File;
