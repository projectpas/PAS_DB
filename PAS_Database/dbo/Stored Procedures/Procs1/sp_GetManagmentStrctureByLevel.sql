
--exec [sp_GetManagmentStrctureByLevel] 80,0,0
CREATE  Procedure [dbo].[sp_GetManagmentStrctureByLevel]
@parentId  bigint,
@employeeID bigint = 0,
@editparentId bigint = 0
AS
BEGIN

 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON


BEGIN TRY
BEGIN TRANSACTION

IF OBJECT_ID(N'tempdb..#EMSID') IS NOT NULL
BEGIN
DROP TABLE #EMSID 
END
CREATE TABLE #EMSID 
(
 ID BIGINT NOT NULL IDENTITY, 
 ManagementStructureId BIGINT NULL
)

INSERT INTO #EMSID (ManagementStructureId) SELECT ManagementStructureId FROM dbo.EmployeeManagementStructure WITH (NOLOCK)
                                                      WHERE IsActive = 1 AND IsDeleted = 0 AND  EmployeeId  = @EmployeeID

IF OBJECT_ID(N'tempdb..#MSID') IS NOT NULL
BEGIN
DROP TABLE #MSID 
END
CREATE TABLE #MSID 
(
 ID BIGINT NOT NULL IDENTITY, 
 ManagementStructureId BIGINT NULL
)

DECLARE @EManagementStructureId as bigint 
DECLARE @CNTM as int =  0
DECLARE @I as int = 0;
SELECT @CNTM = MAX(ID)  FROM #EMSID
DECLARE @MPIDd as int
WHILE (@CNTM > 0)
BEGIN

SELECT TOP 1 @EManagementStructureId = ManagementStructureId FROM #EMSID WHERE ID = @CNTM
--SELECT TOP 1 @EManagementStructureId = ManagementStructureId FROM #EMSID WHERE ID = @CNTM

INSERT INTO #MSID (ManagementStructureId) SELECT @EManagementStructureId
SELECT  @MPIDd = ISNULL(ParentID,0) from dbo.ManagementStructure WITH (NOLOCK) where ManagementStructureId = @EManagementStructureId

SET @MPIDd = @EManagementStructureId
MParent:
SELECT  @MPIDd = ISNULL(ParentID,0) from dbo.ManagementStructure WITH (NOLOCK) where ManagementStructureId = @MPIDd
IF(@MPIDd > 0)
BEGIN
INSERT INTO #MSID(ManagementStructureId) SELECT @MPIDd 
GOTO MParent 
END 
SET @I = @I + 1;
SET @CNTM  = @CNTM - 1;
END

SELECT DISTINCT
 ms.Code + ' - ' + ms.Name as label,
 ms.ManagementStructureId as value
FROM dbo.ManagementStructure ms WITH (NOLOCK)
INNER JOIN #MSID M ON ms.ManagementStructureId = M.ManagementStructureId
where 
ISNULL(ms.IsDeleted,0) = 0 AND ISNULL(ms.IsActive,1) = 1
AND ms.ParentId = @parentId
--UNION 
--SELECT DISTINCT
-- ms.Code + ' - ' + ms.Name as label,
-- ms.ManagementStructureId as value
--FROM dbo.ManagementStructure ms
--where 
--ms.ParentId = @editparentId
--Order By label

COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetManagmentStrctureByLevel' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@parentId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END