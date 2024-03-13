--------------------------------------------------------
--  DDL for Table PAID_ITEMS_TMP
--------------------------------------------------------

  CREATE TABLE "CISADM_APPS"."PAID_ITEMS_TMP" 
   (	"TRAN_NO" NUMBER, 
	"SEQ_NO" NUMBER(3,0), 
	"PAY_CODE" VARCHAR2(20 BYTE), 
	"AMOUNT_CREDIT" NUMBER(15,2)
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "CISTS_DATA01" ;
--------------------------------------------------------
--  DDL for Index PAID_ITEMS_TMP_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "CISADM_APPS"."PAID_ITEMS_TMP_PK" ON "CISADM_APPS"."PAID_ITEMS_TMP" ("TRAN_NO", "SEQ_NO") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "CISTS_DATA01" ;
--------------------------------------------------------
--  Constraints for Table PAID_ITEMS_TMP
--------------------------------------------------------

  ALTER TABLE "CISADM_APPS"."PAID_ITEMS_TMP" MODIFY ("TRAN_NO" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."PAID_ITEMS_TMP" MODIFY ("SEQ_NO" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."PAID_ITEMS_TMP" MODIFY ("PAY_CODE" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."PAID_ITEMS_TMP" ADD CONSTRAINT "PAID_ITEMS_TMP_PK" PRIMARY KEY ("TRAN_NO", "SEQ_NO")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "CISTS_DATA01"  ENABLE;
--------------------------------------------------------
--  Ref Constraints for Table PAID_ITEMS_TMP
--------------------------------------------------------

  ALTER TABLE "CISADM_APPS"."PAID_ITEMS_TMP" ADD CONSTRAINT "PAID_ITEMS_TMP_FK" FOREIGN KEY ("TRAN_NO")
	  REFERENCES "CISADM_APPS"."PAYMENT_TRANSACTIONS_TMP" ("TRAN_NO") ENABLE;
