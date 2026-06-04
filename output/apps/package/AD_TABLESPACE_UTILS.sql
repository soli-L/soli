
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_TABLESPACE_UTILS" AUTHID CURRENT_USER AS
  -- $Header: adsputls.pls 120.0 2005/05/25 12:05:00 appldev noship $

procedure get_mview_tablespaces
           (X_data_tablespace  out nocopy varchar2,
            X_index_tablespace out nocopy varchar2);

END;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_TABLESPACE_UTILS" AS
  -- $Header: adsputlb.pls 120.0 2005/05/25 11:50:10 appldev noship $

  --
  -- Procedure to return tablespaces to used for Materialized Views.
  -- All Materialized view must be created in APPS but using a set
  -- of tablespaces for storage. In the current release, the
  -- tablespaces associated with BIS will be used.
  --
procedure get_mview_tablespaces
           (X_data_tablespace  out nocopy varchar2,
            X_index_tablespace out nocopy varchar2)
as
    l_data_tablespace  varchar2(30);
    l_index_tablespace varchar2(30);
  begin

    select tablespace, index_tablespace
    into   X_data_tablespace, X_index_tablespace
    from   fnd_product_installations
    where  application_id = 191 -- BIS application id
    and    install_group_num in (0, 1);

  end;

END;
