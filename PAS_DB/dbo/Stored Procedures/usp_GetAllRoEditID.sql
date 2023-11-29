---------------------------------------------------------------------------------------------------------

CREATE Procedure [dbo].[usp_GetAllRoEditID]
@roID  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		IF OBJECT_ID(N'tempdb..#ROEditList') IS NOT NULL
		BEGIN
		DROP TABLE #ROEditList 
		END
		CREATE TABLE #ROEditList 
		(
		 ID bigint NOT NULL IDENTITY,
		 [Value] bigint null,
		 Label varchar(100) null
		)

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(VendorId,0), 'VENDOR' FROM dbo.RepairOrder WITH(NOLOCK) Where RepairOrderId = @roID

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(ROPartSplitUserId,0), 'VENDOR' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID AND ROPartSplitUserTypeId = 2

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(ROPartSplitUserId,0), 'COMPANY' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID AND ROPartSplitUserTypeId = 9

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(ROPartSplitUserId,0), 'CUSTOMER' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID AND ROPartSplitUserTypeId = 1

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(RequisitionerId,0), 'EMPLOYEE' FROM dbo.RepairOrder WITH(NOLOCK) Where RepairOrderId = @roID

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(PriorityId,0), 'PRIORITY' FROM dbo.RepairOrder WITH(NOLOCK) Where RepairOrderId = @roID

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(PriorityId,0), 'PRIORITY' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(ConditionId,0), 'CONDITION' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(RevisedPartId,0), 'REVISEDPART' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID AND RevisedPartId > 0

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(FunctionalCurrencyId,0), 'CURRENCY' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(ReportCurrencyId,0), 'CURRENCY' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(ApproverId,0), 'EMPLOYEE' FROM dbo.RepairOrder WITH(NOLOCK) Where RepairOrderId = @roID

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(WorkOrderId,0), 'WONO' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID AND WorkOrderId > 0

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(SubWorkOrderId,0), 'SOWONO' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID AND SubWorkOrderId > 0

		INSERT INTO #ROEditList ([Value],Label)
		SELECT  ISNULL(SalesOrderId,0), 'SONO' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID AND SalesOrderId > 0

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(MS.LegalEntityId,0), 'MSCOMPANYID' from dbo.RepairOrder PO WITH(NOLOCK) 
		INNER JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON PO.ManagementStructureId = MS.ManagementStructureId
		WHERE RepairOrderId = @roID 

		SELECT * FROM #ROEditList

	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetAllRoEditID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@roID, '') + ''
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