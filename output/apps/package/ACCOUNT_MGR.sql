
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."ACCOUNT_MGR" AUTHID CURRENT_USER AS
/* $Header: JTFAACTS.pls 120.1 2005/07/02 01:59:21 appldev ship $ */

  FUNCTION query_accounts(API_VERSION IN NUMBER DEFAULT 1.0,
                          P_PARTY_ID  IN NUMBER DEFAULT 1220) RETURN VARCHAR2;

  PROCEDURE test(API_VERSION IN NUMBER DEFAULT 1.0,
                 P_PARTY_ID  IN NUMBER DEFAULT 1220);

END ACCOUNT_MGR;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."ACCOUNT_MGR" AS
/* $Header: JTFAACTB.pls 115.3 2002/09/06 21:41:37 badams ship $ */

  FUNCTION query_accounts(API_VERSION IN NUMBER,
                          P_PARTY_ID  IN NUMBER)
  RETURN VARCHAR2 IS

     l_sort_data               JTF_TASKS_PUB.SORT_DATA;
     l_total_retrieved         NUMBER;
     l_total_returned          NUMBER;
     l_rs                      VARCHAR2(1);
     l_msg_count               NUMBER;
     l_msg_data                VARCHAR2(2000);
     l_version_num             NUMBER;

     l_account_name            VARCHAR2(2000);

     -- temporary strings...
     l_account0                VARCHAR2(4000) := '';
     l_account1                VARCHAR2(4000) := '';
     l_account2                VARCHAR2(4000) := '';
     l_account3                VARCHAR2(4000) := '';
     l_account4                VARCHAR2(4000) := '';

     new_row                   VARCHAR2(4000) := '';
     result                    VARCHAR2(4000) := '';

     current_count             NUMBER := 1;
     row_count                 NUMBER := 10;

     CURSOR ACCOUNT_DATA IS
        SELECT ACCOUNT_NAME, PARTY_ID
        FROM   HZ_CUST_ACCOUNTS
        WHERE  PARTY_ID = P_PARTY_ID
        ORDER BY 1;

     one_row ACCOUNT_DATA%rowtype;

  BEGIN

--DBMS_OUTPUT.PUT_LINE('Querying account data...');

     OPEN ACCOUNT_DATA;
     FETCH ACCOUNT_DATA INTO one_row;

     WHILE ACCOUNT_DATA%FOUND LOOP

       current_count := current_count + 1;
       IF (current_count > row_count) THEN
         EXIT;
       END IF;

       l_account_name      := one_row.account_name;

       IF( l_account_name IS NULL ) THEN
         l_account_name := 'account_name null '|| one_row.party_id;
       END IF;

       new_row := trim(l_account_name);

       result := result||new_row||'^';

       FETCH ACCOUNT_DATA INTO one_row;
     END LOOP;

     CLOSE ACCOUNT_DATA;

     l_account0 := 'AccountName0^2000^100';
     l_account1 := 'AccountName1^2001^101';
     l_account2 := 'AccountName2^2002^102';
     l_account3 := 'AccountName3^2003^103';
     l_account4 := 'AccountName4^2004^104';

     result := result||'^'||l_account0||'^'||
                            l_account1||'^'||
                            l_account2||'^'||
                            l_account3||'^'||
                            l_account4;

     RETURN( result );

  END QUERY_ACCOUNTS;


  PROCEDURE test(API_VERSION IN NUMBER,
                 P_PARTY_ID  IN NUMBER) IS

     l_sort_data               JTF_TASKS_PUB.SORT_DATA;
     l_total_retrieved         NUMBER;
     l_total_returned          NUMBER;
     l_rs                      VARCHAR2(1);
     l_msg_count               NUMBER;
     l_msg_data                VARCHAR2(2000);
     l_version_num             NUMBER;

     -- temporary strings...
     l_account0                VARCHAR2(4000) := '';
     l_account1                VARCHAR2(4000) := '';
     l_account2                VARCHAR2(4000) := '';
     l_account3                VARCHAR2(4000) := '';
     l_account4                VARCHAR2(4000) := '';

     l_account_name            VARCHAR2(2000);

     new_row                   VARCHAR2(4000) := '';
     result                    VARCHAR2(4000) := '';

     current_count             NUMBER := 1;
     row_count                 NUMBER := 10;

     CURSOR ACCOUNT_DATA IS
        SELECT ACCOUNT_NAME, PARTY_ID
        FROM   HZ_CUST_ACCOUNTS
        WHERE  PARTY_ID = P_PARTY_ID
        ORDER BY 1;

     one_row ACCOUNT_DATA%rowtype;

  BEGIN

--     DBMS_OUTPUT.PUT_LINE('TEST querying account data...');

     OPEN ACCOUNT_DATA;
     FETCH ACCOUNT_DATA INTO one_row;

     WHILE ACCOUNT_DATA%FOUND LOOP

       l_account_name      := one_row.account_name;

       IF( l_account_name IS NULL ) THEN
         l_account_name := 'account_name null '|| one_row.party_id;
       END IF;

       new_row := trim(l_account_name);

       result := result||new_row||'^';

--DBMS_OUTPUT.PUT_LINE('3 current_count = '||current_count);
--DBMS_OUTPUT.PUT_LINE('3 new row       = '||new_row);

       current_count := current_count + 1;
       IF (current_count > row_count) THEN
         EXIT;
       END IF;

       FETCH ACCOUNT_DATA INTO one_row;

     END LOOP;

     CLOSE ACCOUNT_DATA;

     l_account0 := 'AccountName0^2000^100';
     l_account1 := 'AccountName1^2001^101';
     l_account2 := 'AccountName2^2002^102';
     l_account3 := 'AccountName3^2003^103';
     l_account4 := 'AccountName4^2004^104';

     result := result||'^'||l_account0||'^'||
                            l_account1||'^'||
                            l_account2||'^'||
                            l_account3||'^'||
                            l_account4;

--DBMS_OUTPUT.PUT_LINE('result = '||result);

  END test;

END ACCOUNT_MGR;
