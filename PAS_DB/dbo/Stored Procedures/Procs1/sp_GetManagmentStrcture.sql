-- exec [sp_GetManagmentStrcture] 86,32,86

CREATE  Procedure [dbo].[sp_GetManagmentStrcture]
@ManagementStructureId  bigint,
@EmployeeID bigint = 0,
@EditManagementStructureId bigint = 0,
@MasterCompanyId int = 1
AS
BEGIN
BEGIN TRAN
BEGIN TRY

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
IF @EditManagementStructureId  > 0
BEGIN
INSERT INTO #EMSID (ManagementStructureId) SELECT @EditManagementStructureId
END 

IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
BEGIN
DROP TABLE #ManagmetnStrcture 
END
CREATE TABLE #ManagmetnStrcture 
(
 ID BIGINT NOT NULL IDENTITY, 
 ManagementStructureId BIGINT NULL,
 ManagementStrctureLevel varchar(100) NULL

)
DECLARE @ParentId as int
DECLARE @I as int = 1
INSERT INTO #ManagmetnStrcture(ManagementStructureId,ManagementStrctureLevel) SELECT @ManagementStructureId , 'Level' 
SELECT  @ParentId = ISNULL(ParentID,0) from dbo.ManagementStructure WITH (NOLOCK) where ManagementStructureId = @ManagementStructureId

SET @ParentId = @ManagementStructureId
Parent:
SELECT  @ParentId = ISNULL(ParentID,0) from dbo.ManagementStructure WITH (NOLOCK) where ManagementStructureId = @ParentId
IF(@ParentId > 0)
BEGIN
INSERT INTO #ManagmetnStrcture(ManagementStructureId, ManagementStrctureLevel) SELECT @ParentId , 'Level'
GOTO Parent 
END

IF OBJECT_ID(N'tempdb..#ManagmetnStrctureLevelData') IS NOT NULL
BEGIN
DROP TABLE #ManagmetnStrctureLevelData 
END
CREATE TABLE #ManagmetnStrctureLevelData 
(
 ID BIGINT NOT NULL IDENTITY, 
 value BIGINT NULL,
 Label varchar(500) NULL,
 ManagementStrctureLevel varchar(100) NULL,
 ParentId bigint NULL
)
DECLARE @CNT as int =  0
SELECT @CNT = MAX(ID)  FROM #ManagmetnStrcture
WHILE (@CNT > 0)
BEGIN
UPDATE #ManagmetnStrcture SET ManagementStrctureLevel = 'Level' + CAST(@I as VARCHAR(10))
WHERE ID  = @CNT

INSERT INTO #ManagmetnStrctureLevelData(value, Label, ManagementStrctureLevel, ParentId)
  SELECT MID.ManagementStructureId,MID.Code + ' - ' + MID.Name, 'Level' + CAST(@I + 1 as VARCHAR(10)), (SELECT ManagementStructureId FROM #ManagmetnStrcture WHERE ID = @CNT )
    FROM dbo.ManagementStructure MID WITH (NOLOCK)      
			  WHERE (MID.IsDeleted = 0 OR MID.IsDeleted = null) 
			     AND (MID.IsActive = 1 OR MID.IsActive = null) 
				 AND  MID.ParentId IN (SELECT ManagementStructureId FROM #ManagmetnStrcture WHERE ID = @CNT )
SET @I = @I + 1;
SET @CNT = @CNT - 1;
END

INSERT INTO #ManagmetnStrctureLevelData(value, Label, ManagementStrctureLevel, ParentId)
  SELECT MID.ManagementStructureId,MID.Code + ' - ' + MID.Name, 'Level1', NULL 
    FROM dbo.ManagementStructure MID  WITH (NOLOCK)
			  WHERE (MID.IsDeleted = 0 OR MID.IsDeleted = null) 
			     AND (MID.IsActive = 1 OR MID.IsActive = null) 
				 AND  MID.ParentId IS NULL

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
SET @I = 0;
SELECT @CNTM = MAX(ID)  FROM #EMSID
DECLARE @MPIDd as int
WHILE (@CNTM > 0)
BEGIN

SELECT TOP 1 @EManagementStructureId = ManagementStructureId FROM #EMSID WHERE ID = @CNTM
--SELECT TOP 1 @EManagementStructureId = ManagementStructureId FROM #EMSID WHERE ID = @CNTM

INSERT INTO #MSID (ManagementStructureId) SELECT @EManagementStructureId
SELECT  @MPIDd = ISNULL(ParentID,0) from dbo.ManagementStructure  WITH (NOLOCK) where ManagementStructureId = @EManagementStructureId

SET @MPIDd = @EManagementStructureId
MParent:
SELECT  @MPIDd = ISNULL(ParentID,0) from dbo.ManagementStructure  WITH (NOLOCK) where ManagementStructureId = @MPIDd
IF(@MPIDd > 0)
BEGIN
INSERT INTO #MSID(ManagementStructureId) SELECT @MPIDd 
GOTO MParent 
END 
SET @I = @I + 1;
SET @CNTM  = @CNTM - 1;
END


IF OBJECT_ID(N'tempdb..#EditManagmetnStrctureLevelData') IS NOT NULL
BEGIN
DROP TABLE #EditManagmetnStrctureLevelData 
END
CREATE TABLE #EditManagmetnStrctureLevelData 
(
 ID BIGINT NOT NULL IDENTITY, 
 value BIGINT NULL,
 Label varchar(500) NULL,
 ManagementStrctureLevel varchar(100) NULL,
 ParentId bigint NULL
)


--SELECT MAX(ManagementStrctureLevel) FROM #ManagmetnStrcture
DECLARE @parentIdNL as bigint
SELECT @parentIdNL = ManagementStructureId  FROM #ManagmetnStrcture  WHERE ManagementStrctureLevel IN (SELECT MAX(ManagementStrctureLevel) FROM #ManagmetnStrcture)
--SELECT @parentIdNL


-------------> Next Level  Part 
IF OBJECT_ID(N'tempdb..#EMSIDNL') IS NOT NULL
BEGIN
DROP TABLE #EMSIDNL 
END
CREATE TABLE #EMSIDNL 
(
 ID BIGINT NOT NULL IDENTITY, 
 ManagementStructureId BIGINT NULL
)

INSERT INTO #EMSIDNL (ManagementStructureId) SELECT ManagementStructureId FROM dbo.EmployeeManagementStructure WITH (NOLOCK)
                                                      WHERE IsActive = 1 AND IsDeleted = 0 AND  EmployeeId  = @EmployeeID

IF OBJECT_ID(N'tempdb..#MSIDNL') IS NOT NULL
BEGIN
DROP TABLE #MSIDNL 
END
CREATE TABLE #MSIDNL 
(
 ID BIGINT NOT NULL IDENTITY, 
 ManagementStructureId BIGINT NULL
)

DECLARE @EManagementStructureIdNL as bigint 
DECLARE @CNTMNL as int =  0
DECLARE @INL as int = 0;
SELECT @CNTMNL = MAX(ID)  FROM #EMSIDNL
DECLARE @MPIDdNL as int
WHILE (@CNTMNL > 0)
BEGIN

SELECT TOP 1 @EManagementStructureIdNL = ManagementStructureId FROM #EMSID WHERE ID = @CNTMNL
--SELECT TOP 1 @EManagementStructureId = ManagementStructureId FROM #EMSID WHERE ID = @CNTM

INSERT INTO #MSIDNL (ManagementStructureId) SELECT @EManagementStructureIdNL
SELECT  @MPIDdNL = ISNULL(ParentID, 0) from dbo.ManagementStructure WITH (NOLOCK) where ManagementStructureId = @EManagementStructureIdNL

SET @MPIDdNL = @EManagementStructureIdNL
MParentNL:
SELECT  @MPIDdNL = ISNULL(ParentID, 0) from dbo.ManagementStructure WITH (NOLOCK) where ManagementStructureId = @MPIDdNL
IF(@MPIDdNL > 0)
BEGIN
INSERT INTO #MSIDNL(ManagementStructureId) SELECT @MPIDdNL 
GOTO MParentNL 
END 
SET @INL = @INL + 1;
SET @CNTMNL  = @CNTMNL - 1;
END

--SELECT DISTINCT
-- ms.Code + ' - ' + ms.Name as label,
-- ms.ManagementStructureId as value
--FROM dbo.ManagementStructure ms
--INNER JOIN #MSIDNL M ON ms.ManagementStructureId = M.ManagementStructureId
--where 
--ISNULL(ms.IsDeleted,0) = 0 AND ISNULL(ms.IsActive,1) = 1
--AND ms.ParentId = @parentIdNL

------------------------------------------------------------
IF OBJECT_ID(N'tempdb..#ResultMS') IS NOT NULL
BEGIN
DROP TABLE #ResultMS 
END
CREATE TABLE #ResultMS 
(
 ManagementStructureId BIGINT NOT NULL, 
 Value BIGINT NULL,
 Label varchar(500) NULL,
 [Level] varchar(100) NULL,
 ParentId bigint NULL
)

IF @EmployeeID > 0 
BEGIN
INSERT INTO #ResultMS (ManagementStructureId,Value,Label,[Level],ParentId)
    SELECT DISTINCT  MS.ManagementStructureId,
	       TL.value as Value,
		   TL.Label as Label,
		   TL.ManagementStrctureLevel as [Level],
		   TL.parentId as ParentId 
	FROM #ManagmetnStrctureLevelData  TL 
	     INNER JOIN #ManagmetnStrcture MS  ON TL.ManagementStrctureLevel = MS.ManagementStrctureLevel
		WHERE TL.value in (select ManagementStructureId 
							from #MSID)	
	ORDER BY [Level] 
END
ELSE 
BEGIN
INSERT INTO #ResultMS (ManagementStructureId, Value, Label, [Level], ParentId)
	SELECT MS.ManagementStructureId, TL.value as Value, TL.Label as Label, TL.ManagementStrctureLevel as [Level], TL.parentId as ParentId 
	FROM #ManagmetnStrctureLevelData  TL 
	     INNER JOIN #ManagmetnStrcture MS  ON TL.ManagementStrctureLevel = MS.ManagementStrctureLevel	
	--UNION 
	--SELECT DISTINCT
	--	-1 as ManagementStructureId,
	--	ms.ManagementStructureId as Value,
	--	ms.Code + ' - ' + ms.Name as Label,
	--	'NEXT' as ManagementStrctureLevel,
	--	NULL
	--	FROM dbo.ManagementStructure ms
	--	INNER JOIN #MSIDNL M ON ms.ManagementStructureId = M.ManagementStructureId
	--	where 
	--	ISNULL(ms.IsDeleted,0) = 0 AND ISNULL(ms.IsActive,1) = 1
	--	AND ms.ParentId = @parentIdNL
	--	ORDER BY TL.ManagementStrctureLevel 		
	
END
INSERT INTO #ResultMS (ManagementStructureId, Value, Label, [Level], ParentId)
SELECT DISTINCT
    	0 as ManagementStructureId,
		ms.ManagementStructureId as Value,
		ms.Code + ' - ' + ms.Name as Label,
		'NEXT' as [Level],
		NULL as ParentId 
		FROM dbo.ManagementStructure ms  WITH (NOLOCK)
		INNER JOIN #MSIDNL M ON ms.ManagementStructureId = M.ManagementStructureId
		where 
		ISNULL(ms.IsDeleted, 0) = 0 AND ISNULL(ms.IsActive, 1) = 1
		AND ms.ParentId = @parentIdNL
		AND ms.MasterCompanyId = @MasterCompanyId

SELECT * FROM #ResultMS
	
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetManagmentStrcture' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ManagementStructureId, '') + ''
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