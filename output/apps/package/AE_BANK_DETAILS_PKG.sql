
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AE_BANK_DETAILS_PKG" AUTHID CURRENT_USER AS
 -- $Header: peaebank.pkh 120.0 2011/12/14 12:25:50 abdash noship $
 --
 --
 -- Validates the International bank account number for AE.
 --
 -- The format is AE123456789012345678901
 --
 --

FUNCTION validate_account
         (p_iban_account_number IN VARCHAR2,
          p_account_number      IN VARCHAR2
	  ) RETURN NUMBER;


END ae_bank_details_pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AE_BANK_DETAILS_PKG" AS
 -- $Header: peaebank.pkb 120.0 2011/12/14 12:28:12 abdash noship $
 --
 --
 -- Validates the AE International bank account number.
 --
 -- The format is AE123456789012345678901
 --


FUNCTION validate_account
         (p_iban_account_number IN VARCHAR2,
          p_account_number      IN VARCHAR2
	 )

RETURN NUMBER

IS

BEGIN

 IF (p_iban_account_number is not null) THEN

    IF length(p_iban_account_number) <> 23 THEN
             return 1;
    END IF;
 ELSIF (p_iban_account_number is null and p_account_number is null) then
    return 2;
 END IF;

return 0;

END validate_account;

END ae_bank_details_pkg;
