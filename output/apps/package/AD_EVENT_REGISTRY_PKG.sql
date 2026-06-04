
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_EVENT_REGISTRY_PKG" AUTHID CURRENT_USER AS
-- $Header: adevntrgs.pls 120.0 2005/05/25 11:50:30 appldev noship $

  -- Event Types can be the following
  BOOLEAN_TYPE          CONSTANT VARCHAR2(7)  := 'BOOLEAN';
  MULTI_TYPE            CONSTANT VARCHAR2(10) := 'MULTISTATE';

  -- Default Event Context
  DEFAULT_CONTEXT       CONSTANT VARCHAR2(4)  := 'NONE';

  -- Event Status can be the following values
  INITIALIZED_STATUS    CONSTANT VARCHAR2(11) := 'INITIALIZED';
  COMPLETED_STATUS      CONSTANT VARCHAR2(9)  := 'COMPLETED';
  NOTAPPLICABLE_STATUS  CONSTANT VARCHAR2(2)  := 'NA';

  -- Maximum workers
  MAX_ALLOWED_WORKERS   CONSTANT NUMBER       := 999;

  -- If the event is not define return the following status
  EVENT_NOT_DEFINED     CONSTANT VARCHAR2(17) := 'EVENT_NOT_DEFINED';

  -- Exceptions are declared below

  --
  -- The following excption is raised by the assert event procedure
  -- in cases when the event is not complete.
  --
  assert_event_EXP            EXCEPTION;

  --
  -- This is a general exception which will be raised for various conditions.
  --
  event_error_EXP             EXCEPTION;

  PRAGMA EXCEPTION_INIT(assert_event_EXP,            -20007);
  PRAGMA EXCEPTION_INIT(event_error_EXP,             -20010);


  -- Procedure declarations follows
  PROCEDURE Initialize_Event(
              p_Owner            IN VARCHAR2,
              p_Event_Name       IN VARCHAR2,
              p_Module_Name      IN VARCHAR2,
              p_Event_Type       IN VARCHAR2   := NULL ,
              p_Context          IN VARCHAR2   := NULL ,
              p_Version          IN NUMBER     := NULL ,
              p_Worker_Id        IN NUMBER     := NULL ,
              p_Num_Workers      IN NUMBER     := NULL ) ;

  PROCEDURE Start_Event(
              p_Owner            IN VARCHAR2,
              p_Event_Name       IN VARCHAR2,
              p_Context          IN VARCHAR2 := NULL );

  PROCEDURE End_Event(
              p_Owner            IN VARCHAR2,
              p_Event_Name       IN VARCHAR2,
              p_Context          IN VARCHAR2   := NULL );

  FUNCTION Is_Event_Done(
              p_Owner            IN VARCHAR2 ,
	      p_Event_Name       IN VARCHAR2 ,
	      p_Context          IN VARCHAR2   := NULL ,
	      p_Min_Version      IN NUMBER     := NULL ,
	      p_Specific_Version IN NUMBER     := NULL ,
	      p_Worker_Id        IN NUMBER     := NULL ,
	      p_Num_Workers      IN NUMBER     := NULL )
  RETURN   BOOLEAN;

  PROCEDURE Assert_Event(
              p_Owner            IN VARCHAR2 ,
              p_Event_Name       IN VARCHAR2 ,
              p_Context          IN VARCHAR2   := NULL ,
              p_Min_Version      IN VARCHAR2   := NULL ,
              p_Specific_Version IN VARCHAR2   := NULL );

  FUNCTION Check_Min_Completed_Version(
            p_Owner                 IN VARCHAR2 ,
	    p_Event_Name            IN VARCHAR2 ,
	    p_Min_Completed_Version IN NUMBER ,
    	    p_Context               IN VARCHAR2 := NULL )
  RETURN BOOLEAN ;

  FUNCTION Get_Event_Status(
              p_Owner            IN VARCHAR2 ,
              p_Event_Name       IN VARCHAR2 ,
              p_Context          IN VARCHAR2   := NULL ,
              p_Min_Version      IN NUMBER     := NULL ,
              p_Specific_Version IN NUMBER     := NULL )
  RETURN VARCHAR2;

  PROCEDURE Set_Event_Status(
              p_Owner            IN VARCHAR2,
              p_Event_Name       IN VARCHAR2,
	      p_Status           IN VARCHAR2,
              p_Context          IN VARCHAR2  := NULL );

  PROCEDURE   Reset_Event(
              p_Owner            IN VARCHAR2 ,
              p_Event_Name       IN VARCHAR2 ,
      	      p_Module_Name      IN VARCHAR2 ,
              p_Context          IN VARCHAR2 := NULL );

  PROCEDURE Set_Event_As_Done(
             p_Owner             IN VARCHAR2 ,
             p_Event_Name        IN VARCHAR2 ,
	     p_Module_Name       IN VARCHAR2 ,
             p_Context           IN VARCHAR2 := NULL ,
             p_Event_Type        IN VARCHAR2 := NULL ,
             p_Version           IN NUMBER   := NULL ,
             p_Worker_Id         IN NUMBER   := NULL ,
             p_Num_Workers       IN NUMBER   := NULL );
-----------

END Ad_Event_Registry_Pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_EVENT_REGISTRY_PKG" AS
-- $Header: adevntrgb.pls 120.0 2005/05/25 12:03:04 appldev noship $

  -- Event Lock Mode
  EVENT_LOCK_MODE       CONSTANT NUMBER       := DBMS_LOCK.X_MODE;
  -- Constant for Relase on commit option for locks.
  RELEASE_COMMIT_CONST  CONSTANT BOOLEAN      := FALSE ;
  -- Default value of Event Version
  DEFAULT_VERSION       CONSTANT NUMBER       := 1;

  -- Event record type is declared here.
  TYPE Event_Rec_Type IS RECORD(
    Owner            ad_events.owner%TYPE,
    Event_Name       ad_events.event_name%TYPE,
    Event_Context    ad_events.event_context%TYPE,
    Event_Id         ad_events.event_id%TYPE,
    Event_Status     ad_event_versions.status%TYPE,
    -- worker status will be a string indicating status of all the workers
    Worker_Status    ad_event_versions.worker_status%TYPE,
    Event_Version    ad_events.last_version%TYPE,
    Event_Type       ad_events.event_type%TYPE ,
    Module_Name      ad_event_transitions.module_name%TYPE,
    Worker_Id        ad_event_transitions.worker_id%TYPE,
    Max_Workers      ad_event_versions.num_workers%TYPE );

  -- Type of table to store the list of events.
  TYPE Event_Tbl_Type IS TABLE OF Event_Rec_Type INDEX BY BINARY_INTEGER ;

  -- Lock Record
  TYPE Lock_Rec_Type IS RECORD (
    Lock_Name        VARCHAR2 (128),
    Lock_handle      VARCHAR2 (128) );

  -- Lock table type.
  TYPE Lock_Tbl_Type IS TABLE OF Lock_Rec_Type INDEX BY BINARY_INTEGER ;

  -- Global variables are declared here

  -- Table to store the list of events already registered is declared below.
  g_Events_Tbl       Event_Tbl_Type;
  -- Table to store allocated lock details.
  g_Lock_Tbl         Lock_Tbl_Type;

  -- Lock declaration
  g_Event_LockHandle    VARCHAR2(128);
  g_Event_LockName      VARCHAR2(128);

  FUNCTION Get_Event_Index(
              p_Owner      IN VARCHAR2 ,
	      p_Event_Name IN VARCHAR2 ,
	      p_Context    IN VARCHAR2 )
  RETURN NUMBER
  IS
  BEGIN
    --
    -- The function returns 0 if there are no events registered
    -- The function returns 0 if there is no matching event registered so far.
    --
    IF (  g_Events_Tbl.COUNT = 0 ) THEN
      RETURN 0;
    END IF ;
    --
    -- Now check in the Global event list whether an event with the same name
    -- Owner and Context is already registered. If so return the index of the
    -- same. If not return 0.
    --
    FOR i IN g_Events_Tbl.FIRST .. g_Events_Tbl.LAST LOOP
      IF (  g_Events_Tbl(i).Owner         = p_Owner        AND
            g_Events_Tbl(i).Event_Name    = p_Event_Name   AND
	    g_Events_Tbl(i).Event_Context = p_Context    ) THEN
	 RETURN i;
      END IF ;
    END LOOP ;
    -- If there are no matching events return 0.
    RETURN 0;
  END Get_Event_Index;

  PROCEDURE Validate_Globals(
             p_Owner      IN VARCHAR2 ,
	     p_Event_Name IN VARCHAR2 ,
	     p_Context    IN VARCHAR2 )
  IS
    l_Event_Index   NUMBER ;
  BEGIN
   --
   -- Get the index of the event from the global event list.
   -- index value 0 means that the event is not registered in the session.
   --
   l_Event_Index := Get_Event_Index(
                      p_Owner      ,
		      p_Event_Name ,
		      p_Context    );

   IF ( l_Event_Index = 0 ) THEN
     raise_application_error(-20010,'Event Not Initialized');
   END IF ;

  END Validate_Globals;

  PROCEDURE Request_Lock(
              p_Owner       IN VARCHAR2 ,
	      p_Event_Name  IN VARCHAR2 )
  IS
  l_LockName       VARCHAR2(128);
  l_Found          BOOLEAN ;
  l_Temp_Index     BINARY_INTEGER ;
  BEGIN

      -- Construct the lock name.
      l_LockName := p_Owner||'_'||p_Event_Name;

      l_Found := FALSE ;
      IF ( g_Lock_Tbl.COUNT <> 0 ) THEN
      FOR i IN g_Lock_Tbl.FIRST .. g_Lock_Tbl.LAST LOOP
        IF ( g_Lock_Tbl(i).Lock_Name = l_LockName ) THEN
	  g_Event_LockHandle := g_Lock_Tbl(i).Lock_Handle;
	  l_Found := TRUE ;
	  EXIT ;
	END IF ;
      END LOOP ;
      END IF ;

      -- Get the named lock.
      AD_LOCK_UTILS_PKG.Get_Lock(
	             p_LockName          => l_LockName,
	             p_LockMode          => EVENT_LOCK_MODE,
		     p_Release_On_Commit => RELEASE_COMMIT_CONST,
		     x_LockHandle        => g_Event_LockHandle);

      IF ( l_Found = FALSE ) THEN
        l_Temp_Index                         := NVL(g_Lock_Tbl.LAST,0) + 1;
        g_Lock_Tbl(l_Temp_Index).Lock_Name   := l_LockName;
	g_Lock_Tbl(l_Temp_Index).Lock_Handle := g_Event_LockHandle;
      END IF ;
  END Request_Lock;

--------------------------------
-- This is the function to initialize the worker status string.
-- The string will be initialized to Num_workers number of 'N's
--------------------------------
  FUNCTION Initialize_worker_string(
              p_Num_Workers IN NUMBER )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN LPAD ('N',p_Num_Workers,'N');
  END Initialize_worker_string;

---------------------------------
-- This function will set the worker status string, i.e. it will
-- put a 'Y' indicating that the worker has completed
---------------------------------
  PROCEDURE Set_Worker_Status_String(
              p_Worker_Id IN NUMBER ,
	      p_Worker_Status_String IN OUT NOCOPY VARCHAR2 )
  IS
  BEGIN
    p_Worker_Status_String :=
         SUBSTR (p_Worker_Status_String, 1, (p_Worker_Id-1)) ||
         'Y'||
         SUBSTR (p_Worker_Status_String, (p_Worker_Id+1));
  END Set_Worker_Status_String;


---------------------------------
-- This procedure will insert data into the AD_EVENT_TRANSITIONS table.
--
---------------------------------
  PROCEDURE Insert_Event_Transitions(
              p_Event_Id    IN NUMBER ,
	      p_Version     IN NUMBER ,
	      p_New_Status  IN VARCHAR2 ,
	      p_Old_Status  IN VARCHAR2 := NULL ,
	      p_Module_Name IN VARCHAR2 ,
	      p_Worker_Id   IN NUMBER := NULL )
  AS
  BEGIN
    INSERT INTO ad_event_transitions(
                  transition_id,
                  event_id,
                  version,
                  new_status,
                  prior_status,
                  transition_time,
                  module_name,
                  worker_id)
    VALUES (
                  ad_event_transitions_s.NEXTVAL,
                  p_Event_Id,
                  p_Version,
                  p_New_Status,
                  p_Old_Status,
                  SYSDATE ,
                  p_Module_Name,
                  p_Worker_Id);

  END Insert_Event_Transitions;
--------------------------------
-- This procedure is used to perform Basic validations on the parameters
--------------------------------
  PROCEDURE Validate_Parameters(
              p_Owner       IN VARCHAR2 ,
	      p_Event_Name  IN VARCHAR2 ,
	      p_Event_Type  IN VARCHAR2 ,
	      p_Num_Workers IN NUMBER )
  IS
  BEGIN
    IF (p_Owner IS NULL ) THEN
      RAISE_APPLICATION_ERROR(-20010,
           'Error: Value for Owner is passed as NULL.');
    END IF ;
    IF (p_Event_Name IS NULL ) THEN
      RAISE_APPLICATION_ERROR(-20010,
           'Error: Value for Evant Name is passed as NULL .');
    END IF ;
    IF ( p_Event_Type <> BOOLEAN_TYPE AND p_Event_Type <> MULTI_TYPE ) THEN
      RAISE_APPLICATION_ERROR(-20010,
           'Error: Invalid event type : '||p_Event_Type );
    END IF;

    --
    -- If the number of workers is greater than 999 raise an error.
    --
    IF ( NVL(p_Num_Workers ,1 ) > MAX_ALLOWED_WORKERS ) THEN
      RAISE_APPLICATION_ERROR(-20010,
        'Error: Number of workers exceeds the maximum limit.');
    END IF ;

    --
    -- Check whether a multi worker event is initialized with
    -- multiple workers. If so raise an error. This block will
    -- handle all the cases, already registered and new events.
    --
    IF ( p_Event_Type = MULTI_TYPE AND nvl(p_Num_Workers,1) > 1 ) THEN
      RAISE_APPLICATION_ERROR(-20010,'Multi State Events Cannot be '||
	                         'Initialized with multiple Workers');
    END IF;

  END Validate_Parameters;
--------------------------------------------------------------------------
  PROCEDURE Initialize_Event(
              p_Owner       IN VARCHAR2,
              p_Event_Name  IN VARCHAR2,
              p_Module_Name IN VARCHAR2,
              p_Event_Type  IN VARCHAR2   := NULL ,
              p_Context     IN VARCHAR2   := NULL ,
              p_Version     IN NUMBER     := NULL ,
              p_Worker_Id   IN NUMBER     := NULL ,
              p_Num_Workers IN NUMBER     := NULL )
   IS
  -- Local variable declarations
  l_Version               ad_events.last_version%TYPE;
  l_Event_Id              ad_events.event_id%TYPE;
  l_Event_Type            ad_events.event_type%TYPE;
  l_Event_Status          ad_event_versions.status%TYPE;
  l_Worker_Status_String  ad_event_versions.worker_status%TYPE;
  l_Event_Index           NUMBER(3) ;
  l_Commit_Flag           BOOLEAN := FALSE ;

  -- The following variables will be used to store the IN parameter value
  l_p_Event_Type          ad_events.event_type%TYPE;
  l_p_Context             ad_events.event_context%TYPE ;
  l_p_Version             ad_events.last_version%TYPE;

  -- The following variable holds the value of number of workers in the last
  -- call, in case the event fails and restarted this value will be useful.
  l_Prev_Max_Workers      ad_event_versions.num_workers%TYPE ;
  l_Error_Message         VARCHAR2 (100);

  BEGIN  -- Begin Procedure
    --
    -- The following block is used to take care of the default values
    -- Change done for file.sql.35
    --
    l_p_Event_Type := nvl(p_Event_Type, BOOLEAN_TYPE);
    l_p_Context    := nvl(p_Context, DEFAULT_CONTEXT);
    l_p_Version    := nvl(p_Version, DEFAULT_VERSION);

    --
    -- Call the procedure for validating the parameters
    --
    Validate_Parameters(
                 p_Owner       => p_Owner ,
		 p_Event_Name  => p_Event_Name ,
		 p_Event_Type  => l_p_Event_Type,
		 p_Num_Workers => p_Num_Workers);

    --
    -- Request for the lock
    --
    Request_Lock(p_Owner,
                   p_Event_Name);

    BEGIN -- Block 1

      -- Select the details of the event for the passed parameters.
      SELECT last_version,
             event_id,
             event_type
      INTO   l_Version,
             l_Event_Id,
             l_Event_Type
      FROM   ad_events
      WHERE  owner         = p_Owner
      AND    event_name    = p_Event_Name
      AND    event_context = l_p_Context;

      --
      -- Compare the event type in the database with that in the call.
      -- If both doesn't match raise an error.
      --
      IF ( l_Event_Type <> l_p_Event_Type ) THEN
        RAISE_APPLICATION_ERROR (-20010,'Event initialized with a '||
	                                'wrong Type');
      END IF ;

      --
      -- The following block is to make sure that an already registered
      -- multi state event is not initialized with multiple workers.
      --
      IF ( l_Event_Type = MULTI_TYPE AND nvl(p_Num_Workers,0) > 1 ) THEN
        RAISE_APPLICATION_ERROR (-20010,'Multi State Event Cannot be '||
	                         'Initialized with multiple Workers');
      END IF;

      IF ( l_Version < l_p_Version ) THEN -- If 1 to check version
        --
	-- Get the worker status string
	--
	l_Worker_Status_String := Initialize_Worker_String(p_Num_Workers);
        --
        -- I.e. A version with a lesser version number exists.
        -- A higher version is being registered.
	-- It has to be inserted into AD_EVENT_VERSIONS.
	--
        INSERT INTO ad_event_versions(
	             event_id,
	             version,
	             status,
		     creation_date,
		     last_update_date,
		     num_workers,
		     worker_status)
        VALUES(      l_Event_Id,
	             l_p_Version,
	             INITIALIZED_STATUS,
                     SYSDATE ,
		     SYSDATE,
		     p_Num_Workers,
		     l_Worker_Status_String)
	RETURNING    status
	INTO         l_Event_Status ;

	--
	-- If event with lesser version number exists; version and last
	-- update date are updated in AD_EVENTS
	--
	UPDATE ad_events
	SET    last_version     = l_p_Version,
               last_update_date = SYSDATE
	WHERE  event_id         = l_Event_Id;

	l_Commit_Flag      := TRUE ; -- Committing the transaction here.
	l_Prev_Max_Workers := p_Num_Workers;
      ELSE -- else to check version
        BEGIN --Block 2
 	  --
	  -- The control comes here when the event is already
	  -- registered and the version is greater than or equal to p_Version
	  --
	  SELECT status,
	         worker_status,
		 num_workers
	  INTO   l_Event_Status,
	         l_Worker_Status_String,
		 l_Prev_Max_Workers
	  FROM   ad_Event_Versions
	  WHERE  event_id = l_Event_Id
	  AND    version  = l_p_Version;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR (-20010,'Event with version '||
	              l_p_Version||' not registered. ');
        END; --End of Block2
      END IF; -- End If 1 to check version

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       -- No Events with the same Owner,Name,Context are registered so far.
       -- New Event can be registered Now.
       INSERT INTO ad_events(
                    event_id,
		    owner,
                    event_name,
		    event_context,
		    event_type,
		    last_version,
                    creation_date,
		    last_update_date)
       VALUES(
                    ad_events_s.NEXTVAL,
		    p_Owner,
                    p_Event_Name,
		    l_p_Context,
		    l_p_Event_Type,
		    l_p_Version,
                    SYSDATE,
		    SYSDATE  )
       RETURNING   event_id
       INTO        l_Event_Id;

       -- Insert the version details into AD_EVENT_VERSIONS
       --
       -- Form the worker status string
       --
       l_Worker_Status_String := Initialize_Worker_String(p_Num_Workers);

       INSERT INTO ad_event_versions(
                    event_id,
		    version,
		    status,
                    creation_date,
		    last_update_date,
		    num_workers,
		    worker_status)
       VALUES(
                    l_Event_Id,
		    l_p_Version,
		    INITIALIZED_STATUS,
                    SYSDATE,
		    SYSDATE,
		    p_Num_Workers,
		    l_Worker_Status_String);

       l_Commit_Flag      := TRUE ;
       -- Argument event type will be the type of the new event.
       l_Event_Type       := l_p_Event_Type;
       -- For new event, status will be initialized status
       l_Event_Status     := INITIALIZED_STATUS;
       l_Prev_Max_Workers := p_Num_Workers;
     WHEN OTHERS THEN
       RAISE ;
    END; -- End of Block 1

    --
    -- If the event is already initialized in the session it is not required
    -- to add the same to the global event list again.
    -- The below function call gets the index of the event from the
    -- global event list, if the event is already registered in the session.
    -- Ideally the function call should return 0.
    --
    l_Event_Index   := Get_Event_Index(
                                        p_Owner      => p_Owner,
					p_Event_Name => p_Event_Name ,
					p_Context    => l_p_Context);

    --
    -- For new events add the event details to the end of
    -- the global event list. For already registered events update the
    -- details in the global event list.
    --
    -- For new events the index value returned by the above call will be 0
    IF ( l_Event_Index = 0 ) THEN
      l_Event_Index := NVL(g_Events_Tbl.LAST,0) + 1;
      g_Events_Tbl(l_Event_Index).Owner         := p_Owner;
      g_Events_Tbl(l_Event_Index).Event_Name    := p_Event_Name;
      g_Events_Tbl(l_Event_Index).Event_Context := l_p_Context;
      g_Events_Tbl(l_Event_Index).Event_Id      := l_Event_Id;
      g_Events_Tbl(l_Event_Index).Event_Status  := l_Event_Status;
      g_Events_Tbl(l_Event_Index).Worker_Status := l_Worker_Status_String;
      g_Events_Tbl(l_Event_Index).Event_Version := l_p_Version;
      g_Events_Tbl(l_Event_Index).Event_Type    := l_Event_Type;
      g_Events_Tbl(l_Event_Index).Module_Name   := p_Module_Name;
      g_Events_Tbl(l_Event_Index).Worker_Id     := p_Worker_Id;
      g_Events_Tbl(l_Event_Index).Max_Workers   := p_Num_Workers;
    ELSE
      g_Events_Tbl(l_Event_Index).Event_Version := l_p_Version;
      g_Events_Tbl(l_Event_Index).Event_Status  := l_Event_Status; -- check this
      g_Events_Tbl(l_Event_Index).Module_Name   := p_Module_Name;
      g_Events_Tbl(l_Event_Index).Worker_Id     := p_Worker_Id;
      g_Events_Tbl(l_Event_Index).Max_Workers   := p_Num_Workers;
    END IF ;

    --
    -- If the multi-worker event fails before completion,
    -- and gets re-started with a different number of workers then
    -- the worker information in the db and session has to be updated.
    --
    IF ( l_Event_Status <> COMPLETED_STATUS -- If worker re-schedule
    AND NVL (l_Prev_Max_Workers,1) <> NVL (p_Num_Workers,1) ) THEN
       --
       -- Form the worker status string
       --
       g_Events_Tbl(l_Event_Index).Worker_Status :=
			Initialize_Worker_String(p_Num_Workers);
       -- reset the worker status string and number_workers
       -- in ad_event_versions
       UPDATE ad_event_versions
       SET num_workers      = p_Num_Workers,
	   worker_status    = g_Events_Tbl(l_Event_Index).Worker_Status ,
	   last_update_date = SYSDATE
       WHERE event_id = l_Event_Id
       AND   version  = l_p_Version ;

       -- Inserting a record into the transition record to show that
       -- a rescheduling has happened for the event.
       Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_p_Version,
	      p_New_Status  => 'RE-SCHEDULED',
	      p_Old_Status  => l_Event_Status,
	      p_Module_Name => p_Module_Name,
	      p_Worker_Id   => p_Worker_Id);

	-- Set the commit flag
	l_Commit_Flag := TRUE ;
    END IF ; -- End If worker re-schedule
    -- Commit the transaction if the commit flag is set
    IF ( l_Commit_Flag = TRUE ) THEN
      COMMIT ;
    END IF ;

    --
    -- Release the lock
    --
    AD_LOCK_UTILS_PKG.Release_Lock(
                     p_LockHandle => g_Event_LockHandle);

    g_Event_LockHandle := NULL ;

   EXCEPTION
    WHEN OTHERS THEN
     IF ( g_Event_LockHandle IS NOT NULL ) THEN
       BEGIN -- begin for release lock
	    AD_LOCK_UTILS_PKG.Release_Lock(
		             p_LockHandle => g_Event_LockHandle);
	    g_Event_LockHandle := NULL ;
       EXCEPTION
        WHEN OTHERS THEN
	 NULL ;
       END ; -- end for release lock
     END IF ;
     RAISE ;
  END Initialize_Event;
--------------------------------------------------------------------------

  PROCEDURE Start_Event(
              p_Owner       IN VARCHAR2,
              p_Event_Name  IN VARCHAR2,
              p_Context     IN VARCHAR2 := NULL
  )
  IS
    l_Event_Status         ad_event_versions.status%TYPE;
    l_Event_type           ad_events.event_type%TYPE;
    l_Event_Id             ad_events.event_id%TYPE;
    l_Version              ad_event_versions.version%TYPE;
    l_Worker_Id            ad_event_transitions.worker_id%TYPE ;
    l_Worker_Status_String ad_event_versions.worker_status%TYPE ;
    l_Module_Name          ad_event_transitions.module_name%TYPE ;
    l_Event_Index          NUMBER ;
    -- this variable is used to hold in the IN parameter
    l_p_Context            ad_events.event_context%TYPE ;
  BEGIN
   --
   -- The below block checks the value of parameter p_Contect
   -- if the value is null, it is assumed that the value is default value.
   -- the change was done for file.sql.35
   --
   l_p_Context := nvl(p_Context, DEFAULT_CONTEXT);

   --
   -- The following call checks whether the event is initialized
   -- Compares the global variable values with the values in
   -- the current call also.
   --
   Validate_Globals(p_Owner,
                    p_Event_Name,
		    l_p_Context);
   --
   -- Now get the index of the current event from the global event list.
   -- Use this index value to access the other event details.
   --
   l_Event_Index := Get_Event_Index(
                                     p_Owner,
				     p_Event_Name,
				     l_p_Context);
   BEGIN -- Block 1
     --
     -- we are not going to select the event details from db.
     -- get it from the global event list in the session.
     --
     l_Event_Status         := g_Events_Tbl(l_Event_Index).Event_Status;
     l_Event_type           := g_Events_Tbl(l_Event_Index).Event_Type;
     l_Event_Id             := g_Events_Tbl(l_Event_Index).Event_id;
     l_Version              := g_Events_Tbl(l_Event_Index).Event_Version;
     l_Worker_Id            := g_Events_Tbl(l_Event_Index).Worker_Id;
     l_Worker_Status_String := g_Events_Tbl(l_Event_Index).Worker_Status;
     l_Module_Name          := g_Events_Tbl(l_Event_Index).Module_Name;

     IF ( NVL(g_Events_Tbl(l_Event_Index).Max_Workers,1) > 1
        AND SUBSTR(l_Worker_Status_String, l_Worker_Id,1) = 'Y' ) THEN
     -- If worker status
       --
       -- The worker has already completed.
       --
       RAISE_APPLICATION_ERROR(-20010,'Worker has completed already.');
     END IF ; --end if worker status

     IF ( l_Event_Status = COMPLETED_STATUS ) THEN -- if event status
       --
       -- The Event is already completed, so it is not possible
       -- to start the same.
       --
       RAISE_APPLICATION_ERROR(-20010,'Event is Already Completed');
     ELSIF ( l_Event_Status = INITIALIZED_STATUS ) THEN --else if event status
       --
       -- Update the start time and last update date in AD_EVENT_VERSIONS.
       --
       UPDATE ad_event_versions
       SET start_time       = SYSDATE ,
           last_update_date = SYSDATE
       WHERE event_id = l_Event_Id
       AND   version  = l_Version;
       --
       -- Whenver an Event is getting started
       -- an entry is inserted into AD_EVENT_TRANSITIONS with
       -- old status NULL and new status as Initialized status.
       --
       Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_Version,
	      p_New_Status  => INITIALIZED_STATUS,
	      p_Module_Name => l_Module_Name,
	      p_Worker_Id   => l_Worker_Id);

     ELSE -- else if event status
       --
       -- The event is in some status other than completed and initialized.
       -- It means that event is already started, so it is not possible to
       -- start the same once again.
       --
       RAISE_APPLICATION_ERROR (-20010,'Invalid Event Status. '||
                                       'Not possible to start.');
     END IF; -- end if event status
   END; -- End Block 1
   COMMIT ;
  END Start_Event;

  ---------------------------------------------------------------------------

  Procedure End_Event(
              p_Owner       IN VARCHAR2,
              p_Event_Name  IN VARCHAR2,
              p_Context     IN VARCHAR2 := NULL
  )
  IS
    l_Event_Status          ad_event_versions.status%TYPE;
    l_New_Status            ad_event_versions.status%TYPE;
    l_Event_type            ad_events.event_type%TYPE;
    l_Event_Id              ad_events.event_id%TYPE;
    l_Version               ad_event_versions.version%TYPE;
    l_Worker_Status_String  ad_event_versions.worker_status%TYPE;
    l_End_Time              DATE ;
    l_Max_Workers           ad_event_versions.num_workers%TYPE ;
    l_Worker_Id             ad_event_transitions.worker_id%TYPE ;
    l_Module_Name           ad_event_transitions.module_name%TYPE ;
    -- the following variable stores the index that points to the current
    -- event's record in the event list
    l_Event_Index           NUMBER ;
    -- this variable is used to hold in the IN parameter
    l_p_Context            ad_events.event_context%TYPE ;

  BEGIN -- begin procedure
   --
   -- The below block checks the value of parameter p_Contect
   -- if the value is null, it is assumed that the value is default value.
   -- the change was done for file.sql.35
   --
   l_p_Context    := nvl(p_Context, DEFAULT_CONTEXT);

   --
   -- The following call checks whether the event is initialized
   -- in the current session
   --
   Validate_Globals(p_Owner,
                    p_Event_Name,
		    l_p_Context);
   --
   -- Get the index of the event from the global event list
   --
   l_Event_Index := Get_Event_Index(p_Owner,
                                    p_Event_Name,
                                    l_p_Context);

   -- Now get the details from the global event list
   l_Max_Workers := g_Events_Tbl(l_Event_Index).Max_Workers;
   l_Worker_Id   := g_Events_Tbl(l_Event_Index).Worker_Id;
   l_Module_Name := g_Events_Tbl(l_Event_Index).Module_Name;

   BEGIN -- Block 1
     --
     -- Request for the lock.
     --
     Request_Lock(p_Owner,
                  p_Event_Name);

     --
     -- Select the details of the event joining AD_EVENTS and
     -- AD_EVENT_VERSIONS by joining using the version.
     --

     SELECT status,
            event_type,
	    ae.event_id,
	    av.version,
	    worker_status
     INTO   l_Event_Status,
            l_Event_type,
	    l_Event_Id,
	    l_Version,
	    l_Worker_Status_String
     FROM   ad_events ae, ad_event_versions av
     WHERE  ae.event_id      = av.event_id
     AND    ae.last_version  = av.version
     AND    ae.owner         = p_Owner
     AND    ae.event_name    = p_Event_Name
     AND    ae.event_context = l_p_Context;

     IF ( l_Event_Status = COMPLETED_STATUS ) THEN -- if status check
       --
       -- The event is already completed so no need to end the same again.
       --
       RAISE_APPLICATION_ERROR(-20010,'Event is Already Completed.');
     ELSE  -- else status check
       --
       -- The below if block is for checking multi-worker events.
       --
       IF ( NVL(l_Max_Workers,0) > 1 ) THEN  -- if max workers

         --
	 -- Copy the current status of the event to l_New_Status.
	 --
         l_New_Status := l_Event_Status;

	 --
	 -- Worker status uses positional characters to indicate
	 -- status of a worker.
	 -- Form the new worker status string by changing 'N' to 'Y'
	 -- at the proper position for the worker in the string.
	 --
	 Set_Worker_Status_String (l_Worker_Id,
	                           l_Worker_Status_String);

	 --
	 -- Check whether all the workers are completed.
	 -- If there are no 'N's in the new worker status string it means
	 -- that all the workers have completed.
	 -- So set the new worker status as completed status.
	 -- otherwise status remains as the old status.
	 --
	 IF ( INSTR(l_Worker_Status_String,'N') = 0 ) THEN
	   l_New_Status := COMPLETED_STATUS;
	   l_End_Time   := SYSDATE;
	 END IF;

         UPDATE  ad_event_versions
	 SET     status           = l_New_Status,
	         end_time         = l_End_Time,
	         last_update_date = SYSDATE ,
                 worker_status    = l_Worker_Status_String
	 WHERE   event_id   = l_Event_Id
         AND     version    = l_Version;

         --
         -- The below block is for inserting the event transition records
         -- for multi-worker events.
         -- The transition records will be inserted only when the event is
         -- completed. In case of multi-worker events, Event gets completed
         -- only when all the workers are completed.
         --
         IF ( l_New_Status = COMPLETED_STATUS )THEN -- if for completed status
           Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_Version,
	      p_New_Status  => l_New_Status,
	      p_Old_Status  => l_Event_Status,
	      p_Module_Name => l_Module_Name,
	      p_Worker_Id   => l_Worker_Id);

         END IF; -- end if for completed status

	 -- Commit the transaction here
         COMMIT;

       ELSE  -- else max workers
         --
	 -- Single worker events.
	 -- New status will be - completed status.
	 --
	 l_New_Status := COMPLETED_STATUS;

         UPDATE   ad_event_versions
         SET      status           = l_New_Status,
                  end_time         = SYSDATE ,
                  last_update_date = SYSDATE
         WHERE    event_id   = l_Event_Id
         AND      version    = l_Version;

         --
         -- The below block is for inserting the event transition records
         -- for single-worker events.
         -- The transition records will be inserted only when the event is
         -- completed.
         --
           Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_Version,
	      p_New_Status  => l_New_Status,
	      p_Old_Status  => l_Event_Status,
	      p_Module_Name => l_Module_Name);

	 -- Commit the transaction here
         COMMIT;

       END IF; -- End if max workers

       --
       -- Set the global variables
       --
       g_Events_Tbl(l_Event_Index).Event_Status  := l_New_Status;
       g_Events_Tbl(l_Event_Index).Worker_Status := l_Worker_Status_String;


     END IF;   -- End if status check
     --
     -- Release the lock.
     -- The lock is released only after doing all the DMLs
     -- and the commit
     --
     AD_LOCK_UTILS_PKG.Release_Lock(
                    p_LockHandle => g_Event_LockHandle);

    g_Event_LockHandle := NULL ;

   EXCEPTION
    WHEN OTHERS THEN
     RAISE ;
   END; -- End Block 1
  EXCEPTION
    WHEN OTHERS THEN
     IF ( g_Event_LockHandle IS NOT NULL ) THEN
       BEGIN -- begin for release lock
	    AD_LOCK_UTILS_PKG.Release_Lock(
		             p_LockHandle => g_Event_LockHandle);
	    g_Event_LockHandle := NULL ;
       EXCEPTION
        WHEN OTHERS THEN
	 NULL ;
       END ; -- end for release lock
     END IF ;
     RAISE ;
  END End_Event;
--------------------------------------------------------------------------
  FUNCTION Check_Min_Completed_Version(
            p_Owner                 IN VARCHAR2 ,
	    p_Event_Name            IN VARCHAR2 ,
	    p_Min_Completed_Version IN NUMBER ,
    	    p_Context               IN VARCHAR2 := NULL )
  RETURN BOOLEAN
  IS
    -- Local Variables
    l_Temp_Var       NUMBER ;
    l_Return_Status  BOOLEAN ;
    -- this variable is used to hold in the IN parameter
    l_p_Context      ad_events.event_context%TYPE ;

  BEGIN
    --
    -- If NULL is passed as the context assume the value to be DEFAULT
    l_p_Context    := nvl(p_Context, DEFAULT_CONTEXT);

    --
    -- Set the return status to false
    l_Return_Status := FALSE ;

    --
    -- Select the status, version of the versions higher than or equal to
    -- the p_Min_Completed_Version.
    -- if any of these versions are completed, it means that the event is
    -- completed to atleast that level. hence return TRUE
    -- Else return FALSE
    --
    SELECT 1
    INTO   l_Temp_Var
    FROM   ad_events ae,
           ad_Event_Versions av
    WHERE  ae.owner = p_Owner
    AND    ae.event_name = p_Event_Name
    AND    ae.event_context = l_p_Context
    AND    ae.event_id = av.event_id
    AND    av.version >= p_Min_Completed_Version
    AND    av.status = COMPLETED_STATUS
    AND    ROWNUM < 2;

    l_Return_Status := TRUE ;

    RETURN l_Return_Status;

   EXCEPTION
    --
    -- When the select returns no rows it means that there are no versions
    -- matching the IN parameters. Return FALSE
    --
    WHEN NO_DATA_FOUND THEN
     RETURN l_Return_Status ;
  END Check_Min_Completed_Version;
--------------------------------------------------------------------------

  FUNCTION Is_Event_Done(
            p_Owner             IN VARCHAR2 ,
	    p_Event_Name        IN VARCHAR2 ,
	    p_Context           IN VARCHAR2 := NULL ,
	    p_Min_Version       IN NUMBER   := NULL ,
	    p_Specific_Version  IN NUMBER   := NULL ,
	    p_Worker_Id         IN NUMBER   := NULL ,
	    p_Num_Workers       IN NUMBER   := NULL )
  RETURN   BOOLEAN
  IS
    -- Local variable declarations.
    l_Event_Status           ad_event_versions.status%TYPE;
    l_Worker_Status_String   ad_event_versions.worker_status%TYPE;
    l_Num_Workers            ad_event_versions.num_workers%TYPE;
    l_Return_Status          BOOLEAN;
    l_Event_Version          ad_event_versions.version%TYPE;
    -- this variable is used to hold in the IN parameter
    l_p_Context            ad_events.event_context%TYPE ;

  BEGIN
    --
    -- The below block checks the value of parameter p_Contect
    -- if the value is null, it is assumed that the value is default value.
    -- the change was done for file.sql.35
    --
    l_p_Context    := nvl(p_Context, DEFAULT_CONTEXT);

    --
    -- The user can specify either a Minimum version or a Specific version
    -- only. Both should not be used in the same call.
    -- Raise an error if both are specified.
    --
    IF ( p_Min_Version IS NOT NULL AND p_Specific_Version IS NOT NULL ) THEN
      RAISE_APPLICATION_ERROR(-20010,'Minimum version and Specific version '||
                              'should not be used together.');
    END IF ;

    --
    -- Select the details of the event based on the input details.
    -- Since the event id is available in AD_EVENTS only AD_EVENTS and
    -- AD_EVENT_VERSIONS are joined on this column.
    -- If a specific version is supplied use that version in the where
    -- clause otherwise use the last_version column of ad_events.
    --
    SELECT av.status,
           av.worker_status,
           av.version,
	   av.num_workers
    INTO   l_Event_Status,
           l_Worker_Status_String,
           l_Event_Version,
	   l_Num_Workers
    FROM   ad_events ae,
           ad_event_versions av
    WHERE  ae.owner         = p_Owner
    AND    ae.event_name    = p_Event_Name
    AND    ae.event_context = l_p_Context
    AND    av.event_id      = ae.event_id
    AND    av.version       = NVL(p_Specific_Version,ae.last_version);

    --
    -- If the current version of the event is less than
    -- the min version required, return FLASE.
    --
    IF ( l_Event_Version < NVL(p_Min_Version, l_Event_Version) ) THEN
       RETURN FALSE;
    END IF;

    --
    -- If the event status is completed return TRUE
    -- for both multi-worker and single worker events.
    --
    IF ( l_Event_Status = COMPLETED_STATUS ) THEN -- if event completed
        l_Return_Status := TRUE;
    ELSE -- else event completed
        IF ( NVL(l_Num_Workers,1) > 1 ) THEN -- if num workers
	    --
            -- if number of workers does not match in the current run and
            -- prior run, return FALSE irrespective of the individual
            -- worker status.
            --
            IF ( p_Worker_Id IS NOT NULL
	    AND NVL(p_Num_Workers, 1) = NVL(l_Num_Workers, 1)
            AND SUBSTR(l_Worker_Status_String,p_Worker_Id,1) = 'Y' ) THEN
            -- If worker done
                --
                -- The control comes here when the number of workers is > 1
                -- and the the corresponding worker is completed.
                -- worker status 'Y' indicated that worker is completed.
                --
                l_Return_Status := TRUE;
            ELSE -- else worker done
                l_Return_Status := FALSE;
            END IF; -- end if worker done
        ELSE -- else num workers
            --
            -- The control comes here when the event is not completed and
            -- the number of workers is 1.
            -- So return false.
            --
            l_Return_Status := FALSE;
        END IF; -- end if num workers
    END IF; -- end if event completed

    RETURN l_Return_Status;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END Is_Event_Done ;

--------------------------------------------------------------------------

  PROCEDURE Assert_Event(
              p_Owner            IN VARCHAR2 ,
              p_Event_Name       IN VARCHAR2 ,
              p_Context          IN VARCHAR2 := NULL ,
              p_Min_Version      IN VARCHAR2 := NULL ,
              p_Specific_Version IN VARCHAR2 := NULL )
  IS
    v_Event_Status BOOLEAN ;
    -- this variable is used to hold in the IN parameter
    l_p_Context            ad_events.event_context%TYPE ;
  BEGIN
    --
    -- The below block checks the value of parameter p_Contect
    -- if the value is null, it is assumed that the value is default value.
    -- the change was done for file.sql.35
    --
    l_p_Context    := nvl(p_Context, DEFAULT_CONTEXT);
    --
    -- Is_Event_Done function is called to check whether the event is done.
    -- If not raise an error.
    --
    v_Event_Status := Is_Event_Done(
                        p_Owner,
                        p_Event_Name,
                        l_p_Context,
                        p_Min_Version,
                        p_Specific_Version,
                        NULL,
                        NULL );
    IF ( v_Event_Status = FALSE ) THEN
      RAISE_APPLICATION_ERROR(-20007,'The event is not completed');
    END IF ;
  END Assert_Event ;

--------------------------------------------------------------------------

  FUNCTION Get_Event_Status(
             p_Owner            IN VARCHAR2 ,
             p_Event_Name       IN VARCHAR2 ,
             p_Context          IN VARCHAR2 := NULL ,
             p_Min_Version      IN NUMBER   := NULL ,
             p_Specific_Version IN NUMBER   := NULL )
  RETURN VARCHAR2
  IS
    l_Status        ad_event_versions.status%TYPE;
    l_Event_Version ad_event_versions.version%TYPE;
    -- this variable is used to hold in the IN parameter
    l_p_Context            ad_events.event_context%TYPE ;
  BEGIN
    --
    -- The below block checks the value of parameter p_Contect
    -- if the value is null, it is assumed that the value is default value.
    -- the change was done for file.sql.35
    --
    l_p_Context    := nvl(p_Context, DEFAULT_CONTEXT);

    --
    -- The user can specify either a Minimum version or a Specific version
    -- only. Both should not be used in the same call.
    -- Raise an error if both are specified.
    --
    IF ( p_Min_Version IS NOT NULL AND p_Specific_Version IS NOT NULL ) THEN
      RAISE_APPLICATION_ERROR(-20010,'Minimum version and Specific version '||
                              'should not be used together.');
    END IF ;

    --
    -- Select the details from the db.
    -- If a specific version is supplied then select the details foe the same.
    -- Otherwise select the details of the version pointed by AD_EVENTS.
    --
    SELECT av.status,
           av.version
    INTO   l_Status,
           l_Event_Version
    FROM
           ad_events ae,
           ad_event_versions av
    WHERE  ae.owner         = p_Owner
    AND    ae.event_name    = p_Event_Name
    AND    ae.event_context = l_p_Context
    AND    av.event_id      = ae.event_id
    AND    av.version       = NVL(p_Specific_Version, ae.last_version);

    --
    -- If the minimum version of the event required is greater than the
    -- current version, then return EVENT_NOT_DEFINED.
    -- Else return the current status.
    --
    IF ( l_Event_Version < p_Min_Version ) THEN
      RETURN EVENT_NOT_DEFINED;
    ELSE
      RETURN l_Status;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN EVENT_NOT_DEFINED;
  END Get_Event_Status ;

--------------------------------------------------------------------------

  PROCEDURE Set_Event_Status(
              p_Owner      IN VARCHAR2,
              p_Event_Name IN VARCHAR2,
	      p_Status     IN VARCHAR2,
              p_Context    IN VARCHAR2  := NULL )
  IS
    l_Event_Status      ad_event_versions.status%TYPE;
    l_Num_Workers       ad_event_versions.num_workers%TYPE;
    l_Event_Id          ad_event_versions.event_id%TYPE;
    l_Version           ad_event_versions.version%TYPE;
    l_Event_Index       NUMBER ;
    l_Event_Type        ad_events.event_type%TYPE ;
    l_Module_Name       ad_event_transitions.module_name%TYPE ;
    l_Worker_Id         ad_event_transitions.worker_id%TYPE ;
    -- this variable is used to hold in the IN parameter
    l_p_Context         ad_events.event_context%TYPE ;
  BEGIN
    --
    -- The below block checks the value of parameter p_Contect
    -- if the value is null, it is assumed that the value is default value.
    -- the change was done for file.sql.35
    --
    l_p_Context    := nvl(p_Context, DEFAULT_CONTEXT);

    IF ( p_Status = COMPLETED_STATUS ) THEN
      RAISE_APPLICATION_ERROR(-20010,'Set_Event_Status cannot be used to '||
                              'complete an Event');
    END IF;

   --
   -- The following call checks whether the event is initialized
   -- and compares the global variable values with the values in
   -- the current call also.
   --
   Validate_Globals(p_Owner,
                    p_Event_Name,
		    l_p_Context);
    --
    -- Now get the index value for the current event from the global
    -- event list
    --
    l_Event_Index := Get_Event_Index( p_Owner,
                                      p_Event_Name,
				      l_p_Context);

     --
     -- now get the details from the global events table
     --
     l_Event_Type   := g_Events_Tbl(l_Event_Index).Event_Type;
     l_Event_Status := g_Events_Tbl(l_Event_Index).Event_Status;
     l_Num_Workers  := g_Events_Tbl(l_Event_Index).Max_Workers;
     l_Event_Id     := g_Events_Tbl(l_Event_Index).Event_Id;
     l_Version      := g_Events_Tbl(l_Event_Index).Event_Version;
     l_Module_Name  := g_Events_Tbl(l_Event_Index).Module_Name;
     l_Worker_Id    := g_Events_Tbl(l_Event_Index).Worker_Id;

    --
    -- If the type of the event is boolean raise an error.
    -- Because for boolean events there are no intermediate states to be set.
    --
    IF ( l_Event_Type = BOOLEAN_TYPE ) THEN
      RAISE_APPLICATION_ERROR (-20010,'Set_Event_Status not applicable to '||
                               'boolean events.');
    END IF;

    --
    -- This block checks whether the event is a multi-worker event.
    --
    IF ( NVL(l_Num_Workers,1) > 1 ) THEN
      RAISE_APPLICATION_ERROR (-20010,'Set_Event_Status not applicable to '||
                                      'multi-worker events.');
    END IF ;

    --
    -- If already the status is completed return error.
    --
    IF ( l_Event_Status = COMPLETED_STATUS ) THEN
      RAISE_APPLICATION_ERROR(-20010,'Event is Already Completed');
    END IF;

    --
    -- If number of workers is greater then 1 raise an error.
    --
    IF ( nvl(l_Num_Workers,1) > 1 ) THEN
      RAISE_APPLICATION_ERROR (-20010,'Set_Event_Status not applicable to '||
                                      'multi-worker events.');
    END IF;

    -- Request for the lock
    Request_Lock(p_Owner,
                 p_Event_Name);
    --
    -- Validations are thru. Now update the status.
    --
    UPDATE ad_event_versions
    SET    status = p_Status,
           last_update_date = SYSDATE
    WHERE  event_id = l_Event_Id
    AND    version  = l_Version;

    --
    -- Insert the event transition entries
    --
    Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_Version,
	      p_New_Status  => p_Status,
	      p_Old_Status  => l_Event_Status,
	      p_Module_Name => l_Module_Name,
	      p_Worker_Id   => l_Worker_Id);

    --Set the global values here
    g_Events_Tbl(l_Event_Index).Event_Status := p_Status;

    -- commit the transaction here
    COMMIT;
    -- Release the lock.
    AD_LOCK_UTILS_PKG.Release_Lock(
                     p_LockHandle => g_Event_LockHandle);

    g_Event_LockHandle := NULL ;

   EXCEPTION
    WHEN OTHERS THEN
     IF ( g_Event_LockHandle IS NOT NULL ) THEN
       BEGIN -- begin for release lock
	    AD_LOCK_UTILS_PKG.Release_Lock(
		             p_LockHandle => g_Event_LockHandle);
	    g_Event_LockHandle := NULL ;
       EXCEPTION
        WHEN OTHERS THEN
	 NULL ;
       END ; -- end for release lock
     END IF ;
     RAISE ;
  END Set_Event_Status ;


--------------------------------------------------------------------------

  PROCEDURE   Reset_Event(
              p_Owner       IN VARCHAR2 ,
              p_Event_Name  IN VARCHAR2 ,
      	      p_Module_Name IN VARCHAR2 ,
              p_Context     IN VARCHAR2 := NULL )
  IS
    l_Event_Id             ad_event_versions.event_id%TYPE;
    l_Event_Version        ad_event_versions.version%TYPE;
    l_Event_Status         ad_event_versions.status%TYPE;
    l_Max_Workers          ad_event_versions.num_workers%TYPE ;
    l_Worker_Status_String ad_event_versions.worker_status%TYPE;
    l_Worker_Id            ad_event_transitions.worker_id%TYPE ;
    l_Module_Name          ad_event_transitions.module_name%TYPE ;
    l_Event_Index          NUMBER ;
    -- this variable is used to hold in the IN parameter
    l_p_Context         ad_events.event_context%TYPE ;

  BEGIN  -- begin procedure
    --
    -- The below block checks the value of parameter p_Contect
    -- if the value is null, it is assumed that the value is default value.
    -- the change was done for file.sql.35
    --
    l_p_Context    := nvl(p_Context, DEFAULT_CONTEXT);

    l_Module_Name := p_Module_Name;
    l_Worker_Id   := NULL ;

    --
    -- Request the lock.
    --
    Request_Lock(p_Owner,
                 p_Event_Name);

    --
    -- Select the event id and the version from AD_EVENTS.
    --
    SELECT ae.event_id,
           ae.last_version,
           av.status,
	   av.num_workers
    INTO   l_Event_Id,
           l_Event_Version,
           l_Event_Status,
	   l_Max_Workers
    FROM   ad_events ae, ad_event_versions av
    WHERE  ae.owner         = p_Owner
    AND    ae.event_name    = p_Event_Name
    AND    ae.event_context = l_p_Context
    AND    av.event_id      = ae.event_id
    AND    av.version       = ae.last_version;

    IF ( l_Event_Status = INITIALIZED_STATUS ) THEN
      RAISE_APPLICATION_ERROR ( -20010,'The event is already in '||
                               'Initialized status, Not possible to reset');
    END IF ;
    --
    -- The validations are through, now reset the event information.
    --
    -- Form the worker status string
    l_Worker_Status_String := Initialize_Worker_String(l_Max_Workers);

    UPDATE ad_event_versions
    SET    status           = INITIALIZED_STATUS,
           start_time       = NULL ,
           end_time         = NULL ,
           last_update_date = SYSDATE ,
           worker_status    = LPAD('N',l_Max_Workers,'N')
    WHERE  event_id = l_Event_Id
    AND    version  = l_Event_Version;

    -- Insert the event transition entry.
    Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_Event_Version,
	      p_New_Status  => INITIALIZED_STATUS,
	      p_Old_Status  => l_Event_Status,
	      p_Module_Name => l_Module_Name,
	      p_Worker_Id   => l_Worker_Id);

    -- Commit the transaction here.
    COMMIT;

    --
    -- Release the lock.
    --
    AD_LOCK_UTILS_PKG.Release_Lock(
                     p_LockHandle => g_Event_LockHandle);
    g_Event_LockHandle := NULL ;

    -- Get the index pointing to the event from the global event list
    -- This step will be useful in case an event is reset in the same
    -- session which has initialized the event.
    l_Event_Index := Get_Event_Index(p_Owner,
                                     p_Event_Name,
				     l_p_Context);
    -- If the event is initialized in the session the index value
    -- will be non-zero.
    IF l_Event_Index <> 0 THEN
      -- Set the package global event list values
      g_Events_Tbl(l_Event_Index).Event_Status  := INITIALIZED_STATUS;
      g_Events_Tbl(l_Event_Index).Worker_Status := LPAD('N',l_Max_Workers,'N');
    END IF ;
 EXCEPTION
   WHEN OTHERS THEN
     IF ( g_Event_LockHandle IS NOT NULL ) THEN
       BEGIN -- begin for release lock
	    AD_LOCK_UTILS_PKG.Release_Lock(
		             p_LockHandle => g_Event_LockHandle);
	    g_Event_LockHandle := NULL ;
       EXCEPTION
        WHEN OTHERS THEN
	 NULL ;
       END ; -- end for release lock
     END IF ;
     IF SQLCODE = 100 THEN
       RAISE_APPLICATION_ERROR(-20010,'Event not registered. '||
                                    'Not possible to reset.');
     ELSE
       RAISE ;
     END IF ;
  END Reset_Event ;

--------------------------------------------------------------------------

  PROCEDURE Set_Event_As_Done(
             p_Owner       IN VARCHAR2 ,
             p_Event_Name  IN VARCHAR2 ,
	     p_Module_Name IN VARCHAR2 ,
             p_Context     IN VARCHAR2 := NULL ,
             p_Event_Type  IN VARCHAR2 := NULL ,
             p_Version     IN NUMBER   := NULL ,
             p_Worker_Id   IN NUMBER   := NULL ,
             p_Num_Workers IN NUMBER   := NULL )
  IS
    l_Event_Id             ad_events.event_id%TYPE;
    l_Event_Version        ad_event_versions.version%TYPE ;
    l_Event_Status         ad_event_versions.status%TYPE ;
    l_New_Status           ad_event_versions.status%TYPE ;
    l_Worker_Status_String ad_event_versions.worker_status%TYPE ;
    l_End_Time             ad_event_versions.end_time%TYPE ;
    l_Worker_Id            ad_event_transitions.worker_id%TYPE ;
    l_Prev_Max_Workers     ad_event_versions.num_workers%TYPE ;
    l_Commit_Flag          BOOLEAN ;
    l_event_completed_EXP  EXCEPTION ;
    -- these variables are used to hold in the IN parameter
    l_p_Context            ad_events.event_context%TYPE ;
    l_p_Event_Type         ad_events.event_type%TYPE ;
    l_p_Version            ad_events.last_version%TYPE ;
  BEGIN
    --
    -- The below block checks the value of parameter p_Contect
    -- if the value is null, it is assumed that the value is default value.
    -- the change was done for file.sql.35
    --
    l_p_Context    := nvl(p_Context,    DEFAULT_CONTEXT);
    l_p_Event_Type := nvl(p_Event_Type, BOOLEAN_TYPE);
    l_p_Version    := nvl(p_Version,    DEFAULT_VERSION);

    l_Worker_id := p_Worker_Id;
    --
    -- Call the procedure for validating the parameters
    --
    Validate_Parameters(
                 p_Owner       => p_Owner ,
		 p_Event_Name  => p_Event_Name ,
		 p_Event_Type  => l_p_Event_Type,
		 p_Num_Workers => p_Num_Workers);

   -- Get the lock
   Request_Lock(p_Owner,
                p_Event_Name);
   BEGIN -- block 1
    --
    -- Select the details of the event from the registry.
    --
    SELECT status,
           ae.event_id,
	   worker_status,
	   num_workers,
	   av.version
    INTO   l_Event_Status,
           l_Event_Id,
	   l_Worker_Status_String,
	   l_Prev_Max_Workers,
	   l_Event_Version
    FROM   ad_events ae, ad_event_versions av
    WHERE  ae.event_id      = av.event_id
    AND    ae.last_version  = av.version
    AND    ae.owner         = p_Owner
    AND    ae.event_name    = p_Event_Name
    AND    ae.event_context = l_p_Context;

    --
    -- If there is an event in the db with the same version as that
    -- of the one being registered, do the following.
    --
    IF ( l_Event_Version = l_p_Version ) THEN -- if version check
      --
      -- If the event in the db is already in completed status
      --
      IF ( l_Event_Status = COMPLETED_STATUS ) THEN
	RAISE l_event_completed_EXP;
      END IF ;
      --
      -- Control goes to the following block, when
      -- the event is already registered, and there is a change in the
      -- number of workers.
      -- Here we compare the number of workers in this call with the number
      -- of workers from the registry. If there is any change we assume that
      -- the event is re-scheduled among a different set of workers.
      -- So, the worker details in ad_event_versions has to be updated
      -- and a special transition entry has to be inserted into
      -- ad_event_transitions.
      --
      IF ( NVL (l_Prev_Max_Workers,1) <> NVL (p_Num_Workers,1) ) THEN
      -- # if resch check
	-- Set the commit flag
	l_Commit_Flag := TRUE ;

	-- Inserting a record into the transition record to show that
        -- a rescheduling has happened for the event.
        Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_p_Version,
	      p_New_Status  => 'RE-SCHEDULED',
	      p_Old_Status  => 'RE-SCHEDULED',
	      p_Module_Name => p_Module_Name,
	      p_Worker_Id   => p_Worker_Id);

	IF ( NVL (p_Num_Workers,1) > 1 ) THEN -- if # resch_worker
	  --
	  -- The control comes here when the event is re-scheduled
	  -- and the number of workers is more than 1. So we have to form
	  -- the worker status string, and the event status will be NULL.
	  --
	  -- form the worker status string
	  l_Worker_Status_String := LPAD('N',p_Num_Workers,'N');
	  --
          -- Form the new status string
          --
	  Set_Worker_Status_String(l_Worker_Id, l_Worker_Status_String);

	  l_New_Status := NULL ;
	ELSE -- if # resch_worker ( number of workers = 1)
	  --
	  -- If the number of workers after the re-scheduling is 1, the
	  -- worker status string will be null. And immediately we can
	  -- say that the event has completed, so the event status will
	  -- become COMPLETED_STATUS.
	  --
	  l_Worker_Status_String := NULL ;
          l_New_Status           := COMPLETED_STATUS;
	  l_End_Time             := SYSDATE ;
	  --
	  -- Since the event has completed here, we have to insert an
	  -- event transition entry as below.
	  --
          Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_p_Version,
	      p_New_Status  => l_New_Status,
	      p_Old_Status  => 'RE-SCHEDULED',
	      p_Module_Name => p_Module_Name,
	      p_Worker_Id   => p_Worker_Id);

	END IF ; -- if # resch_worker
        --
	-- Now update ad_Event_Versions to make the changes happened as a
	-- result of the re-scheduling.
	--
	UPDATE ad_event_versions
        SET num_workers      = p_Num_Workers,
	    status           = l_New_Status,
	    worker_status    = l_Worker_Status_String,
	    start_time       = DECODE(start_time,null,SYSDATE,
		                             start_time),
	    last_update_date = SYSDATE ,
	    end_time         = l_End_Time
        WHERE event_id = l_Event_Id
        AND   version  = l_p_Version;

      ELSE -- re-schedule check
      --
      -- If the event is multi-worker, then do the following.
      -- Multi-worker events require all the workers to complete for the
      -- event to get completed.
      -- So whenever a worker calls this API the corresponding character
      -- position in the worker status string will be updated. When the
      -- string is updated to all Y's the event status will be updated to
      -- completed.
      -- The control comes to this block only from the second call to this
      -- procedure. i.e from the second worker only. During the first call
      -- there wont be any event of the particular name and it will be
      -- caught in the exception handling section below.
      --
      IF ( NVL(p_Num_Workers,1) > 1 ) THEN -- if num workers

        l_Commit_Flag := TRUE ;

        --
        -- Form the new status string
        --
        Set_Worker_Status_String(l_Worker_Id, l_Worker_Status_String);

        --
        -- If all the workers have completed update the event status to
        -- completed and the event end time to the current time.
        --
        IF ( INSTR(l_Worker_Status_String,'N') = 0 ) THEN
           l_New_Status := COMPLETED_STATUS;
           l_End_Time   := SYSDATE;
        END IF;

        --
        -- Update ad_event_versions with the new status
        --
        UPDATE  ad_event_versions
        SET     status           = l_New_Status,
	        end_time         = l_End_Time,
	        last_update_date = SYSDATE ,
                start_time       = DECODE(start_time,null,SYSDATE,
		                             start_time),
                worker_status    = l_Worker_Status_String
        WHERE   event_id   = l_Event_Id
        AND     version    = l_p_Version;

        --
        -- The below block is for inserting the event transition records
        -- for multi-worker events.
        -- The transition records will be inserted only when the event is
        -- completed. In case of multi-worker events, Event gets completed
        -- only when all the workers are completed.
        --
        IF ( l_New_Status = COMPLETED_STATUS )THEN -- if for completed status
          Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_p_Version,
	      p_New_Status  => COMPLETED_STATUS,
	      p_Old_Status  => COMPLETED_STATUS,
	      p_Module_Name => p_Module_Name,
	      p_Worker_Id   => p_Worker_Id);

        END IF; -- end if for completed status

      ELSE -- else for num workers
        --
	-- Here the number of workers is 1, the event is already registered
	-- and the status is something other than COMPLETED_STATUS
	-- This is for fixing bug no : 4260836
	--
	IF ( l_Event_Status <> COMPLETED_STATUS ) THEN
          l_Commit_Flag := TRUE ;
	  --
	  -- Mark the event as completed here
	  --
          UPDATE   ad_event_versions
          SET      status           = COMPLETED_STATUS,
	           start_time       = DECODE(start_time,null,SYSDATE,
		                             start_time),
                   end_time         = SYSDATE ,
                   last_update_date = SYSDATE
          WHERE    event_id   = l_Event_Id
          AND      version    = l_p_Version;
          --
	  -- Insert the transition entries here
	  --
          Insert_Event_Transitions(
             p_Event_Id    => l_Event_Id,
	     p_Version     => l_p_Version,
	     p_New_Status  => COMPLETED_STATUS,
	     p_Old_Status  => l_Event_Status,
	     p_Module_Name => p_Module_Name);
	ELSE
	  RAISE l_event_completed_EXP;
	END IF ;
      END IF ; -- end if num workers.

      END IF ; -- re-schedule check

    ELSIF ( l_Event_Version < l_p_Version ) THEN -- else version check
      --
      -- The following is a multi-worker event.
      -- Here an existing event with a higher version is being registered
      -- This is the first worker registering it. So set a new worker status
      -- string.
      --
      IF ( NVL(p_Num_Workers,1) > 1 )  THEN -- if num workers 2
        l_Worker_Status_String := LPAD('N',p_Num_Workers,'N');
        Set_Worker_Status_String(l_Worker_Id, l_Worker_Status_String);

      ELSE
        l_Event_Status := COMPLETED_STATUS;
	l_New_Status   := COMPLETED_STATUS;
	l_End_Time     := SYSDATE ;
        l_Commit_Flag  := TRUE ;

        -- Insert the transition details.
        Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_p_Version,
	      p_New_Status  => l_New_Status,
	      p_Old_Status  => l_Event_Status,
	      p_Module_Name => p_Module_Name,
	      p_Worker_Id   => p_Worker_Id);

      END IF ;  -- end if num workers 2
        --
	-- The control comes here when the version being registered is
	-- greater than the latest version and the event is single-worker.
	--
        l_Commit_Flag := TRUE ;

        UPDATE   ad_events
	SET      last_version     = l_p_Version,
	         last_update_date = SYSDATE
	WHERE    event_id         = l_Event_Id;

        -- Insert the version details.
	INSERT INTO ad_event_versions (
	             event_id,
		     version,
		     status,
		     start_time,
		     end_time,
		     creation_date,
		     last_update_date,
		     num_workers,
		     worker_status)
        VALUES (
	             l_Event_Id,
		     l_p_Version,
		     l_New_Status,
		     SYSDATE ,
		     l_End_Time ,
		     SYSDATE ,
                     SYSDATE ,
		     p_Num_Workers ,
		     l_Worker_Status_String );
    END IF ; -- end if Version check

   EXCEPTION   -- exceptions for block 1

    WHEN l_event_completed_EXP THEN
      --
      -- It was decided to do nothing for this exception.
      --
      NULL ;
    WHEN NO_DATA_FOUND THEN

      l_Commit_Flag := TRUE ;

      -- For new events control comes here.
      INSERT INTO ad_events(
                   event_id,
	           owner,
                   event_name,
		   event_context,
		   event_type,
		   last_version,
                   creation_date,
		   last_update_date)
      VALUES(
                   ad_events_s.NEXTVAL,
	           p_Owner,
                   p_Event_Name,
		   l_p_Context,
		   l_p_Event_Type,
		   l_p_Version,
                   SYSDATE,
		   SYSDATE  )
      RETURNING    event_id
      INTO         l_Event_Id;
      --
      -- If there is only a single worker it means that the event
      -- is completed here itself. So set the status as completed.
      --
      IF ( NVL(p_Num_Workers,1) > 1 ) THEN  -- if num-workers
        --
	-- Form the worker status string for a multi worker event.
	-- The event status will remain as NULL here .
	-- The subsequent workers whoever is updating the event has
	-- to take care of updating the event status.
	--
        l_Worker_Status_String := LPAD('N',p_Num_Workers,'N');
        Set_Worker_Status_String(l_Worker_Id, l_Worker_Status_String);

      ELSE  -- else num-workers
        -- The control comes here for single-worker events.
        -- For single-worker event the status can be put as completed
        l_Event_Status := COMPLETED_STATUS;
	-- The end time also can be put as the current time.
	l_End_Time     := SYSDATE ;

        --
	-- Insert the transition records for single-worker events.
	--

        Insert_Event_Transitions(
              p_Event_Id    => l_Event_Id,
	      p_Version     => l_p_Version,
	      p_New_Status  => COMPLETED_STATUS,
	      p_Old_Status  => COMPLETED_STATUS,
	      p_Module_Name => p_Module_Name,
	      p_Worker_Id   => p_Worker_Id);

      END IF ; -- end if num-workers
      --
      -- Insert the event version details here
      -- This insertion is done for both single-worker and multi-worker cases
      -- but only for the first time.
      --
      INSERT INTO ad_event_versions(
                    event_id,
		    version,
		    status,
		    start_time,
		    end_time,
                    creation_date,
		    last_update_date,
		    num_workers,
		    worker_status)
       VALUES(
                    l_Event_Id,
		    l_p_Version,
		    l_Event_Status,
		    SYSDATE,
		    l_End_Time,
                    SYSDATE,
		    SYSDATE,
		    p_Num_Workers,
		    l_Worker_Status_String);
   END ; -- block 1
   --
   -- If the commit flag is set commit the txn here
   --
   IF ( l_Commit_Flag = TRUE ) THEN
     COMMIT ;
   END IF ;
   --
   -- Release the lock
   --
   AD_LOCK_UTILS_PKG.Release_Lock(
                      p_LockHandle => g_Event_LockHandle);
   g_Event_LockHandle := NULL ;

   EXCEPTION
    WHEN OTHERS THEN
     IF ( g_Event_LockHandle IS NOT NULL ) THEN
       BEGIN -- begin for release lock
	    AD_LOCK_UTILS_PKG.Release_Lock(
		             p_LockHandle => g_Event_LockHandle);
	    g_Event_LockHandle := NULL ;
       EXCEPTION
        WHEN OTHERS THEN
	 NULL ;
       END ; -- end for release lock
     END IF ;
     RAISE ;
  END Set_Event_As_Done ;
--------------------------------------------------------------------------

END Ad_Event_Registry_Pkg;
