
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_SQL" AUTHID CURRENT_USER as
/* $Header: ADZDSQLS.pls 120.0.12020000.3 2021/09/15 04:42:26 jwsmith noship $ */

/* Check if a Forward CrossEdition Trigger is applicable on the system. */
/*
** NOTES
**   This procedure is intended to be called from the start of a crossedition
**   trigger creation script.  The caller specifies a new or revised column
**   to be populated by the FCET.  This script will confirm that the output
**   column is only visible to the patch edition.  If the output column is
**   in use by a previous edition then the FCET is obsolete and the script
**   will exit, otherwise control will return to the trigger creation script.
*/
  procedure CHECK_CET(
      X_TABLE_OWNER   in varchar2,
      X_TABLE_NAME    in varchar2,
      X_OUTPUT_COLUMN in varchar2);

end AD_ZD_SQL;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_SQL" as
/* $Header: ADZDSQLB.pls 120.0.12020000.5 2021/09/15 18:33:54 jwsmith noship $ */

/*
** Check if a Forward CrossEdition Trigger is applicable on the system.
**
** NOTES
**   This procedure is intended to be called from the start of a crossedition
**   trigger creation script.  The caller specifies a new or revised column
**   to be populated by the FCET.  This script will confirm that the output
**   column is only visible to the patch edition.  If the output column is
**   in use by a previous edition then the FCET is obsolete and the script
**   will exit, otherwise control will return to the trigger creation script.
*/
procedure CHECK_CET(
   X_TABLE_OWNER    in varchar2,
   X_TABLE_NAME     in varchar2,
   X_OUTPUT_COLUMN  in varchar2)
is
  C_MODULE           varchar2(80) := 'ad.plsql.ad_zd_sql.check_cet';
  RUN_EV_COLUMN_NAME varchar2(30);
  EV_NAME            varchar2(30);

begin
   ad_zd.log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name||
             ', Output Column='||x_output_column);

   EV_NAME := ad_zd_table.ev_view(X_TABLE_NAME);

   select evc.table_column_name runev_column_name
   into   RUN_EV_COLUMN_NAME
   from
       ( select max(evae.edition_name) edition_name
           , evae.owner view_owner
           , evae.view_name
           , evae.table_name
         from all_editioning_views_ae evae
         where evae.owner     = upper(X_TABLE_OWNER)
           and evae.view_name = EV_NAME
           and evae.table_name= upper(X_TABLE_NAME)
           and evae.edition_name < ad_zd.get_edition
         group by evae.owner, evae.view_name, evae.table_name) runev,
                  all_editioning_view_cols_ae evc
   where evc.edition_name     = runev.edition_name
     and evc.owner            = runev.view_owner
     and evc.view_name        = runev.view_name
     and evc.view_column_name = ad_zd_table.ev_view_column(upper(X_OUTPUT_COLUMN));

  if upper(RUN_EV_COLUMN_NAME) >= upper(X_OUTPUT_COLUMN) then
    ad_zd.log(c_module, 'WARNING', 'Skipping create of obsolete crossedition trigger for '||
        X_TABLE_OWNER||'.'||X_TABLE_NAME||' '||X_OUTPUT_COLUMN);
    raise_application_error(-20001, 'WARNING: Skipping create of obsolete crossedition trigger for '||
        X_TABLE_OWNER||'.'||X_TABLE_NAME||' '||X_OUTPUT_COLUMN);
  end if;

  ad_zd.log(c_module, 'PROCEDURE', 'end');

  exception when no_data_found then
    ad_zd.log(c_module, 'STATEMENT', 'No data found');
    ad_zd.log(c_module, 'PROCEDURE', 'end');

end CHECK_CET;

end AD_ZD_SQL;
