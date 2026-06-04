
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_JAR" AUTHID CURRENT_USER as
/* $Header: ADJRIS.pls 120.0.12020000.2 2013/05/16 04:28:55 mkumandu noship $ */

procedure get_jripasswords(storepass OUT NOCOPY varchar2,
                           keypass OUT NOCOPY varchar2);

procedure put_jripasswords(storepass in varchar2 default null,
                           keypass in varchar2 default null);

procedure del_jripasswords;

end AD_JAR;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_JAR" as
/* $Header: ADJRIB.pls 120.0.12020000.2 2013/05/16 04:29:40 mkumandu noship $ */


/*-----------------------------------------------------------------+
 |                                                                 |
 | get_jripasswords - Gets JRI passwords from FND_VAULT.           |
 |                                                                 |
 +-----------------------------------------------------------------*/
procedure get_jripasswords(storepass OUT NOCOPY varchar2,
                           keypass OUT NOCOPY varchar2)
is
l_storepass varchar2(30);
l_keypass varchar2(30);
begin

  dbms_session.set_context('AD_JAR', 'VAULT_ACCESS', 'Y');

  l_storepass := fnd_vault.get('AD_JAR', 'STOREPASS');
  l_keypass   := fnd_vault.get('AD_JAR', 'KEYPASS');

  dbms_session.set_context('AD_JAR', 'VAULT_ACCESS', 'N');

  storepass := nvl(l_storepass, 'NOT-EXIST');
  keypass   := nvl(l_keypass, 'NOT-EXIST');

end get_jripasswords;

/*-----------------------------------------------------------------+
 |                                                                 |
 | put_jripasswords - Puts JRI passwords into FND_VAULT.           |
 |                                                                 |
 +-----------------------------------------------------------------*/
procedure put_jripasswords(storepass in varchar2 default null,
                           keypass in varchar2 default null)
is
begin

  if (storepass is null and keypass is null)
  then
    raise_application_error(-20001, 'Both Store Password and Key Password cannot be null');
  end if;

  dbms_session.set_context('AD_JAR', 'VAULT_ACCESS', 'Y');

  if (storepass is not null)
  then
    fnd_vault.puts('AD_JAR', 'STOREPASS', storepass);
  end if;

  if (keypass is not null)
  then
    fnd_vault.puts('AD_JAR', 'KEYPASS', keypass);
  end if;

  dbms_session.set_context('AD_JAR', 'VAULT_ACCESS', 'N');

end put_jripasswords;


/*-----------------------------------------------------------------+
 |                                                                 |
 | del_jripasswords - Deletes JRI passwords from FND_VAULT.        |
 |                                                                 |
 +-----------------------------------------------------------------*/
procedure del_jripasswords
is
begin

  dbms_session.set_context('AD_JAR', 'VAULT_ACCESS', 'Y');

  fnd_vault.del('AD_JAR', 'STOREPASS');
  fnd_vault.del('AD_JAR', 'KEYPASS');

  dbms_session.set_context('AD_JAR', 'VAULT_ACCESS', 'N');

end del_jripasswords;


end AD_JAR;
