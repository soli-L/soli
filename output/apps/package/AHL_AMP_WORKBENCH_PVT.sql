
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_AMP_WORKBENCH_PVT" AUTHID CURRENT_USER AS
  /* $Header: AHLVAMPS.pls 120.0.12020000.2 2012/12/11 03:06:52 prakkum noship $ */
  --
  ---------------------------------------------------------------------
  -- Define Record Types for record structures needed by the APIs --
  ---------------------------------------------------------------------
-- Record Type used for Org Search criteria
TYPE ORG_SCH_SEARCH_REC
IS
  RECORD
  (
    ORG_ID            NUMBER,
    DEPARTMENT_ID     NUMBER,
    SPACE_ID          NUMBER,
    DEPARTMENT_NAME   VARCHAR2(240),
    SPACE_NAME        VARCHAR2(240),
    START_FROM_DATE   DATE,
    START_BEFORE_DATE DATE,
    DISPLAY_WINDOW    NUMBER,
    RESULT_FILTER     VARCHAR2(15) );

-- Record Type used for Fleet Search criteria
TYPE FLEET_SCH_SEARCH_REC
IS
  RECORD
  (
    FLEET_ID          NUMBER,
    UNIT_ID           NUMBER,
    UNIT_NAME         VARCHAR2(240),
    MASTER_CONFIG     VARCHAR2(240),
    MINIMUM_DURATION  NUMBER,
    UOM               VARCHAR2(15),
    START_FROM_DATE   DATE,
    START_BEFORE_DATE DATE,
    DISPLAY_WINDOW    NUMBER );

-- Record Type used return data which will populate the VO
TYPE SCH_GRAPH_RESULTS_REC
IS
  RECORD
  (
    ORG_ID           NUMBER,
    DEPARTMENT_ID    NUMBER,
    DEPARTMENT_DESC  VARCHAR2(240),
    SPACE_ID         NUMBER,
    SPACE_NAME       VARCHAR2(30),
    UNIT_ID          NUMBER,
    UNIT_NAME        VARCHAR2(240),
    SCHEDULE_TYPE_1  VARCHAR2(30),
    VISIT_DATE_1     DATE,
    VISIT_ID_1       NUMBER,
    SCHEDULE_TYPE_2  VARCHAR2(30),
    VISIT_DATE_2     DATE,
    VISIT_ID_2       NUMBER,
    SCHEDULE_TYPE_3  VARCHAR2(30),
    VISIT_DATE_3     DATE,
    VISIT_ID_3       NUMBER,
    SCHEDULE_TYPE_4  VARCHAR2(30),
    VISIT_DATE_4     DATE,
    VISIT_ID_4       NUMBER,
    SCHEDULE_TYPE_5  VARCHAR2(30),
    VISIT_DATE_5     DATE,
    VISIT_ID_5       NUMBER,
    SCHEDULE_TYPE_6  VARCHAR2(30),
    VISIT_DATE_6     DATE,
    VISIT_ID_6       NUMBER,
    SCHEDULE_TYPE_7  VARCHAR2(30),
    VISIT_DATE_7     DATE,
    VISIT_ID_7       NUMBER,
    SCHEDULE_TYPE_8  VARCHAR2(30),
    VISIT_DATE_8     DATE,
    VISIT_ID_8       NUMBER,
    SCHEDULE_TYPE_9  VARCHAR2(30),
    VISIT_DATE_9     DATE,
    VISIT_ID_9       NUMBER,
    SCHEDULE_TYPE_10 VARCHAR2(30),
    VISIT_DATE_10    DATE,
    VISIT_ID_10      NUMBER,
    SCHEDULE_TYPE_11 VARCHAR2(30),
    VISIT_DATE_11    DATE,
    VISIT_ID_11      NUMBER,
    SCHEDULE_TYPE_12 VARCHAR2(30),
    VISIT_DATE_12    DATE,
    VISIT_ID_12      NUMBER,
    SCHEDULE_TYPE_13 VARCHAR2(30),
    VISIT_DATE_13    DATE,
    VISIT_ID_13      NUMBER,
    SCHEDULE_TYPE_14 VARCHAR2(30),
    VISIT_DATE_14    DATE,
    VISIT_ID_14      NUMBER,
    SCHEDULE_TYPE_15 VARCHAR2(30),
    VISIT_DATE_15    DATE,
    VISIT_ID_15      NUMBER,
    SCHEDULE_TYPE_16 VARCHAR2(30),
    VISIT_DATE_16    DATE,
    VISIT_ID_16      NUMBER,
    SCHEDULE_TYPE_17 VARCHAR2(30),
    VISIT_DATE_17    DATE,
    VISIT_ID_17      NUMBER,
    SCHEDULE_TYPE_18 VARCHAR2(30),
    VISIT_DATE_18    DATE,
    VISIT_ID_18      NUMBER,
    SCHEDULE_TYPE_19 VARCHAR2(30),
    VISIT_DATE_19    DATE,
    VISIT_ID_19      NUMBER,
    SCHEDULE_TYPE_20 VARCHAR2(30),
    VISIT_DATE_20    DATE,
    VISIT_ID_20      NUMBER,
    SCHEDULE_TYPE_21 VARCHAR2(30),
    VISIT_DATE_21    DATE,
    VISIT_ID_21      NUMBER,
    FILTER_REC       BOOLEAN := FALSE );

-- Record Type used to returns the Visit Details
TYPE SCH_VISITS_REC
IS
  RECORD
  (
    VISIT_ID   NUMBER,
    START_DATE DATE,
    END_DATE   DATE );

-- Maintenance Capacity Graph -Input record type
-- resource availability will be filled by API while processing

TYPE resource_input_rec_type
IS
  RECORD
  (
    resource_id           NUMBER,
    resource_availability NUMBER); /* Sthilak removed the numeric precision */

-- Maintenance Capacity Graph -Output record type
TYPE resource_ouput_rec_type
IS
  RECORD
  (
    on_date     DATE,
    cent_percent_capacity NUMBER, -- STHILAK Cent percent BAr
    r1_capacity NUMBER,
    r2_capacity NUMBER,
    r3_capacity NUMBER,
    r4_capacity NUMBER,
    r5_capacity NUMBER ); /* Sthilak removed the numeric precision */

  ----------------------------------------------
  -- Define Table Type for records structures --
  ----------------------------------------------
TYPE SCH_GRAPH_RESULTS_TBL
IS
  TABLE OF SCH_GRAPH_RESULTS_REC INDEX BY BINARY_INTEGER;

TYPE SCH_VISITS_TBL
IS
  TABLE OF SCH_VISITS_REC INDEX BY BINARY_INTEGER;

TYPE resource_input_tbl_type
IS
  TABLE OF resource_input_rec_type INDEX BY BINARY_INTEGER;

TYPE resource_output_tbl_type
IS
  TABLE OF resource_ouput_rec_type INDEX BY BINARY_INTEGER;

  -----------------------------------------------
  --      Define Procedures and Functions      --
  -----------------------------------------------
  -- Procedure name              : GET_ORG_SCH_GRAPH
  -- Type                        : Public
  -- Parameters                  :
  --
  -- Standard IN  Parameters :
  --      p_api_version               NUMBER   Required
  --      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
  --      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
  --
  -- Standard OUT Parameters :
  --      x_return_status             VARCHAR2 Required
  --      x_msg_count                 NUMBER   Required
  --      x_msg_data                  VARCHAR2 Required
  -- GET_ORG_SCH_GRAPH params
  --      p_org_sch_search_rec        ORG_SCH_SEARCH_REC    Required
  --      x_sch_graph_results_tbl     SCH_GRAPH_RESULTS_TBL

PROCEDURE GET_ORG_SCH_GRAPH(
    p_api_version           IN         NUMBER   := 1.0,
    p_init_msg_list         IN         VARCHAR2 := FND_API.G_TRUE,
    p_validation_level      IN         NUMBER   := FND_API.G_VALID_LEVEL_FULL,
    x_return_status         OUT NOCOPY VARCHAR2,
    x_msg_count             OUT NOCOPY NUMBER,
    x_msg_data              OUT NOCOPY VARCHAR2,
    p_org_sch_search_rec    IN         ORG_SCH_SEARCH_REC,
    x_sch_graph_results_tbl OUT NOCOPY SCH_GRAPH_RESULTS_TBL );

  -- Procedure name              : GET_VISITS_FOR_DATE
  -- Type                        : Public
  -- Parameters                  :
  --
  -- Standard IN  Parameters :
  --      p_api_version               NUMBER   Required
  --      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
  --      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
  --
  -- Standard OUT Parameters :
  --      x_return_status             VARCHAR2 Required
  --      x_msg_count                 NUMBER   Required
  --      x_msg_data                  VARCHAR2 Required
  -- GET_VISITS_FOR_DATE_ORG params
  --      p_org_sch_search_rec        ORG_SCH_SEARCH_REC    Required
  --      x_sch_graph_rec             SCH_GRAPH_RESULTS_REC
  --      x_sch_visits_tbl            SCH_VISITS_TBL

PROCEDURE GET_VISITS_FOR_DATE_ORG(
    p_api_version        IN         NUMBER   := 1.0,
    p_init_msg_list      IN         VARCHAR2 := FND_API.G_TRUE,
    p_validation_level   IN         NUMBER   := FND_API.G_VALID_LEVEL_FULL,
    x_return_status      OUT NOCOPY VARCHAR2,
    x_msg_count          OUT NOCOPY NUMBER,
    x_msg_data           OUT NOCOPY VARCHAR2,
    p_org_sch_search_rec IN         ORG_SCH_SEARCH_REC,
    x_sch_graph_rec      OUT NOCOPY SCH_GRAPH_RESULTS_REC,
    x_sch_visits_tbl     OUT NOCOPY SCH_VISITS_TBL );

  -- Procedure name              : GET_FLT_SCH_GRAPH
  -- Type                        : Public
  -- Parameters                  :
  --
  -- Standard IN  Parameters :
  --      p_api_version               NUMBER   Required
  --      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
  --      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
  --
  -- Standard OUT Parameters :
  --      x_return_status             VARCHAR2 Required
  --      x_msg_count                 NUMBER   Required
  --      x_msg_data                  VARCHAR2 Required
  -- GET_ORG_SCH_GRAPH params
  --      p_flt_sch_search_rec        FLEET_SCH_SEARCH_REC    Required
  --      x_sch_graph_results_tbl     SCH_GRAPH_RESULTS_TBL

PROCEDURE GET_FLT_SCH_GRAPH(
    p_api_version           IN         NUMBER   := 1.0,
    p_init_msg_list         IN         VARCHAR2 := FND_API.G_TRUE,
    p_validation_level      IN         NUMBER   := FND_API.G_VALID_LEVEL_FULL,
    x_return_status         OUT NOCOPY VARCHAR2,
    x_msg_count             OUT NOCOPY NUMBER,
    x_msg_data              OUT NOCOPY VARCHAR2,
    p_flt_sch_search_rec    IN         FLEET_SCH_SEARCH_REC,
    x_sch_graph_results_tbl OUT NOCOPY SCH_GRAPH_RESULTS_TBL );

  -- Procedure name              : GET_VISITS_FOR_DATE
  -- Type                        : Public
  -- Parameters                  :
  --
  -- Standard IN  Parameters :
  --      p_api_version               NUMBER   Required
  --      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
  --      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
  --
  -- Standard OUT Parameters :
  --      x_return_status             VARCHAR2 Required
  --      x_msg_count                 NUMBER   Required
  --      x_msg_data                  VARCHAR2 Required
  -- GET_VISITS_FOR_DATE params
  --      p_flt_sch_search_rec        FLEET_SCH_SEARCH_REC  Required
  --      x_sch_graph_rec             SCH_GRAPH_RESULTS_REC
  --      x_sch_visits_tbl            SCH_VISITS_TBL

PROCEDURE GET_VISITS_FOR_DATE_FLT(
    p_api_version        IN         NUMBER   := 1.0,
    p_init_msg_list      IN         VARCHAR2 := FND_API.G_TRUE,
    p_validation_level   IN         NUMBER   := FND_API.G_VALID_LEVEL_FULL,
    x_return_status      OUT NOCOPY VARCHAR2,
    x_msg_count          OUT NOCOPY NUMBER,
    x_msg_data           OUT NOCOPY VARCHAR2,
    p_flt_sch_search_rec IN         FLEET_SCH_SEARCH_REC,
    x_sch_graph_rec      OUT NOCOPY SCH_GRAPH_RESULTS_REC,
    x_sch_visits_tbl     OUT NOCOPY SCH_VISITS_TBL );

  -- Procedure name              : GET_MC_GRAPH_DATA
  -- Type                        : Public
  -- Pre-reqs                    :
  -- Function                    :
  -- Parameters                  :
  --
  -- Standard IN  Parameters :
  --      p_api_version               NUMBER   Required
  --      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
  --      p_commit                    VARCHAR2 Default  FND_API.G_FALSE
  --      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
  --      p_default                   VARCHAR2 Default  FND_API.G_TRUE
  --      p_module_type               VARCHAR2 Default  NULL
  --
  -- Standard OUT Parameters :
  --      x_return_status             VARCHAR2 Required
  --      x_msg_count                 NUMBER   Required
  --      x_msg_data                  VARCHAR2 Required
  -- GET_MC_GRAPH_DATA params
  --   p_organization_id    - organization id
  --   p_department_id      - department id
  --   p_start_date         - start date from which the data for graph has to be calculated
  --   p_no_of_days         - for how many number of days  - the data has to be calculated
  --   p_x_resource_input - list of resource ids for which - the data has to be calculated
  --   p_x_resource_output  - calculated data for drawing graph
  --   x_plan_date   - the date when ASCP program ran last

PROCEDURE GET_MC_GRAPH_DATA(
    p_api_version      IN NUMBER := 1.0,
    p_init_msg_list    IN VARCHAR2 := FND_API.G_TRUE,
    p_commit           IN VARCHAR2 := FND_API.G_FALSE,
    p_validation_level IN NUMBER := FND_API.G_VALID_LEVEL_FULL,
    p_default          IN VARCHAR2 := FND_API.G_FALSE,
    p_module_type      IN VARCHAR2 := NULL,
    x_return_status OUT NOCOPY VARCHAR2,
    x_msg_count OUT NOCOPY     NUMBER,
    x_msg_data OUT NOCOPY      VARCHAR2,
    p_organization_id   IN NUMBER,
    p_department_id     IN NUMBER,
    p_start_date        IN DATE , -- Sthilak removed the defaulting ER1#3799535
    p_no_of_days        IN NUMBER,
	p_max_range         IN NUMBER, --Sthilak added to make the max range as parameterized
    p_x_resource_input  IN OUT NOCOPY resource_input_tbl_type,
    p_x_resource_output IN OUT NOCOPY resource_output_tbl_type,
    x_plan_date OUT NOCOPY DATE);
/*-------------------------------STHILAK ER1#3799535 STARTS------------------------*/

-- Function name              : GET_NUMBER_OF_WORKING_DAYS
-- TO calculate the number of working days in given interval
FUNCTION GET_NUMBER_OF_WORKING_DAYS(
	p_org_id NUMBER ,
	p_dept_id NUMBER,
	p_start_dt DATE ,
	p_end_dt DATE)
RETURN NUMBER;

-- Function name              : GET_NEXT_WORKING_DATE
-- TO calculate the nth working day from the given date
FUNCTION GET_NEXT_WORKING_DATE(
	p_org_id NUMBER ,
	p_dept_id NUMBER,
	p_start_dt DATE ,
	p_no_of_days NUMBER)
RETURN DATE;

-- Function name              : GET_NEW_REQ_END_DATE
-- TO calculate the new requirement end date based on params
	--    p_org_id NUMBER ,
	--	p_start_dt DATE,
	--	p_end_date DATE,
	--	p_usage_units NUMBER,
	--	p_applied_units NUMBER
FUNCTION GET_NEW_REQ_END_DATE(
	p_org_id NUMBER ,
	p_dept_id NUMBER,
	p_start_dt DATE,
	p_end_date DATE,
	p_usage_units NUMBER,
	p_applied_units NUMBER)
RETURN DATE;





-- Function name              : GET_DAY_REQUIREMENT
-- TO calculate the requirement units on a date based on params
	-- p_usage_units NUMBER,
	-- 	p_applied_units NUMBER,
	-- 	p_org_id NUMBER,
	-- 	p_start_date DATE ,
	-- 	p_end_date DATE,
	-- 	p_cal_date DATE
FUNCTION GET_DAY_REQUIREMENT(
	p_usage_units NUMBER,
	p_applied_units NUMBER,
	p_org_id NUMBER,
	p_dept_id NUMBER,
	p_start_date DATE ,
	p_end_date DATE,
	p_cal_date DATE)
RETURN NUMBER;

/*-------------------------------STHILAK ER1#3799535 ENDS------------------------*/

  -- Function name              : GET_FLEET_NAME
  -- Type                       : Public
  -- Parameters                 :
  -- GET_FLEET_NAME params
  --      p_item_instance_id    NUMBER  Required
  --      p_visit_start_date    DATE    Required
  --      p_visit_end_date      DATE    Required

FUNCTION GET_FLEET_NAME(
    p_item_instance_id IN NUMBER,
    p_visit_start_date IN DATE,
    p_visit_end_date   IN DATE)
RETURN VARCHAR2;

  -- Function name              : GET_FLEET_HEADER_ID
  -- Type                       : Public
  -- Parameters                 :
  -- GET_FLEET_NAME params
  --      p_item_instance_id    NUMBER  Required
  --      p_visit_start_date    DATE    Required
  --      p_visit_end_date      DATE    Required

FUNCTION GET_FLEET_HEADER_ID(
    p_item_instance_id IN NUMBER,
    p_visit_start_date IN DATE,
    P_VISIT_END_DATE   IN DATE)
RETURN NUMBER;

END AHL_AMP_WORKBENCH_PVT;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_AMP_WORKBENCH_PVT" AS
  /* $Header: AHLVAMPB.pls 120.0.12020000.2 2012/12/10 16:59:08 prakkum noship $ */

-----------------------------------------------------------------
--   Define Global CONSTANTS                                   --
-----------------------------------------------------------------
G_APP_NAME        CONSTANT VARCHAR2(3)  := 'AHL';
G_PKG_NAME        CONSTANT VARCHAR2(30) := 'AHL_AMP_WORKBENCH_PVT';
G_DEBUG                    VARCHAR2(1)  := NVL(AHL_DEBUG_PUB.is_log_enabled,'N');
------------------------------------
-- Common constants and variables --
------------------------------------
l_log_current_level   NUMBER   := fnd_log.g_current_runtime_level;
l_log_statement       NUMBER   := fnd_log.level_statement;
l_log_procedure       NUMBER   := fnd_log.level_procedure;
l_log_error           NUMBER   := fnd_log.level_error;
l_log_unexpected      NUMBER   := fnd_log.level_unexpected;

-- constants for WHO Columns
-- Added by Prithwi as a part of Public API cleanup

G_LAST_UPDATE_DATE   DATE          := SYSDATE;
G_LAST_UPDATED_BY   NUMBER(15)    := FND_GLOBAL.user_id;
G_LAST_UPDATE_LOGIN   NUMBER(15)  := FND_GLOBAL.login_id;
G_CREATION_DATE   DATE            := SYSDATE;
G_CREATED_BY    NUMBER(15)        := FND_GLOBAL.user_id;

G_SPACE_TYPE VARCHAR2(5) := 'SPACE';
G_DEPT_TYPE  VARCHAR2(4) := 'DEPT';
G_FILTER_ALL CONSTANT VARCHAR2(3) := 'ALL';


PROCEDURE GET_GRAPH_REC_FOR_DATE(
p_graph_rec_date        IN               DATE,
p_graph_rec_num         IN               NUMBER,
p_visit_count           IN               NUMBER,
p_not_for_sch           IN               VARCHAR2 := Fnd_Api.g_false,
p_filter_criteria       IN               VARCHAR2 := 'ALL',
p_rec_type              IN               VARCHAR2 := G_SPACE_TYPE,
p_sch_visits_tbl        IN               SCH_VISITS_TBL,
p_x_sch_graph_rec       IN OUT  NOCOPY   SCH_GRAPH_RESULTS_REC
);

/*------------- STHILAK ER # 13799535 STARTS----------------------- */

-- Function name              : GET_NUMBER_OF_WORKING_DAYS
-- TO calculate the number of working days in given interval
-- Sthilak bug #13958744 department_id is added in claculating working days
FUNCTION GET_NUMBER_OF_WORKING_DAYS(p_org_id NUMBER ,p_dept_id NUMBER,p_start_dt DATE , p_end_dt DATE)
RETURN NUMBER
IS
  l_number_of_days NUMBER;
   -- cursor to get the working days in the interval
  CURSOR c_number_of_working_days (c_org_id NUMBER,c_dept_id NUMBER,c_start_date DATE , c_end_date DATE)
  IS
 -- STHILAK CHANGES THE CURSOR DEFNITION
 select count(distinct drc.AVAILABLE_DATE) no_of_working_date from AHL_DEPT_RESOURCE_CAPACITY drc where drc.available_date between TRUNC(c_start_date) and TRUNC(c_end_date) AND drc.organization_id = c_org_id  AND drc.department_id = c_dept_id AND
  drc.ASCP_PLAN_DATE  = (SELECT MAX(ASCP_PLAN_DATE) FROM AHL_DEPT_RESOURCE_CAPACITY ) order by drc.available_date;
  BEGIN

   OPEN   c_number_of_working_days(p_org_id,p_dept_id,p_start_dt,p_end_dt);

   FETCH c_number_of_working_days into l_number_of_days;
   IF c_number_of_working_days%NOTFOUND THEN
      l_number_of_days :=0;
   END IF;

   CLOSE c_number_of_working_days;

  RETURN l_number_of_days;
END ;
 /*---------------------------------------------------------*/

-- NOT USED Function name              : GET_NEXT_WORKING_DATE
-- TO calculate the nth working day from the given date
-- Sthilak bug #13958744 department_id is added in claculating working days
FUNCTION GET_NEXT_WORKING_DATE(p_org_id NUMBER ,p_dept_id NUMBER,p_start_dt DATE , p_no_of_days NUMBER)
RETURN DATE
IS
l_date   DATE;
l_index NUMBER;

CURSOR c_next_working_day(c_org_id NUMBER,c_start_date DATE )
IS
	SELECT  DISTINCT cal.calendar_date working_date
    FROM mtl_parameters param,
      bom_calendar_dates cal,
      bom_shift_times shifts
    WHERE param.organization_id = c_org_id
    AND TRUNC(cal.calendar_date) >= TRUNC(c_start_date)
    AND cal.calendar_code    = param.calendar_code
    AND cal.exception_set_id = param.calendar_exception_set_id
    AND param.calendar_code  = shifts.calendar_code
      --AND TRUNC(cal.calendar_date) >= TRUNC(sysdate)
    AND ((cal.seq_num IS NOT NULL
    AND NOT EXISTS
      (SELECT 1
      FROM CRP_CAL_SHIFT_DELTA delta1
      WHERE delta1.calendar_code  = shifts.calendar_code
      AND delta1.exception_set_id = param.calendar_exception_set_id
      AND delta1.delta_code       = 1
      AND delta1.calendar_date    = cal.calendar_date
      AND delta1.shift_num        = shifts.shift_num
      ))
    OR (cal.seq_num IS NULL
    AND EXISTS
      (SELECT 1
      FROM CRP_CAL_SHIFT_DELTA delta1
      WHERE delta1.calendar_code  = shifts.calendar_code
      AND delta1.exception_set_id = param.calendar_exception_set_id
      AND delta1.delta_code       = 2
      AND delta1.calendar_date    = cal.calendar_date
      AND delta1.shift_num        = shifts.shift_num
      ))) order by cal.calendar_date;
BEGIN

   IF p_no_of_days < 0 THEN
	RETURN p_start_dt;
   END IF;

   l_index := p_no_of_days;

   FOR loop_date IN c_next_working_day(p_org_id,p_start_dt)
   LOOP
    l_date := loop_date.working_date;
	l_index := l_index -1;

	EXIT WHEN l_index = 0;
   END LOOP;

   IF l_index > 0 THEN /* exit by finishing the loop bu without finding the needed date */
	l_date := NULL;
   END IF;

  RETURN  l_date;
END;
 /*---------------------------------------------------------*/

  -- NOT USED Function name              : GET_NEW_REQ_END_DATE
-- TO calculate the new requirement end date based on params
	--    p_org_id NUMBER ,
	--	p_start_dt DATE,
	--	p_end_date DATE,
	--	p_usage_units NUMBER,
	--	p_applied_units NUMBER
 -- Sthilak bug #13958744 department_id is added in claculating working days
  FUNCTION GET_NEW_REQ_END_DATE(p_org_id NUMBER ,p_dept_id NUMBER,p_start_dt DATE,p_end_date DATE,p_usage_units NUMBER,p_applied_units NUMBER)
  RETURN DATE
  IS
  l_remaining_units 	NUMBER ;
  l_per_day_average 	NUMBER;
  l_more_days_needed	NUMBER;
  l_left_over_units		NUMBER;
  l_number_of_days      NUMBER;
  l_new_req_end_date 	DATE;

  BEGIN
    l_remaining_units := GREATEST(p_usage_units,p_applied_units) - p_applied_units;

	l_number_of_days := AHL_AMP_WORKBENCH_PVT.GET_NUMBER_OF_WORKING_DAYS(p_org_id,p_dept_id,p_start_dt,p_end_date);

	IF l_number_of_days =0 THEN
	 RETURN NULL;
	END IF;

	l_per_day_average := ROUND(p_usage_units /l_number_of_days,1);

	IF l_per_day_average = 0  THEN
		l_more_days_needed :=0;
		l_left_over_units :=0;
	ELSE
		l_more_days_needed := TRUNC( l_remaining_units / l_per_day_average);

		l_left_over_units := MOD(l_remaining_units,l_per_day_average);
	END IF;

	IF (l_left_over_units > 0) THEN
		l_more_days_needed := l_more_days_needed +1;
	END IF;

	IF p_start_dt <= sysdate THEN
		l_new_req_end_date := AHL_AMP_WORKBENCH_PVT.GET_NEXT_WORKING_DATE(p_org_id,p_dept_id,sysdate,l_more_days_needed);
	ELSE
	    l_new_req_end_date := AHL_AMP_WORKBENCH_PVT.GET_NEXT_WORKING_DATE(p_org_id,p_dept_id,p_start_dt,l_more_days_needed);
	END IF;

	  RETURN l_new_req_end_date;
  END;

  /*---------------------------------------------------------*/


-- Function name              : GET_DAY_REQUIREMENT
-- TO calculate the requirement units on a date based on params
	-- p_usage_units NUMBER,
	-- 	p_applied_units NUMBER,
	-- 	p_org_id NUMBER,
	-- 	p_start_date DATE ,
	-- 	p_end_date DATE,
	-- 	p_cal_date DATE

-- STHILAK UPDATED THE FUNCTION
-- Sthilak bug #13958744 department_id is added in claculating working days
FUNCTION GET_DAY_REQUIREMENT(p_usage_units NUMBER,p_applied_units NUMBER,p_org_id NUMBER,p_dept_id NUMBER,p_start_date DATE , p_end_date DATE,p_cal_date DATE)
RETURN NUMBER
IS
l_req_on_cal_date 	NUMBER;
l_rem_number_of_days 	NUMBER;
l_per_day_req 		NUMBER;
l_remaining_units 	NUMBER;
l_left_over_units 	NUMBER;
l_consumed_units 	NUMBER;
l_start_dt			DATE;

 BEGIN
  	-- calcualte the remaining units
	l_remaining_units := GREATEST(p_usage_units,p_applied_units) - p_applied_units;

	-- calcualte the remainig working days
	IF p_start_date <= sysdate THEN
	   l_start_dt := sysdate;
	 ELSE
       l_start_dt := p_start_date;
	END IF ;
	l_rem_number_of_days := AHL_AMP_WORKBENCH_PVT.GET_NUMBER_OF_WORKING_DAYS(p_org_id,p_dept_id,l_start_dt,p_end_date);

	-- Calcualte he capacity
	IF l_rem_number_of_days = 0 THEN /* if no working day found i.e during holiday then the resource capacity is 0*/
		l_req_on_cal_date:= 0;
	ELSE
		l_req_on_cal_date :=  ROUND((l_remaining_units/ l_rem_number_of_days),2);
	END IF;

  RETURN l_req_on_cal_date;
END;

 /*---------------------------------------------------------*/
-- Procedure name              : GET_MC_GRAPH_DATA
-- Type                        : Public
-- Pre-reqs                    :
-- Function                    :
-- Parameters                  :
--
-- Standard IN  Parameters :
--      p_api_version               NUMBER   Required
--      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
--      p_commit                    VARCHAR2 Default  FND_API.G_FALSE
--      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
--      p_default                   VARCHAR2 Default  FND_API.G_TRUE
--      p_module_type               VARCHAR2 Default  NULL
--
-- Standard OUT Parameters :
--      x_return_status             VARCHAR2 Required
--      x_msg_count                 NUMBER   Required
--      x_msg_data                  VARCHAR2 Required

-- GET_MC_GRAPH_DATA params
-- 		p_organization_id    - organization id
-- 		p_department_id      - department id
-- 		p_start_date         - start date from which the data for graph has to be calculated
-- 		p_no_of_days         - for how many number of days  - the data has to be calculated
-- 		p_x_resource_input	- list of resource ids for which - the data has to be calculated
-- 		p_x_resource_output  - calculated data for drawing graph
-- 		x_plan_date			- the date when ASCP program ran last

-- Sthilak CHANGED THE PROCEDURE LOGIC  ER1#3799535
-- Sthilak bug #13958744 department_id is added in claculating working days
procedure GET_MC_GRAPH_DATA(
 p_api_version           IN            NUMBER     := 1.0,
 p_init_msg_list         IN            VARCHAR2   := FND_API.G_TRUE,
 p_commit                IN            VARCHAR2   := FND_API.G_FALSE,
 p_validation_level      IN            NUMBER     := FND_API.G_VALID_LEVEL_FULL,
 p_default               IN            VARCHAR2   := FND_API.G_FALSE,
 p_module_type           IN            VARCHAR2   := NULL,
 x_return_status         OUT NOCOPY    VARCHAR2,
 x_msg_count             OUT NOCOPY    NUMBER,
 x_msg_data              OUT NOCOPY    VARCHAR2,
 p_organization_id       IN            NUMBER,
 p_department_id         IN            NUMBER,
 p_start_date            IN 		   DATE  ,
 p_no_of_days            IN            NUMBER,
 p_max_range             IN NUMBER, --Sthilak added to make the max range as parameterized
 p_x_resource_input      IN OUT NOCOPY resource_input_tbl_type,
 p_x_resource_output     IN OUT NOCOPY resource_output_tbl_type,
 x_plan_date             OUT NOCOPY    DATE)

 IS

 -- local variables
  l_output_record_counter NUMBER;
  l_requirement           NUMBER;
  l_transacted            NUMBER;
  l_capacity              NUMBER;
  l_availability          NUMBER;
  l_req_uom               VARCHAR2(3);
  l_avail_uom             VARCHAR2(3);
  l_curr_date DATE;
  l_start_date Date;

   -- cursor to get the working days in the interval
  CURSOR c_working_dates(c_org_id NUMBER,c_dept_id NUMBER,c_start_date DATE , c_no_of_days NUMBER)
  IS
	  select cal_date from
	  (select distinct drc.AVAILABLE_DATE cal_date from AHL_DEPT_RESOURCE_CAPACITY drc where drc.available_date >=TRUNC(c_start_date)
	  AND drc.organization_id = c_org_id AND drc.department_id = c_dept_id AND drc.ASCP_PLAN_DATE    = (SELECT MAX(ASCP_PLAN_DATE) FROM AHL_DEPT_RESOURCE_CAPACITY )  order by drc.available_date)
	  where  ROWNUM < (c_no_of_days+1) ; /* Rule is :Rownum is executed first then follwed by order by , thats why made a sub query and put row num on top of that*/



  --cursor 1 Resource_requirement
   CURSOR c_resource_req(c_oranization_id NUMBER,c_department_id NUMBER, c_on_date DATE, c_resource_id NUMBER)
  IS
     SELECT SUM (AHL_AMP_WORKBENCH_PVT.GET_DAY_REQUIREMENT(NVL(wor.usage_rate_or_amount,0),
	                   NVL(wor.APPLIED_RESOURCE_UNITS,0),wor.organization_id,c_department_id,wor.start_date,wor.completion_date,c_on_date)) req_amt, wor.uom_code
    FROM wip_operation_resources wor,
      wip_discrete_jobs wdj,
      wip_entities wip
    WHERE wor.organization_id                                                 = c_oranization_id
    AND wor.department_id                                                     = c_department_id
    AND wor.resource_id                                                       = c_resource_id
    AND c_on_date   BETWEEN TRUNC(wor.start_date) AND TRUNC(wor.completion_date)
    AND wor.wip_entity_id                                                     = wdj.wip_entity_id
    AND wdj.status_type                                                      IN (17,3,1,6) /* included are Draft(17), Released (3), Unreleased(1) and On Hold (6).*/
    AND wor.wip_entity_id                                                     =wip.wip_entity_id
    AND wip.entity_type                                                      IN (1,2,4,5,6)
  GROUP BY wor.uom_code;

  -- cursor 2 resource availability - in hours
  CURSOR c_resource_avail(c_oranization_id NUMBER,c_department_id NUMBER,c_resource_id NUMBER,c_avail_dt DATE)
  IS
    SELECT DECODE(UOM_CODE,'DAY',CAPACITY_UNITS * 24,CAPACITY_UNITS) CAPACITY_UNITS ,
      UOM_CODE
    FROM AHL_DEPT_RESOURCE_CAPACITY drc
    WHERE drc.ORGANIZATION_ID = c_oranization_id
    AND drc.DEPARTMENT_ID     =c_department_id
    AND drc.RESOURCE_ID       =c_resource_id
    AND drc.AVAILABLE_DATE    =TRUNC(c_avail_dt)
    AND drc.ASCP_PLAN_DATE    =
      (SELECT MAX(ASCP_PLAN_DATE) FROM AHL_DEPT_RESOURCE_CAPACITY
      );

  BEGIN
    -- Enable Debug (optional)
    IF ( G_DEBUG = 'Y' ) THEN
      AHL_DEBUG_PUB.enable_debug;
    END IF;

    -- ASCP last ran date
    -- STHILAK ER #13799535 x_plan_date := TRUNC(sysdate);
    SELECT MAX(ASCP_PLAN_DATE)
    INTO x_plan_date
    FROM AHL_DEPT_RESOURCE_CAPACITY;
    IF G_DEBUG = 'Y' THEN
      AHL_DEBUG_PUB.debug( 'AHL_AMP_WORKBENCH_PVT' || '.' || 'GET_MC_GRAPH_DATA' || ' : ASCP plan date = '|| x_plan_date );
    END IF;

    -- set the start date
	l_start_date     := TRUNC(p_start_date);
    IF (l_start_date IS NULL OR l_start_date < sysdate) THEN
      l_start_date   := sysdate;
    END IF;

    l_output_record_counter :=-1;
    FOR cur_date             IN c_working_dates(p_organization_id,p_department_id,l_start_date,p_no_of_days)
    LOOP
		IF l_output_record_counter >= ( p_no_of_days -1 ) THEN
			  IF G_DEBUG  = 'Y' THEN
				  AHL_DEBUG_PUB.debug( 'AHL_AMP_WORKBENCH_PVT' || '.' || 'GET_MC_GRAPH_DATA' || ' : EXITING after reached NO. of records = '|| l_output_record_counter );
			  END IF;
			EXIT; -- number fo records reached . SO exit from main loop. actually this condition is not needed. but added to handle cornercases
		  END IF;

      l_output_record_counter                              := l_output_record_counter+1;
      l_curr_date                                          := cur_date.cal_date;
	  IF G_DEBUG  = 'Y' THEN
			  AHL_DEBUG_PUB.debug( 'AHL_AMP_WORKBENCH_PVT' || '.' || 'GET_MC_GRAPH_DATA' || ' :  reached NO. of records = '|| l_output_record_counter );
			   AHL_DEBUG_PUB.debug( 'AHL_AMP_WORKBENCH_PVT' || '.' || 'GET_MC_GRAPH_DATA' || ' : DATE  = '|| l_curr_date );
	  END IF;

	  -- set the date
      p_x_resource_output(l_output_record_counter).on_date := l_curr_date;
	  -- set the 100 % bar line capacity
	  p_x_resource_output(l_output_record_counter).cent_percent_capacity := 100;

      FOR l_index                                          IN p_x_resource_input.FIRST .. p_x_resource_input.LAST
      LOOP


        -- get the resource requirement
        OPEN c_resource_req(p_organization_id,p_department_id,l_curr_date,p_x_resource_input(l_index).resource_id);
        FETCH c_resource_req INTO l_requirement,l_req_uom;
        IF c_resource_req%NOTFOUND THEN
          l_requirement:=0;
        END IF;

        IF G_DEBUG = 'Y' THEN
          AHL_DEBUG_PUB.debug( 'AHL_AMP_WORKBENCH_PVT' || '.' || 'GET_MC_GRAPH_DATA' || ' : REq = '|| ' res id = ' || p_x_resource_input(l_index).resource_id || ' Date= ' || l_curr_date || '  req units = ' ||l_requirement);
        END IF;

		-- get the resource avail
        OPEN c_resource_avail(p_organization_id,p_department_id,p_x_resource_input(l_index).resource_id,l_curr_date);
        FETCH c_resource_avail INTO l_availability,l_avail_uom;
        IF c_resource_avail%NOTFOUND THEN
          l_availability :=0;
        END IF;

        IF G_DEBUG = 'Y' THEN
          AHL_DEBUG_PUB.debug( 'AHL_AMP_WORKBENCH_PVT' || '.' || 'GET_MC_GRAPH_DATA' || ' : AVAIL= '|| ' res id = ' || p_x_resource_input(l_index).resource_id || ' Date= ' || l_curr_date || '  avail units = ' ||l_availability);
        END IF;

       	-- clacualte capacity
		IF l_availability = 0 AND l_requirement = 0 THEN
			l_capacity := 0;
		ELSIF l_availability = 0 AND l_requirement <> 0 THEN
			l_capacity := p_max_range;
		ELSE
		    l_capacity := ROUND((l_requirement/l_availability) * 100,2); /* l_requirement should not come as zero */
		END IF;

		-- Restricting to MAX LIMIT
		IF l_capacity >p_max_range THEN
			l_capacity:= p_max_range;
		END IF;

        IF G_DEBUG  = 'Y' THEN
          AHL_DEBUG_PUB.debug( 'AHL_AMP_WORKBENCH_PVT' || '.' || 'GET_MC_GRAPH_DATA' || ' : BEfore case index = '|| l_index );
          AHL_DEBUG_PUB.debug( 'AHL_AMP_WORKBENCH_PVT' || '.' || 'GET_MC_GRAPH_DATA' || ' : BEfore case resource Id  = '|| p_x_resource_input(l_index).resource_id );
        END IF;
        CASE (l_index )
        WHEN 1 THEN
          p_x_resource_output(l_output_record_counter).r1_capacity := l_capacity;
        WHEN 2 THEN
          p_x_resource_output(l_output_record_counter).r2_capacity := l_capacity;
        WHEN 3 THEN
          p_x_resource_output(l_output_record_counter).r3_capacity := l_capacity;
        WHEN 4 THEN
          p_x_resource_output(l_output_record_counter).r4_capacity := l_capacity;
        WHEN 5 THEN
          p_x_resource_output(l_output_record_counter).r5_capacity := l_capacity;
        END CASE;
        CLOSE c_resource_req;
        CLOSE c_resource_avail;
      END LOOP;
    END LOOP;

    IF (l_output_record_counter = -1 ) THEN -- STHILAK bug #13889247  handled NO GRPAH DATA i.e NO WORKING DAYS FOUND
      x_plan_date := null;
    END IF;
  END GET_MC_GRAPH_DATA;




  -- Procedure name              : GET_ORG_SCH_GRAPH
  -- Type                        : Public
  -- Parameters                  :
  --
  -- Standard IN  Parameters :
  --      p_api_version               NUMBER   Required
  --      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
  --      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
  --
  -- Standard OUT Parameters :
  --      x_return_status             VARCHAR2 Required
  --      x_msg_count                 NUMBER   Required
  --      x_msg_data                  VARCHAR2 Required
  -- GET_ORG_SCH_GRAPH params
  --      p_org_sch_search_rec        ORG_SCH_SEARCH_REC    Required
  --      x_sch_graph_results_tbl     SCH_GRAPH_RESULTS_TBL

PROCEDURE GET_ORG_SCH_GRAPH(
p_api_version           IN            NUMBER     := 1.0,
p_init_msg_list         IN            VARCHAR2   := FND_API.G_TRUE,
p_validation_level      IN            NUMBER     := FND_API.G_VALID_LEVEL_FULL,
x_return_status         OUT NOCOPY    VARCHAR2,
x_msg_count             OUT NOCOPY    NUMBER,
x_msg_data              OUT NOCOPY    VARCHAR2,
p_org_sch_search_rec    IN            org_sch_search_rec,
x_sch_graph_results_tbl OUT NOCOPY    sch_graph_results_tbl
) IS

-- LOCAL VARIABLE
l_api_name         CONSTANT VARCHAR2(30)  := 'get_org_sch_graph';
l_debug_key        CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || l_api_name;
l_api_version      CONSTANT NUMBER        := 1.0;
l_msg_count                 NUMBER;
l_return_status             VARCHAR2(1);
l_msg_data                  VARCHAR2(2000);
l_loop_window               NUMBER;
l_loop_start_date           DATE;
l_row_inc                   NUMBER := 0;
l_org_sch_search_rec        org_sch_search_rec;
l_sch_graph_rec             SCH_GRAPH_RESULTS_REC;
l_sch_graph_tbl             sch_graph_results_tbl;
l_sch_visits_tbl            sch_visits_tbl;
l_filter_criteria           VARCHAR2(15)  := G_FILTER_ALL;
l_filter_scheduled CONSTANT VARCHAR2(15) := 'SCHEDULED_DAYS';

-- Cursor
CURSOR c_space_dept_for_org (c_org_id IN NUMBER, c_dept_name IN VARCHAR2, c_space_name IN VARCHAR2)
IS
  SELECT SPACE_ID,
    SPACE_NAME,
    DEPARTMENT_ID,
    DEPT_DESCRIPTION,
    ORGANIZATION_ID
  FROM
    (SELECT ASPL.SPACE_ID,
      ASPL.SPACE_NAME,
      ASPL.BOM_DEPARTMENT_ID DEPARTMENT_ID,
      ASPL.ORGANIZATION_ID,
      BDPT.DESCRIPTION DEPT_DESCRIPTION
    FROM AHL_SPACES_VL ASPL,
      BOM_DEPARTMENTS BDPT
    WHERE ASPL.BOM_DEPARTMENT_ID = BDPT.DEPARTMENT_ID
    AND ASPL.ORGANIZATION_ID     = c_org_id
    AND ASPL.INACTIVE_FLAG LIKE 'Y'

    UNION

    SELECT NULL SPACE_ID,
      NULL SPACE_NAME,
      BOM.DEPARTMENT_ID,
      ORG.ORGANIZATION_ID,
      BOM.DESCRIPTION DEPT_DESCRIPTION
    FROM BOM_DEPARTMENTS BOM,
      INV_ORGANIZATION_INFO_V ORG,
      MTL_PARAMETERS MP
    WHERE BOM.ORGANIZATION_ID = ORG.ORGANIZATION_ID
    AND MP.ORGANIZATION_ID    = BOM.ORGANIZATION_ID
    AND MP.EAM_ENABLED_FLAG   = 'Y'
    AND ORG.ORGANIZATION_ID     = c_org_id
    )QRSLT
  WHERE UPPER(DEPT_DESCRIPTION) LIKE UPPER(NVL(c_dept_name, DEPT_DESCRIPTION))
  AND UPPER(NVL(SPACE_NAME,'X')) LIKE UPPER(NVL(c_space_name, NVL(SPACE_NAME,'X')))
  ORDER BY DEPT_DESCRIPTION,
    SPACE_NAME;

space_dept_for_org_rec c_space_dept_for_org%ROWTYPE;




BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT GET_ORG_SCH_GRAPH;

  IF (l_log_procedure >= l_log_current_level) THEN
     fnd_log.string(l_log_procedure,
                    l_debug_key ||'.begin',
                    ' At the start of PL SQL function. '||
                    ' Org Id = '           || p_org_sch_search_rec.ORG_ID ||
                    ' Dept Name = '        || p_org_sch_search_rec.DEPARTMENT_NAME||
                    ' Space Name = '       || p_org_sch_search_rec.SPACE_NAME||
                    ' Start from Date = '  || p_org_sch_search_rec.START_FROM_DATE||
                    ' Start before Date = '|| p_org_sch_search_rec.START_BEFORE_DATE||
                    ' Display Window = '   || p_org_sch_search_rec.DISPLAY_WINDOW||
                    ' Filter Criteria = '  || p_org_sch_search_rec.RESULT_FILTER);
  END IF;

   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
   --  Initialize API return status to success
   x_return_status := FND_API.G_RET_STS_SUCCESS;

   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       Fnd_Msg_Pub.ADD;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;
   --

   IF(p_org_sch_search_rec.ORG_ID IS NULL) OR
      (p_org_sch_search_rec.DISPLAY_WINDOW IS NULL) THEN
    IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,
                       L_DEBUG_KEY,
                       'Passed Mandatory fields Org id or Display window is null');
    END IF;
    Fnd_Message.set_name(G_APP_NAME, 'AHL_AMP_ORG_MANDATORY');
    FND_MSG_PUB.ADD;
    RAISE Fnd_Api.G_EXC_ERROR;

   ELSIF(p_org_sch_search_rec.START_FROM_DATE IS NULL) AND
         (p_org_sch_search_rec.START_BEFORE_DATE IS NULL) THEN

          Fnd_Message.set_name(G_APP_NAME, 'AHL_AMP_DATE_MANDATORY');
          Fnd_Msg_Pub.ADD;
          RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   IF (p_org_sch_search_rec.RESULT_FILTER IS NOT NULL) THEN
      l_filter_criteria := p_org_sch_search_rec.RESULT_FILTER;
   END IF;

   l_loop_window := p_org_sch_search_rec.DISPLAY_WINDOW;

   IF((p_org_sch_search_rec.START_FROM_DATE IS NOT NULL) AND
      (p_org_sch_search_rec.START_BEFORE_DATE IS NOT NULL)) OR
     (p_org_sch_search_rec.START_BEFORE_DATE IS NULL)
     THEN
      l_loop_start_date := p_org_sch_search_rec.START_FROM_DATE;
   ELSIF(p_org_sch_search_rec.START_FROM_DATE IS NULL)  THEN
      l_loop_start_date := p_org_sch_search_rec.START_BEFORE_DATE - l_loop_window + 1;
   END IF;

   IF (l_log_procedure >= l_log_current_level) THEN
     fnd_log.string(l_log_procedure,
                    l_debug_key ||'.middle',
                    ' Before looping through rows. '||
                    ' Loop Start date = '               || l_loop_start_date||
                    ' Filter Criteria'                  ||l_filter_criteria);
   END IF;

   OPEN c_space_dept_for_org(p_org_sch_search_rec.ORG_ID
   , p_org_sch_search_rec.DEPARTMENT_NAME
   , p_org_sch_search_rec.space_name);

   LOOP
   FETCH c_space_dept_for_org INTO space_dept_for_org_rec;
   EXIT WHEN c_space_dept_for_org%NOTFOUND;
    -- call GET_VISITS_FOR_DATE_ORG
    -- prepare in params...
    l_org_sch_search_rec := NULL;
    l_org_sch_search_rec.ORG_ID := p_org_sch_search_rec.ORG_ID;
    l_org_sch_search_rec.DEPARTMENT_ID := space_dept_for_org_rec.DEPARTMENT_ID;
    l_org_sch_search_rec.SPACE_ID := space_dept_for_org_rec.SPACE_ID;
    l_org_sch_search_rec.START_FROM_DATE := l_loop_start_date;
    l_org_sch_search_rec.DISPLAY_WINDOW := l_loop_window;
    l_org_sch_search_rec.RESULT_FILTER  := l_filter_criteria;

    GET_VISITS_FOR_DATE_ORG(
       p_api_version           => p_api_version,
       p_init_msg_list         => FND_API.G_FALSE,
       p_validation_level      => p_validation_level,
       x_return_status         => l_return_status,
       x_msg_count             => l_msg_count,
       x_msg_data              => l_msg_data,
       p_org_sch_search_rec    => l_org_sch_search_rec,
       x_sch_graph_rec         => l_sch_graph_rec,
       x_sch_visits_tbl        => l_sch_visits_tbl);
    -- end of call GET_VISITS_FOR_DATE_ORG

    l_sch_graph_rec.ORG_ID          := p_org_sch_search_rec.ORG_ID;
    l_sch_graph_rec.DEPARTMENT_ID   := space_dept_for_org_rec.DEPARTMENT_ID;
    l_sch_graph_rec.DEPARTMENT_DESC := space_dept_for_org_rec.DEPT_DESCRIPTION;
    l_sch_graph_rec.SPACE_ID        := space_dept_for_org_rec.SPACE_ID;
    L_SCH_GRAPH_REC.SPACE_NAME      := SPACE_DEPT_FOR_ORG_REC.SPACE_NAME;

    --add return rec type to the table
    IF (l_filter_criteria = l_filter_scheduled) AND
       NOT (l_sch_graph_rec.FILTER_REC) THEN
       x_sch_graph_results_tbl(l_row_inc) := l_sch_graph_rec;
       l_row_inc := l_row_inc + 1;
    ELSIF (l_filter_criteria <> l_filter_scheduled) AND
          (l_sch_graph_rec.FILTER_REC) THEN
       x_sch_graph_results_tbl(l_row_inc) := l_sch_graph_rec;
       l_row_inc := l_row_inc + 1;
    END IF;
   END LOOP;
   CLOSE c_space_dept_for_org;

   l_msg_count := Fnd_Msg_Pub.count_msg;
   IF l_msg_count > 0 OR l_return_status <> Fnd_Api.g_ret_sts_success THEN
      IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,
                         L_DEBUG_KEY,
                         'Errors from GET_VISITS_FOR_DATE_ORG. Message count: ' ||
                         l_msg_count || ', Message data: ' || l_msg_data);
      END IF;
      x_msg_count := l_msg_count;
      x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
   END IF;

   x_return_status := Fnd_Api.g_ret_sts_success;
   IF (l_log_procedure >= l_log_current_level) THEN
       fnd_log.string(l_log_procedure,
                      L_DEBUG_KEY || '.end',
                      'Return Status = ' || x_return_status);
   END IF;

EXCEPTION
 WHEN Fnd_Api.G_EXC_ERROR THEN
   x_return_status := Fnd_Api.G_RET_STS_ERROR;
   ROLLBACK TO GET_ORG_SCH_GRAPH;
   Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => Fnd_Api.g_false);
 WHEN Fnd_Api.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO GET_ORG_SCH_GRAPH;
   Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => Fnd_Api.g_false);
 WHEN OTHERS THEN
      ROLLBACK TO GET_ORG_SCH_GRAPH;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
    THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data);

END GET_ORG_SCH_GRAPH;

  -- Procedure name              : GET_VISITS_FOR_DATE_ORG
  -- Type                        : Public
  -- Parameters                  :
  --
  -- Standard IN  Parameters :
  --      p_api_version               NUMBER   Required
  --      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
  --      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
  --
  -- Standard OUT Parameters :
  --      x_return_status             VARCHAR2 Required
  --      x_msg_count                 NUMBER   Required
  --      x_msg_data                  VARCHAR2 Required
  -- GET_VISITS_FOR_DATE_ORG params
  --      p_org_sch_search_rec        ORG_SCH_SEARCH_REC    Required
  --      x_sch_graph_rec             SCH_GRAPH_RESULTS_REC
  --      x_sch_visits_tbl            SCH_VISITS_TBL

PROCEDURE GET_VISITS_FOR_DATE_ORG(
p_api_version           IN            NUMBER     := 1.0,
p_init_msg_list         IN            VARCHAR2   := FND_API.G_TRUE,
p_validation_level      IN            NUMBER     := FND_API.G_VALID_LEVEL_FULL,
x_return_status         OUT NOCOPY    VARCHAR2,
x_msg_count             OUT NOCOPY    NUMBER,
x_msg_data              OUT NOCOPY    VARCHAR2,
p_org_sch_search_rec    IN            org_sch_search_rec,
x_sch_graph_rec         OUT NOCOPY    SCH_GRAPH_RESULTS_REC,
x_sch_visits_tbl        OUT NOCOPY    sch_visits_tbl
) IS

-- LOCAL VARIABLE
l_api_name        CONSTANT VARCHAR2(30)  := 'GET_VISITS_FOR_DATE_ORG';
l_debug_key       CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || l_api_name;
l_api_version     CONSTANT NUMBER        := 1.0;
l_msg_count                NUMBER;
l_return_status            VARCHAR2(1);
l_msg_data                 VARCHAR2(2000);
l_loop_window              NUMBER;
l_loop_start_date          DATE;
l_column_inc               NUMBER := 0;
l_day_inc                  NUMBER := 1;
l_visit_rec                SCH_VISITS_REC;
l_visit_count              NUMBER := 0;
l_org_sch_search_rec       org_sch_search_rec;
l_sch_graph_rec            SCH_GRAPH_RESULTS_REC;
l_sch_visits_tbl           sch_visits_tbl;

-- Cursor
-- inner cursor for ROW wise calculation for space
CURSOR c_visit_for_space_day (c_org_id IN NUMBER, c_dept_id IN NUMBER, c_space_id IN NUMBER, c_loop_date IN DATE)
IS
  SELECT ASA.SPACE_ID,
    AVL.visit_id ,
    NVL2(ASA.START_FROM , ASA.START_FROM , AVL.START_DATE_TIME) START_DATE_TIME ,
    NVL2(ASA.END_TO , ASA.END_TO , AVL.CLOSE_DATE_TIME) CLOSE_DATE_TIME
  FROM AHL_SPACE_ASSIGNMENTS ASA,
    AHL_VISITS_VL AVL
  WHERE ASA.visit_id      = AVL.visit_id
  AND ASA.SPACE_ID        = c_space_id
  AND AVL.department_id   = c_dept_id
  AND AVL.organization_id = c_org_id
  AND AVL.status_code    IN ('PLANNING','RELEASED','PARTIALLY RELEASED')
  AND AVL.template_flag   = 'N'
  AND TRUNC(c_loop_date) BETWEEN TRUNC(NVL2(ASA.START_FROM, ASA.START_FROM
                                                    , AVL.START_DATE_TIME))
                         AND TRUNC(NVL2(ASA.END_TO, ASA.END_TO
                                            , NVL(AVL.CLOSE_DATE_TIME, c_loop_date + 1)))
  ORDER BY AVL.START_DATE_TIME;

c_visit_for_space_day_rec c_visit_for_space_day%ROWTYPE;

-- inner cursor for ROW wise calculation for dept only
CURSOR c_visit_for_dept_day (c_org_id IN NUMBER, c_dept_id IN NUMBER, c_loop_date IN DATE)
IS
  SELECT AVL.visit_id,
    AVL.START_DATE_TIME,
    AVL.CLOSE_DATE_TIME
  FROM AHL_VISITS_VL AVL
  WHERE AVL.visit_id NOT IN
    (SELECT DISTINCT ASA.VISIT_ID
     FROM AHL_SPACE_ASSIGNMENTS ASA,
      AHL_VISITS_VL AVL
     WHERE TRUNC(c_loop_date) BETWEEN TRUNC(NVL2(ASA.START_FROM, ASA.START_FROM , AVL.START_DATE_TIME))
           AND TRUNC(NVL2(ASA.END_TO, ASA.END_TO , NVL(AVL.CLOSE_DATE_TIME, c_loop_date)))
    )
AND AVL.department_id   = c_dept_id
AND AVL.organization_id = c_org_id
AND AVL.status_code    IN ('PLANNING','RELEASED','PARTIALLY RELEASED')
AND AVL.TEMPLATE_FLAG   = 'N'
AND TRUNC(c_loop_date) BETWEEN TRUNC(AVL.START_DATE_TIME)
                       AND TRUNC(NVL(AVL.CLOSE_DATE_TIME, c_loop_date + 1))
ORDER BY AVL.START_DATE_TIME;

c_visit_for_dept_day_rec c_visit_for_dept_day%ROWTYPE;

BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT GET_VISITS_FOR_DATE_ORG;

  IF (l_log_procedure >= l_log_current_level) THEN
     fnd_log.string(l_log_procedure,
                    l_debug_key ||'.begin',
                    ' At the start of PL SQL function. '||
                    ' Org Id = '           || p_org_sch_search_rec.ORG_ID ||
                    ' Dept Id = '          || p_org_sch_search_rec.DEPARTMENT_ID||
                    ' Space Id = '         || p_org_sch_search_rec.SPACE_ID||
                    ' Loop Start Date = '  || p_org_sch_search_rec.START_FROM_DATE||
                    ' Loop Window = '      || p_org_sch_search_rec.DISPLAY_WINDOW||
                    ' Filter Criteria = '  || p_org_sch_search_rec.RESULT_FILTER);
  END IF;

   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
   --  Initialize API return status to success
   x_return_status := FND_API.G_RET_STS_SUCCESS;

   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       Fnd_Msg_Pub.ADD;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;
   --

   IF(p_org_sch_search_rec.ORG_ID IS NULL) OR
     (p_org_sch_search_rec.DEPARTMENT_ID IS NULL) OR
     (p_org_sch_search_rec.START_FROM_DATE IS NULL) OR
     (p_org_sch_search_rec.DISPLAY_WINDOW IS NULL) THEN
    IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,
                       L_DEBUG_KEY,
                       'One of the Passed Mandatory fields is null');
    END IF;
    Fnd_Message.set_name(G_APP_NAME, 'AHL_AMP_ORG_MANDATORY');
    FND_MSG_PUB.ADD;
    RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   l_loop_window     := p_org_sch_search_rec.DISPLAY_WINDOW;
   l_loop_start_date := p_org_sch_search_rec.START_FROM_DATE;

   LOOP
   EXIT WHEN l_day_inc > l_loop_window;
       l_visit_count := 0;
       l_sch_visits_tbl.DELETE;
       IF (p_org_sch_search_rec.SPACE_ID IS NOT NULL)  THEN
       --Space Cursor
           OPEN c_visit_for_space_day(p_org_sch_search_rec.ORG_ID
                                     ,p_org_sch_search_rec.DEPARTMENT_ID
                                     ,p_org_sch_search_rec.SPACE_ID
                                     ,l_loop_start_date);
           LOOP
           FETCH c_visit_for_space_day INTO c_visit_for_space_day_rec;
           EXIT WHEN c_visit_for_space_day%NOTFOUND;
                l_visit_rec.VISIT_ID := c_visit_for_space_day_rec.visit_id;
                l_visit_rec.START_DATE := c_visit_for_space_day_rec.START_DATE_TIME;
                l_visit_rec.END_DATE := c_visit_for_space_day_rec.CLOSE_DATE_TIME;
                l_sch_visits_tbl(l_visit_count) := l_visit_rec;
                l_visit_count := l_visit_count + 1;
           END LOOP;
           CLOSE c_visit_for_space_day;

           -- call GET_GRAPH_REC_FOR_DATE
           GET_GRAPH_REC_FOR_DATE(
                     p_graph_rec_date  => l_loop_start_date,
                     p_graph_rec_num   => l_day_inc,
                     p_visit_count     => l_visit_count,
                     p_filter_criteria => p_org_sch_search_rec.RESULT_FILTER,
                     p_rec_type        => G_SPACE_TYPE,
                     p_sch_visits_tbl  => l_sch_visits_tbl,
                     p_x_sch_graph_rec => l_sch_graph_rec);

       ELSIF (p_org_sch_search_rec.SPACE_ID IS NULL) THEN
       -- Dept cursor
           OPEN c_visit_for_dept_day(p_org_sch_search_rec.ORG_ID
                                     ,p_org_sch_search_rec.DEPARTMENT_ID
                                     ,l_loop_start_date);
           LOOP
           FETCH c_visit_for_dept_day INTO c_visit_for_dept_day_rec;
           EXIT WHEN c_visit_for_dept_day%NOTFOUND;
                l_visit_rec.VISIT_ID := c_visit_for_dept_day_rec.visit_id;
                l_visit_rec.START_DATE := c_visit_for_dept_day_rec.START_DATE_TIME;
                l_visit_rec.END_DATE := c_visit_for_dept_day_rec.CLOSE_DATE_TIME;
                l_sch_visits_tbl(l_visit_count) := l_visit_rec;
                l_visit_count := l_visit_count + 1;
           END LOOP;
           CLOSE c_visit_for_dept_day;

           -- call GET_GRAPH_REC_FOR_DATE
           GET_GRAPH_REC_FOR_DATE(
                     p_graph_rec_date  => l_loop_start_date,
                     p_graph_rec_num   => l_day_inc,
                     p_visit_count     => l_visit_count,
                     p_filter_criteria => p_org_sch_search_rec.RESULT_FILTER,
                     p_rec_type        => G_DEPT_TYPE,
                     p_sch_visits_tbl  => l_sch_visits_tbl,
                     p_x_sch_graph_rec => l_sch_graph_rec);
       END IF;

   l_loop_start_date := l_loop_start_date+1;
   l_day_inc         := l_day_inc+1;
   END LOOP;
   x_sch_visits_tbl := l_sch_visits_tbl;
   x_sch_graph_rec  := l_sch_graph_rec;


   l_msg_count := Fnd_Msg_Pub.count_msg;
   IF l_msg_count > 0 OR l_return_status <> Fnd_Api.g_ret_sts_success THEN
      IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,
                         L_DEBUG_KEY,
                         'Errors from GET_VISITS_FOR_DATE_ORG. Message count: ' ||
                         l_msg_count || ', Message data: ' || l_msg_data);
      END IF;
      x_msg_count := l_msg_count;
      x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
   END IF;

   x_return_status := Fnd_Api.g_ret_sts_success;
   IF (l_log_procedure >= l_log_current_level) THEN
       fnd_log.string(l_log_procedure,
                      L_DEBUG_KEY || '.end',
                      'Return Status = ' || x_return_status);
   END IF;

EXCEPTION
 WHEN Fnd_Api.G_EXC_ERROR THEN
   x_return_status := Fnd_Api.G_RET_STS_ERROR;
   ROLLBACK TO GET_VISITS_FOR_DATE_ORG;
   Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => Fnd_Api.g_false);
 WHEN Fnd_Api.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO GET_VISITS_FOR_DATE_ORG;
   Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => Fnd_Api.g_false);
 WHEN OTHERS THEN
      ROLLBACK TO GET_VISITS_FOR_DATE_ORG;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
    THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data);

END GET_VISITS_FOR_DATE_ORG;

  -- Procedure name              : GET_FLT_SCH_GRAPH
  -- Type                        : Public
  -- Parameters                  :
  --
  -- Standard IN  Parameters :
  --      p_api_version               NUMBER   Required
  --      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
  --      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
  --
  -- Standard OUT Parameters :
  --      x_return_status             VARCHAR2 Required
  --      x_msg_count                 NUMBER   Required
  --      x_msg_data                  VARCHAR2 Required
  -- GET_ORG_SCH_GRAPH params
  --      p_flt_sch_search_rec        FLEET_SCH_SEARCH_REC    Required
  --      x_sch_graph_results_tbl     SCH_GRAPH_RESULTS_TBL

PROCEDURE GET_FLT_SCH_GRAPH(
p_api_version           IN            NUMBER     := 1.0,
p_init_msg_list         IN            VARCHAR2   := FND_API.G_TRUE,
p_validation_level      IN            NUMBER     := FND_API.G_VALID_LEVEL_FULL,
x_return_status         OUT NOCOPY    VARCHAR2,
x_msg_count             OUT NOCOPY    NUMBER,
x_msg_data              OUT NOCOPY    VARCHAR2,
p_flt_sch_search_rec    IN            FLEET_SCH_SEARCH_REC,
x_sch_graph_results_tbl OUT NOCOPY    sch_graph_results_tbl
) IS

-- LOCAL VARIABLE
l_api_name         CONSTANT VARCHAR2(30)  := 'GET_FLT_SCH_GRAPH';
l_debug_key        CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || l_api_name;
l_api_version      CONSTANT NUMBER        := 1.0;
l_msg_count                 NUMBER;
l_return_status             VARCHAR2(1);
l_msg_data                  VARCHAR2(2000);
l_loop_window               NUMBER;
l_loop_start_date           DATE;
l_end_date                  DATE;
l_visit_duration            NUMBER := 0;
l_row_inc                   NUMBER := 0;
l_flt_sch_search_rec        FLEET_SCH_SEARCH_REC;
l_sch_graph_rec             SCH_GRAPH_RESULTS_REC;
l_sch_graph_tbl             sch_graph_results_tbl;
l_sch_visits_tbl            sch_visits_tbl;

-- Cursor
CURSOR c_unit_for_flt (c_fleet_id IN NUMBER, c_unit_name IN VARCHAR2, c_mc_name IN VARCHAR2, c_start_date IN DATE, c_end_date IN DATE)
IS
  SELECT DISTINCT UCH.NAME UNIT_NAME,
    UCH.UNIT_CONFIG_HEADER_ID UNIT_ID
  FROM AHL_UNIT_CONFIG_HEADERS UCH,
    AHL_FLEET_HEADERS_B FHB,
    AHL_FLEET_UNIT_ASSOCS FUA,
    AHL_MC_HEADERS_B MC
  WHERE FUA.UNIT_CONFIG_HEADER_ID = UCH.UNIT_CONFIG_HEADER_ID
  AND FUA.FLEET_HEADER_ID         = FHB.FLEET_HEADER_ID
  AND UCH.MASTER_CONFIG_ID        = MC.MC_HEADER_ID
  AND FUA.SIMULATION_PLAN_ID      =
    (SELECT ASP.SIMULATION_PLAN_ID
    FROM AHL_SIMULATION_PLANS_B ASP
    WHERE ASP.PRIMARY_PLAN_FLAG = 'Y'
    AND ASP.status_code         = 'ACTIVE'
	AND ASP.simulation_type = 'UMP' -- Sthilak added this extra filter condition AMP-AutoVisit Changes
    )
AND UCH.UNIT_CONFIG_STATUS_CODE           <> 'DRAFT'
AND TRUNC(NVL(UCH.ACTIVE_END_DATE,c_end_date+1)) > TRUNC(c_end_date)
AND FHB.STATUS_CODE                       = 'COMPLETE'
AND FHB.FLEET_HEADER_ID = c_fleet_id
AND UPPER(UCH.NAME) LIKE UPPER(NVL(c_unit_name,UCH.NAME))
AND UPPER(MC.NAME) LIKE UPPER(NVL(c_mc_name,MC.NAME))
AND (TRUNC(c_start_date) BETWEEN TRUNC(FUA.association_start) AND TRUNC(NVL(FUA.association_end, c_end_date))
     OR TRUNC(c_end_date) BETWEEN TRUNC(FUA.association_start) AND TRUNC(NVL(FUA.association_end, c_end_date))
     OR TRUNC(FUA.association_start) BETWEEN TRUNC(c_start_date) AND TRUNC(c_end_date))
ORDER BY UCH.NAME;

unit_for_flt_rec c_unit_for_flt%ROWTYPE;



BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT GET_FLT_SCH_GRAPH;

  IF (l_log_procedure >= l_log_current_level) THEN
     fnd_log.string(l_log_procedure,
                    l_debug_key ||'.begin',
                    ' At the start of PL SQL function. '||
                    ' Fleet Id = '         || p_flt_sch_search_rec.FLEET_ID ||
                    ' Unit Name = '        || p_flt_sch_search_rec.UNIT_NAME||
                    ' MC Name = '          || p_flt_sch_search_rec.MASTER_CONFIG||
                    ' Minimum Duration = ' || p_flt_sch_search_rec.MINIMUM_DURATION||
                    ' Duration UOM = '     || p_flt_sch_search_rec.UOM||
                    ' Start from Date = '  || p_flt_sch_search_rec.START_FROM_DATE||
                    ' Start before Date = '|| p_flt_sch_search_rec.START_BEFORE_DATE||
                    ' Display Window = '   || p_flt_sch_search_rec.DISPLAY_WINDOW);
  END IF;

   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
   --  Initialize API return status to success
   x_return_status := FND_API.G_RET_STS_SUCCESS;

   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       Fnd_Msg_Pub.ADD;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;
   --

   IF(p_flt_sch_search_rec.FLEET_ID IS NULL) OR
      (p_flt_sch_search_rec.DISPLAY_WINDOW IS NULL) THEN
    IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,
                       L_DEBUG_KEY,
                       'Passed Mandatory fields Org id or Display window is null');
    END IF;
    Fnd_Message.set_name(G_APP_NAME, 'AHL_AMP_FLEET_MANDATORY');
    FND_MSG_PUB.ADD;
    RAISE Fnd_Api.G_EXC_ERROR;

   ELSIF(p_flt_sch_search_rec.START_FROM_DATE IS NULL) AND
         (p_flt_sch_search_rec.START_BEFORE_DATE IS NULL) THEN

          Fnd_Message.set_name(G_APP_NAME, 'AHL_AMP_DATE_MANDATORY');
          Fnd_Msg_Pub.ADD;
          RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   l_loop_window := p_flt_sch_search_rec.DISPLAY_WINDOW;

   IF((p_flt_sch_search_rec.START_FROM_DATE IS NOT NULL) AND
      (p_flt_sch_search_rec.START_BEFORE_DATE IS NOT NULL)) OR
     (p_flt_sch_search_rec.START_BEFORE_DATE IS NULL)
     THEN
      l_loop_start_date := p_flt_sch_search_rec.START_FROM_DATE;
      l_end_date := p_flt_sch_search_rec.START_FROM_DATE + l_loop_window - 1;
   ELSIF(p_flt_sch_search_rec.START_FROM_DATE IS NULL)  THEN
      l_loop_start_date := p_flt_sch_search_rec.START_BEFORE_DATE - l_loop_window + 1;
      l_end_date := p_flt_sch_search_rec.START_BEFORE_DATE;
   END IF;

   IF(p_flt_sch_search_rec.MINIMUM_DURATION IS NOT NULL) THEN
    IF(p_flt_sch_search_rec.UOM = 'HOUR') THEN
      l_visit_duration := p_flt_sch_search_rec.MINIMUM_DURATION;
    ELSE
      l_visit_duration := p_flt_sch_search_rec.MINIMUM_DURATION * 24;
    END IF;
   END IF;

   IF (l_log_procedure >= l_log_current_level) THEN
     fnd_log.string(l_log_procedure,
                    l_debug_key ||'.middle',
                    ' Before looping through rows. '||
                    ' Loop Start date = '               || l_loop_start_date ||
                    ' End date = '                      || l_end_date ||
                    ' Duration in Hours = '             || l_visit_duration);
   END IF;

   OPEN c_unit_for_flt(p_flt_sch_search_rec.FLEET_ID
   , p_flt_sch_search_rec.UNIT_NAME
   , p_flt_sch_search_rec.MASTER_CONFIG
   , l_loop_start_date
   , l_end_date);

   LOOP
   FETCH c_unit_for_flt INTO unit_for_flt_rec;
   EXIT WHEN c_unit_for_flt%NOTFOUND;
    -- call GET_VISITS_FOR_DATE_FLT
    -- prepare in params...
    l_flt_sch_search_rec := NULL;
    l_flt_sch_search_rec.FLEET_ID := p_flt_sch_search_rec.FLEET_ID;
    l_flt_sch_search_rec.UNIT_ID := unit_for_flt_rec.UNIT_ID;
    l_flt_sch_search_rec.MINIMUM_DURATION  := l_visit_duration;
    l_flt_sch_search_rec.START_FROM_DATE := l_loop_start_date;
    l_flt_sch_search_rec.DISPLAY_WINDOW := l_loop_window;

    GET_VISITS_FOR_DATE_FLT(
       p_api_version           => p_api_version,
       p_init_msg_list         => FND_API.G_FALSE,
       p_validation_level      => p_validation_level,
       x_return_status         => l_return_status,
       x_msg_count             => l_msg_count,
       x_msg_data              => l_msg_data,
       p_flt_sch_search_rec    => l_flt_sch_search_rec,
       x_sch_graph_rec         => l_sch_graph_rec,
       x_sch_visits_tbl        => l_sch_visits_tbl);
    -- end of call GET_VISITS_FOR_DATE_FLT

    l_sch_graph_rec.UNIT_ID         := unit_for_flt_rec.UNIT_ID;
    l_sch_graph_rec.UNIT_NAME       := unit_for_flt_rec.UNIT_NAME;

    --add return rec type to the table
    x_sch_graph_results_tbl(l_row_inc) := l_sch_graph_rec;
    l_row_inc := l_row_inc + 1;

   END LOOP;
   CLOSE c_unit_for_flt;

   l_msg_count := Fnd_Msg_Pub.count_msg;
   IF l_msg_count > 0 OR l_return_status <> Fnd_Api.g_ret_sts_success THEN
      IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,
                         L_DEBUG_KEY,
                         'Errors from GET_VISITS_FOR_DATE_FLT. Message count: ' ||
                         l_msg_count || ', Message data: ' || l_msg_data);
      END IF;
      x_msg_count := l_msg_count;
      x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
   END IF;

   x_return_status := Fnd_Api.g_ret_sts_success;
   IF (l_log_procedure >= l_log_current_level) THEN
       fnd_log.string(l_log_procedure,
                      L_DEBUG_KEY || '.end',
                      'Return Status = ' || x_return_status);
   END IF;

EXCEPTION
 WHEN Fnd_Api.G_EXC_ERROR THEN
   x_return_status := Fnd_Api.G_RET_STS_ERROR;
   ROLLBACK TO GET_FLT_SCH_GRAPH;
   Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => Fnd_Api.g_false);
 WHEN Fnd_Api.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO GET_FLT_SCH_GRAPH;
   Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => Fnd_Api.g_false);
 WHEN OTHERS THEN
      ROLLBACK TO GET_FLT_SCH_GRAPH;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
    THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data);

END GET_FLT_SCH_GRAPH;

  -- Procedure name              : GET_VISITS_FOR_DATE_FLT
  -- Type                        : Public
  -- Parameters                  :
  --
  -- Standard IN  Parameters :
  --      p_api_version               NUMBER   Required
  --      p_init_msg_list             VARCHAR2 Default  FND_API.G_FALSE
  --      p_validation_level          NUMBER   Default  FND_API.G_VALID_LEVEL_FULL
  --
  -- Standard OUT Parameters :
  --      x_return_status             VARCHAR2 Required
  --      x_msg_count                 NUMBER   Required
  --      x_msg_data                  VARCHAR2 Required
  -- GET_VISITS_FOR_DATE_FLT params
  --      p_flt_sch_search_rec        FLEET_SCH_SEARCH_REC  Required
  --      x_sch_graph_rec             SCH_GRAPH_RESULTS_REC
  --      x_sch_visits_tbl            SCH_VISITS_TBL

PROCEDURE GET_VISITS_FOR_DATE_FLT(
p_api_version           IN            NUMBER     := 1.0,
p_init_msg_list         IN            VARCHAR2   := FND_API.G_TRUE,
p_validation_level      IN            NUMBER     := FND_API.G_VALID_LEVEL_FULL,
x_return_status         OUT NOCOPY    VARCHAR2,
x_msg_count             OUT NOCOPY    NUMBER,
x_msg_data              OUT NOCOPY    VARCHAR2,
p_flt_sch_search_rec    IN            FLEET_SCH_SEARCH_REC,
x_sch_graph_rec         OUT NOCOPY    SCH_GRAPH_RESULTS_REC,
x_sch_visits_tbl        OUT NOCOPY    sch_visits_tbl
) IS

-- LOCAL VARIABLE
l_api_name        CONSTANT VARCHAR2(30)  := 'GET_VISITS_FOR_DATE_FLT';
l_debug_key       CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || l_api_name;
l_api_version     CONSTANT NUMBER        := 1.0;
l_msg_count                NUMBER;
l_return_status            VARCHAR2(1);
l_msg_data                 VARCHAR2(2000);
l_loop_window              NUMBER;
l_loop_start_date          DATE;
l_column_inc               NUMBER := 0;
l_day_inc                  NUMBER := 1;
l_visit_rec                SCH_VISITS_REC;
l_visit_count              NUMBER := 0;
l_flt_sch_search_rec       fleet_sch_search_rec;
l_sch_graph_rec            SCH_GRAPH_RESULTS_REC;
l_sch_visits_tbl           sch_visits_tbl;
l_dummy                    VARCHAR2(1);
l_not_for_sch              VARCHAR2(1) := FND_API.G_FALSE;

-- Cursor
CURSOR c_visit_for_unit_day (c_unit_id IN NUMBER, c_duration IN NUMBER, c_loop_date IN DATE)
IS
  SELECT AVT.visit_id,
    AVT.START_DATE_TIME,
    AVT.CLOSE_DATE_TIME
  FROM
    (SELECT AVL.visit_id,
      AVL.START_DATE_TIME,
      AVL.CLOSE_DATE_TIME,
      UCH.UNIT_CONFIG_HEADER_ID,
      TRUNC((AVL.CLOSE_DATE_TIME - AVL.START_DATE_TIME)*24) visit_duration
    FROM ahl_visits_vl AVL,
      AHL_UNIT_CONFIG_HEADERS UCH
    WHERE AVL.status_code       IN ('PLANNING','RELEASED','PARTIALLY RELEASED')
    AND AVL.template_flag        = 'N'
    AND UCH.csi_item_instance_id = AVL.Item_Instance_id
    ) AVT
WHERE NVL(AVT.visit_duration,10000) > NVL(c_duration,0)
AND AVT.UNIT_CONFIG_HEADER_ID   = c_unit_id
AND TRUNC(c_loop_date) BETWEEN TRUNC(AVT.START_DATE_TIME)
                       AND TRUNC(NVL(AVT.CLOSE_DATE_TIME, c_loop_date + 1))
ORDER BY AVT.START_DATE_TIME;

c_visit_for_unit_day_rec c_visit_for_unit_day%ROWTYPE;

CURSOR c_flt_unit_ass_day ( c_fleet_id IN NUMBER, c_unit_id IN NUMBER, c_loop_date IN DATE)
IS
  SELECT 'X'
  FROM AHL_UNIT_CONFIG_HEADERS UCH,
    AHL_FLEET_HEADERS_B FHB,
    AHL_FLEET_UNIT_ASSOCS FUA
  WHERE fua.unit_config_header_id = uch.unit_config_header_id
  AND FUA.FLEET_HEADER_ID         = FHB.FLEET_HEADER_ID
  AND FUA.SIMULATION_PLAN_ID      =
    (SELECT ASP.SIMULATION_PLAN_ID
    FROM AHL_SIMULATION_PLANS_B ASP
    WHERE ASP.PRIMARY_PLAN_FLAG = 'Y'
    AND ASP.status_code         = 'ACTIVE'
	AND ASP.simulation_type = 'UMP' -- Sthilak added this extra filter condition AMP-AutoVisit Changes
    )
AND UCH.UNIT_CONFIG_STATUS_CODE                 <> 'DRAFT'
AND TRUNC(NVL(uch.active_end_date,c_loop_date+1)) > TRUNC(c_loop_date)
AND fhb.status_code                              = 'COMPLETE'
AND fua.unit_config_header_id                    = c_unit_id
AND fua.fleet_header_id                          = c_fleet_id
AND c_loop_date BETWEEN TRUNC(FUA.association_start) AND TRUNC(NVL(FUA.association_end, c_loop_date));

BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT GET_VISITS_FOR_DATE_FLT;

  IF (l_log_procedure >= l_log_current_level) THEN
     fnd_log.string(l_log_procedure,
                    l_debug_key ||'.begin',
                    ' At the start of PL SQL function. '||
                    ' Unit Id = '          || p_flt_sch_search_rec.UNIT_ID ||
                    ' Minimum Duration in hours = ' || p_flt_sch_search_rec.MINIMUM_DURATION||
                    ' Loop Start Date = '  || p_flt_sch_search_rec.START_FROM_DATE||
                    ' Loop Window = '      || p_flt_sch_search_rec.DISPLAY_WINDOW);
  END IF;

   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
   --  Initialize API return status to success
   x_return_status := FND_API.G_RET_STS_SUCCESS;

   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       Fnd_Msg_Pub.ADD;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;
   --

   IF(p_flt_sch_search_rec.UNIT_ID IS NULL) OR
     (p_flt_sch_search_rec.MINIMUM_DURATION IS NULL) OR
     (p_flt_sch_search_rec.START_FROM_DATE IS NULL) OR
     (p_flt_sch_search_rec.DISPLAY_WINDOW IS NULL) THEN
    IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,
                       L_DEBUG_KEY,
                       'One of the Passed Mandatory fields is null');
    END IF;
    Fnd_Message.set_name(G_APP_NAME, 'AHL_AMP_FLEET_MANDATORY');
    FND_MSG_PUB.ADD;
    RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   l_loop_window     := p_flt_sch_search_rec.DISPLAY_WINDOW;
   l_loop_start_date := p_flt_sch_search_rec.START_FROM_DATE;

   LOOP
   EXIT WHEN l_day_inc > l_loop_window;
       l_visit_count := 0;
       l_sch_visits_tbl.DELETE;

       OPEN c_visit_for_unit_day(p_flt_sch_search_rec.UNIT_ID
                                ,p_flt_sch_search_rec.MINIMUM_DURATION
                                ,l_loop_start_date);
       LOOP
       FETCH c_visit_for_unit_day INTO c_visit_for_unit_day_rec;
       EXIT WHEN c_visit_for_unit_day%NOTFOUND;
            l_visit_rec.VISIT_ID := c_visit_for_unit_day_rec.visit_id;
            l_visit_rec.START_DATE := c_visit_for_unit_day_rec.START_DATE_TIME;
            l_visit_rec.END_DATE := c_visit_for_unit_day_rec.CLOSE_DATE_TIME;
            l_sch_visits_tbl(l_visit_count) := l_visit_rec;
            l_visit_count := l_visit_count + 1;
       END LOOP;
       CLOSE c_visit_for_unit_day;

       OPEN c_flt_unit_ass_day(p_flt_sch_search_rec.FLEET_ID
                              ,p_flt_sch_search_rec.UNIT_ID
                              ,l_loop_start_date);

       FETCH c_flt_unit_ass_day INTO l_dummy;
       IF c_flt_unit_ass_day%NOTFOUND  THEN
          l_not_for_sch := FND_API.G_TRUE;
       ELSE
          l_not_for_sch := FND_API.G_FALSE;
       END IF;
       CLOSE c_flt_unit_ass_day;

       -- call GET_GRAPH_REC_FOR_DATE
       GET_GRAPH_REC_FOR_DATE(
                 p_graph_rec_date    => l_loop_start_date,
                 p_graph_rec_num     => l_day_inc,
                 p_visit_count       => l_visit_count,
                 p_not_for_sch       => l_not_for_sch,
                 p_sch_visits_tbl    => l_sch_visits_tbl,
                 p_x_sch_graph_rec   => l_sch_graph_rec);

       l_loop_start_date := l_loop_start_date+1;
       l_day_inc         := l_day_inc+1;
   END LOOP;
   x_sch_visits_tbl := l_sch_visits_tbl;
   x_sch_graph_rec  := l_sch_graph_rec;

   l_msg_count := Fnd_Msg_Pub.count_msg;
   IF l_msg_count > 0 OR l_return_status <> Fnd_Api.g_ret_sts_success THEN
      IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,
                         L_DEBUG_KEY,
                         'Errors from GET_VISITS_FOR_DATE_FLT. Message count: ' ||
                         l_msg_count || ', Message data: ' || l_msg_data);
      END IF;
      x_msg_count := l_msg_count;
      x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
   END IF;

   x_return_status := Fnd_Api.g_ret_sts_success;
   IF (l_log_procedure >= l_log_current_level) THEN
       fnd_log.string(l_log_procedure,
                      L_DEBUG_KEY || '.end',
                      'Return Status = ' || x_return_status);
   END IF;

EXCEPTION
 WHEN Fnd_Api.G_EXC_ERROR THEN
   x_return_status := Fnd_Api.G_RET_STS_ERROR;
   ROLLBACK TO GET_VISITS_FOR_DATE_FLT;
   Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => Fnd_Api.g_false);
 WHEN Fnd_Api.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO GET_VISITS_FOR_DATE_FLT;
   Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => Fnd_Api.g_false);
 WHEN OTHERS THEN
      ROLLBACK TO GET_VISITS_FOR_DATE_FLT;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
    THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data);

END GET_VISITS_FOR_DATE_FLT;

 -- Procedure name              : GET_GRAPH_REC_FOR_DATE
 -- Type                        : Private
 -- Parameters                  :
 -- GET_GRAPH_REC_FOR_DATE params
 -- 		p_graph_rec_date    DATE
 -- 		p_graph_rec_num     NUMBER
 -- 		p_visit_count       NUMBER
 --             p_not_for_sch       VARCHAR2
 -- 		p_filter_criteria   VARCHAR2
 -- 		p_rec_type	    VARCHAR2
 -- 		p_sch_visits_tbl    SCH_VISITS_TBL
 -- 		p_x_sch_graph_rec   SCH_GRAPH_RESULTS_REC

PROCEDURE GET_GRAPH_REC_FOR_DATE(
p_graph_rec_date        IN               DATE,
p_graph_rec_num         IN               NUMBER,
p_visit_count           IN               NUMBER,
p_not_for_sch           IN               VARCHAR2 := Fnd_Api.g_false,
p_filter_criteria       IN               VARCHAR2 := 'ALL',
p_rec_type              IN               VARCHAR2 := G_SPACE_TYPE,
p_sch_visits_tbl        IN               sch_visits_tbl,
p_x_sch_graph_rec       IN OUT  NOCOPY   SCH_GRAPH_RESULTS_REC
) IS

--local variable
l_api_name        CONSTANT VARCHAR2(30)  := 'GET_GRAPH_REC_FOR_DATE';
l_debug_key       CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || l_api_name;

l_schedule_type             VARCHAR2(30) := NULL;
l_visit_id                  NUMBER       := NULL;
l_visit_start               VARCHAR2(10);
l_visit_end                 VARCHAR2(10);
l_graph_rec_date_char       VARCHAR2(10);
l_tbl_inc                   NUMBER := 1;
l_end_counter               NUMBER;

l_S_V_start        CONSTANT VARCHAR2(30) := 'SingleVisitStart';
l_S_V_day          CONSTANT VARCHAR2(30) := 'SingleVisitDay';
l_S_V_end          CONSTANT VARCHAR2(30) := 'SingleVisitEnd';
l_M_V_no_overlap   CONSTANT VARCHAR2(30) := 'MultiVisitNoOverlap';
l_M_V_no_conflict  CONSTANT VARCHAR2(30) := 'MultiVisitNoConflict';
l_M_V_conflict     CONSTANT VARCHAR2(30) := 'MultiVisitConflict';
l_N_no_visit       CONSTANT VARCHAR2(30) := 'NoVisit';
l_N_not_available  CONSTANT VARCHAR2(30) := 'NoSchedule';

l_filter_conflict  CONSTANT VARCHAR2(15) := 'CONFLICT_DAYS';
l_filter_open      CONSTANT VARCHAR2(15) := 'OPEN_DAYS';
l_filter_scheduled CONSTANT VARCHAR2(15) := 'SCHEDULED_DAYS';
l_loop_inc                  NUMBER       := 1;

l_conflict                  VARCHAR2(30) := l_M_V_conflict||p_graph_rec_num;
l_no_visit                  VARCHAR2(30) := l_N_no_visit||p_graph_rec_num;

BEGIN
    IF(p_not_for_sch = Fnd_Api.g_true) THEN
       l_schedule_type := l_N_not_available||p_graph_rec_num;

    ELSIF(p_visit_count < 1) THEN
       l_schedule_type := l_N_no_visit || p_graph_rec_num;

    ELSIF (p_visit_count = 1) THEN
       l_visit_start         := to_char(p_sch_visits_tbl(0).START_DATE, 'DD-MM-YYYY');
       l_visit_end           := to_char(p_sch_visits_tbl(0).END_DATE, 'DD-MM-YYYY');
       l_graph_rec_date_char := to_char(p_graph_rec_date, 'DD-MM-YYYY');

       IF(l_visit_start = l_graph_rec_date_char) THEN
          l_schedule_type := l_S_V_start || p_graph_rec_num;

       ELSIF(l_visit_end = l_graph_rec_date_char) THEN
          l_schedule_type := l_S_V_end || p_graph_rec_num;

       ELSE
          l_schedule_type := l_S_V_day || p_graph_rec_num;
       END IF;

       l_visit_id := p_sch_visits_tbl(0).VISIT_ID;

    ELSIF (p_visit_count > 1) THEN

       l_end_counter := p_visit_count-1;

       FOR l_tbl_inc IN 1..l_end_counter LOOP
          IF(p_sch_visits_tbl(l_tbl_inc-1).END_DATE
             >=
             p_sch_visits_tbl(l_tbl_inc).START_DATE) THEN

              IF(p_rec_type = G_DEPT_TYPE) THEN
                  l_schedule_type := l_M_V_no_conflict || p_graph_rec_num;
              ELSE
                  l_schedule_type := l_M_V_conflict || p_graph_rec_num;
              END IF;
              EXIT;
           END IF;

       END LOOP;

       IF (l_schedule_type IS NULL) THEN
           l_schedule_type := l_M_V_no_overlap || p_graph_rec_num;
       END IF;

    END IF;

    CASE p_graph_rec_num
    WHEN 1 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_1 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_1 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_1 := l_visit_id;
    WHEN 2 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_2 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_2 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_2 := l_visit_id;
    WHEN 3 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_3 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_3 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_3 := l_visit_id;
    WHEN 4 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_4 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_4 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_4 := l_visit_id;
    WHEN 5 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_5 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_5 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_5 := l_visit_id;
    WHEN 6 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_6 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_6 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_6 := l_visit_id;
    WHEN 7 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_7 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_7 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_7 := l_visit_id;
    WHEN 8 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_8 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_8 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_8 := l_visit_id;
    WHEN 9 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_9 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_9 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_9 := l_visit_id;
    WHEN 10 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_10 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_10 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_10 := l_visit_id;
    WHEN 11 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_11 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_11 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_11 := l_visit_id;
    WHEN 12 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_12 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_12 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_12 := l_visit_id;
    WHEN 13 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_13 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_13 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_13 := l_visit_id;
    WHEN 14 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_14 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_14 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_14 := l_visit_id;
    WHEN 15 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_15 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_15 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_15 := l_visit_id;
    WHEN 16 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_16 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_16 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_16 := l_visit_id;
    WHEN 17 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_17 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_17 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_17 := l_visit_id;
    WHEN 18 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_18 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_18 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_18 := l_visit_id;
    WHEN 19 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_19 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_19 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_19 := l_visit_id;
    WHEN 20 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_20 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_20 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_20 := l_visit_id;
    WHEN 21 THEN
    p_x_sch_graph_rec.SCHEDULE_TYPE_21 := l_schedule_type;
    p_x_sch_graph_rec.VISIT_DATE_21 := p_graph_rec_date;
    p_x_sch_graph_rec.VISIT_ID_21 := l_visit_id;
    ELSE
      FND_MSG_PUB.ADD;
      RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
    END CASE;

    IF(p_filter_criteria IN (l_filter_open, l_filter_conflict)) THEN
      IF NOT p_x_sch_graph_rec.FILTER_REC THEN
       IF(p_filter_criteria = l_filter_open) AND
            (l_schedule_type = l_no_visit)THEN
             p_x_sch_graph_rec.FILTER_REC := TRUE;

       ELSIF((p_filter_criteria = l_filter_conflict) AND
          (l_schedule_type = l_conflict))THEN
           p_x_sch_graph_rec.FILTER_REC := TRUE;
       END IF;
      END IF;
    ELSIF(p_filter_criteria = l_filter_scheduled) THEN
      IF (p_graph_rec_num <> 1) AND
         (p_x_sch_graph_rec.FILTER_REC) THEN
          IF l_schedule_type NOT IN (l_conflict,l_no_visit)THEN
              p_x_sch_graph_rec.FILTER_REC := FALSE;
          END IF;
      ELSIF(p_graph_rec_num = 1) THEN
        IF l_schedule_type NOT IN (l_conflict,l_no_visit)THEN
              p_x_sch_graph_rec.FILTER_REC := FALSE;
        ELSE
          p_x_sch_graph_rec.FILTER_REC := TRUE;
        END IF;
      END IF;
    ELSE
       p_x_sch_graph_rec.FILTER_REC := TRUE;
    END IF;
END GET_GRAPH_REC_FOR_DATE;

  -- Function name              : GET_FLEET_NAME
  -- Type                       : Public
  -- Parameters                 :
  -- GET_FLEET_NAME params
  --      p_item_instance_id    NUMBER  Required
  --      p_visit_start_date    DATE    Required
  --      p_visit_end_date      DATE    Required

FUNCTION GET_FLEET_NAME(p_item_instance_id IN  NUMBER,
                        p_visit_start_date IN  DATE,
                        p_visit_end_date   IN  DATE)
RETURN VARCHAR2
IS

CURSOR c_fleet_name_for_unit (c_instance_id IN NUMBER, c_start_date IN DATE, c_end_date IN DATE)
IS
  SELECT DISTINCT FHB.NAME FLEET_NAME,
    FUA.association_start
  FROM AHL_UNIT_CONFIG_HEADERS UCH,
    AHL_FLEET_HEADERS_B FHB,
    AHL_FLEET_UNIT_ASSOCS FUA,
    AHL_MC_HEADERS_B MC
  WHERE FUA.UNIT_CONFIG_HEADER_ID = UCH.UNIT_CONFIG_HEADER_ID
  AND FUA.FLEET_HEADER_ID         = FHB.FLEET_HEADER_ID
  AND UCH.MASTER_CONFIG_ID        = MC.MC_HEADER_ID
  AND FUA.SIMULATION_PLAN_ID      =
    (SELECT ASP.SIMULATION_PLAN_ID
    FROM AHL_SIMULATION_PLANS_B ASP
    WHERE ASP.PRIMARY_PLAN_FLAG = 'Y'
    AND ASP.status_code         = 'ACTIVE'
	AND ASP.simulation_type = 'UMP' -- Sthilak added this extra filter condition AMP-AutoVisit Changes
    )
AND UCH.UNIT_CONFIG_STATUS_CODE           <> 'DRAFT'
AND FHB.STATUS_CODE                       = 'COMPLETE'
AND TRUNC(NVL(UCH.ACTIVE_END_DATE,c_end_date+1)) > TRUNC(c_end_date)
AND UCH.csi_item_instance_id              = c_instance_id
AND (TRUNC(c_start_date) BETWEEN TRUNC(FUA.association_start) AND TRUNC(NVL(FUA.association_end, c_end_date))
     OR TRUNC(c_end_date) BETWEEN TRUNC(FUA.association_start) AND TRUNC(NVL(FUA.association_end, c_end_date))
     OR TRUNC(FUA.association_start) BETWEEN TRUNC(c_start_date) AND TRUNC(c_end_date))
ORDER BY association_start;

c_fleet_name_for_unit_rec c_fleet_name_for_unit%ROWTYPE;

BEGIN

   OPEN c_fleet_name_for_unit(p_item_instance_id,p_visit_start_date,p_visit_end_date);
   FETCH c_fleet_name_for_unit INTO c_fleet_name_for_unit_rec;
   IF(c_fleet_name_for_unit%NOTFOUND)THEN
      RETURN NULL;
   ELSE
    RETURN c_fleet_name_for_unit_rec.FLEET_NAME;
   END IF;
   CLOSE c_fleet_name_for_unit;

   RETURN NULL;
END GET_FLEET_NAME;

  -- Function name              : GET_FLEET_HEADER_ID
  -- Type                       : Public
  -- Parameters                 :
  -- GET_FLEET_NAME params
  --      p_item_instance_id    NUMBER  Required
  --      p_visit_start_date    DATE    Required
  --      p_visit_end_date      DATE    Required

FUNCTION GET_FLEET_HEADER_ID(p_item_instance_id IN  NUMBER,
                        p_visit_start_date IN  DATE,
                        p_visit_end_date   IN  DATE)
RETURN NUMBER
IS

CURSOR c_fleet_id_for_unit (c_instance_id IN NUMBER, c_start_date IN DATE, c_end_date IN DATE)
IS
  SELECT DISTINCT FHB.NAME FLEET_NAME,
    FUA.association_start,
    FHB.FLEET_HEADER_ID
  FROM AHL_UNIT_CONFIG_HEADERS UCH,
    AHL_FLEET_HEADERS_B FHB,
    AHL_FLEET_UNIT_ASSOCS FUA,
    AHL_MC_HEADERS_B MC
  WHERE FUA.UNIT_CONFIG_HEADER_ID = UCH.UNIT_CONFIG_HEADER_ID
  AND FUA.FLEET_HEADER_ID         = FHB.FLEET_HEADER_ID
  AND UCH.MASTER_CONFIG_ID        = MC.MC_HEADER_ID
  AND FUA.SIMULATION_PLAN_ID      =
    (SELECT ASP.SIMULATION_PLAN_ID
    FROM AHL_SIMULATION_PLANS_B ASP
    WHERE ASP.PRIMARY_PLAN_FLAG = 'Y'
    AND ASP.status_code         = 'ACTIVE'
	AND ASP.simulation_type = 'UMP' -- Sthilak added this extra filter condition AMP-AutoVisit Changes
    )
AND UCH.UNIT_CONFIG_STATUS_CODE           <> 'DRAFT'
AND FHB.STATUS_CODE                       = 'COMPLETE'
AND TRUNC(NVL(UCH.ACTIVE_END_DATE,c_end_date+1)) > TRUNC(c_end_date)
AND UCH.csi_item_instance_id              = c_instance_id
AND (TRUNC(c_start_date) BETWEEN TRUNC(FUA.association_start) AND TRUNC(NVL(FUA.association_end, c_end_date))
     OR TRUNC(c_end_date) BETWEEN TRUNC(FUA.association_start) AND TRUNC(NVL(FUA.association_end, c_end_date))
     OR TRUNC(FUA.association_start) BETWEEN TRUNC(c_start_date) AND TRUNC(c_end_date))
ORDER BY association_start;

c_fleet_id_for_unit_rec c_fleet_id_for_unit%ROWTYPE;

BEGIN

   OPEN c_fleet_id_for_unit(p_item_instance_id,p_visit_start_date,p_visit_end_date);
   FETCH c_fleet_id_for_unit INTO c_fleet_id_for_unit_rec;
   IF(c_fleet_id_for_unit%NOTFOUND)THEN
      RETURN NULL;
   ELSE
    RETURN c_fleet_id_for_unit_rec.FLEET_HEADER_ID;
   END IF;
   CLOSE c_fleet_id_for_unit;
   RETURN NULL;
END GET_FLEET_HEADER_ID;

END AHL_AMP_WORKBENCH_PVT;
