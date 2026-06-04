
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_UPDATE_WORK_PARAMS_PKG" AUTHID CURRENT_USER AS
-- $Header: adupwrks.pls 115.3 2004/09/17 07:36:58 msailoz ship $

UNDEF_VALUE  CONSTANT VARCHAR2(20) := '#~#UNDEFVALUE#~#';
SYSADMIN_VALUE NUMBER := 1;
GLOBAL_SESSION_VALUE NUMBER := 0 ;
--
-- Defines and Sets the value of a parameter at the global level.
--
PROCEDURE SET_PARAMETER(
                 p_owner IN VARCHAR2,
                 p_name  IN VARCHAR2,
                 p_value IN VARCHAR2);

--
-- Returns UNDEF_VALUE if parameter is not defined
--
FUNCTION GET_PARAMETER(
                 p_owner IN VARCHAR2,
                 p_name  IN VARCHAR2) RETURN VARCHAR2;


--
-- Defines and Sets the value of a parameter for a session
--

PROCEDURE SET_SESSION_PARAMETER(
                 p_session_id IN number,
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2,
                 p_value      IN VARCHAR2);

--
-- Returns UNDEF_VALUE if parameter is not defined
--
FUNCTION GET_SESSION_PARAMETER(
                 p_session_id IN number,
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2) RETURN VARCHAR2;


END AD_UPDATE_WORK_PARAMS_PKG;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_UPDATE_WORK_PARAMS_PKG" AS
-- $Header: adupwrkb.pls 115.3 2004/09/17 07:37:07 msailoz ship $

PROCEDURE SET_PARAMETER(
                 p_owner IN VARCHAR2,
                 p_name  IN VARCHAR2,
                 p_value IN VARCHAR2)
IS
	l_owner AD_UPDATE_WORK_PARAMS.owner%TYPE ;
	l_name  AD_UPDATE_WORK_PARAMS.name%TYPE ;
BEGIN
	l_owner := upper(p_owner);
	l_name  := upper(p_name);
	--Update the value if the parameter already exists
	UPDATE AD_UPDATE_WORK_PARAMS
	SET  value   =   p_value,
	last_update_date = SYSDATE,
	last_updated_by  = SYSADMIN_VALUE
	WHERE owner  =   l_owner
	AND   name   =   l_name
	AND   session_id = GLOBAL_SESSION_VALUE;

	IF SQL%ROWCOUNT = 0 THEN
	--Create a new parameter if the parameter has not been updated
		INSERT INTO AD_UPDATE_WORK_PARAMS(
		session_id,
		owner,
		name,
		value,
		creation_date,
		created_by,
		last_update_date,
		last_updated_by)
		VALUES(
		GLOBAL_SESSION_VALUE,
		l_owner,
		l_name,
		p_value,
		SYSDATE ,
		SYSADMIN_VALUE,
		SYSDATE ,
		SYSADMIN_VALUE);

	END IF ;

	COMMIT ;

END SET_PARAMETER;

FUNCTION GET_PARAMETER(
                 p_owner IN VARCHAR2,
                 p_name  IN VARCHAR2)
RETURN VARCHAR2
IS
	l_value AD_UPDATE_WORK_PARAMS.value%TYPE ;
BEGIN
--Get the value for the parameter which is global
	SELECT value INTO l_value
	FROM AD_UPDATE_WORK_PARAMS
	WHERE session_id =  GLOBAL_SESSION_VALUE
	AND   owner      =  upper(p_owner)
	AND   name       =  upper(p_name);

	RETURN l_value;

EXCEPTION
--If the value doesnot exist return undefined value
	WHEN NO_DATA_FOUND THEN
	RETURN UNDEF_VALUE;
END GET_PARAMETER;

PROCEDURE SET_SESSION_PARAMETER(
                 p_session_id IN NUMBER,
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2,
                 p_value      IN VARCHAR2)
IS
	l_owner AD_UPDATE_WORK_PARAMS.owner%TYPE ;
	l_name  AD_UPDATE_WORK_PARAMS.name%TYPE ;
BEGIN

	l_owner :=  upper(p_owner);
	l_name  := upper(p_name);
	--Update the value if the parameter already exists for the session
	UPDATE AD_UPDATE_WORK_PARAMS
	SET  value   =   p_value,
	last_update_date = SYSDATE,
	last_updated_by  = SYSADMIN_VALUE
	WHERE owner  =   l_owner
	AND   name   =   l_name
	AND   session_id = p_session_id;

	IF SQL%ROWCOUNT = 0 THEN
	--Create a new parameter if the parameter has not been updated for the session
		INSERT INTO AD_UPDATE_WORK_PARAMS(
		session_id,
		owner,
		name,
		value,
		creation_date,
		created_by,
		last_update_date,
		last_updated_by)
		VALUES(
		p_session_id,
		l_owner,
		l_name,
		p_value,
		SYSDATE ,
		SYSADMIN_VALUE,
		SYSDATE,
		SYSADMIN_VALUE);

	END IF ;

COMMIT ;

END SET_SESSION_PARAMETER;


FUNCTION GET_SESSION_PARAMETER(
                 p_session_id IN NUMBER,
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2)
RETURN VARCHAR2
IS
	l_value AD_UPDATE_WORK_PARAMS.value%TYPE ;
BEGIN
--Get the parameter for the name, owner and session
	SELECT value INTO l_value
	FROM AD_UPDATE_WORK_PARAMS
	WHERE session_id =  p_session_id
	AND   owner      =  upper(p_owner)
	AND   name       =  upper(p_name);

	RETURN l_value;

EXCEPTION
--Return undefined if the parameter has not been defined
	WHEN NO_DATA_FOUND THEN
	RETURN UNDEF_VALUE;

END GET_SESSION_PARAMETER;

END AD_UPDATE_WORK_PARAMS_PKG;
