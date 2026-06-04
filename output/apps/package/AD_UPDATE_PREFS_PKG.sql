
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_UPDATE_PREFS_PKG" AUTHID CURRENT_USER AS
-- $Header: adupprfs.pls 115.3 2004/09/17 07:37:27 msailoz ship $

UNDEF_VALUE  CONSTANT VARCHAR2(20) := '#~#UNDEFVALUE#~#';
SYSADMIN_VALUE NUMBER := 1;
GLOBAL_SESSION_VALUE NUMBER := 0 ;
--
-- Defines and Sets the value of a parameter at the global level.
--
PROCEDURE DEFINE_PREFERENCE(
                 p_owner          IN VARCHAR2,
                 p_name           IN VARCHAR2,
                 p_description    IN VARCHAR2 DEFAULT NULL,
                 p_default_value  IN VARCHAR2 DEFAULT NULL
                 );

--
-- Updates the definition of a existing parameter.
--

PROCEDURE UPDATE_DEF_PREFERENCE(
                 p_owner          IN  VARCHAR2,
                 p_name           IN  VARCHAR2,
                 p_description    IN  VARCHAR2,
                 p_default_value  IN  VARCHAR2,
		 p_pref_id	  OUT NOCOPY  NUMBER
                 );



--
-- returns NULL if preference is not found
--
FUNCTION GET_PREFERENCE_ID(
                 p_owner          IN VARCHAR2,
                 p_name           IN VARCHAR2)
		 RETURN number;

--
-- Gets the preference value for global if session preference is not found
-- Returns UNDEF_VALUE if parameter is not defined
--
FUNCTION GET_PREFERENCE_VALUE(
                 p_owner IN VARCHAR2,
                 p_name  IN VARCHAR2,
                 p_session_id IN NUMBER DEFAULT NULL )
		 RETURN VARCHAR2;

--
-- Gets Session preference value
--

FUNCTION GET_SESSION_PREFERENCE_VALUE(
                 p_owner IN VARCHAR2,
                 p_name  IN VARCHAR2,
                 p_session_id IN NUMBER) RETURN VARCHAR2;


--
-- Creates an new global value for a preference
--

PROCEDURE CREATE_PREFERENCE_VALUE(
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2,
                 p_value      IN VARCHAR2);

--
-- Updates the global value for a preference
--

PROCEDURE UPDATE_PREFERENCE_VALUE(
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2,
                 p_value      IN VARCHAR2);

--
-- Sets value for a preference (Global)
--

PROCEDURE SET_SESSION_PREFERENCE_VALUE(
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2,
                 p_session_id IN NUMBER,
                 p_value      IN VARCHAR2);


END AD_UPDATE_PREFS_PKG;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_UPDATE_PREFS_PKG" AS
-- $Header: adupprfb.pls 115.3 2004/09/17 07:37:36 msailoz ship $

PROCEDURE DEFINE_PREFERENCE(
                 p_owner          in VARCHAR2,
                 p_name           in VARCHAR2,
                 p_description    in VARCHAR2 DEFAULT NULL ,
                 p_default_value  in VARCHAR2 DEFAULT NULL )
IS
	l_owner ad_update_preferences.owner%TYPE ;
	l_name  ad_update_preferences.name%TYPE ;
	p_pref_id ad_update_preferences.preference_id%TYPE ;

BEGIN
	l_owner := upper(p_owner);
	l_name  := upper(p_name);

-- Check if the preference already exists

	SELECT  preference_id
	  INTO  p_pref_id
	  FROM  ad_update_preferences
	 WHERE  name = l_name
   	   AND  owner= l_owner;

	IF SQL%ROWCOUNT > 0 THEN
     	   RAISE_APPLICATION_ERROR(-20001,'Preference "'|| p_pref_id ||' : '|| l_name ||'" already exists');
	END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

-- Insert a new record to define the new preference

	INSERT INTO ad_update_preferences(
		preference_id,
		owner,
		name,
		description,
		default_value,
		creation_date,
		created_by,
		last_update_date,
		last_updated_by)
	VALUES(
		AD_UPDATE_PREFERENCES_S.NEXTVAL ,
		l_owner,
		l_name,
		p_description,
		p_default_value,
		SYSDATE,
		SYSADMIN_VALUE,
		SYSDATE,
		SYSADMIN_VALUE);

	COMMIT ;

END DEFINE_PREFERENCE;

PROCEDURE UPDATE_DEF_PREFERENCE(
                 p_owner          IN  VARCHAR2,
                 p_name           IN  VARCHAR2,
                 p_description    IN  VARCHAR2,
                 p_default_value  IN  VARCHAR2,
                 p_pref_id        OUT NOCOPY  NUMBER )
IS
        l_owner AD_UPDATE_PREFERENCES.owner%TYPE ;
        l_name  AD_UPDATE_PREFERENCES.name%TYPE ;
BEGIN
        l_owner := upper(p_owner);
        l_name  := upper(p_name);

	-- Check if the preference already exists

        SELECT  preference_id
          INTO  p_pref_id
          FROM  ad_update_preferences
         WHERE  name = l_name
           AND  owner= l_owner;


	UPDATE  ad_update_preferences
   	   SET  description = p_description,
        	default_value= p_default_value,
        	last_update_date = SYSDATE,
        	last_updated_by  = SYSADMIN_VALUE
 	 WHERE  name = l_name
   	   AND  owner= l_owner;

	COMMIT ;

EXCEPTION
WHEN NO_DATA_FOUND THEN
     RAISE_APPLICATION_ERROR(-20001,'Preference '||'l_name'||' does not exist');

END UPDATE_DEF_PREFERENCE;



FUNCTION GET_PREFERENCE_ID(
                 p_owner          IN VARCHAR2,
                 p_name           IN VARCHAR2)
RETURN NUMBER
IS
	l_pref_id ad_update_preferences.preference_id%TYPE ;
BEGIN

	SELECT preference_id INTO l_pref_id
	FROM ad_update_preferences
	WHERE owner = upper(p_owner)
	AND   name  = upper(p_name) ;

	RETURN l_pref_id;

EXCEPTION
--Return NULL if the preference is not found

	WHEN NO_DATA_FOUND THEN
	RETURN NULL;

END GET_PREFERENCE_ID;



FUNCTION GET_PREFERENCE_VALUE(
                 p_owner IN VARCHAR2,
                 p_name  IN VARCHAR2,
                 p_session_id IN NUMBER DEFAULT NULL)
RETURN VARCHAR2
IS
	l_value ad_update_pref_values.value%TYPE ;
BEGIN

	SELECT  value INTO l_value
	FROM ad_update_pref_values v,ad_update_preferences p
	WHERE v.preference_id=p.preference_id
	AND  owner = upper(p_owner)
	AND  name = upper(p_name)
	--Check for global or session preference
	AND  pref_level =  decode(p_session_id,NULL,'G','S')
	--Match the session id if session preference otherwise always true for global preference
	AND  NVL (pref_level_value,0)  =  NVL (p_session_id, NVL(pref_level_value, 0) );

RETURN l_value;

EXCEPTION
	WHEN NO_DATA_FOUND THEN

	BEGIN
	--If Session level preference is not found get the global preference

		SELECT value INTO l_value
		FROM ad_update_pref_values v,ad_update_preferences p
		WHERE v.preference_id=p.preference_id
		AND  owner = upper(p_owner)
		AND  name = upper(p_name)
		AND  pref_level = 'G';
		RETURN l_value;

	EXCEPTION
	--Return undefined value if global preference is also not found

			WHEN NO_DATA_FOUND THEN
			RETURN UNDEF_VALUE;

	END;

END GET_PREFERENCE_VALUE;


FUNCTION GET_SESSION_PREFERENCE_VALUE(
                 p_owner IN VARCHAR2,
                 p_name  IN VARCHAR2,
                 p_session_id IN NUMBER)
RETURN VARCHAR2
IS
	l_value ad_update_pref_values.value%TYPE ;
BEGIN
--Get the session level preference value for the given parameters

	SELECT  value INTO l_value
	FROM ad_update_pref_values v,ad_update_preferences p
	WHERE v.preference_id=p.preference_id
	AND  owner = upper(p_owner)
	AND  name=upper(p_name )
	AND  pref_level = 'S'
	AND  pref_level_value=p_session_id;

	RETURN l_value;

EXCEPTION
--Return undefined value if the session preference is not found

	WHEN NO_DATA_FOUND THEN
	RETURN UNDEF_VALUE;

END GET_SESSION_PREFERENCE_VALUE;



PROCEDURE UPDATE_PREFERENCE_VALUE(
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2,
                 p_value      IN VARCHAR2)
IS
	p_pref_id AD_UPDATE_PREFERENCES.preference_id%TYPE ;
        l_owner AD_UPDATE_PREFERENCES.owner%TYPE ;
        l_name  AD_UPDATE_PREFERENCES.name%TYPE ;
	l_value AD_UPDATE_PREF_VALUES.value%TYPE ;
BEGIN
        l_owner := upper(p_owner);
        l_name  := upper(p_name);
-- Check the existence of the preference
	 p_pref_id := get_preference_id (l_owner,l_name);
	 IF p_pref_id IS  NULL THEN
		 RAISE_APPLICATION_ERROR(-20001,'Preference Not Found');
	  END IF;
-- Check for the record for the Global Preference Value
	   SELECT value
	   INTO l_value
	   FROM AD_UPDATE_PREF_VALUES
	   WHERE preference_id = p_pref_id
	   AND pref_level = 'G';

-- Update the value for the Global Preference
	UPDATE  ad_update_pref_values
   	   SET  value  = p_value,
        	last_update_date = SYSDATE,
        	last_updated_by  = SYSADMIN_VALUE
 	 WHERE  preference_id=p_pref_id;

	COMMIT ;

EXCEPTION
WHEN NO_DATA_FOUND THEN
	RAISE_APPLICATION_ERROR(-20001,'Global Preference value"'|| p_pref_id ||': '||
				l_name ||'" does not exist');

END UPDATE_PREFERENCE_VALUE;


PROCEDURE CREATE_PREFERENCE_VALUE(
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2,
                 p_value      IN VARCHAR2)
IS
p_pref_id ad_update_preferences.preference_id%TYPE ;
l_owner AD_UPDATE_PREFERENCES.owner%TYPE ;
l_name  AD_UPDATE_PREFERENCES.name%TYPE ;
BEGIN
        l_owner := upper(p_owner);
        l_name  := upper(p_name);
	-- Check the existence of the preference
	p_pref_id := get_preference_id (l_owner,l_name);
	IF p_pref_id IS NULL THEN
		 RAISE_APPLICATION_ERROR(-20001,'Preference Not Found');
	END IF;

	SELECT  preference_id
	  INTO  p_pref_id
	  FROM  ad_update_pref_values
	 WHERE  preference_id = p_pref_id
	 AND pref_level = 'G';
-- Check if the record for the Global Preference Value already exists

	IF SQL%ROWCOUNT > 0 THEN
     	   RAISE_APPLICATION_ERROR(-20001,'Global Preference value for "'|| l_name ||'" already exists');
	END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

-- Insert a new record to define the new Global preference value

	INSERT INTO ad_update_pref_values(
		preference_id,
		pref_level,
		pref_level_value,
		value,
		creation_date,
		created_by,
		last_update_date,
		last_updated_by)
	VALUES(
		p_pref_id,
		'G',
		GLOBAL_SESSION_VALUE,
		p_value,
		SYSDATE,
		SYSADMIN_VALUE,
		SYSDATE,
		SYSADMIN_VALUE);

	COMMIT ;

END CREATE_PREFERENCE_VALUE;

PROCEDURE SET_SESSION_PREFERENCE_VALUE(
                 p_owner      IN VARCHAR2,
                 p_name       IN VARCHAR2,
                 p_session_id IN NUMBER,
                 p_value      IN VARCHAR2)
IS
	l_pref_id ad_update_pref_values.preference_id%TYPE ;
BEGIN
--Get the preference_id for the given owner,name of the preference

	SELECT preference_id INTO l_pref_id
	FROM ad_update_preferences WHERE
	owner = upper(p_owner)
	AND name = upper(p_name);

	--Update the preference value for that particular session
	UPDATE ad_update_pref_values
	SET value = p_value,
	last_update_date = SYSDATE,
	last_updated_by =SYSADMIN_VALUE
	WHERE
	preference_id = l_pref_id
	AND pref_level = 'S'
	AND pref_level_value=p_session_id;

	IF SQL%ROWCOUNT = 0 THEN
	-- Create new value record if the value record is not updated
		INSERT INTO ad_update_pref_values(
		preference_id,
		pref_level,
		pref_level_value,
		value,
		creation_date,
		created_by,
		last_update_date,
		last_updated_by)
		VALUES (
		l_pref_id,
		'S',
		p_session_id,
		p_value,
		SYSDATE ,
		SYSADMIN_VALUE,
		SYSDATE ,
		SYSADMIN_VALUE);
	END IF ;
COMMIT;
EXCEPTION WHEN NO_DATA_FOUND then
	--Raise an exception
	RAISE_APPLICATION_ERROR (-20001,'Preference does not exist');
END SET_SESSION_PREFERENCE_VALUE;

END AD_UPDATE_PREFS_PKG;
