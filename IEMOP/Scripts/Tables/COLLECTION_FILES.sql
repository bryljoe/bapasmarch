--------------------------------------------------------
--  DDL for Table COLLECTION_FILES
--------------------------------------------------------

  CREATE TABLE "CISADM_APPS"."COLLECTION_FILES" 
   (	"HDR_ID" NUMBER, 
	"DU_CD" VARCHAR2(10 BYTE), 
	"FILE_ID" NUMBER, 
	"FILE_TYPE" VARCHAR2(10 BYTE), 
	"FILE_NAME" VARCHAR2(255 BYTE), 
	"ATTACHMENT" CLOB, 
	"CREATED_BY" VARCHAR2(30 BYTE), 
	"CREATED_ON" DATE, 
	"UPLOADED_BY" VARCHAR2(30 BYTE), 
	"UPLOADED_ON" DATE, 
	"STATUS" VARCHAR2(5 BYTE) DEFAULT 'P'
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "CISTS_DATA01" 
 LOB ("ATTACHMENT") STORE AS SECUREFILE (
  TABLESPACE "CISTS_DATA01" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES ) ;

   COMMENT ON COLUMN "CISADM_APPS"."COLLECTION_FILES"."STATUS" IS 'P = Pending, U = Uploaded, E = Error, C = Cancelled';
--------------------------------------------------------
--  DDL for Index COLLECTION_FILES_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "CISADM_APPS"."COLLECTION_FILES_PK" ON "CISADM_APPS"."COLLECTION_FILES" ("HDR_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "CISTS_DATA01" ;
--------------------------------------------------------
--  DDL for Trigger COLLECTION_FILES_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "CISADM_APPS"."COLLECTION_FILES_TRG" before
  insert on collection_files
  for each row
   WHEN (new.hdr_id is null) begin
  select collection_files_seq.nextval
  into :new.hdr_id
  from dual;

exception
  when others then
    raise_application_error(-20001, sqlerrm);
end;

/
ALTER TRIGGER "CISADM_APPS"."COLLECTION_FILES_TRG" ENABLE;
--------------------------------------------------------
--  Constraints for Table COLLECTION_FILES
--------------------------------------------------------

  ALTER TABLE "CISADM_APPS"."COLLECTION_FILES" MODIFY ("HDR_ID" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."COLLECTION_FILES" MODIFY ("DU_CD" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."COLLECTION_FILES" MODIFY ("FILE_ID" NOT NULL ENABLE);
  ALTER TABLE "CISADM_APPS"."COLLECTION_FILES" ADD CONSTRAINT "COLLECTION_FILES_PK" PRIMARY KEY ("HDR_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "CISTS_DATA01"  ENABLE;
