-----------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[PROCGetVendorRFQROEditID]
@VendorRFQRepairOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		IF OBJECT_ID(N'tempdb..#RFQROEditList') IS NOT NULL
		BEGIN
		DROP TABLE #RFQROEditList 
		END
		CREATE TABLE #RFQROEditList 
		(
		 ID bigint NOT NULL IDENTITY,
		 [Value] bigint null,
		 Label varchar(100) null
		)

		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT ISNULL(VendorId,0), 'VENDOR' FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId;
		
		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT  ISNULL(RequisitionerId,0), 'EMPLOYEE' FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId;

		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT  ISNULL(PriorityId,0), 'PRIORITY' FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId;

		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT  ISNULL(PriorityId,0), 'PRIORITY' FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId;

		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT  ISNULL(ConditionId,0), 'CONDITION' FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId;

		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT  ISNULL(RevisedPartId,0), 'REVISEDPART' FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId AND RevisedPartId > 0

		--INSERT INTO #RFQROEditList ([Value],Label)
		--SELECT  ISNULL(FunctionalCurrencyId,0), 'CURRENCY' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID

		--INSERT INTO #RFQROEditList ([Value],Label)
		--SELECT  ISNULL(ReportCurrencyId,0), 'CURRENCY' FROM dbo.RepairOrderPart WITH(NOLOCK) Where RepairOrderId = @roID

		--INSERT INTO #RFQROEditList ([Value],Label)
		--SELECT  ISNULL(ApproverId,0), 'EMPLOYEE' FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId;

		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT  ISNULL(WorkOrderId,0), 'WONO' FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId AND WorkOrderId > 0

		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT  ISNULL(SubWorkOrderId,0), 'SOWONO' FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId AND SubWorkOrderId > 0

		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT  ISNULL(SalesOrderId,0), 'SONO' FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) Where VendorRFQRepairOrderId = @VendorRFQRepairOrderId AND SalesOrderId > 0

		INSERT INTO #RFQROEditList ([Value],Label)
		SELECT ISNULL(MS.LegalEntityId,0), 'MSCOMPANYID' from dbo.VendorRFQRepairOrder PO WITH(NOLOCK) 
		INNER JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON PO.ManagementStructureId = MS.ManagementStructureId
		WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId; 

		SELECT * FROM #RFQROEditList

	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'PROCGetVendorRFQROEditID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQRepairOrderId, '') + ''
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