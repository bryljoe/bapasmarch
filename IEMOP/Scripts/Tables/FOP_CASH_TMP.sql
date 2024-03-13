--------------------------------------------------------
--  DDL for Table FOP_CASH_TMP
--------------------------------------------------------

  CREATE TABLE "CISADM_APPS"."FOP_CASH_TMP" 
   (	"TRAN_NO" NUMBER, 
	"SEQ_NO" NUMBER(3,0), 
	"AMOUNT_TENDERED" NUMBER(15,2)
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "CISTS_DATA01" ;
--------------------------------------------------------
--  DDL for Index FOP_CASH_TMP_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "CISADM_APPS"."FOP_CASH_TMP_PK" ON "CISADM_APPS"."FOP_CASH_TMP" ("TRAN_NO", "SEQ_NO") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "CISTS_DATA01" ;
--------------------------------------------------------
--  Constraints for Table FOP_CASH_TMP
--------------------------------------------------------

  ALTER TABLE "CISADM_APPS"."FOP_CASH_TMP" MODIFY ("TRAN_NO" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."FOP_CASH_TMP" MODIFY ("SEQ_NO" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."FOP_CASH_TMP" ADD CONSTRAINT "FOP_CASH_TMP_PK" PRIMARY KEY ("TRAN_NO", "SEQ_NO")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "CISTS_DATA01"  ENABLE;
--------------------------------------------------------
--  Ref Constraints for Table FOP_CASH_TMP
--------------------------------------------------------

  ALTER TABLE "CISADM_APPS"."FOP_CASH_TMP" ADD CONSTRAINT "FOP_CASH_TMP_FK" FOREIGN KEY ("TRAN_NO", "SEQ_NO")
	  REFERENCES "CISADM_APPS"."FORMS_OF_PAYMENT_TMP" ("TRAN_NO", "SEQ_NO") ENABLE;
