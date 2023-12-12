
CREATE  Procedure [dbo].[sp_DeleteMSByEmployee]
@MSID  bigint,
@EmployeeID bigint = 0
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

BEGIN TRY
BEGIN TRANSACTION


IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
BEGIN
DROP TABLE #ManagmetnStrcture 
END
CREATE TABLE #ManagmetnStrcture 
(
 ID BIGINT NOT NULL IDENTITY, 
 ManagementStructureId BIGINT NULL,
 IsCheck bit default 0
)

INSERT INTO #ManagmetnStrcture 
(ManagementStructureId,IsCheck)
SELECT @MSID,1

INSERT INTO 
#ManagmetnStrcture 
(ManagementStructureId)
SELECT * from dbo.udfGetMSByMSId(@MSID)

Declare  @CNT as int = 0; 
Declare  @SMSID as int = 0; 
Select TOP 1 @CNT = ID,@SMSID = ManagementStructureId  FROM #ManagmetnStrcture WHERE IsCheck = 0 ORDER BY ID 

WHILE (@SMSID > 0)
BEGIN
INSERT INTO 
#ManagmetnStrcture 
(ManagementStructureId)
SELECT * from dbo.udfGetMSByMSId(@SMSID)

SET @SMSID = 0;
UPDATE #ManagmetnStrcture SET IsCheck = 1 WHERE ID  = @CNT
Select TOP 1 @CNT = ID,@SMSID = ManagementStructureId  FROM #ManagmetnStrcture WHERE IsCheck = 0 ORDER BY ID 

END
DELETE EMS FROM dbo.EmployeeManagementStructure EMS WITH (NOLOCK)
INNER JOIN #ManagmetnStrcture MS 
on EMS.ManagementStructureId = MS.ManagementStructureId
WHERE EMS.EmployeeId = @EmployeeID

SELECT @MSID

COMMIT  TRANSACTION

END TRY    
BEGIN CATCH      
IF @@trancount > 0
	PRINT 'ROLLBACK'
	ROLLBACK TRANSACTION;

	IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
	BEGIN
	DROP TABLE #ManagmetnStrcture 
	END

	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
  , @AdhocComments     VARCHAR(150)    = 'sp_DeleteMSByEmployee' 
  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@MSID, '') as Varchar(100)) + 
										  '@Parameter2 = '''+ CAST(ISNULL(@EmployeeID, '') as Varchar(100)) 										  	
  , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------PLEASE DO NOT EDIT BELOW----------------------------------------

  exec spLogException 
           @DatabaseName           = @DatabaseName
         , @AdhocComments          = @AdhocComments
         , @ProcedureParameters    = @ProcedureParameters
         , @ApplicationName        =  @ApplicationName
         , @ErrorLogID             = @ErrorLogID OUTPUT ;
  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
  RETURN(1);
END CATCH

IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
BEGIN
DROP TABLE #ManagmetnStrcture 
END
END