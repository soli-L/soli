
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PA_MISC" AUTHID CURRENT_USER as
/* $Header: adpamiss.pls 120.2.12010000.1 2010/03/30 15:10:59 mkumandu noship $*/

function get_total_time_stringformat(prid number,
                        tsid number,
                        prd varchar2,
                        pname varchar2)
return varchar2;

function get_total_time(prid number,
                        tsid number,
                        prd varchar2,
                        pname varchar2)
return number;

function get_total_time(ssid number,
                        prd varchar2,
                        pname varchar2) return
varchar2;
end ad_pa_misc;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PA_MISC" as
/* $Header: adpamisb.pls 120.2 2010/03/31 06:34:27 mkumandu noship $ */

function get_total_time_stringformat(prid number,
                        tsid number,
                        prd varchar2,
                        pname varchar2)
return varchar2 is
BEGIN

return ad_core.get_formatted_elapsed_time(get_total_time(prid,
                                                         tsid,
                                                         prd,
                                                         pname), 2);
END;

function get_total_time(prid number,
                        tsid number,
                        prd varchar2,
                        pname varchar2)
return number is
TYPE job_name   IS TABLE OF ad_program_run_task_jobs.job_name%TYPE;
TYPE start_time IS TABLE OF ad_program_run_task_jobs.start_time%TYPE;
TYPE end_time   IS TABLE OF ad_program_run_task_jobs.end_time%TYPE;

l_job_name   job_name;
l_start_time start_time;
l_end_time   end_time;

l_total_time number;
l_previous_start_time date;
l_previous_end_time date;

l_ctr NUMBER;
l_prd VARCHAR2(512) := UPPER(prd);


BEGIN
SELECT job_name,
       start_time,
       end_time
BULK COLLECT INTO l_job_name,
                  l_start_time,
                  l_end_time
FROM   ad_program_run_task_jobs
WHERE program_run_id=prid
AND   task_status_id=tsid
AND   phase_name=pname
AND   (product=prd OR
       (product='java' AND ((arguments like '%fullpath:'||prd||':%') OR
                           (arguments like '%fullpath_'||prd||'_%') OR
                           (arguments like '%'||UPPER(prd)||'_TOP%'))))
ORDER BY start_time;
l_total_time := 0;
IF l_job_name.COUNT>0 THEN
   l_previous_start_time := l_start_time(1);
   l_previous_end_time := l_end_time(1);
   FOR l_ctr in 1..l_job_name.COUNT
   LOOP
          IF (l_start_time(l_ctr) < l_previous_end_time OR
              l_start_time(l_ctr) = l_previous_end_time) AND
             (l_previous_end_time < l_end_time(l_ctr) OR
              l_previous_end_time = l_end_time(l_ctr)) THEN
                l_previous_end_time := l_end_time(l_ctr);
          ELSIF (l_start_time(l_ctr) < l_previous_end_time OR
                 l_start_time(l_ctr) = l_previous_end_time) AND
                l_previous_end_time > l_end_time(l_ctr) THEN
                   null;
          ELSE
             l_total_time := l_total_time + (l_previous_end_time - l_previous_start_time);
             l_previous_start_time := l_start_time(l_ctr);
             l_previous_end_time := l_end_time(l_ctr);
          END IF;
   END LOOP;
   l_total_time := l_total_time + (l_previous_end_time - l_previous_start_time);
END IF;

return l_total_time;
end get_total_time;

function get_total_time(ssid number,
                        prd varchar2,
                        pname varchar2)
return varchar2 is
TYPE job_name   IS TABLE OF ad_task_timing.job_name%TYPE;
TYPE start_time IS TABLE OF ad_task_timing.start_time%TYPE;
TYPE end_time   IS TABLE OF ad_task_timing.end_time%TYPE;

l_job_name   job_name;
l_start_time start_time;
l_end_time   end_time;

l_total_time number;
l_previous_start_time date;
l_previous_end_time date;

l_ctr NUMBER;


BEGIN
SELECT job_name,
       start_time,
       end_time
BULK COLLECT INTO l_job_name,
                  l_start_time,
                  l_end_time
FROM   ad_task_timing
WHERE session_id=ssid
AND   phase_name=pname
AND   (product=prd OR
       (product='java' AND ((arguments like '%fullpath:'||prd||':%') OR
                           (arguments like '%fullpath_'||prd||'_%') OR
                           (arguments like '%'||UPPER(prd)||'_TOP%'))))
ORDER BY start_time;

/*
SELECT job_name,
       start_time,
       end_time
BULK COLLECT INTO l_job_name,
                  l_start_time,
                  l_end_time
FROM   ad_task_timing
WHERE session_id=ssid
AND   phase_name=pname
AND   prd=NVL(DECODE(product,
                     'java',
                     regexp_substr(
                            regexp_substr(
                                   regexp_substr(arguments,
                                                 'fullpath[:|_](\w+)[:|_]'),
                                    ':\w+:'),
                                 '\w+'),
                             product), NVL(lower(
                                               regexp_substr(
                                                 regexp_substr(arguments,
                                                               '[A-Z]+_TOP'),
                                              '[A-Z]+')), product))
ORDER BY start_time;

AND   prd=DECODE(product, 'java',
          regexp_substr(
                 regexp_substr(
                        regexp_substr(arguments,
                                      'fullpath[:|_](\w+)[:|_]'),
                               ':\w+:'),
                        '\w+'), product) product
 */
l_total_time := 0;
IF l_job_name.COUNT>0 THEN
   l_previous_start_time := l_start_time(1);
   l_previous_end_time := l_end_time(1);
   FOR l_ctr in 1..l_job_name.COUNT
   LOOP
          IF (l_start_time(l_ctr) < l_previous_end_time OR
              l_start_time(l_ctr) = l_previous_end_time) AND
             (l_previous_end_time < l_end_time(l_ctr) OR
              l_previous_end_time = l_end_time(l_ctr)) THEN
                l_previous_end_time := l_end_time(l_ctr);
          ELSIF (l_start_time(l_ctr) < l_previous_end_time OR
                 l_start_time(l_ctr) = l_previous_end_time) AND
                l_previous_end_time > l_end_time(l_ctr) THEN
                   null;
          ELSE
             l_total_time := l_total_time + (l_previous_end_time - l_previous_start_time);
             l_previous_start_time := l_start_time(l_ctr);
             l_previous_end_time := l_end_time(l_ctr);
          END IF;
   END LOOP;
   l_total_time := l_total_time + (l_previous_end_time - l_previous_start_time);
END IF;
return ad_core.get_formatted_elapsed_time(l_total_time, 2);
end get_total_time;

END ad_pa_misc;
