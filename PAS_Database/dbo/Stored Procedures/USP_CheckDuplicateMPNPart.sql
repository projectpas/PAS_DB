/*************************************************************           
 ** File:   [USP_CheckDuplicateMPNPart]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Check Duplicate MPN Part - StockLine Pair
 ** Date:   21-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    21-May-2025   Devendra Shekh		Created
	 
declare @p6 dbo.WorkOrderPartNumberType
insert into @p6 values(0,0,10,NULL,'2025-05-20 00:00:00',NULL,NULL,N'2',1,199975,N'',23,19,1,3,1,1,0,3,1,N'ADMIN User',N'ADMIN User','2025-05-20 06:28:14.0010000','2025-05-20 06:28:14.0010000',1,0,3,0,9,19,NULL,1,0,N'',NULL,0,'2025-05-01 00:00:00',0,N'',NULL,NULL,0,NULL,N'SIDNEY GRADY',NULL,NULL,NULL,NULL,NULL,6276,NULL,NULL,NULL,NULL,NULL,NULL,NULL,N'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,N'',N'',N'',N'',N'ROSEMOUNT AEROSPACE',N'',N'',N'PUB-12547',N'',3)
insert into @p6 values(0,0,10,NULL,'2025-05-20 00:00:00',NULL,NULL,N'2',1,199975,N'',23,19,1,3,1,1,0,3,1,N'ADMIN User',N'ADMIN User','2025-05-20 06:28:18.0450000','2025-05-20 06:28:18.0450000',1,0,3,0,9,19,NULL,1,0,N'',NULL,0,'2025-05-01 00:00:00',0,N'',NULL,NULL,0,NULL,N'SIDNEY GRADY',NULL,NULL,NULL,NULL,NULL,6276,NULL,NULL,NULL,NULL,NULL,NULL,NULL,N'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,N'',N'',N'',N'',N'ROSEMOUNT AEROSPACE',N'',N'',N'PUB-12547',N'',3)

declare @p7 bit
set @p7=0
exec dbo.USP_CheckDuplicateMPNPart @WorkOrderId=0,@WorkOrderTypeId=1,@CustomerId=44,@EmployeeId=2,@MasterCompanyId=1,@tbl_WorkOrderPartNumberType=@p6,@AllowProcessWO=@p7 output
select @p7
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CheckDuplicateMPNPart]
@WorkOrderId BIGINT = NULL,
@WorkOrderTypeId BIGINT = NULL,
@CustomerId BIGINT = NULL,
@EmployeeId BIGINT = NULL,
@MasterCompanyId INT,
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@AllowProcessWO BIT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		IF OBJECT_ID('tempdb..#tempWOMPNParts') IS NOT NULL
			DROP TABLE #tempWOMPNParts

		IF OBJECT_ID('tempdb..#tmpResult') IS NOT NULL
			DROP TABLE #tmpResult

		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, StockLineId, ConditionId, MasterCompanyId, ItemMasterId INTO #tempWOMPNParts FROM @tbl_WorkOrderPartNumberType

		SELECT COUNT(RowId) AS RecordId INTO #tmpResult FROM #tempWOMPNParts GROUP BY StockLineId, ItemMasterId, MasterCompanyId HAVING COUNT(RowId) > 1;
		
		SET @AllowProcessWO = 1;

		IF EXISTS(SELECT 1 FROM #tmpResult)
		BEGIN
			SET @AllowProcessWO = 0;
		END

	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrder' 
		, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
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