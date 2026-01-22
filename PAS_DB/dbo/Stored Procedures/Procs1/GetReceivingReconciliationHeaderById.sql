/*************************************************************           
 ** File:   [GetReceivingReconciliationHeaderById]
 ** Author: unknown
 ** Description: This stored procedure is used TO Get Receiving Reconciliation Header Details
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1                 unknown        Created
	2    09/27/2023   Moin Bloch     Modify(Added Invoice Date)
	3    09/30/2023   Hemant Saliya  Modify(Added Accounting Calendor Id)
	4    10/25/2023   Moin Bloch     Modify(Added Invoice On Hold Field)
	5    12/27/2024   AMIT GHEDIYA   Modify(Added ControlNumber Field)
	6    12/31/2024   RAJESH GAMI   Getting Vendor Proforma Invoice Amount From the PO/RO 

***********************************************************************     
-- EXEC GetReceivingReconciliationHeaderById 352
************************************************************************/
CREATE   PROCEDURE [dbo].[GetReceivingReconciliationHeaderById]
@ReceivingReconciliationId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @totalProformaInvoiceAmount decimal(18,2) = 0, @moduleType int = 1, @totalPartCount int = 0, @PartLoopId int = 1, @ReferenceId BIGINT = 0;
		SELECT  @moduleType = MAX(Isnull([Type],0)) FROM dbo.ReceivingReconciliationDetails WITH(NOLOCK) WHERE ReceivingReconciliationId = @ReceivingReconciliationId

		IF OBJECT_ID(N'tempdb..#tmpDetailTbl') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpDetailTbl
			END
						
		CREATE TABLE #tmpDetailTbl
		(
				ID BIGINT NOT NULL IDENTITY, 
				[PurchaseOrderId] [bigint] NULL
		)		

		INSERT INTO #tmpDetailTbl ([PurchaseOrderId]) 
		SELECT DISTINCT PurchaseOrderId
		FROM DBO.ReceivingReconciliationDetails WITH (NOLOCK) WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;

		SET @totalPartCount = (SELECT COUNT(1) FROM #tmpDetailTbl)
		 
		WHILE @PartLoopId <= @totalPartCount
		BEGIN
			SELECT @ReferenceId = PurchaseOrderId FROM #tmpDetailTbl Where ID =@PartLoopId;
			IF(@moduleType  =1) /** Type =1 : Purchase Order , For 2 Repair Order **/
			BEGIN
				SET @totalProformaInvoiceAmount = CONVERT(DECIMAL(18,2),@totalProformaInvoiceAmount) + (SELECT ISNULL(DepositAmount,0) FROM Dbo.PurchaseOrder WHERE PurchaseOrderId = @ReferenceId AND ISNULL(DepositAmount,0) > 0 AND ISNULL(VendorProformaInvoiceNo,'') != '')

			END
			ELSE IF (@moduleType  =2)
			BEGIN
				SET @totalProformaInvoiceAmount = CONVERT(DECIMAL(18,2),@totalProformaInvoiceAmount) + CONVERT(DECIMAL(18,2),(SELECT ISNULL(DepositAmount,0) FROM Dbo.RepairOrder WHERE RepairOrderId = @ReferenceId AND ISNULL(DepositAmount,0) > 0 AND ISNULL(VendorProformaInvoiceNo,'') != ''))
			END
			SET @PartLoopId +=1
		END
	

		SELECT RRH.[ReceivingReconciliationId]
               ,RRH.[ReceivingReconciliationNumber]
               ,RRH.[InvoiceNum]
               ,RRH.[StatusId]
               ,RRH.[Status]
               ,RRH.[VendorId]
               ,RRH.[VendorName]
               ,RRH.[CurrencyId]
               ,RRH.[CurrencyName]
               ,RRH.[OpenDate]
               ,ISNULL(RRH.[OriginalTotal],0) AS OriginalTotal
               ,ISNULL(RRH.[RRTotal],0) AS RRTotal
               ,ISNULL(RRH.[InvoiceTotal],0) AS InvoiceTotal
			   ,ISNULL(RRH.[DIfferenceAmount],0) AS DIfferenceAmount
			   ,ISNULL(RRH.[TotalAdjustAmount],0) AS TotalAdjustAmount
               ,RRH.[MasterCompanyId]
               ,RRH.[CreatedBy]
               ,RRH.[UpdatedBy]
               ,RRH.[CreatedDate]
               ,RRH.[UpdatedDate]
               ,RRH.[IsActive]
               ,RRH.[IsDeleted]
			   ,RRH.[InvoiceDate]
			   ,RRH.[AccountingCalendarId]
			   ,RRH.[IsInvoiceOnHold]
			   ,RRH.[ControlNumber],
			   CASE WHEN ISNULL(RRH.VendorProformaAmount,0) > 0 THEN ISNULL(RRH.VendorProformaAmount,0) ELSE ISNULL(@totalProformaInvoiceAmount,0) END as VendorProformaAmount,
			   CASE WHEN ISNULL(RRH.VendorProformaAmount,0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(@totalProformaInvoiceAmount,0) > 0 THEN 1 ELSE 0  END) END as IsVendorProforma
			   
          FROM [dbo].[ReceivingReconciliationHeader] RRH WITH(NOLOCK) WHERE ReceivingReconciliationId = @ReceivingReconciliationId
		  
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetJournalBatchHeaderById'             
			, @ProcedureParameters VARCHAR(200) = '@Parameter1 = ''' + CAST(ISNULL(@ReceivingReconciliationId, '') AS varchar(100)) 
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