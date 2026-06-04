
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PATCH_ANALYSIS_ENGINE" 
/* $Header: adpaengs.pls 120.2.12020000.5 2014/07/10 04:41:49 tshort ship $ */
AUTHID CURRENT_USER AS

  TYPE typeHashVarchar IS TABLE OF VARCHAR2(50) INDEX BY VARCHAR2(50);

  ----------------------------------------------------------------------------
  -- Procedure to print out the usage of this package.
  ----------------------------------------------------------------------------
  PROCEDURE usage;

  ----------------------------------------------------------------------------
  -- Procedure to initialize the global variables.
  ----------------------------------------------------------------------------
  PROCEDURE initialize;

  ----------------------------------------------------------------------------
  -- Function to print messages on console
  ----------------------------------------------------------------------------
  PROCEDURE debugPrint
  ( p_message       IN   VARCHAR2
  );

  ----------------------------------------------------------------------------
  -- Get the value from desired hash
  ----------------------------------------------------------------------------
  FUNCTION getValueFromHash
  ( p_key           IN   VARCHAR2,
    p_hash          IN   typeHashVarchar
  )
  RETURN VARCHAR2;

  ----------------------------------------------------------------------------
  -- Function to compare the the 2 inputs codelevels.
  ----------------------------------------------------------------------------
   FUNCTION compareLevel
   ( p_level_1       IN   VARCHAR2 DEFAULT '',
     p_level_2       IN   VARCHAR2 DEFAULT ''
   )
   RETURN NUMBER;

  ----------------------------------------------------------------------------
  -- Function to validate and add the pre-reqs.
  ----------------------------------------------------------------------------
  PROCEDURE addPrereq
  ( p_te_abbr	        IN      VARCHAR2 ,
    p_te_level          IN      VARCHAR2 ,
    p_hashRequires      IN OUT  NOCOPY typeHashVarchar
  );

  ----------------------------------------------------------------------------
  -- Function to get global view snapshot id since AD doesn't have one
  ----------------------------------------------------------------------------
  FUNCTION getGlobalViewSnapshotID
  RETURN NUMBER;

  ----------------------------------------------------------------------------
  -- Function to get the status of the user input patch and baseline.
  ----------------------------------------------------------------------------
  FUNCTION getPatchStatus
  ( p_bug_number        IN    NUMBER,
    p_baseline          IN    VARCHAR2,
    p_release           IN    VARCHAR2,
    p_err_message       OUT   NOCOPY VARCHAR2
  )
  RETURN VARCHAR2;

  ----------------------------------------------------------------------------
  -- Function to get the status of the user input patch and baseline.
  ----------------------------------------------------------------------------
  FUNCTION getPatchStatus
  ( p_bug_number        IN    NUMBER,
    p_baseline          IN    VARCHAR2,
    p_release           IN    VARCHAR2,
    p_err_message       OUT   NOCOPY  VARCHAR2,
    p_analysis_run_id   IN    NUMBER ,
    p_user_id           IN    NUMBER ,
    p_overwrite         IN    BOOLEAN   DEFAULT   FALSE
  )
  RETURN VARCHAR2;

  FUNCTION ISCUTOVER(p_bug_number in varchar2)
  RETURN BOOLEAN;

END ad_patch_analysis_engine;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PATCH_ANALYSIS_ENGINE" 
/* $Header: adpaengb.pls 120.13.12020000.10 2017/10/02 21:33:18 tshort ship $ */
AS

  ----------------------------------------------------------------------------
  -- Declaration of the global variables.
  ----------------------------------------------------------------------------

  ghashLevel          typeHashVarchar;
  ghashIfUsed         typeHashVarchar;
  ghashIfLoad         typeHashVarchar;

  ghashLevelIntr      typeHashVarchar;
  ghashBaselineIntr	  typeHashVarchar;
  ghashRequires	      typeHashVarchar;


  ----------------------------------------------------------------------------
  -- Procedure to print the usage of this package.
  -- This intializes the following
  --     *  Caching of CodeLevels on customer instance
  --     *  Caching of Baselines on customer instance
  --     *  Caching of IfLoad on customer instance
  --     *  Caching of IfUsed on customer instance
  ----------------------------------------------------------------------------

  PROCEDURE usage
  IS

  BEGIN
    debugPrint ('--------------------------------------------------');
    debugPrint ('------------Compare 2 Codelevels------------------');
    debugPrint ('--------------------------------------------------');
    debugPrint (' ad_patch_analysis_engine.compareLevel(<codelevel1>,<codelevel2>);');
    debugPrint ('--------------------------------------------------');
    debugPrint ('------------ Run the Analysis Engine ------------------');
    debugPrint ('--------------------------------------------------');
    debugPrint (' ad_patch_analysis_engine.getPatchStatus(  '
      ||'<bug_number>,'
      ||'<baseline>,'
      ||'<release>,'
      ||'<OUT error_message>'
      ||');');
    debugPrint ('RETURNS patch_status                              ');
    debugPrint ('--------------------------------------------------');
    debugPrint ('----- Run the Analysis Engine and Update database------');
    debugPrint ('--------------------------------------------------');
    debugPrint (' ad_patch_analysis_engine.getPatchStatus(  '
      ||'<bug_number>,'
      ||'<baseline>,'
      ||'<release>,'
      ||'<OUT error_message>,'
      ||'<analysis_run_id>,'
      ||'<user_id>,'
      ||'<overwrite_database>'
      ||');');
    debugPrint ('RETURNS patch_status                              ');

  END;

  ----------------------------------------------------------------------------
  -- Function to print messages on console
  ----------------------------------------------------------------------------
  PROCEDURE debugPrint
  ( p_message       IN   VARCHAR2
  )
  IS
  BEGIN
    NULL;
    -- DBMS_OUTPUT.put_line (p_message);
  END;



  ----------------------------------------------------------------------------
  -- Get the value from desired hash
  ----------------------------------------------------------------------------
  FUNCTION getValueFromHash
  ( p_key           IN   VARCHAR2,
    p_hash          IN   typeHashVarchar
  )
  RETURN VARCHAR2
  IS
    l_Value         VARCHAR2(50);
  BEGIN

    l_Value := p_hash(p_key);

    RETURN l_Value;

  EXCEPTION

    WHEN OTHERS THEN
    RETURN NULL;

  END;



  ----------------------------------------------------------------------------
  -- Procedure to initialize the global variables.
  -- This intializes the following
  --     *  Caching of CodeLevels on customer instance
  --     *  Caching of Baselines on customer instance
  --     *  Caching of IfLoad on customer instance
  --     *  Caching of IfUsed on customer instance
  ----------------------------------------------------------------------------

  PROCEDURE initialize
  IS

  BEGIN
    FOR rec IN
    (SELECT
        abbreviation abbr,
        NVL(used_flag, 'Y') used_flag,
        NVL(load_flag, 'N') load_flag,
        codelevel te_level
     FROM ad_trackable_entities)
    LOOP
      ghashLevel(rec.abbr) := rec.te_level;
      ghashIfUsed(rec.abbr) := rec.used_flag;
      ghashIfLoad(rec.abbr) := rec.load_flag;


    END LOOP;
    debugPrint ('ghashLevel: '|| ghashLevel.COUNT || ' rows defined.');
    debugPrint ('ghashIfUsed: '|| ghashIfUsed.COUNT || ' rows defined.');
    debugPrint ('ghashIfLoad: '|| ghashIfLoad.COUNT || ' rows defined.');

    ghashLevelIntr.DELETE;
    ghashBaselineIntr.DELETE;
    ghashRequires.DELETE;

  END;

  ----------------------------------------------------------------------------
  -- Function to compare the the 2 inputs codelevels.
  -- Currently assuming the codelevels are numeric.
  -- Return 1 if (input1 > input2),
  --        2 if (input1 < input2)
  --        0 if (input1 = input2)
  --       -1 in case of Error
  ----------------------------------------------------------------------------
  FUNCTION compareLevel
  ( p_level_1    IN   VARCHAR2 DEFAULT '',
    p_level_2    IN   VARCHAR2 DEFAULT ''
  )
  RETURN NUMBER
  IS
     TYPE arrVar IS TABLE OF VARCHAR2(10);
     l_n	                 NUMBER := 0;
     l_str                 VARCHAR2(100);
     -- As specified in the doc max decimal places can be 10. So initializing the
     -- table with 10 values of 0 each.
     l_arrLevel_1          arrVar := arrVar('0','0','0','0','0','0','0','0','0','0');
     l_arrLevel_2          arrVar := arrVar('0','0','0','0','0','0','0','0','0','0');
     l_arrLevel_1_size     NUMBER := 0;
     l_arrLevel_2_size     NUMBER := 0;
  BEGIN

    -- Compare if the two levels are same (string comparison)
    IF (p_level_1 = p_level_2) THEN
      RETURN 0;
    END IF;

    -- Storing all the decimal values for Level 1 in plsql table
    -- Also calculate the real size of the table.
    -- If input level is empty replace with 0.
    CASE
      WHEN length(p_level_1) = 0 THEN l_str := '0';
      WHEN length(p_level_1) > 0 THEN l_str := LOWER(p_level_1);
      ELSE l_str := '0';
    END CASE;

    LOOP
      l_n := instr(l_str, '.' );
	    IF ( length(l_str) > 0 AND l_n = 0) THEN
        l_arrLevel_1_size := l_arrLevel_1_size +1;
	      l_arrLevel_1(l_arrLevel_1_size) := l_str;
	    END IF;
      EXIT WHEN (nvl(l_n,0) = 0);
      l_arrLevel_1_size := l_arrLevel_1_size +1;
      l_arrLevel_1(l_arrLevel_1_size) := substr(l_str, 1, l_n-1);
      l_str := ltrim( substr( l_str, l_n+1 ) );
    END LOOP;

    -- Storing all the decimal values for Level 2 in plsql table
    -- Also calculate the real size of the table.
    -- If input level is empty replace with 0.
    CASE
      WHEN length(p_level_2) = 0 THEN l_str := '0';
      WHEN length(p_level_2) > 0 THEN l_str := LOWER(p_level_2);
      ELSE l_str := '0';
    END CASE;

    LOOP
      l_n := instr(l_str, '.' );
	    IF ( length(l_str) > 0 AND l_n = 0) THEN
        l_arrLevel_2_size := l_arrLevel_2_size +1;
	      l_arrLevel_2(l_arrLevel_2_size) := l_str;
	    END IF;
      EXIT WHEN (nvl(l_n,0) = 0);
      l_arrLevel_2_size := l_arrLevel_2_size +1;
      l_arrLevel_2(l_arrLevel_2_size) := substr(l_str, 1, l_n-1);
      l_str := ltrim( substr( l_str, l_n+1 ) );
    END LOOP;

    --debugPrint(' 1::::'|| l_arrLevel_1_size);
    --debugPrint(' 2::::'|| l_arrLevel_2_size);


    -- Compare the each decimal value of one codelevel with the corresponding
    -- decimal level of other codelevel for the same place. If one is
    DECLARE
      l_tmpSize       NUMBER := 0;
      l_tmpFlg        NUMBER := 0;
      l_tmpVar        VARCHAR2(10);
      l_value_1	      VARCHAR2(10);
      l_value_2	      VARCHAR2(10);

    BEGIN
      IF(l_arrLevel_1_size >= l_arrLevel_2_size) THEN
        l_tmpSize := l_arrLevel_1_size;
      ELSE
        l_tmpSize := l_arrLevel_2_size;
      END IF;

      --debugPrint(' '|| l_tmpSize);

      -- Loop for each of the decimal places
      FOR i IN 1..l_tmpSize LOOP
        BEGIN
          l_value_1 := l_arrLevel_1(i);
          l_value_2 := l_arrLevel_2(i);

          -- remove the keyword 'delta' before processing
          l_value_1 := REPLACE(l_value_1,'delta','');
          l_value_2 := REPLACE(l_value_2,'delta','');

          -- Check that the first segment for both the levels should match.
          -- If not return error
          -- ababkuma 26-JUN-2006 Bug#5357093 commented the code below
          -- IF(i = 1 AND l_value_1 <> l_value_2) THEN
          --  RETURN -1;
          -- END IF;

          -- debugPrint(l_value_1||'  '||l_value_2);
          -- In loop when the segments are same then no action.
          -- if one is greater than then return the index of the higher level
          -- The segments 2 onwards could be varchar as well as number.
          CASE
      	    WHEN (TO_NUMBER(l_value_1) = TO_NUMBER(l_value_2) ) THEN NULL;
            WHEN (TO_NUMBER(l_value_1) > TO_NUMBER(l_value_2) ) THEN RETURN 1;
            WHEN (TO_NUMBER(l_value_1) < TO_NUMBER(l_value_2) ) THEN RETURN 2;
	        END CASE;
        EXCEPTION
          WHEN VALUE_ERROR THEN
            SELECT GREATEST(l_value_1, l_value_2) INTO l_tmpVar FROM DUAL;
            CASE
              WHEN ((l_tmpVar = l_value_2) AND (l_tmpVar = l_value_1)) THEN NULL;
              WHEN (l_tmpVar = l_value_1)  THEN RETURN 1;
              WHEN (l_tmpVar = l_value_2)  THEN RETURN 2;
            END CASE;
        END;
      END LOOP;
    END;

    CASE
      WHEN length(p_level_1) = 0     THEN RETURN 2;
      WHEN length(p_level_1) IS NULL THEN RETURN 2;
      WHEN length(p_level_2) = 0     THEN RETURN 1;
      WHEN length(p_level_2) IS NULL THEN RETURN 1;
      ELSE RETURN 0;
    END CASE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN -1;
  END;

  ----------------------------------------------------------------------------
  -- Procedure to add the pre-req found to the global pre-req associative array.
  -- This also validates if the pre-req is
  --     *  present on customer's instance
  --     *  present in the pre-req associative array
  ----------------------------------------------------------------------------
  PROCEDURE addPrereq
  ( p_te_abbr         IN   VARCHAR2 ,
    p_te_level        IN   VARCHAR2 ,
    p_hashRequires    IN OUT  NOCOPY typeHashVarchar
  )
  IS
    l_te_level VARCHAR2(50);
  BEGIN

   -- Check level in ghashLevel for TE_NAME
    IF (ghashLevel.EXISTS(p_te_abbr)) THEN
      -- check level from hashRequires for TE_NAME
      IF (p_hashRequires.EXISTS(p_te_abbr)) THEN
        IF (compareLevel(p_te_level, p_hashRequires(p_te_abbr)) = 1) THEN
          -- add to hashPrereq TE_NAME, TE_LEVEL
	        p_hashRequires(p_te_abbr) := p_te_level;
          -- debugPrint (p_te_abbr||'   '||p_te_level );
        END IF;
      ELSE
        IF (compareLevel(p_te_level, ghashLevel(p_te_abbr)) = 1 ) THEN
          -- add to hashPrereq TE_NAME, TE_LEVEL
          p_hashRequires(p_te_abbr) := p_te_level;
          -- debugPrint (p_te_abbr||'   '||p_te_level );
        END IF;
      END IF;
    ELSE
      -- get level from hashPrereq for TE_NAME
      IF (p_hashRequires.EXISTS(p_te_abbr)) THEN
        IF ( compareLevel(p_te_level, p_hashRequires(p_te_abbr)) = 1) THEN
          p_hashRequires(p_te_abbr) := p_te_level;
          -- debugPrint (p_te_abbr||'   '||p_te_level );
        END IF;
      ELSE
        p_hashRequires(p_te_abbr) := p_te_level;
          -- debugPrint (p_te_abbr||'   '||p_te_level );
      END IF;
    END IF;
  END;

  ----------------------------------------------------------------------------
  -- Function to get global view snapshot id
  -- since AD doesn't have an api and I have to call this repeatedly
  -- created my own until one is provided by AD
  ----------------------------------------------------------------------------

  FUNCTION getGlobalViewSnapshotID
  RETURN NUMBER IS
    l_snapshot_id	NUMBER := 0;
  BEGIN

	SELECT snapshot_id INTO l_snapshot_id
	FROM ad_snapshots ads, ad_appl_tops adat
	WHERE ads.snapshot_name = 'GLOBAL_VIEW'
	and ads.snapshot_type = 'G'
	and ads.appl_top_id = adat.appl_top_id
	and adat.appl_top_type = 'G'
	and adat.active_flag = 'Y'
	and adat.applications_system_name in
	(select applications_system_name from
	fnd_product_groups where product_group_id = 1);

    RETURN l_snapshot_id;

  END;

  ----------------------------------------------------------------------------
  -- Procedure to determine the status of the patch asked by user and also
  -- determines the reasons for output status.
  -- This procedure is exposed to user.
  ----------------------------------------------------------------------------

  FUNCTION getPatchStatus (
    p_bug_number        IN    NUMBER,
    p_baseline          IN    VARCHAR2,
    p_release           IN    VARCHAR2,
    p_err_message       OUT   NOCOPY VARCHAR2,
    p_analysis_run_id   IN    NUMBER,
    p_user_id           IN    NUMBER,
    p_overwrite         IN    BOOLEAN   DEFAULT   FALSE
  )
  RETURN VARCHAR2 IS
    l_analysis_run_bug_id       NUMBER := 0;
    l_tmpCnt                    NUMBER := 0;
    l_tmpVar                    VARCHAR2(30);
    l_patch_status              VARCHAR2(100) := 'ERROR';
    l_tmpLevel                  VARCHAR2(30) := NULL;
    l_tmpBaseline               VARCHAR2(30) := NULL;
    l_snapshot_id		NUMBER := 0;
  BEGIN

    debugPrint ('Start - Calling pre-req');
    l_patch_status := getPatchStatus (p_bug_number, p_baseline, p_release, p_err_message);
    debugPrint ('End - Pre-req is ');

    -- Perform the insertion in the Patch Wizard tables if analysis_id is specified
    IF (p_analysis_run_id > 0) THEN
      SELECT analysis_run_bug_id INTO l_analysis_run_bug_id
      FROM   ad_pa_analysis_run_bugs
      WHERE   analysis_run_id = p_analysis_run_id
      AND     bug_number      = p_bug_number
      AND     baseline        = p_baseline;

      if (l_patch_status = ('READY')) THEN
	-- 14504286 - if getPatchStatus returned APPLIED, ERROR, or MISSING then dont go through
	-- this block as it will be overriden to IMPLICIT, if there are no
	-- new or upgraded files

      -- 14504286 - determine when 0 files will be impacted or only file is
      -- ad_apply_patch.xml
      DECLARE
	l_file_count                NUMBER := 0;
	l_patch_id		    NUMBER := 0;
	l_actual_file_count         NUMBER := 0;
	l_is_code_level		    VARCHAR2(1) := NULL;
      BEGIN

	-- added baseline to query as an upgrade customer
	-- had the same bug_number in ad_pm_patches for both 11i and B
	SELECT is_code_level INTO l_is_code_level
	FROM ad_pm_patches
	WHERE bug_number = p_bug_number
	AND baseline = p_baseline;

 	IF (l_is_code_level = 'N') THEN

	  l_snapshot_id := getGlobalViewSnapshotID();

          SELECT distinct new + upgrade, patch_id  INTO l_file_count, l_patch_id
          FROM fnd_imp_pisummary a,
	  (select max(patch_id) mx from fnd_imp_pisummary
          WHERE bug_no = p_bug_number
	  AND snapshot_id = l_snapshot_id) b
	  where a.patch_id = b.mx
	  and snapshot_id = l_snapshot_id;

          IF (l_file_count = 0) THEN

		l_patch_status := 'IMPLICIT';

	  -- 19663883 - still need to show implicit for both
	  -- ad_apply_patch and fnd_oneoff_disclaimer_info
          ELSE IF (l_file_count <= 3) THEN

		SELECT count(*) INTO l_actual_file_count
		FROM fnd_imp_psmaster2
		WHERE bug_no = p_bug_number
		AND patch_id = l_patch_id
		AND typeid in ('new','upgrade')
		AND snapshot_id = l_snapshot_id
		AND filename not in
		('ad_apply_patch.xml','ad_apply_hotpatch.xml','fnd_oneoff_disclaimer_info.xml') ;

		IF (l_actual_file_count = 0) THEN
		   l_patch_status := 'IMPLICIT';
		END IF;

	  END IF;

	  END IF;

	END IF; --if not l_is_code_level

        RETURN l_patch_status;

	EXCEPTION
	   WHEN no_data_found THEN
	      RETURN l_patch_status;

      END; --declare block

      END IF; --if l_patch_status

      IF (l_analysis_run_bug_id > 0) THEN
        UPDATE ad_pa_analysis_run_bugs
        SET    analysis_status = l_patch_status
        WHERE  analysis_run_id = p_analysis_run_id
        AND     bug_number      = p_bug_number
        AND     baseline        = p_baseline;

        -- Insert the pre-req data in ad_pa_anal_run_bug_prereqs
        debugPrint ('PREREQ CNT:'|| ghashRequires.COUNT);

        IF(ghashRequires.COUNT > 0) THEN
          l_tmpVar := ghashRequires.FIRST; -- get subscript of first element
          WHILE l_tmpVar IS NOT NULL LOOP
            debugPrint ('Pre-req is '|| l_tmpVar ||'   Level: '|| ghashRequires(l_tmpVar));

            IF (p_overwrite) THEN
              DELETE FROM ad_pa_anal_run_bug_prereqs
              WHERE analysis_run_bug_id = l_analysis_run_bug_id
              AND prereq_te_abbr = l_tmpVar;
            END IF;

            INSERT INTO ad_pa_anal_run_bug_prereqs
            (analysis_run_bug_id, prereq_te_abbr,  prereq_te_level,
             created_by,  creation_date,	last_updated_by , last_update_date)
            SELECT  l_analysis_run_bug_id,
                    l_tmpVar ,
                    ghashRequires(l_tmpVar),
                    p_user_id,
                    sysdate,
                    p_user_id,
                    sysdate
            FROM DUAL
            WHERE NOT EXISTS
            ( SELECT 'x' FROM ad_pa_anal_run_bug_prereqs
              WHERE analysis_run_bug_id = l_analysis_run_bug_id
              AND prereq_te_abbr = l_tmpVar
            );

            l_tmpVar := ghashRequires.NEXT(l_tmpVar);
          END LOOP;
        END IF;

        -- Insert the introducing codelevel/baseline data in ad_pa_anal_run_bug_codelevels
        IF (ghashLevelIntr.COUNT > 0) THEN
          debugPrint ('Introducing :'|| ghashLevelIntr.COUNT );
          l_tmpVar := ghashLevelIntr.FIRST; -- get subscript of first element

          WHILE l_tmpVar IS NOT NULL LOOP
            debugPrint ('Introducing for '|| l_tmpVar || '   Level: '|| getValueFromHash(l_tmpVar, ghashLevelIntr)||'  Baseline:'||getValueFromHash(l_tmpVar, ghashBaselineIntr) );

            IF (p_overwrite) THEN
              DELETE FROM ad_pa_anal_run_bug_codelevels
              WHERE analysis_run_bug_id = l_analysis_run_bug_id
              AND intr_te_abbr = l_tmpVar;
            END IF;

            l_tmpLevel := getValueFromHash(l_tmpVar, ghashLevelIntr);
            l_tmpBaseline := getValueFromHash(l_tmpVar, ghashBaselineIntr);

            INSERT INTO ad_pa_anal_run_bug_codelevels
            (analysis_run_bug_id, intr_te_abbr,  intr_te_level,
             intr_te_baseline, intr_te_type,
             created_by,  creation_date,	last_updated_by , last_update_date)
            SELECT  l_analysis_run_bug_id,
                    l_tmpVar ,
                    l_tmpLevel,
                    l_tmpBaseline,
                    null,
                    p_user_id,
                    sysdate,
                    p_user_id,
                    sysdate
            FROM DUAL
            WHERE NOT EXISTS
            ( SELECT 'x' FROM ad_pa_anal_run_bug_codelevels
              WHERE analysis_run_bug_id = l_analysis_run_bug_id
              AND intr_te_abbr = l_tmpVar
            );

            l_tmpVar := ghashLevelIntr.NEXT(l_tmpVar);
          END LOOP;
        END IF;

        COMMIT;

      END IF;
    END IF;

    RETURN l_patch_status;

  EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
    RETURN l_patch_status;

  END;

  ----------------------------------------------------------------------------
  -- Procedure to determine the status of the patch asked by user and also
  -- determines the reasons for output status.
  -- This procedure is exposed to user.
  ----------------------------------------------------------------------------

  FUNCTION getPatchStatus (
    p_bug_number        IN    NUMBER,
    p_baseline          IN    VARCHAR2,
    p_release           IN    VARCHAR2,
    p_err_message       OUT   NOCOPY VARCHAR2
  )
  RETURN VARCHAR2 IS
    l_patch_status      VARCHAR2(100) := 'READY';
    l_patch_type        VARCHAR2(100) :='';
    l_count             NUMBER := 0;
    l_patch_id          NUMBER := 0;
    l_te_abbr           VARCHAR2(30) ;
    l_te_baseline       VARCHAR2(30) ;
    adj_baseline	VARCHAR2(30) ;

  BEGIN

    debugPrint ('Calling Initiallize.... ');
    initialize();
    debugPrint ('End Calling Initiallize.... ');

    -- Check for the existence of BUG_NUMBER, BASELINE in Snapshot tables for global snapshot.
    -- If found then set output status as 'APPLIED'
    -- msailoz bug#5505349
    -- If baseline is not provided or patch is baseline independent only search
    -- for the existence of bug_number in AD_BUGS

    IF ( length(trim(p_baseline)) = 0 OR p_baseline = 'R12') THEN

      SELECT count(SNAPSHOT_BUG_ID) INTO l_count
      FROM ad_snapshot_bugfixes
      WHERE bugfix_id in
         (SELECT bug_id FROM AD_BUGS
         WHERE bug_number = to_char(p_bug_number)
  		   AND ARU_RELEASE_NAME = p_release)
      AND snapshot_id in
         (SELECT snapshot_id
          FROM ad_snapshots
  		    WHERE snapshot_name = 'GLOBAL_VIEW'
  		    and snapshot_type in ('G','Q'));
    ELSE
  	--if p_baseline like %.0 remove the .0
	if (instr(p_baseline,'.0',-1,1) = 2) then
	    adj_baseline := substr(p_baseline,0,length(p_baseline)-2);
	else
	    adj_baseline := p_baseline;
	end if;

      SELECT count(SNAPSHOT_BUG_ID) INTO l_count
      FROM ad_snapshot_bugfixes
      WHERE bugfix_id in
         (SELECT bug_id FROM AD_BUGS
         WHERE bug_number = to_char(p_bug_number)
  		   AND baseline_name = adj_baseline
  		   AND ARU_RELEASE_NAME = p_release)
      AND snapshot_id in
         (SELECT snapshot_id
          FROM ad_snapshots
  		    WHERE snapshot_name = 'GLOBAL_VIEW'
  		    and snapshot_type in ('G','Q'));
    END IF;

    debugPrint ('Count'|| l_count);

    IF (l_count > 0) THEN
      if (isCutover(p_bug_number)) THEN
         l_patch_status := 'APPLIED';
      ELSE
         l_patch_status := 'PENDING';
      end if;
      RETURN l_patch_status;
    ELSE
      debugPrint ('No records found in Snapshot');
      NULL;
    END IF;

    -- Check whether this patch has been uploaded
    debugPrint ('... Checking uploading of patch');
    DECLARE
      l_upload_id   NUMBER := 0;
    BEGIN

      SELECT  entity_abbr,
              patch_id,
              NVL(upload_run_id,-1),
              NVL(patch_type,'')
      INTO    l_te_abbr,
              l_patch_id,
              l_upload_id,
              l_patch_type
      FROM   ad_pm_patches
      WHERE  bug_number = p_bug_number
      AND    baseline = p_baseline;

      --- 09-Aug-2006 ababkuma bug#5357552 handling obsoleted patch
      IF (l_patch_id = 0 ) THEN
        l_patch_status := 'ERROR';
        p_err_message := 'PATCH NOT UPLOADED';
        RETURN l_patch_status;
      ELSIF (l_upload_id <= 0 ) THEN
        l_patch_status := 'ERROR';
        p_err_message := 'PATCH METADATA NOT UPLOADED';
        RETURN l_patch_status;
      ELSIF (l_patch_type = 'obsoleted' ) THEN
        l_patch_status := 'OBSOLETED';
        p_err_message := 'PATCH IS OBSOLETED';
        RETURN l_patch_status;
      END IF;

    EXCEPTION
      WHEN no_data_found THEN
        l_patch_status := 'ERROR';
        p_err_message := 'PATCH NOT UPLOADED';
        RETURN l_patch_status;
    END;

    -- Compare the baseline of patch with that on customer instance
    debugPrint ('... Checking uploading of patch');

    -- if the patch is generic patch then no need of comparing with baseline on customer instance
    IF (p_baseline <> 'R12' AND  LENGTH(TRIM(p_baseline)) > 0) THEN
      BEGIN

        SELECT baseline
        INTO   l_te_baseline
        FROM   ad_trackable_entities
        WHERE  abbreviation = l_te_abbr;

        -- if the patch is not generic and doesn't match with the baseline
        -- on customer instance then error out
        IF (compareLevel(l_te_baseline, p_baseline) <> 0 ) THEN
          l_patch_status := 'ERROR';
          p_err_message := 'PATCH BASELINE NOT MATCHING';
        END IF;

      EXCEPTION
        WHEN no_data_found THEN
          l_patch_status := 'READY';
      END;
    END IF;

    -- Check all the baselines introduced are higher or equal to that on the customer instance.
    -- Also mark the new CodeLevels introduced
    DECLARE
      l_tmpVar         VARCHAR2(100) := NULL;
    BEGIN
      debugPrint ('... Checking levels of patch');
      FOR rec IN
      (SELECT appei.te_abbr,
              nvl(ate.baseline,0) curr_baseline,
	            nvl(appei.baseline,0) intr_baseline,
              nvl(ate.codelevel,0) curr_level,
	            nvl(appei.te_level,0) intr_level
       FROM  ad_pa_patch_entity_info appei,
             ad_trackable_entities ate
       WHERE appei.te_abbr = ate.abbreviation(+)
       AND   appei.patch_id = l_patch_id)
      LOOP
        debugPrint (rec.te_abbr ||' BASELINE (current,intr) ('|| rec.curr_baseline||', '||rec.intr_baseline
	       ||') CODELEVEL (current,intr) ('|| rec.curr_level||', '|| rec.intr_level||')');
        IF( compareLevel(rec.intr_baseline, rec.curr_baseline) <> 2) THEN
          IF( compareLevel(rec.intr_level, rec.curr_level) = 1 ) THEN
            ghashLevelIntr(rec.te_abbr) := rec.intr_level;
          END IF;
          IF( compareLevel(rec.intr_baseline, rec.curr_baseline) = 1 ) THEN
            ghashBaselineIntr(rec.te_abbr) := rec.intr_level;
          END IF;
        END IF;
      END LOOP;

      -- IF(l_tmpStatus != NULL) THEN
      --  l_patch_status := 'ERROR';
      --  p_err_message := 'Found higher '||l_tmpStatus||' baselines than in Patch';
      --  RETURN l_patch_status;
      --END IF;

      -- Store the introducing levels in output string
      IF ( ghashLevelIntr.COUNT > 0) THEN
        p_err_message := p_err_message || 'INTRODUCES ';
        l_tmpVar := ghashLevelIntr.FIRST;
        WHILE l_tmpVar IS NOT NULL LOOP
          p_err_message := p_err_message || l_tmpVar ||':'|| ghashLevelIntr(l_tmpVar) ||' ';
          l_tmpVar := ghashLevelIntr.NEXT(l_tmpVar);
        END LOOP;
      END IF;
    END;

    debugPrint ('New Levels Introduced: '|| ghashLevelIntr.COUNT );
    debugPrint ('New Baselines Introduced: '|| ghashBaselineIntr.COUNT );


    -- Check all the requires and conditional requires (PRE_REQUISITES )specified in patch driver.
    DECLARE
      l_tmpVar         VARCHAR2(100) := NULL;
    BEGIN
      debugPrint ('... Checking Requires of patch');
      debugPrint ('PATCH ID: '|| l_patch_id);
      FOR rec IN
      ( SELECT   appri.patch_requires_id,
                 appri.te_abbr,
                 appri.requires_te_abbr,
                 appri.requires_te_level ,
                 appcri.condition_type,
                 appcri.condition_te_abbr,
                 appcri.condition_te_level
        FROM  ad_pa_patch_requires_info appri,
        ad_pa_patch_cond_requires_info appcri
        WHERE appri.patch_id = l_patch_id
        AND   appri.patch_requires_id = appcri.patch_requires_id (+) )

      LOOP
        IF (rec.condition_type IS NULL) THEN
          addPrereq(rec.requires_te_abbr, rec.requires_te_level, ghashRequires);
        ELSIF( UPPER(rec.condition_type) = 'IFUSED') THEN
          IF( ghashIfUsed.EXISTS(rec.condition_te_abbr)) THEN
            IF(ghashIfUsed(rec.condition_te_abbr) = 'Y'
              AND (compareLevel(rec.condition_te_level, ghashLevel(rec.condition_te_abbr)) = 1
                   OR compareLevel(rec.condition_te_level, ghashLevel(rec.condition_te_abbr)) = 0 )
             ) THEN

              addPrereq(rec.requires_te_abbr, rec.requires_te_level, ghashRequires);
            END IF;
          END IF;
        ELSIF( UPPER(rec.condition_type) = 'IFLOAD') THEN
          IF(ghashIfLoad.EXISTS(rec.condition_te_abbr)) THEN
            IF(ghashIfLoad(rec.condition_te_abbr) = 'Y'
             AND (compareLevel(rec.condition_te_level, ghashLevel(rec.condition_te_abbr)) = 1
                 OR compareLevel(rec.condition_te_level, ghashLevel(rec.condition_te_abbr)) = 0 )
               ) THEN
              addPrereq(rec.requires_te_abbr, rec.requires_te_level, ghashRequires);
            END IF;
          END IF;
        END IF;
      END LOOP;

      debugPrint ('Total Requires: '|| ghashRequires.COUNT );
      -- Store the requires in output string
      IF ( ghashRequires.COUNT > 0) THEN
        l_patch_status := 'MISSING';
        p_err_message := p_err_message || 'REQUIRES ';
        l_tmpVar := ghashRequires.FIRST;
        WHILE l_tmpVar IS NOT NULL LOOP
          p_err_message := p_err_message || UPPER(l_tmpVar) ||'.'|| ghashRequires(l_tmpVar) ||' ';

          l_tmpVar := ghashRequires.NEXT(l_tmpVar);
        END LOOP;

        RETURN l_patch_status;
      END IF;
    END;

    RETURN l_patch_status;

  END;

  FUNCTION ISCUTOVER(p_bug_number in varchar2)
  RETURN BOOLEAN
  IS

  adop_count number := 0;

  cursor c_cutover_status(c_bug_number varchar2) is
	select aas.cutover_status from
	ad_adop_sessions aas,
	ad_adop_session_patches aasp
	where aasp.bug_number = p_bug_number
	and aas.adop_session_id = aasp.adop_session_id;

  BEGIN

   	for cutoverrec in c_cutover_status(p_bug_number) loop
	    if (cutoverrec.cutover_status = 'Y') then
		return TRUE;
	    elsif (cutoverrec.cutover_status = 'N' or cutoverrec.cutover_status is null) then
		adop_count := adop_count+1;
   	    end if;
	end loop;

	if (adop_count > 0) then
		return FALSE;
	else
		return TRUE;
	end if;

  END;

-- var p varchar2(100)
-- var c varchar2(100)
--- exec :p := ad_patch_analysis_engine.getPatchStatus(9000002,'R12','R12', :c);
--- exec :p := ad_patch_analysis_engine.getPatchStatus(7000002,'AD.1.0','R12', :c, 4652175, 4);
--- exec :p := ad_patch_analysis_engine.getPatchStatus(8000004,'R12','R12', :c);
--- exec :p := ad_patch_analysis_engine.compareLevel('AD.1.2','AD.1')
--  select ad_patch_analysis_engine.compareLevel('120.22','33') from dual

END ad_patch_analysis_engine;
