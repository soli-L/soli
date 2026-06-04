
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_LONGTOLOB_PKG" 
-- $Header: adl2lpkgs.pls 120.0 2005/09/30 06:19:19 vpalakur noship $
AUTHID CURRENT_USER AS
  -- Constants to indicate the status of the migration process
  -- Initial status of the tables before starting the migration process.
  G_INITIALIZED_STATUS    CONSTANT VARCHAR2 (30) := 'INITIALIZED';
  -- Status after adding the NEW columns
  G_ADD_NEW_COLUMN_STATUS CONSTANT VARCHAR2 (30) := 'NEW_COL_ADDED';
  -- Status after adding the triggers.
  G_ADD_TRIGGER_STATUS    CONSTANT VARCHAR2 (30) := 'TRIGGER_ADDED';
  -- Status after migrating the data.
  G_UPDATE_ROWS_STATUS    CONSTANT VARCHAR2 (30) := 'TABLE_UPDATED';
  G_DROP_OLD_COLUMN_STATUS CONSTANT VARCHAR2 (30) := 'DROP OLD COLUMN';
  G_COL_RENAMED_STATUS    CONSTANT VARCHAR2 (30) := 'LONG_LOB_RENAMED';
  G_DROP_TRIGGER_STATUS   CONSTANT VARCHAR2 (30) := 'TRIGGER_DROPPED';
  G_COMPLETE_STATUS       CONSTANT VARCHAR2 (30) := 'COMPLETED';
  G_DEFERRED_STATUS       CONSTANT VARCHAR2 (30) := 'DEFERRED';

  -- Diffrent actions to be performed on the tables.
  G_NO_ACTION             CONSTANT VARCHAR2 (10) := 'NO_ACTION';
  G_WITH_DATA             CONSTANT VARCHAR2 (10) := 'WITH_DATA';
  G_WITHOUT_DATA          CONSTANT VARCHAR2 (15) := 'WITHOUT_DATA';
  G_DROP_COLUMN           CONSTANT VARCHAR2 (15) := 'DROP_COLUMN';

  PROCEDURE initialize_process(
                           p_Specific_Table   VARCHAR2 := NULL ,
	                   p_Specific_Product VARCHAR2 := NULL ,
	                   p_Specific_Schema  VARCHAR2 := NULL );
  PROCEDURE add_new_column(
                           p_Schema               IN VARCHAR2 ,
                           p_Table_Name           IN VARCHAR2 ,
                           p_Old_Column_Name      IN VARCHAR2 ,
			   p_New_Column_Name      IN VARCHAR2 ,
                           p_New_Data_Type        IN VARCHAR2 ,
			   p_Curr_Status          IN VARCHAR2 ,
			   p_Action               IN VARCHAR2 );
  PROCEDURE write_long_rep;
  PROCEDURE write_long_rep( p_Path VARCHAR2);
  PROCEDURE create_transform_triggers(
                           p_Schema           IN VARCHAR2 ,
                           p_Table_Name       IN VARCHAR2 ,
                           p_Old_Column_Name  IN VARCHAR2 ,
                           p_New_Column_Name  IN VARCHAR2 ,
                           p_New_Data_Type    IN VARCHAR2 );
  PROCEDURE update_new_data(
                           p_Schema           IN VARCHAR2 ,
                           p_Old_Table_Name   IN VARCHAR2 ,
                           p_Old_Column_Name  IN VARCHAR2 ,
                           p_Old_Data_Type    IN VARCHAR2 ,
                           p_New_Column_Name  IN VARCHAR2 ,
                           p_Batch_Size       IN NUMBER DEFAULT 1000);
  PROCEDURE defer_table(   p_Schema           IN VARCHAR2 ,
                           p_Table_Name       IN VARCHAR2 );
  PROCEDURE re_enable_table(p_Schema          IN VARCHAR2 ,
                            p_Table_Name      IN VARCHAR2 );

END Ad_LongToLob_Pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_LONGTOLOB_PKG" 
-- $Header: adl2lpkgb.pls 120.2 2012/01/02 09:03:25 asutrala ship $
AS
  TYPE TableNames_Tbl_Type  IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER ;
  TYPE To_DataType_Tbl_Type IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER ;
  -- Collection to store the tables to be migrated
-- remove
--  g_TableNames_Tbl  TableNames_Tbl_Type ;
  -- Collection to store the target data type.
--  g_To_DataType_Tbl To_DataType_Tbl_Type ;

--  g_Counter NUMBER ;

  -- The following variable is for specific table to be registered
  g_Specific_Table VARCHAR2 (40);

  -- The following variable is for specific product to be registered
  g_Specific_Product VARCHAR2 (30);

  -- The following variable is for specific schema to be registered
  g_Specific_Schema  VARCHAR2 (30);

 --
 -- This function gives the current status of the table.
 -- Status indicates the stage of processing of the table.
 -- Refer to the defined status in the package above.
 --

 FUNCTION get_table_status( p_Schema          IN VARCHAR2 ,
                            p_Table_Name  IN VARCHAR2 ,
                            p_Old_Column_Name IN VARCHAR2 )
 RETURN VARCHAR2
 IS
    l_status VARCHAR2 (30);
 BEGIN
    SELECT status
    INTO   l_status
    FROM   ad_long_column_conversions
    WHERE  schema_name = p_Schema
    AND    table_name  = p_Table_Name
    AND    old_column_name = p_Old_Column_Name;

    RETURN(l_status);

 EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN (G_INITIALIZED_STATUS);
 END get_table_status;

 --
 -- This procedure is used to update the status of each table
 -- after each step in the conversion process
 --
 PROCEDURE update_table_status( p_Schema          IN VARCHAR2 ,
                                p_Table_Name      IN VARCHAR2 ,
                                p_Old_Column_Name IN VARCHAR2 ,
                                p_Status          IN VARCHAR2 )
  IS
    l_current_status  VARCHAR2 (30);
    l_invalid_change  BOOLEAN := FALSE;
  BEGIN
     --
     -- if the requested status is not in the following set raise an error.
     --
     IF (p_Status NOT IN (G_INITIALIZED_STATUS,
			  G_ADD_NEW_COLUMN_STATUS,
                          G_ADD_TRIGGER_STATUS,
			  G_UPDATE_ROWS_STATUS,
			  G_COMPLETE_STATUS,
			  G_DROP_OLD_COLUMN_STATUS))
     THEN
        RAISE_APPLICATION_ERROR (-20001,
            'update_table_status() - invalid status  : '||p_Status);

     END IF ;

     --
     -- Get the current status of the record and compare it with the
     -- new status to validate for the valid combinations.
     --
     l_current_status := get_table_status( p_Schema,
                                           p_Table_Name,
                                           p_Old_Column_Name);

     /*IF ((p_Status = l2l_pack.G_ADD_NEW_COLUMN_STATUS AND
          l_current_status <> l2l_pack.G_UNINITIALIZED_STATUS)
         OR
         (p_Status = l2l_pack.G_ADD_TRIGGER_STATUS AND
          l_current_status <> l2l_pack.G_ADD_NEW_COLUMN_STATUS)
         OR
         (p_Status = l2l_pack.G_UPDATE_ROWS_STATUS AND
          l_current_status <> l2l_pack.G_ADD_TRIGGER_STATUS)
         OR
         (p_Status = l2l_pack.G_SWAP_STATUS1 AND
          l_current_status <> l2l_pack.G_UPDATE_ROWS_STATUS)
         OR
         (p_Status = l2l_pack.G_SWAP_STATUS2 AND
          l_current_status <> l2l_pack.G_SWAP_STATUS1)
         OR
         (p_Status = l2l_pack.G_COMPLETE_STATUS AND
          l_current_status <> l2l_pack.G_SWAP_STATUS2)
        )
     THEN
       RAISE_APPLICATION_ERROR (-20001,
            'update_table_status() - invalid status change  : '||
            l_current_status||' to '||p_Status);
     END IF ; */

     --
     -- Update the table with the new status.
     --
     UPDATE  AD_LONG_COLUMN_CONVERSIONS
     SET     status      = p_Status
     WHERE   schema_name = p_Schema
     AND     table_name  = p_Table_Name
     AND     old_column_name = p_Old_Column_Name;

     COMMIT ;

  END update_table_status;

  FUNCTION check_to_register(
			p_Product         IN VARCHAR2 ,
			p_Table_Name      IN VARCHAR2 ,
			p_Schema          IN VARCHAR2 )
  RETURN BOOLEAN
  AS
    l_register_flag BOOLEAN ;
  BEGIN
    l_register_flag := FALSE ;
    IF ( g_Specific_Table IS NULL AND g_Specific_Product IS NULL AND
         g_Specific_Schema IS NULL ) THEN -- outer if
      l_register_flag := TRUE ;
    ELSE
      -- Register the specific table passed
      IF ( g_Specific_Table IS NOT NULL AND
           g_Specific_Table = p_Table_Name ) THEN
        l_register_flag := TRUE ;
      END IF ;
      -- Register all the tables for specific product passed
      IF ( g_Specific_Product IS NOT NULL AND
           g_Specific_Product = p_Product ) THEN
        l_register_flag := TRUE ;
      END IF ;
      -- Register tables for specific schema passed
      IF (g_Specific_Schema IS NOT NULL AND
          g_Specific_Schema = p_Schema ) THEN
        l_register_flag := TRUE ;
      END IF ;
    END IF ; -- outer if

    RETURN l_register_flag ;
  END check_to_register;
  --
  -- This procedures populated the initial data for the migration
  --
  PROCEDURE register_table(
			p_Product         IN VARCHAR2 ,
			p_Table_Name      IN VARCHAR2 ,
			p_Old_Column_Name IN VARCHAR2 ,
			p_Old_Data_Type   IN VARCHAR2 ,
			p_New_column_name IN VARCHAR2 ,
			p_New_Data_Type   IN VARCHAR2 ,
			p_Action          IN VARCHAR2 )
  AS
    l_Status          VARCHAR2 (50);
    l_Schema          VARCHAR2 (50);  -- Stores the oracle schema name
    l_dummy_stat      VARCHAR2 (100); -- dummy variable, not used
    l_dummy_ind       VARCHAR2 (100); -- dummy variable, not used
    l_ret_val         BOOLEAN ;       -- dummy variable, not used
    l_New_Column_Name VARCHAR2 (50);
    l_register_flg    BOOLEAN ;
  BEGIN
   IF ( p_Action <> G_NO_ACTION ) THEN -- if p_action <> no action

    IF p_Action IN ( G_DROP_COLUMN ) THEN
      l_Status := G_DROP_OLD_COLUMN_STATUS;
    ELSE
      l_Status := G_INITIALIZED_STATUS;
    END IF ;

    IF ( p_Old_Column_Name = p_New_Column_Name ) THEN
      l_New_Column_Name := 'R118_'||p_Old_Column_Name;
    ELSE
      l_New_Column_Name := p_New_Column_Name;
    END IF ; -- old column name, new column name

--    g_Counter                    := g_Counter + 1;
--    g_TableNames_Tbl(g_Counter)  := p_Table_Name;
--    g_To_DataType_Tbl(g_Counter) := p_New_Data_Type;

    --
    -- The below function call is used to get the oracle schema name
    -- for the product short name passed as parameter.
    -- The schema names can be different from the application short names.
    -- Here, if the p_Prodct is an invalid one the schema name returned
    -- will be null, but since we are passing the same from a hard coded
    -- list it should be a valid one.
    --
    l_ret_val := fnd_installation.get_app_info(
                                                p_Product,
						l_dummy_stat,
						l_dummy_ind,
						l_Schema);
    l_register_flg := FALSE ;
    -- Remove
--   dbms_output.put_line(' Product name '||p_Product);
--   dbms_output.put_line(' table name   '||p_Table_Name);
--   dbms_output.put_line(' schema name  '||l_Schema);

    l_register_flg := check_to_register(
                                 p_Product,
				 p_Table_Name,
				 l_Schema);
    IF ( l_register_flg = TRUE ) THEN
      INSERT INTO AD_LONG_COLUMN_CONVERSIONS (
		schema_name, table_name, old_column_name,
		old_data_type,
		new_column_name, new_data_type,
		action, status
	)
	SELECT  l_Schema, p_Table_Name, p_Old_Column_Name,
	        p_Old_Data_Type,
	        l_New_Column_Name, p_New_Data_Type,
		p_Action, l_Status
	FROM dual
	WHERE NOT EXISTS (
		SELECT 'x'
		FROM   AD_LONG_COLUMN_CONVERSIONS l
		WHERE  l.schema_name     = l_Schema
		AND    l.table_name      = p_Table_Name
		AND    l.old_column_name = p_Old_Column_Name);
     END IF ; -- end if l_register_flg

   END IF ; -- end if p_action <> no action
  END register_table;

  --
  -- This procedure is called initially to populate the
  -- ad_long_column_conversions table with the tables and the related
  -- information.
  --
  PROCEDURE initialize_process(
              p_Specific_Table   VARCHAR2 := NULL ,
	      p_Specific_Product VARCHAR2 := NULL ,
	      p_Specific_Schema  VARCHAR2 := NULL )
  IS
    l_Par_Counter NUMBER ;
  BEGIN
    l_Par_Counter := 0;
    IF ( p_Specific_Table IS NOT NULL ) THEN
      l_Par_Counter := l_Par_Counter + 1;
    END IF ;

    IF ( p_Specific_Product IS NOT NULL ) THEN
      l_Par_Counter := l_Par_Counter + 1;
    END IF ;

    IF ( p_Specific_Schema  IS NOT NULL ) THEN
      l_Par_Counter := l_Par_Counter + 1;
    END IF ;

    IF l_Par_Counter > 1 THEN
      RAISE_APPLICATION_ERROR (-20001,
       ' Error: call Initialize_process with any one of the parameters '||
       ' p_Specific_Table/p_Specific_Product/p_Specific_Schema');
    END IF ;

    -- Set the global variables now
    g_Specific_Table   := p_Specific_Table;
    g_Specific_Product := p_Specific_Product;
    g_Specific_Schema  := p_Specific_Schema;

-- remove
--    g_Counter := 0 ;

	register_table('AHM', 'AHM_DBA_CONSTRAINTS', 'SEARCH_CONDITION', 'LONG', 'SEARCH_CONDITION', 'CLOB', G_WITH_DATA );
	register_table('AHM', 'AHM_DBA_IND_EXPRESSIONS', 'COLUMN_EXPRESSION', 'LONG', 'COLUMN_EXPRESSION', 'CLOB', G_WITH_DATA );
	register_table('AHM', 'AHM_DBA_TAB_COLUMNS', 'DATA_DEFAULT', 'LONG', 'DATA_DEFAULT', 'CLOB', G_WITH_DATA );
	register_table('ALR', 'ALR_ALERTS', 'SQL_STATEMENT_TEXT', 'LONG', 'SQL_STATEMENT_TEXT', 'CLOB', G_WITH_DATA );
	register_table('ALR', 'ALR_PROFILE_OPTIONS', 'PROFILE_OPTION_LONG', 'LONG', 'PROFILE_OPTION_LONG', 'CLOB', G_WITH_DATA );
	register_table('ALR', 'ALR_RESPONSE_MESSAGES', 'BODY', 'LONG', 'BODY', 'CLOB', G_WITH_DATA );
	register_table('ALR', 'ALR_VALID_RESPONSES', 'RESPONSE_TEXT', 'LONG', 'RESPONSE_TEXT', 'CLOB', G_WITH_DATA );
	register_table('AMS', 'AMS_LIST_QUERIES_ALL', 'QUERY', 'LONG', 'QUERY', 'CLOB', G_WITH_DATA );
	register_table('AR', 'AR_APP_RULE_SETS', 'RULE_SOURCE', 'LONG', 'RULE_SOURCE', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_ALL_ORGANIZATION_UNITS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('AZ', 'AZ_SELECTION_SET_APIS', 'FILTERING_PARAMETER', 'LONG', 'FILTERING_PARAMETER', 'CLOB', G_WITH_DATA );
	register_table('AZ', 'AZ_SELECTION_SET_ENTITIES_B', 'FILTERING_PARAMETERS', 'LONG', 'FILTERING_PARAMETERS', 'CLOB', G_WITH_DATA );
	register_table('AZ', 'AZ_STRUCTURE_APIS_B', 'FILTERING_PARAMETER', 'LONG', 'FILTERING_PARAMETER', 'CLOB', G_WITH_DATA );
	register_table('BIC', 'BIC_DEBUG', 'MESSAGE', 'LONG', 'MESSAGE', 'CLOB', G_WITH_DATA );
	register_table('BIS', 'BIS_SCHEDULER', 'CACHED_GRAPH', 'LONG', 'CACHED_GRAPH', 'CLOB', G_WITH_DATA );
	register_table('BOM', 'BOM_DELETE_SQL_STATEMENTS', 'SQL_STATEMENT', 'LONG', 'SQL_STATEMENT', 'CLOB', G_WITH_DATA );
	register_table('BSC', 'BSC_SYS_FILES', 'FILE_BODY', 'LONG RAW', 'FILE_BODY', 'BLOB', G_WITH_DATA );
	register_table('CN', 'CN_OBJECTS_ALL', 'STATEMENT_TEXT', 'LONG', 'STATEMENT_TEXT', 'CLOB', G_WITH_DATA );
	register_table('CN', 'CN_PROCESS_AUDITS_ALL', 'STATEMENT_TEXT', 'LONG', 'STATEMENT_TEXT', 'CLOB', G_WITH_DATA );
	register_table('CN', 'CN_TABLE_MAPS_ALL', 'FILTER', 'LONG', 'FILTER', 'CLOB', G_WITH_DATA );
	register_table('CZ', 'CZ_JRAD_CHUNKS', 'XML_CHUNK', 'LONG', 'XML_CHUNK', 'CLOB', G_WITH_DATA );
	register_table('DDD', 'DDD_3DI_DATA', 'DATA', 'LONG RAW', 'DATA', 'BLOB', G_WITH_DATA );
	register_table('DDD', 'DDD_COLLABORATION_DATA', 'BINARY_DATA', 'LONG RAW', 'BINARY_DATA', 'BLOB', G_WITH_DATA );
	register_table('DDD', 'DDD_MODEL_ATTRIBUTE_VALUES', 'BINARYVAL', 'LONG RAW', 'BINARYVAL', 'BLOB', G_WITH_DATA );
	register_table('DDD', 'DDD_UPDATES_DATA', 'DATA', 'LONG RAW', 'DATA', 'BLOB', G_WITH_DATA );
	register_table('FF', 'FF_COMPILED_INFO_F', 'COMPILED_TEXT', 'LONG', 'COMPILED_TEXT', 'CLOB', G_NO_ACTION );
	register_table('FF', 'FF_FORMULAS_F', 'FORMULA_TEXT', 'LONG', 'FORMULA_TEXT', 'CLOB', G_WITH_DATA );
	register_table('FF', 'FF_QP_REPORTS', 'QP_TEXT', 'LONG', 'QP_TEXT', 'CLOB', G_WITH_DATA );
	register_table('FF', 'FF_ROUTES', 'TEXT', 'LONG', 'TEXT', 'CLOB', G_WITH_DATA );
	register_table('FND', 'FND_COMPILED_DESCRIPTIVE_FLEXS', 'COMPILED_DEFINITION', 'LONG', 'COMPILED_DEFINITION', 'CLOB', 	G_WITH_DATA );
	register_table('FND', 'FND_COMPILED_ID_FLEX_STRUCTS', 'COMPILED_DEFINITION', 'LONG', 'COMPILED_DEFINITION', 'CLOB', 	G_WITH_DATA );
	register_table('FND', 'FND_COMPILED_ID_FLEXS', 'COMPILED_DEFINITION', 'LONG', 'COMPILED_DEFINITION', 'CLOB', G_WITH_DATA );
	register_table('FND', 'FND_DOCUMENTS_LONG_RAW', 'LONG_RAW', 'LONG RAW', 'LONG_RAW', 'BLOB', G_WITH_DATA );
	register_table('FND', 'FND_DOCUMENTS_LONG_TEXT', 'LONG_TEXT', 'LONG', 'LONG_TEXT', 'CLOB', G_WITH_DATA );
	register_table('FND', 'FND_FLEX_VALIDATION_EVENTS', 'USER_EXIT', 'LONG', 'USER_EXIT', 'CLOB', G_WITH_DATA );
	register_table('FND', 'FND_FLEX_VALIDATION_TABLES', 'ADDITIONAL_WHERE_CLAUSE', 'LONG', 'ADDITIONAL_WHERE_CLAUSE', 'CLOB', 	G_WITH_DATA );
	register_table('FND', 'FND_LOBS_DOCUMENT', 'CONTENT', 'LONG RAW', 'CONTENT', 'BLOB', G_WITH_DATA );
	register_table('FND', 'FND_PLAN_TABLE', 'OTHER', 'LONG', 'OTHER', 'CLOB', G_WITH_DATA );
	register_table('FND', 'FND_VIEWS', 'TEXT', 'LONG', 'TEXT', 'CLOB', G_WITH_DATA );
	register_table('FV', 'FV_CFS_REP_LINES', 'FOOTNOTES', 'LONG', 'FOOTNOTES', 'CLOB', G_WITH_DATA );
	register_table('GMA', 'SY_PURG_DEF', 'SQLSTATEMENT', 'LONG', 'SQLSTATEMENT', 'CLOB', G_WITH_DATA );
	register_table('GMD', 'GMD_REPLACE', 'QUERY', 'LONG', 'QUERY', 'CLOB', G_WITH_DATA );
	register_table('HXC', 'HXC_DEBUG_TEXT', 'TEXT', 'LONG', 'TEXT', 'CLOB', G_WITH_DATA );
	register_table('HXC', 'HXC_TIME_CATEGORIES', 'TIME_SQL', 'LONG', 'TIME_SQL', 'CLOB', G_WITH_DATA );
	register_table('IBA', 'IBA_R_RULECONTEXTS', 'RULETEXT', 'LONG', 'RULETEXT', 'CLOB', G_WITH_DATA );
	register_table('IES', 'IES_QUESTION_DATA', 'FREEFORM_LONG', 'LONG', 'FREEFORM_LONG', 'CLOB', G_WITH_DATA );
	register_table('IGI', 'IGI_DOS_ITEMS', 'ITEM_TEXT', 'LONG', 'ITEM_TEXT', 'CLOB', G_WITH_DATA );
	register_table('IGI', 'IGI_EXP_POS_STRUCTURES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('IGS', 'IGS_CO_DTL', 'CORD_TEXT', 'LONG', 'CORD_TEXT', 'CLOB', G_WITH_DATA );
	register_table('IGS', 'IGS_CO_DTL_OLE', 'CORD_OLE', 'LONG RAW', 'CORD_OLE', 'BLOB', G_WITH_DATA );
	register_table('IGS', 'IGS_GE_NOTE', 'NOTE_OLE', 'LONG RAW', 'NOTE_OLE', 'BLOB', G_WITH_DATA );
	register_table('IGS', 'IGS_PE_PERSON_IMAGE', 'PERSON_IMAGE', 'LONG RAW', 'PERSON_IMAGE', 'BLOB', G_WITH_DATA );
	register_table('IGS', 'IGS_UC_APPLICANTS', 'PERSONAL_STATEMENT', 'LONG', 'PERSONAL_STATEMENT', 'CLOB', G_WITH_DATA );
	register_table('IGS', 'IGS_UC_IREFRNC_INTS', 'STATEMENT', 'LONG', 'STATEMENT', 'CLOB', G_WITH_DATA );
	register_table('IGS', 'IGS_UC_ISTMNT_INTS', 'STATEMENT', 'LONG', 'STATEMENT', 'CLOB', G_WITH_DATA );
	register_table('IGS', 'IGS_UC_MV_IVSTMNT', 'STATEMENT', 'LONG', 'STATEMENT', 'CLOB', G_WITH_DATA );
	register_table('IGS', 'IGS_UC_OFFER_CONDS', 'LETTER_TEXT', 'LONG', 'LETTER_TEXT', 'CLOB', G_WITH_DATA );
	register_table('IGW', 'IGW_BUDGET_DETAILS', 'BUDGET_JUSTIFICATION', 'LONG', 'BUDGET_JUSTIFICATION', 'CLOB', G_WITH_DATA );
	register_table('IGW', 'IGW_REPORT_BUDG_JUSTIFICATION', 'JUSTIFICATION', 'LONG', 'JUSTIFICATION', 'CLOB', G_WITH_DATA );
	register_table('IGW', 'IGW_REPORT_ITEMIZED_BUDGET', 'EXPENDITURE_DESCRIPTION', 'LONG', 'EXPENDITURE_DESCRIPTION', 'CLOB', 	G_WITH_DATA );
	register_table('INV', 'MTL_SHORT_CHK_STATEMENTS', 'SHORT_STATEMENT', 'LONG', 'SHORT_STATEMENT', 'CLOB', G_WITH_DATA );
	register_table('JTF', 'JTF_BRM_RULES_B', 'VIEW_DEFINITION', 'LONG', 'VIEW_DEFINITION', 'CLOB', G_WITH_DATA );
	register_table('JTF', 'JTF_R_RULECONTEXTS', 'RULETEXT', 'LONG', 'RULETEXT', 'CLOB', G_WITH_DATA );
	register_table('JTF', 'JTF_R_RULESETS_B', 'RULESET_SER', 'LONG', 'RULESET_SER', 'CLOB', G_WITH_DATA );
	register_table('MSC', 'MSC_ERRORS', 'RROW', 'LONG', 'RROW', 'CLOB', G_WITH_DATA );
	register_table('N/A', 'BEN_COPY_ENTITY_RESULTS', 'INFORMATION323', 'LONG', 'INFORMATION323', 'CLOB', G_WITH_DATA );
	register_table('N/A', 'CSF_M_LOBS_INQ', 'FILE_DATA', 'LONG RAW', 'FILE_DATA', 'BLOB', G_WITH_DATA );
	register_table('N/A', 'CSI_XNP_MSGS_TEMP', 'MSG_TEXT', 'LONG', 'MSG_TEXT', 'CLOB', G_NO_ACTION );
	register_table('N/A', 'CSM_CUSTOM_7_INQ', 'ATTRIBUTE30', 'LONG RAW', 'ATTRIBUTE30', 'BLOB', G_WITH_DATA );
	register_table('N/A', 'IES_META_PROPERTY_VALUES', 'LONG_VAL', 'LONG', 'LONG_VAL', 'CLOB', G_WITH_DATA );
	register_table('N/A', 'RG_REPORT_STANDARD_AXES_B', 'PERIOD_QUERY', 'LONG', 'PERIOD_QUERY', 'VARCHAR2', G_WITH_DATA );
	register_table('OE', 'SO_ACTION_CLAUSES', 'WHERE_CLAUSE', 'LONG', 'WHERE_CLAUSE', 'CLOB', G_NO_ACTION );
	register_table('OE', 'SO_EXCEPTIONS', 'MESSAGE_TEXT', 'LONG', 'MESSAGE_TEXT', 'CLOB', G_NO_ACTION );
	register_table('OE', 'SO_HEADERS_INTERFACE_ALL', 'REPORT_SUMMARY', 'LONG', 'REPORT_SUMMARY', 'CLOB', G_NO_ACTION );
	register_table('OE', 'SO_HOLD_RELEASES', 'RELEASE_COMMENT', 'LONG', 'RELEASE_COMMENT', 'CLOB', G_NO_ACTION );
	register_table('OE', 'SO_HOLD_SOURCES_ALL', 'HOLD_COMMENT', 'LONG', 'HOLD_COMMENT', 'CLOB', G_NO_ACTION );
	register_table('OE', 'SO_LINE_APPROVALS', 'APPROVAL_COMMENT', 'LONG', 'APPROVAL_COMMENT', 'CLOB', G_WITH_DATA );
	register_table('OE', 'SO_NOTES', 'NOTE', 'LONG', 'NOTE', 'CLOB', G_NO_ACTION );
	register_table('OE', 'SO_OBJECTS', 'COMPILED_INFORMATION', 'LONG', 'COMPILED_INFORMATION', 'CLOB', G_NO_ACTION );
	register_table('OE', 'SO_ORDER_APPROVALS', 'APPROVAL_COMMENT', 'LONG', 'APPROVAL_COMMENT', 'CLOB', G_WITH_DATA );
	register_table('OE', 'SO_ORDER_CANCELLATIONS', 'CANCEL_COMMENT', 'LONG', 'CANCEL_COMMENT', 'CLOB', G_NO_ACTION );
	register_table('OE', 'SO_PICKING_CANCELLATIONS', 'CANCEL_COMMENT', 'LONG', 'CANCEL_COMMENT', 'CLOB', G_NO_ACTION );
	register_table('OE', 'SO_STANDARD_VALUE_RULE_SETS', 'COMPILED_INFORMATION', 'LONG', 'COMPILED_INFORMATION', 'CLOB', G_NO_ACTION );
	register_table('OFA', 'FA_RX_LOV', 'SELECT_STATEMENT', 'LONG', 'SELECT_STATEMENT', 'VARCHAR2', G_WITH_DATA );
	register_table('OKE', 'OKE_K_COMMUNICATIONS', 'TEXT', 'LONG', 'TEXT', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_BALANCE_TYPES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PA', 'PA_RULES', 'SELECT_STATEMENT', 'LONG', 'SELECT_STATEMENT', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_CALENDARS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_CONSOLIDATION_SETS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_CUSTOMIZED_RESTRICTIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_ELEMENT_SETS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_MONETARY_UNITS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_PAYROLL_ACTIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_PROCESS_GROUP_ACTIONS', 'ARGUMENT_LIST', 'LONG', 'ARGUMENT_LIST', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_RATES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_SHADOW_FORMULAS', 'FORMULA_TEXT', 'LONG', 'FORMULA_TEXT', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_WC_FUNDS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_WCI_ACCOUNTS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_WCI_OCCUPATIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PAY_WCI_RATES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PAY', 'PER_PAY_PROPOSALS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'BEN_BENEFIT_CLASSIFICATIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_ALL_POSITIONS_F', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_API_TRANSACTIONS', 'URL', 'LONG', 'URL', 'VARCHAR2', G_WITH_DATA );
	register_table('PER', 'HR_COMMENTS', 'COMMENT_TEXT', 'LONG', 'COMMENT_TEXT', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_PUMP_BATCH_LINES', 'PLONGVAL', 'LONG', 'PLONGVAL', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_QUEST_FIELDS', 'HTML_TEXT', 'LONG', 'HTML_TEXT', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_QUESTIONNAIRES', 'TEXT', 'LONG', 'TEXT', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_S_BALANCE_TYPES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_S_BENEFIT_CLASSIFICATIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_S_ELEMENT_SETS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_S_FORMULAS_F', 'FORMULA_TEXT', 'LONG', 'FORMULA_TEXT', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_S_MONETARY_UNITS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_S_QP_REPORTS', 'QP_TEXT', 'LONG', 'QP_TEXT', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_S_ROUTES', 'TEXT', 'LONG', 'TEXT', 'CLOB', G_WITH_DATA );
	register_table('PER', 'HR_TIPS', 'TEXT', 'LONG', 'TEXT', 'CLOB', G_NO_ACTION );
	register_table('PER', 'PER_ABSENCE_ATTENDANCE_TYPES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_ABSENCE_ATTENDANCES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_ADDRESSES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_ALL_POSITIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_ALL_VACANCIES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_APPLICATIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_APPRAISAL_TEMPLATES', 'INSTRUCTIONS', 'LONG', 'INSTRUCTIONS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_ASSESSMENT_TYPES', 'INSTRUCTIONS', 'LONG', 'INSTRUCTIONS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_BOOKINGS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_BUDGET_VERSIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_BUDGETS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_CAREER_PATHS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_COBRA_COV_ENROLLMENTS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_COBRA_COVERAGE_STATUSES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_CONTACT_RELATIONSHIPS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_EVENTS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_GRADES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_IMAGES', 'IMAGE', 'LONG RAW', 'IMAGE', 'BLOB', G_WITH_DATA );
	register_table('PER', 'PER_JOB_EVALUATIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_JOB_REQUIREMENTS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_JOBS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_LETTER_TYPES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_ORGANIZATION_STRUCTURES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_PARENT_SPINES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_PAY_BASES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_PAY_PROPOSAL_COMPONENTS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_PERIODS_OF_SERVICE', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_PERSON_ANALYSES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_POSITION_STRUCTURES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_RECRUITMENT_ACTIVITIES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_SCHED_COBRA_PAYMENTS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_SECONDARY_ASS_STATUSES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_SPECIAL_INFO_TYPES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PER', 'PER_VALID_GRADES', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PO', 'PO_ACCEPTANCES', 'NOTE', 'LONG', 'NOTE', 'CLOB', G_WITH_DATA );
	register_table('PO', 'PO_NOTES', 'NOTE', 'LONG', 'NOTE', 'CLOB', G_WITH_DATA );
	register_table('PQH', 'PQH_COPY_ENTITY_RESULTS', 'LONG_ATTRIBUTE1', 'LONG', 'LONG_ATTRIBUTE1', 'CLOB', G_WITH_DATA );
	register_table('PQH', 'PQH_POSITION_TRANSACTIONS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PQH', 'PQH_PTX_SHADOW', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PQH', 'PQH_TJR_SHADOW', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('PQH', 'PQH_TXN_JOB_REQUIREMENTS', 'COMMENTS', 'LONG', 'COMMENTS', 'CLOB', G_WITH_DATA );
	register_table('RG', 'RG_REPORT_AXIS_SETS', 'COLUMN_SET_HEADER', 'LONG', 'COLUMN_SET_HEADER', 'VARCHAR2', G_WITH_DATA );
	register_table('RG', 'RG_REPORT_STANDARD_AXES', 'PERIOD_QUERY', 'LONG', 'PERIOD_QUERY', 'VARCHAR2', G_WITH_DATA );
	register_table('RLA', 'RLA_DEMAND_EXCEPTIONS', 'REPORT_SUMMARY', 'LONG', 'REPORT_SUMMARY', 'CLOB', G_NO_ACTION );
	register_table('RLM', 'RLM_DEMAND_EXCEPTIONS', 'REPORT_SUMMARY', 'LONG', 'REPORT_SUMMARY', 'CLOB', G_WITH_DATA );
	register_table('WMS', 'WMS_LABEL_REQUESTS_HIST', 'LABEL_CONTENT', 'LONG', 'LABEL_CONTENT', 'CLOB', G_WITH_DATA );
	register_table('WSH', 'WSH_SAVED_QUERIES_B', 'PSEUDO_QUERY', 'LONG', 'PSEUDO_QUERY', 'CLOB', G_WITH_DATA );
	COMMIT ;

        g_Specific_Table   := NULL ;
        g_Specific_Product := NULL ;
        g_Specific_Schema  := NULL ;

  END initialize_process;

  --
  -- The following procedure alters the table to add the new column.
  -- with the new data type.
  -- For each of the tables from AD_LONG_COLUMN_CONVERSIONS
  -- this procedure has to be called repeatedly.
  --
  PROCEDURE add_new_column(p_Schema               IN VARCHAR2 ,
                           p_Table_Name           IN VARCHAR2 ,
                           p_Old_Column_Name      IN VARCHAR2 ,
			   p_New_Column_Name      IN VARCHAR2 ,
                           p_New_Data_Type        IN VARCHAR2 ,
			   p_Curr_Status          IN VARCHAR2 ,
			   p_Action               IN VARCHAR2 )
  IS
     l_stmt            VARCHAR2 (500);
     l_New_Column_Name VARCHAR2 (50);
     l_New_Status      VARCHAR2 (30);
     l_New_Data_Type   VARCHAR2 (30);

  BEGIN -- procedure
    --
    -- The new column has to be added for actions with_data and
    -- without_data only.
    -- And, the new columns will be added only when the tables are in
    -- the initialized status. The below if condition checks both.
    --
    IF ( p_Action IN (G_WITH_DATA, G_WITHOUT_DATA) AND
         p_Curr_Status = G_INITIALIZED_STATUS ) THEN

      l_New_Column_Name := p_New_Column_Name;
      --
      -- If the new column name is same as the old column name
      -- it indicates that the new column has to be added with a
      -- different name.
      --

      IF p_New_Data_Type = 'VARCHAR2' THEN
        l_New_Data_Type := 'VARCHAR2(4000)';
      ELSE
      l_New_Data_Type := p_New_Data_Type;
      END IF ;
      l_stmt := 'ALTER TABLE '||p_schema||'.'||p_Table_Name||
               ' ADD ( '||l_New_Column_Name||'  '||l_New_Data_Type||')';

      BEGIN -- inner block
        EXECUTE IMMEDIATE l_stmt;

      EXCEPTION
        WHEN OTHERS THEN
           IF (SQLCODE = -1430) THEN
              NULL ;
           ELSE
	   -- DBMS_OUTPUT.PUT_LINE('the exeception is here only'); --remove
              RAISE ;
           END IF ;
      END ; -- inner block
      --
      -- If the action is without_data it means that it is enough to add
      -- the new column. No need to migrate the data. So for such cases
      -- the process completes here. Hence for them status is updated as
      -- COMPLETED, so that it wont be picked up in the next stages again.
      --
      IF (p_Action = G_WITHOUT_DATA ) THEN
        l_New_Status := G_DROP_OLD_COLUMN_STATUS;
      ELSE
        l_New_Status := G_ADD_NEW_COLUMN_STATUS;
      END IF ;
      update_table_status(p_Schema,
                           p_Table_Name,
			   p_Old_Column_Name,
                           l_New_Status );

    END IF ; -- end if p_action
  END add_new_column;

  --
  -- This function creates the triggers those are needed to handle
  -- online updates to the long data
  --
  PROCEDURE create_transform_triggers(
                                       p_Schema           IN VARCHAR2 ,
                                       p_Table_Name       IN VARCHAR2 ,
                                       p_Old_Column_Name  IN VARCHAR2 ,
                                       p_New_Column_Name  IN VARCHAR2 ,
                                       p_New_Data_Type    IN VARCHAR2 )

  IS
     l_stmt           VARCHAR2 (2000);
     l_trig_name      VARCHAR2 (30);
     l_lob_value_col  VARCHAR2 (30);
  BEGIN
     --
     -- Depending on the target data type needed, assign the column name
     -- in the temporary table.
     --
     IF (p_New_Data_Type    = 'CLOB') THEN
        l_lob_value_col := 'clob_value';
     ELSIF (p_New_Data_Type = 'BLOB') THEN
        l_lob_value_col := 'blob_value';
     ELSIF (p_New_Data_Type = 'VARCHAR2') THEN
        l_lob_value_col := 'clob_value';
     END IF ;

     --
     -- create a ROW level trigger that inserts rowid for changed or newly
     -- added rows into a temporary table. Trigger is created on the
     -- LONG column.
     --

     l_trig_name := substr(p_Table_Name, 1, 24)||'_$R2U1';

     l_stmt := ' CREATE OR REPLACE TRIGGER '||l_trig_name||
               ' AFTER INSERT OR UPDATE OF '||p_Old_Column_Name||
               ' ON '||p_Schema||'.'||p_Table_Name||
               ' FOR EACH ROW'||
               ' BEGIN'||
               '   INSERT INTO AD_LONG_CONV_TEMP(table_name, apps_rowid) '||
               '   VALUES ('''||p_Table_Name||''', :new.rowid);'||
               ' END;';

     EXECUTE IMMEDIATE l_stmt;
--   dbms_output.put_line('drop trigger '||l_trig_name ||chr(10)||'/');
-- dbms_output.put_line('the first trigger '); -- remove
-- dbms_output.put_line(substr(l_stmt,1,220)); -- remove
-- dbms_output.put_line(substr(l_stmt,220,200)); -- remove

     --
     -- create a STATEMENT level trigger that updates the main table
     -- for the changed rows
     --

     l_trig_name := substr(p_Table_Name, 1, 24)||'_$R2U2';


     l_stmt := ' CREATE OR REPLACE TRIGGER '||l_trig_name||
               ' AFTER INSERT OR UPDATE OF '||p_Old_Column_Name||
               ' ON '||p_Schema||'.'||p_Table_Name||
               ''||
               ' DECLARE '||
               '   CURSOR c_tmp IS '||
               '     SELECT apps_rowid, '||l_lob_value_col||
               '     FROM   AD_LONG_CONV_TEMP2'||
               '     WHERE  table_name = '''||p_Table_Name||''';'||
               ''||
               ' BEGIN'||
               ''||
               '   INSERT INTO AD_LONG_CONV_TEMP2('||
               '     table_name, apps_rowid, '||l_lob_value_col ||' ) '||
               '   SELECT  '''||p_Table_Name||''', t.apps_rowid, '||
               '          to_lob(f.'||p_Old_Column_Name ||')'||
               '   FROM  AD_LONG_CONV_TEMP t, '||p_Schema||
	       '.'||p_Table_Name||' f '||
               '   WHERE f.rowid = t.apps_rowid;'||
               ''||
               '   FOR c_rec in c_tmp LOOP '||
               '     UPDATE '||p_Schema||'.'||p_Table_Name ||
               '     SET  '||p_New_Column_Name ||' = c_rec.'||l_lob_value_col||
               '     WHERE rowid = c_rec.apps_rowid;'||
               '   END LOOP;'||
               ' END;';

--   dbms_output.put_line('drop trigger '||l_trig_name ||chr(10)||'/');
-- remove
-- dbms_output.put_line(substr(l_stmt,1,200));
-- dbms_output.put_line(substr(l_stmt,201,200));
-- dbms_output.put_line(substr(l_stmt,401,200));
-- dbms_output.put_line(substr(l_stmt,601,200));
     EXECUTE IMMEDIATE l_stmt;
-- dbms_output.put_line('after creation of the second trigger ');

     --
     -- Update the table status to G_ADD_TRIGGER_STATUS
     --
     update_table_status( p_Schema ,
                          p_Table_Name ,
			  p_Old_Column_Name ,
                          G_ADD_TRIGGER_STATUS);

  END create_transform_triggers;

  PROCEDURE update_new_data(p_Schema           IN VARCHAR2 ,
                            p_Old_Table_Name   IN VARCHAR2 ,
                            p_Old_Column_Name  IN VARCHAR2 ,
                            p_Old_Data_Type    IN VARCHAR2 ,
                            p_New_Column_Name  IN VARCHAR2 ,
                            p_Batch_Size       IN NUMBER DEFAULT 1000)
  IS
    l_stmt               VARCHAR2 (10000);
    l_lob_value_col_name VARCHAR2 (30);
  BEGIN

    IF (p_Old_Data_Type = 'LONG') THEN
      l_lob_value_col_name := 'clob_value';
    ELSE
      l_lob_value_col_name := 'blob_value';
    END IF ;

    l_stmt := ' declare '||
              '   cursor c_tab is '||
              '     select rowid'||
              '     from  '||p_Schema||'.'||p_Old_Table_Name||
              '     where '||p_Old_Column_Name||' is not null '||
	      '     and '||p_New_Column_Name||' is null; '||
              ''||
              '   cursor c_tab2 is'||
              '     select apps_rowid, '||l_lob_value_col_name||
              '     from  ad_long_conv_temp2;'||
              ''||
              '   rowtab dbms_sql.urowid_table;'||
              ''||
              ' begin'||
              '   open c_tab;'||
              ''||
              '   loop'||
              ''||
              '     fetch c_tab bulk collect into rowtab limit '||
                            p_Batch_Size||';'||
              ''||
              '     exit when rowtab.count = 0;'||
              ''||
              '     forall i in rowtab.FIRST..rowtab.LAST'||
              '       insert into ad_long_conv_temp2(table_name,'||
              '                apps_rowid, '||l_lob_value_col_name||')'||
              '       select '''||p_Old_Table_Name||''','||
              '                 rowid, to_lob('||p_Old_Column_Name||')'||
              '       from '||p_Schema||'.'||p_Old_Table_Name||
              '       where rowid = rowtab(i);'||
              ''||
              '     for c_rec2 in c_tab2 loop'||
              '       update '||p_Schema||'.'||p_Old_Table_Name||
              '       set '||p_New_Column_Name||' = c_rec2.'||
                                           l_lob_value_col_name||
              '       where rowid = c_rec2.apps_rowid;'||
              '     end loop;'||
              ''||
              '     commit;'||
              '   end loop;'||
              ''||
              '   close c_tab;'||
              ' end;';

--remove
--dbms_output.put_line(substr(l_stmt,1,200));
--dbms_output.put_line(substr(l_stmt,201,200));
--dbms_output.put_line(substr(l_stmt,401,200));
--dbms_output.put_line(substr(l_stmt,601,200));

    EXECUTE IMMEDIATE l_stmt;

    --
    -- Update the table status to rows processed.
    --
    update_table_status( p_Schema,
                         p_Old_Table_Name,
			 p_Old_Column_Name,
                         G_UPDATE_ROWS_STATUS);
  END update_new_data;

  --
  -- This function is used to get the length of the LONG data
  --
  FUNCTION get_long_length( p_Table_Name       IN VARCHAR2,
			    p_Long_Column_Name IN VARCHAR2 ,
			    p_Rowid            IN VARCHAR2 )
	RETURN NUMBER
	IS
	  l_cursor     INTEGER;
	  l_ignore     INTEGER;
	  l_stmt       VARCHAR2(100);
	  out_val      VARCHAR2(1001);
	  out_length   INTEGER;
	  l_row_length NUMBER ;
	  num_bytes    INTEGER := 1000; -- length in bytes of the chunk of data to be read.
	  -- value to be selected
	  l_offset     INTEGER; -- the byte position in the LONG column at which

	BEGIN
	  l_stmt := 'SELECT '||p_Long_Column_Name||' FROM '||p_Table_Name||' WHERE ROWID = '''||p_Rowid||'''';
	  l_cursor := DBMS_SQL.OPEN_CURSOR;
	  DBMS_SQL.PARSE(l_cursor, l_stmt, DBMS_SQL.NATIVE);
	  --
	  --Define the LONG column.
	  --
	  DBMS_SQL.DEFINE_COLUMN_LONG(l_cursor, 1);
	  --
	  -- Execute the query.
	  --
	  l_ignore := DBMS_SQL.EXECUTE(l_cursor);

	  IF DBMS_SQL.FETCH_ROWS(l_cursor) > 0 THEN
	      l_offset := 0;
	      l_row_length := 0;
	      --
	      -- Get the value of the LONG column piece by piece. Here a loop
	      -- is used to get the entire column. The loop exits when there
	      -- is no more data.
	      --
	      LOOP
	       --
	       -- Get the value of a portion of the LONG column.
	       --
		DBMS_SQL.COLUMN_VALUE_LONG(l_cursor, 1, num_bytes, l_offset, out_val, out_length);
		IF out_length <> 0 THEN
		  l_offset := l_offset + num_bytes;
		  l_row_length := l_row_length + out_length;
		ELSE
		  EXIT;
		END IF;
		IF out_length < num_bytes THEN
		  EXIT;
		END IF;
	      END LOOP;
	    ELSE
	      l_row_length := 0;
	  END IF;
	  DBMS_SQL.CLOSE_CURSOR(l_cursor);
	  RETURN l_row_length ;
	EXCEPTION
	  WHEN OTHERS THEN
	    -- DBMS_OUTPUT.PUT_LINE ('Errors in function get_long_length');
	    -- DBMS_OUTPUT.PUT_LINE(sqlerrm);
	    IF DBMS_SQL.is_open(l_cursor) THEN
	       DBMS_SQL.CLOSE_CURSOR(l_cursor);
	    END IF;
  END;

  PROCEDURE write_long_rep
  IS
  BEGIN
    write_long_rep('NA');
  END ;

  PROCEDURE write_long_rep( p_Path VARCHAR2)
	IS

	 TYPE cur_type IS REF CURSOR ;
	 l_cursor cur_type;

	 fp               utl_file.file_type;
	 l_Row_4000_Count NUMBER ;
	 l_str            VARCHAR2 (2000);
	 l_query          VARCHAR2 (400);
	 l_number         NUMBER ;
	 l_Rowid          VARCHAR2 (30);
	 l_File_Name      VARCHAR2 (100);
	 l_Path           VARCHAR2 (200);
	 l_pr             NUMBER := 0;
	 l_Sl_No          NUMBER := 0;

	 l_TableNames_Tbl  TableNames_Tbl_Type ;
	 l_To_DataType_Tbl To_DataType_Tbl_Type;

	 CURSOR c1(p_Table_Name VARCHAR2 ) IS
			SELECT table_name, column_name, a.owner, data_type, bytes/1024/1024 t_size
			FROM dba_tab_columns a, dba_segments b
			WHERE data_type IN ('LONG', 'LONG RAW')
			AND table_name = p_Table_name
			AND segment_name = table_name
			AND a.owner NOT IN ('SYS','SYSTEM','OUTLN')
			AND b.owner = a.owner ;

	 PROCEDURE print_data(p_String VARCHAR2 )
	 IS
	 BEGIN
	   IF l_pr = 0 THEN
	     DBMS_OUTPUT.PUT_LINE(l_str);
	   ELSE
	     utl_file.put_line(fp,l_str);
	   END IF ;
	 END print_data;
	BEGIN
	  l_Path := p_Path;
	  IF INSTR (l_Path,'/') = 0 THEN
	    IF INSTR (l_Path,'\') = 0 THEN
	      l_Path := UPPER (p_Path);
	    END IF ;
	  END IF ;
	  IF l_Path = 'NA' THEN
	    l_pr := 0;
	  ELSE
	    l_pr := 1;
	  END IF ;

--          initialize_process;
          -- Load the information from the control table
	  SELECT table_name, NEW_DATA_TYPE
	  BULK COLLECT
	  INTO l_TableNames_Tbl, l_To_DataType_Tbl
	  FROM ad_long_column_conversions;

	  IF l_TableNames_Tbl.COUNT = 0 THEN
	    RAISE_APPLICATION_ERROR (-20001,
	      ' The tables are not Initialized.'||
              ' Please use Ad_LongToLob_Pkg.initialize_process to'||
              ' initialize the tables for generating report. ');
	  END IF ;

	  BEGIN -- begin for the main block of actions
            l_File_Name := 'long_report.'||to_char(sysdate,'DD-MON-YY.HH24:MI:SS')||'.txt';
	    IF (l_pr = 1 ) THEN
	      fp := utl_file.fopen(l_Path,l_File_Name,'w');
            END IF ;

	    l_str := 'Sl.No  '||lpad('Table Name',28)||'*'|| lpad('Column Name',29)||'*'|| lpad('Owner',11)||'*'||
		   lpad('Data Type',14)||'*'|| lpad('Table Size',14)||'*'|| lpad('Total Rows',14) ||'*'||
		   lpad('Not Null Rows',20)||'*'||lpad('Rows > 4000 ',20);
	    print_data(l_str);
	    l_str := lpad('-',161,'-');
	    print_data(l_str);

	    FOR i IN l_TableNames_Tbl.FIRST .. l_TableNames_Tbl.LAST LOOP
	      FOR rec IN c1(l_TableNames_Tbl(i)) LOOP
	       l_str := NULL ;
	       l_Row_4000_Count := 0;
	       l_Sl_No := l_Sl_No + 1;
	       l_str := rpad(l_Sl_No,6)||'-'||lpad(rec.table_name,29)||lpad(rec.column_name,30)|| lpad(rec.owner,12)||
		     lpad(rec.data_type,15)|| lpad(rec.t_size,15);
	       l_query := null;
	       l_query := 'select count(*) from '||rec.owner||'.'||rec.table_name;
	       execute immediate l_query into l_number;
	       l_str := l_str || lpad(l_number,15);
	       l_query := null;
	       l_query := 'select count(*) from '||rec.owner||'.'||rec.table_name||' where '||rec.column_name||' is not null';
	       execute immediate l_query into l_number;
	       l_str := l_str || lpad(l_number,20);
	       IF l_To_DataType_Tbl(i) = 'VARCHAR2' THEN
	         IF l_cursor%ISOPEN THEN
		   CLOSE l_cursor;
	         END IF ; -- if %is open
	         OPEN l_cursor FOR 'SELECT ROWID FROM '||rec.table_name;
	         LOOP
		   FETCH l_cursor INTO l_Rowid;
		   EXIT WHEN l_cursor%NOTFOUND ;
		   IF get_long_length(rec.table_name,
				      rec.column_name,
				      l_Rowid) > 4000 THEN
		      l_Row_4000_Count := l_Row_4000_Count +1;
		   END IF ;
	         END LOOP ;
	       END IF ;
	       l_str := l_str || lpad(l_Row_4000_Count ,20);
	       print_data(l_str);
	      END LOOP ;
	    END LOOP ;
	    IF (l_pr = 1 ) THEN
	      utl_file.fclose(fp);
	    END IF ;
          END; -- end for the main block of actions
  END write_long_rep;

  --
  -- This procedure can be used to defer the processing of a table.
  -- It can be called at any stage of processing of the table.
  -- I.e. Before starting the Long To LOB conversion, after adding the
  -- new column, after creating the triggers or after converting the data
  --
  PROCEDURE defer_table( p_Schema          IN VARCHAR2 ,
                         p_Table_Name      IN VARCHAR2 )
  IS
    l_Current_Status ad_long_column_conversions.status%TYPE ;
    l_Count          NUMBER(3) ;
  BEGIN
    --
    -- Since this procedure can be called even before starting any of the
    -- processing steps,
    -- the follwing select checks whether the table is initialized.
    -- If not the initialize_process is called to initialize the tables.
    --
    SELECT COUNT(*)
    INTO   l_Count
    FROM   ad_long_column_conversions
    WHERE  schema_name = p_Schema
    AND    table_name  = p_Table_Name ;

    --
    -- The table is not initialized, so call initialize_process
    --
    IF l_Count = 0 THEN
--      initialize_process;
-- Instead raise an error saying that the table is not initialized
      raise_application_error(-20001,
       ' The table is not Initialized.'||
       ' Please use Ad_LongToLob_Pkg.initialize_process to'||
       ' initialize the table for processing ');
    END IF ;

    --
    -- Lock the row for the table to make sure that status of the
    -- table is not being updated by any other session.
    -- If the table name being passed is a wrong one, this select
    -- comes out saying the exception.
    --
    SELECT status
    INTO   l_Current_Status
    FROM   ad_long_column_conversions
    WHERE  schema_name = p_Schema
    AND    table_name  = p_Table_Name
    FOR UPDATE NOWAIT ;

    --
    -- Now update the status to indicate that the table is deferred.
    -- The status will be 'DEFFERRED_'||old_status.
    --
    UPDATE ad_long_column_conversions
    SET    status = G_DEFERRED_STATUS||'_'||status
    WHERE  schema_name = p_Schema
    AND    table_name  = p_Table_Name;

    -- commit the transaction
    COMMIT ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'The table '||p_Schema||'.'||p_Table_Name||
                    ' is not initialized for Long to Lob conversion. ');
  END defer_table;

  --
  -- This procedure is used to re-enable the deferred tables
  --
  PROCEDURE re_enable_table(p_Schema          IN VARCHAR2 ,
                            p_Table_Name      IN VARCHAR2 )
  IS
    l_Prev_Status    ad_long_column_conversions.status%TYPE ;
  BEGIN
    --
    -- Lock the entry in ad_long_column_conversions corresponding to the
    -- table being re-enabled.
    --
    SELECT LTRIM (status,G_DEFERRED_STATUS||'_')
    INTO   l_Prev_Status
    FROM   ad_long_column_conversions
    WHERE  schema_name = p_Schema
    AND    table_name  = p_Table_Name
    AND    status LIKE G_DEFERRED_STATUS||'_%'
    FOR UPDATE NOWAIT ;

    --
    -- Update status of the table to the prior status.
    --
    UPDATE ad_long_column_conversions
    SET    status      = l_Prev_Status
    WHERE  schema_name = p_Schema
    AND    table_name  = p_Table_Name;

    -- commit the transaction
    COMMIT ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'The table '||p_Schema||'.'||p_Table_Name||
       ' is not a deferred table. ');
  END re_enable_table;

END Ad_LongToLob_Pkg;
