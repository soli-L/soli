
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."ADI_DISPLAY_REPORT" AUTHID CURRENT_USER AS
/* $Header: frmdisps.pls 120.0.12000000.3 2007/03/01 20:10:54 ghooker ship $ */
----------------------------------------------------------------------------------------
--  PROCEDURE:    ADI_Display_Report                                                  --
--                                                                                    --
--  DESCRIPTION:  Displays and HTML report/form to the screen.  The HTML output may   --
--                a report published from the Request Center, or a stand alone file   --
--                which was unloaded (also from the Request Center).                  --
--                                                                                    --
--  MODIFICATIONS                                                                     --
--  DATE       DEVELOPER  COMMENTS                                                    --
--             CCLYDE     Initial Creation                                            --
--  16-FEB-00  CCLYDE     Added Package_Revision procedure to see if we can capture   --
--                        the revision number of the package during runtime.          --
--                              (Task:  3858)                                         --
--  16-MAY-00  GSANAP     Moved the $Header comment from the top to under             --
--                        the CREATE OR REPLACE PACKAGE stmt.                         --
--  17-MAY-00  CCLYDE     Created new procedure DisplayBannerFrame, which displays    --
--                        the report Banner in a separate frame.  (Task: 4179)        --
--  17-MAY-00  CCLYDE     Made the following procedures public:  DisplayApprovalFrame --
--                        and DisplayFile, so that they can be called and displayed   --
--                        into two different frames.     (Task: 4192)                 --
--  13-NOV-02  GHOOKER    Bugs 2279439, 2618782 Images not displayed in RM8.          --
--  13-NOV-02  GHOOKER    Procedures not required for RM8 have been stubbed out       --
----------------------------------------------------------------------------------------
   TYPE g_timeArray IS TABLE OF VARCHAR2(2) INDEX BY BINARY_INTEGER;
   PROCEDURE DisplayFile (p_docId IN NUMBER);
   PROCEDURE DisplayHTMLFile (p_ReportTitle   IN VARCHAR2 default '',
                              p_TimeFrame     IN VARCHAR2 default '',
                              p_ExpandedValue IN VARCHAR2 default '',
                              p_StaticFile    IN VARCHAR2 default '',
                              p_PageType      IN VARCHAR2 default '',
                              p_displayBanner IN  VARCHAR2 default 'N');
   PROCEDURE Show (p_ReportTitle    IN  VARCHAR2,
           p_security       IN  VARCHAR2 default '',
                   p_displayBanner  IN  VARCHAR2 default 'N');
END ADI_display_report;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."ADI_DISPLAY_REPORT" AS
/* $Header: frmdispb.pls 120.2.12020000.2 2015/12/04 21:05:37 amgonzal ship $ */
--------------------------------------------------------------------------------
--  PROCEDURE:    ADI_Display_Report                                          --
--                                                                            --
--  DESCRIPTION:  Displays and HTML report/form to the screen.  The HTML      --
--                output may a report published from the Request Center, or   --
--                a stand alone file which was unloaded (also from the        --
--                Request Center).                                            --
--                                                                            --
--  MODIFICATIONS                                                             --
--  DATE       DEVELOPER  COMMENTS                                            --
--             CCLYDE     Initial Creation                                    --
--  08 AUG 99  CCLYDE     Modified DisplayApprovalForm procedure so that      --
--                        the user must enter a date in the correct format.   --
--                        Now using package owa_util.choose_date, rather than --
--                        free text string.  The form looks a little funny,   --
--                        but this is necessary because of the date           --
--                        validation.  It looks even more wierd because the   --
--                        time is also included in the Approval form.         --
--                        Modified UpdatePreviewerDetails to accept the new   --
--                        date format and to convert the date to the          --
--                        following format: YYYY/MM/DD HH24:MI.  Phew!        --
--                        Talk about complex.                                 --
--                        Modified DisplayPublishedReport to convert the      --
--                        Availability Date to the following format:          --
--                        YYYY/MM/DD HH24:MI.                                 --
--  09-AUG-99  CCLYDE     Added DisplayBanner parameter.                      --
--                        Added functionality behind the DisplayBanner        --
--                        parameter.  Preceeded all messages with ADI_        --
--  23-AUG-99  BHOOKER    For timeframe parameter, changed the index of 1 to  --
--                        LAST because Timeframe drop list displayed in       --
--                        descending order.                                   --
--  23-AUG-99  CCLYDE     Changed the way in which the kiosk banner is called.--
--                        New procedure have been created for more            --
--                        flexibility.                                        --
--                        (DisplayHTMLFile / BuildParameterFrake).            --
--  23-AUG-99  CCLYDE     Added 'NOSCROLL' as a parameter to the Parameter    --
--                        Drop List frame (Task: 3286)   (Show)               --
--  26-AUG-99  CCLYDE     Added Exception clauses to all procedures which     --
--                        contained a SQL statement.   (Task: 3275)           --
--  28-AUG-99  CCLYDE     Broke the IF Banner condition into two steps and    --
--                        corrected the Timeframe/ExpandedValue condition.    --
--                        (Task: 3377)                                        --
--                        (DisplayHTMLFile).                                  --
--  28-AUG-99  CCLYDE     Created new procedure ReportNotFound which displays --
--                        a dummy page informing the user that their report   --
--                        was not found.  The page is called if the requested --
--                        report cannot be retrieved from the database.       --
--                        (Task:  3344)                                       --
--                        (DisplayHTMLFile).                                  --
--  10-SEP-99  CCLYDE     Added SQL Statement to retrieve user names from     --
--                        FND_WEB_ users within a 10.7 environment.           --
--                        (DisplayPreviewAccess)                              --
--  13-SEP-99  BHOOKER    Changed ExtractString to support the additional     --
--                        parameter P_DISPLAYBANNER appearing in the          --
--                        parameter list for form functions (after Security   --
--                        ID).                              --
--  13-SEP-99  BHOOKER    Added constant c_ADIDisplayBanner to support        --
--                        extracting security information when                --
--                        P_DISPLAYBANNER exists in the parameter list for    --
--                        parameter list for a form function.                 --
--  13-SEP-99  BHOOKER    Added debug messages to the ON_HOLD logic           --
--  13-SEP-99  BHOOKER    Added code to retrieve g_SessionID if it is NULL    --
--                        at the start of DisplayPublishedReport, as          --
--                        g_SessionID is required to check the Reviewer       --
--                        access rights to ON_HOLD reports.                   --
--  13-SEP-99  BHOOKER    Moved the code to retrieve g_SessionID so that it   --
--                        ONLY gets executed when we are displaying a secured --
--                        secured document.                                   --
--  14-SEP-99  BHOOKER    Change format masks to correctly display future     --
--                        availability date/time for reports.                 --
--                        (DisplayPreviewAccess)                              --
--  14-SEP-99  BHOOKER    Fixed call to owa_util.choose_date to pass the      --
--                        availability date so that the previewer can see     --
--                        when this report will be made available             --
--                        (DisplayApprovalForm)                               --
--  14-SEP-99  BHOOKER    Enhanced Hour and Minute Select Lists to display    --
--                        the availability date so that the previewer can see --
--                        when this  report will be made available.           --
--                        (DisplayApprovalForm)                               --
--  01-NOV-99  CCLYDE     Added an extra IF statement to check the value of   --
--                        p_Security.  If a security model has been chosen,   --
--                        then we need to check that the user also selected   --
--                        a Security Set Id, or a custom package.  Also       --
--                        introduced a new variable, v_Security, so the       --
--                        security model can be changed on the fly.  If the   --
--                        user has selected a security model, but no Set or   --
--                        Custom Package, then security is switched off       --
--                        completed and all expansion values will be          --
--                        available to all users. CreateParameterFrame        --
--                                                                            --
--                        Added a check for the Security model when the type  --
--                        is either SECURITY or PACKAGE.  This ensures that   --
--                        when either the Custom Security, or ADI's Security  --
--                        model is choosen, a Package, or Security Set is     --
--                        also choosen.  (ExtractString)                      --
--                        (Task: 3596).                                       --
--  16-FEB-00  CCLYDE     Added Package_Revision procedure to see if we can   --
--                        capture the revision number of the package during   --
--                        runtime.                                            --
--                                  (Task:  3858)                             --
--  12-MAR-00  DJANCIS    Modified DisplayFile to be able to handle           --
--                        retrieving data from either the FND_LOBS or the     --
--                        FND_DOCUMENTS_LONG_TEXT to conform to new AOL       --
--                        schema changes.  (Task: 3769 )                      --
--  20-MAR-00  DJANCIS    Modified Build_Security_Table to call new flex      --
--                        routinue which will build the access list from all  --
--                        valid flexfield segment values based on flexfield   --
--                        value security (Task: 3121)                         --
--  30-MAR-00  DJANCIS    Modified Build Time Frame Parameter to intialize    --
--                        g_TimeFrame_List (Task 4110 )                       --
--  03-APR-00  DJANCIS    modified Built Time Frame Parameter to initialize   --
--                        g_ExpandedValue_List as the list was not being      --
--                        refreshed properly                                  --
--  15-MAY-00  GSANAP     Replaced all the != occurances with <> for PKM      --
--                        Moved the $Header comment from the top              --
--  17-MAY-00  CCLYDE     Created a second HTML frame so that the banner      --
--                        is displayed in one frame and the actual report     --
--                        output is displayed in the second frame.  Since the --
--                        introduction of the AOL URL redirect, the redirect  --
--                        was failing if the 'image' being redirected wasn't  --
--                        being directed to a new, empty page/frame.          --
--                        Also, created new procedure DisplayBannerFrame,     --
--                        which displays the Banner in a separate frame.      --
--                            (Show)     Task:  4179                          --
--  17-MAY-00  CCLYDE     Modified DisplayHTMLFile so that if a report is     --
--                        published with a status of ON HOLD, the Approval    --
--                        form is displayed in a separate frame from the      --
--                        actual report itself.  Moved DisplayFile out from   --
--                        under DisplayHTMLFile so that I could declare it    --
--                        publicly within the package spec.   (Task: 4192)    --
--  19-MAY-00  DJANCIS    Removed calls to chr and replaced with              --
--                        fnd_global.local_chr as per adchkdrv standards      --
--  29-JUN-00  GSANAP     Modified debug stmts. to include package names      --
--                        Task 4425                                           --
--  07-DEC-00  CCLYDE     Help Tag is now rptmgr1007762.                      --
--                        (Build_ExpandedValue_Parameter, DisplayBannerFrame) --
--  02-AUG-02  JRICHARD   Changeover to using the APPS_SERVLET_AGENT profile  --
--                        instead of the BNE_SERVLET_LINK profile             --
--  02-AUG-02  JRICHARD   Changed show procedure to support the removal of    --
--                        servlet aliases in the zone.properties file.        --
--  14-NOV-02  GHOOKER    Bugs 2279439, 2618782 Images not displayed RM8      --
--                        added for documentation purposes.                   --
--  09-MAY-02  GHOOKER   SQL Bind Compliance - update DisplayFile Procedure   --
--  06-JUL-06  GHOOKER   Bug 5127461 Sec Updates in 11.5.10                   --
--  26-FEB-07  GHOOKER   Bug 5873313                                          --
--  04-Dec-15  amgonzal  22293890 Fwd Port 22249895: DOS IN ADI_BINARY_FILE                      --
--------------------------------------------------------------------------------
g_SessionId      NUMBER;
g_AppsRelease    NUMBER;
g_UserId         INTEGER;
g_Language       VARCHAR2(100);

g_ServerAddress FND_PROFILE_OPTION_VALUES.PROFILE_OPTION_VALUE%TYPE;

TYPE TimeFrameTable IS TABLE OF GL_Periods.Period_Name%TYPE
     INDEX BY BINARY_INTEGER;
TYPE ExpandedTable IS TABLE OF FND_FLEX_VALUES.Parent_Flex_Value_High%TYPE
     INDEX BY BINARY_INTEGER;
g_imgSpacer        VARCHAR2(50)   := 'ADI_Binary_File.Show?p_file=ADISPACE.gif';
g_imgSplash        VARCHAR2(50)   := 'ADI_Binary_File.Show?p_file=ADISPLSH.gif';
c_ADISecurity         CONSTANT VARCHAR2(5)  DEFAULT 'ADIK:';
c_CustomSecurity      CONSTANT VARCHAR2(5)  DEFAULT 'CUST:';
c_FlexSecurity        CONSTANT VARCHAR2(5)  DEFAULT 'FLEX:';
c_ADISecurityPackage  CONSTANT VARCHAR2(25) DEFAULT 'ADI_Secured_Value_Access';
c_ADIDisplayBanner    CONSTANT VARCHAR2(25) DEFAULT '&P_DISPLAYBANNER';
c_HTML_MimeType       CONSTANT VARCHAR2(10) DEFAULT 'text/html';
c_OnHold              CONSTANT VARCHAR2(7)  DEFAULT 'ON_HOLD';

--  Removed call to chr and replaced with fnd_global.local_chr as per adchkdrv
--  standards
-- c_NewLine             CONSTANT VARCHAR2(2)  DEFAULT convert(
--                                                   fnd_global.local_chr(10),
--                                                   substr(userenv('LANGUAGE'),
--                                                   instr(userenv('LANGUAGE'),
--                                                         '.') + 1),
--                                                            'US7ASCII');
c_ChunkSize           CONSTANT INTEGER      DEFAULT 1000;
-- g_Security_List       ADI_Kiosk_Global.AccessTable;
g_TimeFrame_List      TimeFrameTable;
g_ExpandedValue_List  ExpandedTable;
g_ParameterFrame      VARCHAR2(32767) DEFAULT '';
g_ReleaseName         FND_PRODUCT_GROUPS.release_name%TYPE DEFAULT '';
g_CategoryId          FND_DOCUMENT_CATEGORIES.category_id%TYPE;
-----------------------------------------------------------------------------
--  PROCEDURE:    DisplayFile                                              --
--                                                                         --
--  DESCRIPTION:  Procedure extracts the file from FND_DOCUMENTS_LONG_TEXT --
--                and displays it to the browser.  The file to print is    --
--                already known before this procedure is called.           --
--                                                                         --
--  PARAMETERS:   p_ReportTitle  Report name from FND_FORM_FUNCTIONS       --
--                p_Media_Id     Unique identifier in                      --
--                               FND_DOCUMENTS_LONG_TEXT                   --
--                p_Description  Passed to check that the description      --
--                               field in FND_DOCUMENTS_VL is correct      --
--                               and that the user has not modified the    --
--                               URL before calling the Display process.   --
--                                                                         --
--  MODIFICATIONS                                                          --
--  DATE       DEVELOPER  COMMENTS                                         --
--  14-JUN-99  CCLYDE     Initial creation                                 --
--  12-MAR-00  DJANCIS    Modified DisplayFile to be able to handle        --
--                        retrieving data from either the FND_LOBS or the  --
--                        FND_DOCUMENTS_LONG_TEXT to conform to new AOL    --
--                        schema changes. (TASK: 3769 )                    --
--  29-JUN-00  GSANAP     Modified debug stmts. to include package names   --
--                        Task 4425                                        --
--  27-JUN-06  GHOOKER   Bug 5127461 Sec Updates in 11.5.10                --
--  26-FEB-07  GHOOKER   Bug 5873313                                       --
-----------------------------------------------------------------------------
PROCEDURE DisplayFile (p_docId IN NUMBER) AS
  v_cursor        NUMBER;
  v_query         VARCHAR2(2000);
  v_dummy         NUMBER;
  v_image         RAW(32767);
  v_document      LONG;
  v_value_length  NUMBER;
  v_offset        NUMBER;
  o_cursor        NUMBER;
  o_query         VARCHAR2(2000);
  o_datatype_id   NUMBER;
  o_media_id      NUMBER;
  o_dummy         NUMBER;
  url             VARCHAR2(2000);
  -- ghooker 06-Jul-06 Bug 5127461
  o_display_flag  BOOLEAN;
  o_access        NUMBER;
  o_file_name     VARCHAR2(2048);

BEGIN

  -- ghooker 26-FEB-07 bug 5873313
  -- Always ensure we go through ADI_Binary_File.Show we are no longer using
  -- the 10.7 and 11.0 technology
  ADI_Binary_File.Show (p_docId);

EXCEPTION
  WHEN OTHERS THEN
            ICX_UTIL.Add_Error ('ADI_display_report.DisplayFile - ' || SQLERRM);
     ICX_ADMIN_SIG.Error_Screen ('ADI_display_report.DisplayFile - ' || SQLERRM);
END DisplayFile;
----------------------------------------------------------------------------------------
--  PROCEDURE:    Display HTML File                                                   --
--                                                                                    --
--  DESCRIPTION:  Retrieves the static, point in time report from the database and    --
--                displays it through a browser.  When ADI (Request Center) publishes --
--                to the database, the file is uploaded into FND_DOCUMENTS_LONG_TEXT  --
--                (this follows the Apps standards).                                  --
--                                                                                    --
--  PARAMETERS:   ReportTitle      Unique identifier for this report                  --
--                TimeFrame        TimeFrame selected by the user.  This is only      --
--                                 relevant if the report is a periodic report.       --
--                ExpandedValue    Expansion value selected by the user.  This is     --
--                                 only relevant if the report has been generated     --
--                                 using an Expansion Value Set.                      --
--                                                                                    --
--  MODIFICATIONS                                                                     --
--  DATE       DEVELOPER  COMMENTS                                                    --
--  05-MAY-99  CCLYDE     Initial creation                                            --
--  27-MAY-99  CCLYDE     Check to see if the user is logged into the system before   --
--                        displaying the report.                                      --
--                        Check to see if the user has access to the requested        --
--                        expansion value.                                            --
--  23-AUG-99  CCLYDE     Changed the way in which the kiosk banner is called.  New   --
--                        procedure have been created for more flexibility.           --
--  28-AUG-99  CCLYDE     Broke the IF Banner condition into two steps and corrected  --
--                        the Timeframe/ExpandedValue condition.   (Task: 3377)       --
--  14-MAY-03  GHOOKER    Bug 2948978 Re-instated this procedure.                     --
--                        removed parts of original procedure that were not used      --
--                        within RM8.                                                 --
----------------------------------------------------------------------------------------
PROCEDURE DisplayHTMLFile (p_ReportTitle   IN VARCHAR2 default '',
                           p_TimeFrame     IN VARCHAR2 default '',
                           p_ExpandedValue IN VARCHAR2 default '',
                           p_StaticFile    IN VARCHAR2 default '',
                           p_PageType      IN VARCHAR2 default '',
                           p_displayBanner IN VARCHAR2 default 'N') AS
   ----------------------------------------------------------------------------------------
   --  PROCEDURE:    DisplayStaticFile                                                   --
   --                                                                                    --
   --  DESCRIPTION:  This procedure is used if the user tries to display a static html   --
   --                file which was previously uploaded (using the Menu Maintenance      --
   --                form).  It does not get called if the user is displaying a report   --
   --                previously published into the database (using the Request Center    --
   --                functionality); see DisplayPublishedReport.                         --
   --                                                                                    --
   --                If the Mime Type = text/html, the file is retrieved from FND_       --
   --                DOCUMENTS_LONG_TEXT (in text format).  Any other file types are     --
   --                stored as binary objects in FND_DOCUMENTS_LONG_RAW and need to be   --
   --                retrieved differently.                                              --
   --                                                                                    --
   --  PARAMETERS:   p_MediaId      Unique identifier for the file (HTML or other file). --
   --                p_PageType     P    - Public Home Page                              --
   --                               S    - Secured Home Page                             --
   --                               null - Either Public or Secured page, but not home   --
   --                                      page.                                         --
   --                                                                                    --
   --  MODIFICATIONS                                                                     --
   --  DATE       DEVELOPER  COMMENTS                                                    --
   --  14-JUN-99  CCLYDE     Initial creation                                            --
   --  15-JUL-99  CCLYDE     Added p_PageType to differentiate between the different     --
   --                        document categories.                                        --
   --  29-JUN-00  GSANAP     Modified debug stmts. to include package names              --
   --                        Task 4425                                                   --
   --  14-MAY-03  GHOOKER    Bug 2948978 Re-instated this procedure.                     --
   --                        removed parts of original procedure that were not used      --
   --                        within RM8.                                                 --
   ----------------------------------------------------------------------------------------
   PROCEDURE DisplayStaticFile (p_FileName IN VARCHAR2 default '',
                                p_PageType IN VARCHAR2 default '') AS
      v_query           VARCHAR2(500);
      v_cursor          INTEGER;
      v_dummy           INTEGER;
      v_category_name   FND_DOCUMENT_CATEGORIES.name%TYPE;
      v_DocumentId      FND_DOCUMENTS_VL.Document_Id%TYPE;
      v_mimeType        FND_DOCUMENTS_VL.Description%TYPE;
   BEGIN
      v_query := '';
      v_query := v_query || 'SELECT CAT.NAME, ';
      v_query := v_query || '       DOCS.DOCUMENT_ID, ';
      v_query := v_query || '       DOCS.DESCRIPTION ';
      v_query := v_query || 'FROM   FND_DOCUMENT_CATEGORIES CAT, ';
      v_query := v_query || '       FND_DOCUMENTS_VL DOCS ';
      v_query := v_query || 'WHERE  CAT.CATEGORY_ID = DOCS.CATEGORY_ID ';
      -- GHOOKER 14-May-2003 SQL Bind Compliance.
      -- v_query := v_query || 'AND    LOWER (DOCS.FILE_NAME) = LOWER (''' || P_FILENAME || ''') ';
      v_query := v_query || 'AND    LOWER (DOCS.FILE_NAME) = LOWER ( :pfilename ) ';
      IF (p_PageType = 'PUBLIC') THEN
         v_query := v_query || 'AND CAT.NAME = ''ADI_KIOSK_DEFAULT_PUBLIC'' ';
      ELSIF (p_PageType = 'SECURED') THEN
         v_query := v_query || 'AND CAT.NAME = ''ADI_KIOSK_DEFAULT_SECURED'' ';
      END IF;
      v_cursor := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE (v_cursor, v_query, DBMS_SQL.NATIVE);
      -- GHOOKER 14-May-2003 SQL Bind Compliance.
      DBMS_SQL.BIND_VARIABLE (v_cursor, ':pfilename', P_FILENAME);
      DBMS_SQL.DEFINE_COLUMN (v_cursor, 1, v_Category_Name, 30);
      DBMS_SQL.DEFINE_COLUMN (v_cursor, 2, v_DocumentId);
      DBMS_SQL.DEFINE_COLUMN (v_cursor, 3, v_MimeType, 255);
      v_dummy := DBMS_SQL.EXECUTE (v_cursor);
      v_dummy := DBMS_SQL.FETCH_ROWS (v_cursor);
      DBMS_SQL.COLUMN_VALUE (v_cursor, 1, v_Category_Name);
      DBMS_SQL.COLUMN_VALUE (v_cursor, 2, v_DocumentId);
      DBMS_SQL.COLUMN_VALUE (v_cursor, 3, v_MimeType);
      DBMS_SQL.Close_Cursor (v_cursor);
      IF (v_Category_Name IN ('ADI_KIOSK_REPORT', 'ADI_KIOSK_DEFAULT_SECURED')) THEN
         IF (NOT ICX_SEC.ValidateSession) THEN
            GOTO EndOfStaticDisplay;
         END IF;
      END IF;
      IF (v_MimeType = c_HTML_MimeType) THEN
         DisplayFile (v_DocumentId);
      ELSE
         ADI_Binary_File.Show (v_DocumentId);
      END IF;
      <<EndOfStaticDisplay>>
      null;
   EXCEPTION
      WHEN OTHERS THEN
         IF DBMS_SQL.IS_OPEN ( v_cursor) THEN
            DBMS_SQL.CLOSE_CURSOR( v_cursor);
         END IF;
         ICX_UTIL.Add_Error ('ADI_display_report.DisplayStaticFile - ' || SQLERRM);
         ICX_ADMIN_SIG.Error_Screen ('ADI_display_report.DisplayStaticFile - ' || SQLERRM);
   END DisplayStaticFile;
--------------------------------------------------------------------------------
--   DisplayHTMLFile                                                          --
--------------------------------------------------------------------------------
BEGIN

   DisplayStaticFile (p_StaticFile, p_PageType);
END DisplayHTMLFile;
------------------------------------------------------------------------------------
--  FUNCTION:    getServerAddress                                                 --
--                                                                                --
--  DESCRIPTION: Retrieves the leading URL location to call BneApplicationService --
--               from.                                                            --
--                                                                                --
--  PARAMETERS:                                                                   --
--                                                                                --
--  MODIFICATION HISTORY                                                          --
--  Date       Username  Description                                              --
--  11-NOV-01  MWISE    Initial Creation                                          --
------------------------------------------------------------------------------------
FUNCTION getServerAddress RETURN VARCHAR2 IS
   l_query          VARCHAR2(1000);
   l_cursor         NUMBER;
   l_dummy          NUMBER;
BEGIN
   IF (g_ServerAddress IS NULL) THEN
      l_query := '';
      l_query := l_query || 'SELECT V.PROFILE_OPTION_VALUE ';
      l_query := l_query || 'FROM   FND_PROFILE_OPTIONS O, ';
      l_query := l_query || '       FND_PROFILE_OPTION_VALUES V ';
      l_query := l_query || 'WHERE  O.PROFILE_OPTION_NAME = ''APPS_SERVLET_AGENT'' ';
      l_query := l_query || 'AND    O.START_DATE_ACTIVE <= SYSDATE ';
      l_query := l_query || 'AND   (NVL(O.END_DATE_ACTIVE,SYSDATE) >= SYSDATE) ';
      l_query := l_query || 'AND   (V.LEVEL_ID (+) = 10001 AND V.LEVEL_VALUE (+) = 0) ';
      l_query := l_query || 'AND    O.PROFILE_OPTION_ID = V.PROFILE_OPTION_ID (+) ';
      l_query := l_query || 'AND    O.APPLICATION_ID = V.APPLICATION_ID (+) ';
      l_cursor := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.parse (l_cursor, l_query, DBMS_SQL.native);
      DBMS_SQL.Define_Column (l_cursor, 1, g_ServerAddress, 240);
      l_dummy := DBMS_SQL.execute (l_cursor);
      l_dummy := DBMS_SQL.Fetch_Rows (l_cursor);
      DBMS_SQL.Column_Value (l_cursor, 1, g_ServerAddress);
      DBMS_SQL.CLOSE_CURSOR (l_cursor);
   END IF;

   -- Check for trailing slash.
   IF (SUBSTR (g_ServerAddress, LENGTH (g_ServerAddress), 1) <> '/') THEN
      g_ServerAddress := g_ServerAddress || '/';
   END IF;

   RETURN (g_ServerAddress);

EXCEPTION
   WHEN OTHERS THEN
      IF DBMS_SQL.IS_OPEN ( l_cursor) THEN
         DBMS_SQL.CLOSE_CURSOR( l_cursor);
       END IF;
      ICX_UTIL.Add_Error ('getServerAddress - ' || SQLERRM);
      ICX_ADMIN_SIG.Error_Screen ('getServerAddress - ' || SQLERRM);
END getServerAddress;

----------------------------------------------------------------------------------------
--  PROCEDURE:    Show                                                                --
--                                                                                    --
--  DESCRIPTION:  Main procedure for the package.  Checks to see what type of report  --
--                is being displayed and then displays the relevant frames:           --
--                    Parameters                                                      --
--                    Report Contents                                                 --
--                                                                                    --
--                This procedure displays reports available through a secured menu    --
--                ONLY.                                                               --
--                                                                                    --
--  PARAMETERS:   Report Title     Report identifier                                  --
--                Security         Identifies the security model to use               --
--                Display Banner   Display BIS standard banner  Y/N                   --
--                                                                                    --
--  MODIFICATIONS                                                                     --
--  DATE       DEVELOPER  COMMENTS                                                    --
--  16-MAY-99  CCLYDE     Initial creation                                            --
--  09-AUG-99  CCLYDE     Added DisplayBanner parameter.                              --
--  23-AUG-99  CCLYDE     Added 'NOSCROLL' as a parameter to the Parameter Drop List  --
--                        frame.   (Task: 3286)                                       --
--  17-MAY-00  CCLYDE     Created a second HTML frame so that the banner is displayed --
--                        in one frame and the actual report output is displayed in   --
--                        the second frame.  Since the introduction of the AOL URL    --
--                        redirect, the redirect was failing if the 'image' being     --
--                        redirected wasn't being directed to a new, empty page/frame.--
--                            (Task:  4179)                                           --
--  27-JUN-06  GHOOKER    Bug 5127461 Sec Updates in 11.5.10                          --
----------------------------------------------------------------------------------------
PROCEDURE Show (p_ReportTitle    IN  VARCHAR2,
          p_security       IN  VARCHAR2 default '',
                p_displayBanner  IN  VARCHAR2 default 'N') IS

   v_top_frame          VARCHAR2(5000);
   v_bottom_frame       VARCHAR2(100);
   v_MediaId            NUMBER default 0;
   v_periodicReport     INTEGER default 0;
   v_expansionReport    INTEGER default 0;
   v_URL_Params         VARCHAR2(1000);
   v_URL_Contents       VARCHAR2(1000);
   v_ReportType         FND_DOCUMENT_CATEGORIES.name%TYPE;
   v_dummy              BOOLEAN;
   v_frameHeight        NUMBER;
   v_serverAddress      VARCHAR2(255);

BEGIN
   --
   -- Redirect to the RM8.
   --
   v_serverAddress := getServerAddress;
   owa_util.redirect_url( v_serverAddress || 'oracle.apps.bne.webui.BneApplicationService?bne:page=RMDocuments&event=none&frm:filename=' || p_ReportTitle || '&frm:security=' || p_security );
END Show;

END ADI_display_report;
