--------------------------------------------------------
--  DDL for Table CRC_ACCT_NO_MAPPINGS_TMP
--------------------------------------------------------

  CREATE TABLE "CISADM_APPS"."CRC_ACCT_NO_MAPPINGS_TMP" 
   (	"CRC" NUMBER(10,0), 
	"ACCT_NO" VARCHAR2(10 BYTE), 
	"ACCT_STATUS" VARCHAR2(1 BYTE), 
	"SCHEDULE" VARCHAR2(20 BYTE), 
	"AREA_CODE" VARCHAR2(4 BYTE), 
	"GOVERNMENT_CODE" VARCHAR2(2 BYTE), 
	"TIN" VARCHAR2(20 BYTE), 
	"CFNP_REQUIRED_AMT" NUMBER(15,2), 
	"LAST_DATE_PAID" DATE, 
	"LAST_AMOUNT_PAID" NUMBER(15,2), 
	"BD_REQUIRED_AMT" NUMBER(15,2), 
	"EMP_ACCT" NUMBER(1,0) DEFAULT 0, 
	"BUS_ADD" VARCHAR2(100 BYTE), 
	"BUS_ACTIVITY" VARCHAR2(100 BYTE)
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "CISTS_DATA01" ;
--------------------------------------------------------
--  DDL for Index CRC_ACCT_NO_MAPPINGS_TMP_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "CISADM_APPS"."CRC_ACCT_NO_MAPPINGS_TMP_PK" ON "CISADM_APPS"."CRC_ACCT_NO_MAPPINGS_TMP" ("ACCT_NO", "CRC") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "CISTS_DATA01" ;
--------------------------------------------------------
--  Constraints for Table CRC_ACCT_NO_MAPPINGS_TMP
--------------------------------------------------------

  ALTER TABLE "CISADM_APPS"."CRC_ACCT_NO_MAPPINGS_TMP" MODIFY ("CRC" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."CRC_ACCT_NO_MAPPINGS_TMP" MODIFY ("ACCT_NO" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."CRC_ACCT_NO_MAPPINGS_TMP" ADD CONSTRAINT "CRC_ACCT_NO_MAPPINGS_TMP_PK" PRIMARY KEY ("ACCT_NO", "CRC")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "CISTS_DATA01"  ENABLE;