/***************************************************************  
 ** File:   [USP_CheckWOInvoiceExistByWOBillId]             
 ** Author:   Shrey Chandegara
 ** Description: 
 ** Date:  17-March-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    17-March-2025		Shrey Chandegara	Created
	2    25-APR-2025		Moin Bloch          Changed OLD TO NEW Table
	3    26-JUN-2025		Rajesh Gami         Add distinct while STRING_SPLIT
	declare @p4 bit
	set @p4=NULL
	exec USP_CheckWOInvoiceExistByWOBillId @BillingInvoicingId=3213,@WOPartIds=N'8116',@IsProformaInvoice=0,@Result=@p4 output
	select @p4
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CheckWOInvoiceExistByWOBillId]
    @BillingInvoicingId BIGINT,
    @WOPartIds NVARCHAR(MAX),  
    @IsProformaInvoice BIT,
    @Result BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		BEGIN TRY

				IF OBJECT_ID(N'tempdb..#WOPartTable') IS NOT NULL
					BEGIN
						DROP TABLE #WOPartTable
					END

				IF OBJECT_ID(N'tempdb..#DistinctData') IS NOT NULL
					BEGIN
						DROP TABLE #DistinctData
					END

				DECLARE @Count INT = 0;
				DECLARE @TotalCount INT = 0;

				CREATE TABLE #WOPartTable (WorkOrderPartId BIGINT);
				INSERT INTO #WOPartTable (WorkOrderPartId)SELECT DISTINCT CAST(value AS BIGINT) FROM STRING_SPLIT(@WOPartIds, ',');

				-- OLD Code
					--SELECT DISTINCT 
					--	wob.BillingInvoicingId,
					--	wobii.WorkOrderPartId
					--INTO #DistinctData FROM  dbo.[WorkOrderBillingInvoicing] wob WITH(NOLOCK)
					--INNER JOIN dbo.[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK)
					--	ON wob.BillingInvoicingId = wobii.BillingInvoicingId
					--	AND (wobii.IsPerformaInvoice = @IsProformaInvoice OR wobii.IsPerformaInvoice IS NULL)
					--WHERE wob.BillingInvoicingId = @BillingInvoicingId AND (wob.IsPerformaInvoice = @IsProformaInvoice OR wob.IsPerformaInvoice IS NULL)

					SELECT DISTINCT 
						wob.BillingInvoicingId,
						wobii.SubReferenceId
					INTO #DistinctData FROM  dbo.[BillingInvoicing] wob WITH(NOLOCK)
					INNER JOIN dbo.[BillingInvoicingItems] wobii WITH(NOLOCK)
						ON wob.BillingInvoicingId = wobii.BillingInvoicingId
						AND (wobii.IsPerformaInvoice = @IsProformaInvoice OR wobii.IsPerformaInvoice IS NULL)
					WHERE wob.BillingInvoicingId = @BillingInvoicingId AND (wob.IsPerformaInvoice = @IsProformaInvoice OR wob.IsPerformaInvoice IS NULL)

				SELECT @TotalCount = COUNT(*) FROM #DistinctData;

				IF @TotalCount <> (SELECT COUNT(*) FROM #WOPartTable)
				BEGIN
					SET @Result = 1
					RETURN
				END

				SELECT @Count = COUNT(*)
				FROM #DistinctData d
				INNER JOIN #WOPartTable wpt ON d.SubReferenceId = wpt.WorkOrderPartId

				IF @Count = @TotalCount
					SET @Result = 0
				ELSE
					SET @Result = 1

		END TRY
		BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_CheckWOInvoiceExistByWOBillId'
			,@ProcedureParameters VARCHAR(3000) =
					'@Parameter1 = ''' + ISNULL(CAST(@BillingInvoicingId AS VARCHAR(100)), '') + ''', '
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)
		RETURN (1);           
	END CATCH
END;