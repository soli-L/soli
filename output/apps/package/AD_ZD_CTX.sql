
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_CTX" AUTHID DEFINER
/* $Header: ADZDCTXS.pls 120.0.12020000.3 2021/06/09 17:35:45 rsatyava ship $ */
AS
    PROCEDURE SET_DDL_ID(x_ddl_id in number default null);
    PROCEDURE SET_HOSTNAME(x_hostname in varchar2 default null);
END ad_zd_ctx;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_CTX" 
/* $Header: ADZDCTXB.pls 120.0.12020000.2 2016/02/03 11:13:31 seetsing noship $ */
AS
    PROCEDURE SET_DDL_ID(x_ddl_id in number default null)
    is
    BEGIN
      DBMS_SESSION.SET_CONTEXT('AD_ZD_CTX','DDL_ID',X_DDL_ID);
    END;

    PROCEDURE SET_HOSTNAME(x_hostname in varchar2 default null)
    is
    BEGIN
      DBMS_SESSION.SET_CONTEXT('AD_ZD_CTX','HOSTNAME',X_HOSTNAME);
    END;
END ad_zd_ctx;
