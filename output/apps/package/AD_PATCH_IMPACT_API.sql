
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PATCH_IMPACT_API" AUTHID CURRENT_USER AS
/* $Header: adpaias.pls 120.3 2006/04/05 03:29:02 msailoz noship $ */

    TYPE t_rec_patch is TABLE of NUMBER(30)
    INDEX BY BINARY_INTEGER;
    TYPE t_prereq_patch is TABLE of NUMBER(30)
    INDEX BY BINARY_INTEGER;

    TYPE t_recomm_patch_rec IS RECORD (
      bug_number      NUMBER,
      baseline        VARCHAR2(150),
      patch_id        NUMBER
    );

    TYPE t_recomm_patch_tab IS TABLE OF t_recomm_patch_rec;

/**
  The Function returns the list of patches recommended in the current request set.
  i.e., this AD API would query the FND Concurrent Request table to get the request
  ID of the currently running Request Set and use this request ID to query the
  AD_PA_ANALYSIS_RUN_BUGS table to get the list of bug numbers recommended.
**/
 PROCEDURE get_recommend_patch_list
 (
     a_rec_patch OUT NOCOPY  t_rec_patch
 )
  ;

/**
  The Function returns the list of patches recommended in the current request set.
  i.e., this AD API would query the FND Concurrent Request table to get the request
  ID of the currently running Request Set and use this request ID to query the
  AD_PA_ANALYSIS_RUN_BUGS table to get the list of bug numbers recommended.
**/
 PROCEDURE get_recommend_patch_list
 (
     p_recomm_patch_tab OUT NOCOPY  t_recomm_patch_tab
 )
  ;


/**
  This API will return to PIA the Global Snapshot ID.
 **/
 PROCEDURE get_global_snapshot_id
 (
    snap_id OUT NOCOPY Number
 )
  ;

/**
 PIA CPs would call this PL/SQL API that returns the list of
  pre-req'ed patches that have not been applied for each recommended patch.
  API input: recommended patch bug number (obtained from the 1st API)
  API output: list of pre-req's of this recommended patch that have not been
  applied to the system.
**/
  PROCEDURE get_prereq_list
  (
    bug_number_val IN Number,
    a_prereq_patch OUT  NOCOPY t_prereq_patch
   )
    ;

/**
  PIA CPs would call this PL/SQL API that returns the list of
  pre-req'ed patches that have not been applied for each recommended patch
  for a particular request set.
  API input: request set id
  API input: recommended patch bug number (obtained from the 1st API)
  API output: list of pre-req's of this recommended patch that have not been
  applied to the system.
  The Function returns 1 in case of error
 **/
  PROCEDURE get_prereq_list
  (
    pRequestId  IN Number,
    pBugNumber     IN Number,
    pPrereqPatches OUT  NOCOPY t_prereq_patch
   )
   ;


END AD_PATCH_IMPACT_API;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PATCH_IMPACT_API" AS
/* $Header: adpaiab.pls 120.3.12020000.3 2013/08/23 19:19:17 tshort ship $ */
/**
  The Procedure returns the list of patches recommended in the current request set.
  i.e., this AD API would query the FND Concurrent Request table to get the request
  ID of the currently running Request Set and use this request ID to query the
  AD_PA_ANALYSIS_RUN_BUGS table to get the list of bug numbers recommended.
**/
  PROCEDURE get_recommend_patch_list
       ( a_rec_patch  OUT  NOCOPY t_rec_patch )
  IS
    CURSOR rec_cur(X_anal_req_id Number) IS
     select bug_number from
     ad_pa_analysis_run_bugs  where analysis_run_id = X_anal_req_id and
     (analysis_status in ('READY', 'MISSING', 'PENDING', 'IMPLICIT') or analysis_status is null);

    req_id         NUMBER:= 0;
    anal_req_id    NUMBER:= 0;
    count1 Number  default 1;
    Rows_Exceeded  Exception;
  BEGIN
    --Get the request ID of currently running Request Set
    --fnd_file.put_line(fnd_file.log, to_char(sysdate,'HH24:MI:SS')||'> request ID of currently before...');
    select priority_request_id into req_id from fnd_concurrent_requests where
    request_id = fnd_global.conc_request_id;
    --fnd_file.put_line(fnd_file.log, to_char(sysdate,'HH24:MI:SS')||'> request ID of currently After...');
    --Get the request ID of the AD CP within the Request Set

    SELECT
      fcr.request_id into anal_req_id
    FROM
      fnd_application fa,
      fnd_concurrent_requests fcr,
      fnd_concurrent_programs fcp
    WHERE
      fcr.priority_request_id     = req_id and
      fcr.program_application_id  = fcp.application_id and
      fcp.application_id          = fa.application_id and
      fcr.concurrent_program_id   = fcp.concurrent_program_id and
      fa.application_short_name   = 'AD' and
      fcp.concurrent_program_name  in ('PATCHANALYSIS', 'PAANALYSIS','PADOWNLOADPATCHES','PAANALYZEPATCHES','PARECOMMENDPATCHES' ) ;

      --fnd_file.put_line(fnd_file.log, to_char(sysdate,'HH24:MI:SS')||'> request ID of currently After Select...');
      --FOR c in rec_cur(167371) LOOP
      FOR c in rec_cur(anal_req_id) LOOP
        a_rec_patch(count1) := c.bug_number;
        count1 := count1 + 1;
 	--fnd_file.put_line(fnd_file.log, to_char(sysdate,'HH24:MI:SS')||'> request ID of currently After for...');
        /* if count1 > 20 then
         RAISE Rows_Exceeded;
        END if; */
      END LOOP;

    END get_recommend_patch_list;


 /**
  The Procedure returns the list of patches recommended in the current request set.
  i.e., this AD API would query the FND Concurrent Request table to get the request
  ID of the currently running Request Set and use this request ID to query the
  AD_PA_ANALYSIS_RUN_BUGS table to get the list of bug numbers/baseline/patchid.
**/
  PROCEDURE get_recommend_patch_list
    ( p_recomm_patch_tab  OUT  NOCOPY t_recomm_patch_tab )
  IS

    CURSOR rec_cur(X_anal_req_id NUMBER) IS
      SELECT aparb.bug_number, aparb.baseline, app.patch_id
      FROM  ad_pa_analysis_run_bugs  aparb,
            ad_pm_patches app
      WHERE aparb.analysis_run_id = X_anal_req_id
      AND aparb.bug_number = app.bug_number
      AND aparb.baseline = app.baseline
      AND app.patch_metadata_key = 'DEFAULT'
      AND (aparb.analysis_status IN ('READY', 'MISSING', 'PENDING', 'IMPLICIT')
          OR aparb.analysis_status IS NULL);

    req_id              NUMBER := 0;
    anal_req_id         NUMBER := 0;
    count1              NUMBER  DEFAULT 1;
    l_rec               t_recomm_patch_rec;

   BEGIN

    -- Initialize the plsql table
    p_recomm_patch_tab := t_recomm_patch_tab();

    --Get the request ID of currently running Request Set
    SELECT priority_request_id
    INTO req_id
    FROM fnd_concurrent_requests
    WHERE request_id = fnd_global.conc_request_id;

    --Get the request ID of the AD CP within the Request Set
    SELECT
      fcr.request_id into anal_req_id
    FROM
      fnd_application fa,
      fnd_concurrent_requests fcr,
      fnd_concurrent_programs fcp
    WHERE
        fcr.priority_request_id     = req_id
    AND fcr.program_application_id  = fcp.application_id
    AND fcp.application_id          = fa.application_id
    AND fcr.concurrent_program_id   = fcp.concurrent_program_id
    AND fa.application_short_name   = 'AD'
    AND fcp.concurrent_program_name  in
        ('PATCHANALYSIS', 'PAANALYSIS','PADOWNLOADPATCHES','PAANALYZEPATCHES','PARECOMMENDPATCHES' ) ;

    -- For each row store the value in plsql table
    FOR c IN rec_cur(anal_req_id) LOOP

      l_rec.bug_number  := c.bug_number;
      l_rec.baseline    := c.baseline;
      l_rec.patch_id    := c.patch_id;

      p_recomm_patch_tab.extend;
      p_recomm_patch_tab(count1) := l_rec;
      count1 := count1 + 1;
    END LOOP;

    /** For testing purpose
    IF(p_recomm_patch_tab.COUNT > 0) THEN
      FOR c IN 1..p_recomm_patch_tab.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE (p_recomm_patch_tab(c).bug_number ||'   '||
        p_recomm_patch_tab(c).baseline || '   '||
        p_recomm_patch_tab(c).patch_id );
      END LOOP;
    END IF;
    **/

  END get_recommend_patch_list;


 /**
  This API will return to PIA the Global Snapshot ID.
 **/
  PROCEDURE get_global_snapshot_id (snap_id  OUT  NOCOPY Number)
  IS
  BEGIN
    SELECT
      snp.snapshot_id into snap_id
    FROM
      ad_snapshots       snp,
      ad_appl_tops       aat,
      fnd_product_groups fpg
    WHERE
      snp.snapshot_type            = 'G'               and
      snp.snapshot_name            = 'GLOBAL_VIEW'     and
      snp.appl_top_id              = aat.appl_top_id   and
      aat.applications_system_name = fpg.applications_system_name and
      fpg.product_group_id         = 1;

  END get_global_snapshot_id ;


 /**
 PIA CPs would call this PL/SQL API that returns the list of
  pre-req'ed patches that have not been applied for each recommended patch.
  API input: recommended patch bug number (obtained from the 1st API)
  API output: list of pre-req's of this recommended patch that have not been
  applied to the system.
  The Function returns 1 in case of error
**/

  PROCEDURE get_prereq_list
  (
    bug_number_val IN Number,
    a_prereq_patch  OUT NOCOPY t_prereq_patch
  )
  IS
    req_id NUMBER := 0;
    anal_req_id NUMBER := 0;
    count1 Number default 1;
    Rows_Exceeded Exception;

    CURSOR prereq_cur(X_anal_req_id Number , X_bug_number Number) IS
    SELECT
      distinct(prereq_bug_number) prereq_bug_num ,
      prereq_bug_order
    FROM
      ad_pa_anal_bug_deps
    WHERE
      analysis_run_id = X_anal_req_id and
      bug_number = X_bug_number
      order by prereq_bug_order;

  BEGIN
    --Get the request ID of currently running Request Set:

    SELECT
      priority_request_id INTO req_id
    FROM
      fnd_concurrent_requests
    WHERE
      request_id = fnd_global.conc_request_id;

    --Get the request ID of the AD CP within the Request Set
    SELECT
      fcr.request_id INTO anal_req_id
    FROM
      fnd_application fa,
      fnd_concurrent_requests fcr,
      fnd_concurrent_programs fcp
    WHERE
      fcr.priority_request_id = req_id    and
      fcr.program_application_id = fcp.application_id and
      fcp.application_id = fa.application_id and
      fcr.concurrent_program_id = fcp.concurrent_program_id and
      fa.application_short_name = 'AD' and
      fcp.concurrent_program_name in
        ('PATCHANALYSIS', 'PAANALYSIS','PADOWNLOADPATCHES','PAANALYZEPATCHES','PARECOMMENDPATCHES' ) ;

    FOR c in prereq_cur(anal_req_id,bug_number_val) LOOP
      a_prereq_patch(count1) := c.prereq_bug_num;
      count1 := count1 + 1;
      /* if count1 > 20 then
        RAISE Rows_Exceeded;
       END if;  */
    END LOOP;

  END get_prereq_list;

/**
  PIA CPs would call this PL/SQL API that returns the list of
  pre-req'ed patches that have not been applied for each recommended patch
  for a particular request set.
  API input: request id (corresponding to PADOWNLOADPATCHES, PAANALYZEPATCHES, PAMERGEPATCHES)
  API input: recommended patch bug number (obtained from the 1st API)
  API output: list of pre-req's of this recommended patch that have not been
  applied to the system.
  The Function returns 1 in case of error
**/

  PROCEDURE get_prereq_list
  (
    pRequestId     IN Number,
    pBugNumber     IN Number,
    pPrereqPatches OUT  NOCOPY t_prereq_patch
   )
   IS
     count1 Number default 1;

     CURSOR prereq_cur(X_anal_req_id Number , X_bug_number Number) IS
     SELECT
       distinct(prereq_bug_number) prereq_bug_num ,
       prereq_bug_order
     FROM   ad_pa_anal_bug_deps
     WHERE  analysis_run_id = X_anal_req_id AND
       bug_number = X_bug_number
     ORDER BY prereq_bug_order;

   BEGIN

     FOR c in prereq_cur(pRequestId, pBugNumber) LOOP
         pPrereqPatches(count1) := c.prereq_bug_num;
	 -- dbms_output.put_line(c.prereq_bug_num);
         count1 := count1 + 1;
     END LOOP;

  END get_prereq_list;

 END AD_PATCH_IMPACT_API;

