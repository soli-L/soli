
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_LOCK_UTILS_PKG" AUTHID CURRENT_USER AS
-- $Header: adlckutls.pls 115.3 2004/09/17 07:38:37 msailoz noship $

  PROCEDURE Get_Lock(
              p_LockName          IN  VARCHAR2 ,
              p_LockMode          IN  VARCHAR2 ,
	      p_Release_On_Commit IN  BOOLEAN);

  PROCEDURE Get_Lock(
              p_LockName          IN  VARCHAR2 ,
              p_LockMode          IN  VARCHAR2 ,
	      p_Release_On_Commit IN  BOOLEAN,
	      x_LockHandle        IN OUT NOCOPY VARCHAR2 );

  PROCEDURE Release_Lock(
              p_LockName          IN  VARCHAR2);

  PROCEDURE Release_Lock(
              p_LockHandle        IN VARCHAR2 );

  PROCEDURE Acquire_PDML_Lock;

  PROCEDURE Release_PDML_Lock;

END Ad_Lock_Utils_Pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_LOCK_UTILS_PKG" AS
-- $Header: adlckutlb.pls 115.3 2004/09/17 07:38:49 msailoz noship $

  g_LockName    varchar2(128);
  g_LockHandle  varchar2(128);

  PDML_LOCK_NAME CONSTANT VARCHAR2(30) := 'AD_PARALLEL';

  --
  -- Procedure Allocate_Handle
  --
  --     Allocates lockhandle for a given lock
  --
  --     This is defined as an autonomous transaction as DBMS_LOCK.Allocate_Unique does an implicit
  --     commit
  --
  PROCEDURE Allocate_Handle(
             p_LockName          IN  VARCHAR2 ,
             x_LockHandle         OUT NOCOPY VARCHAR2 )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION ;
    l_LockHandle    VARCHAR2(128);
  BEGIN
      DBMS_LOCK.ALLOCATE_UNIQUE(
                  lockname   => p_LockName,
                  lockhandle => l_LockHandle);
      x_LockHandle := l_LockHandle;

      COMMIT ;
  END Allocate_Handle ;

  PROCEDURE Get_Lock(
              p_LockName          IN  VARCHAR2 ,
              p_LockMode          IN  VARCHAR2 ,
	      p_Release_On_Commit IN  BOOLEAN,
	      x_LockHandle        IN OUT NOCOPY VARCHAR2 )
  IS
    l_reqid  number;
  BEGIN

     IF (g_LockName = p_LockName) THEN
       x_LockHandle := g_LockHandle;
     ELSE
        Allocate_Handle(p_LockName, x_LockHandle);
        g_LockHandle := x_LockHandle;
        g_LockName := p_LockName;
     END IF;

     l_reqid := dbms_lock.request(lockhandle=>x_LockHandle,
                                  lockmode=>p_LockMode,
                                  timeout=>dbms_lock.maxwait,
                                  release_on_commit=>p_Release_On_Commit);

     IF (l_reqid <> 0) THEN
        raise_application_error(-20001,
            'dbms_lock.request('|| g_LockHandle ||
            ', ' || p_LockMode ||
            ', ' || dbms_lock.maxwait ||
            ') returned : ' || l_reqid);
     END IF;
  END;

  PROCEDURE Get_Lock(
              p_LockName          IN  VARCHAR2 ,
              p_LockMode          IN  VARCHAR2 ,
	      p_Release_On_Commit IN  BOOLEAN)
  IS
    l_LockHandle varchar2(128);
  BEGIN

    l_LockHandle := NULL;

    ad_lock_utils_pkg.Get_Lock(
              p_LockName=>p_LockName,
              p_LockMode=>p_LockMode,
              p_Release_On_Commit=>p_Release_On_Commit,
              x_LockHandle=>l_LockHandle);
  END;

  PROCEDURE Release_Lock(
              p_LockHandle IN VARCHAR2 )
  IS
    l_LockStatus number;
  BEGIN

    l_LockStatus := DBMS_LOCK.RELEASE(
                        lockhandle => p_LockHandle);

    IF (l_LockStatus <> 0) THEN
      raise_application_error(-20001, 'DBMS_LOCK.release() returned '||l_LockStatus);
    END IF;
  END;

  PROCEDURE Release_Lock(p_LockName  IN  VARCHAR2)
  IS
    l_LockHandle varchar2(128);
  BEGIN

     IF (g_LockName = p_LockName) THEN
       l_LockHandle := g_LockHandle;
     ELSE
        Allocate_Handle(p_LockName, l_LockHandle);
        g_LockHandle := l_LockHandle;
        g_LockName := p_LockName;
     END IF;

     Release_Lock(p_LockHandle=>l_LockHandle);
  END;

  PROCEDURE Acquire_PDML_Lock
  IS
  BEGIN
      Get_Lock(p_LockName=>PDML_LOCK_NAME,
               p_LockMode=>DBMS_LOCK.X_MODE,
               p_Release_On_Commit=>FALSE);
  END;

  PROCEDURE Release_PDML_Lock
  IS
  BEGIN
     Release_Lock( p_LockName=>PDML_LOCK_NAME);

  END;

BEGIN
  g_LockName   := '##UNKNOWN##';
  g_LockHandle := '##UNKNOWN##';
END Ad_Lock_Utils_Pkg;
