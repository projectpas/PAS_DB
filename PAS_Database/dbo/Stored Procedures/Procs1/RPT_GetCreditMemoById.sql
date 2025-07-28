/*************************************************************           
 ** File:   [RPT_GetCreditMemoById]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Get Credit Memo Details for SSRS Report
 ** Purpose:         
 ** Date:   04/21/2023      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		  Change Description            
 ** --   --------     -------		  --------------------------------          
    1    04/21/2023   Amit Ghediya    Created
    2    06/26/2023   Vishal Suthar   TRIM the PO/RO number
	3	 01/02/2024	  AMIT GHEDIYA	  added isperforma Flage for SO
    4    07-07-2025   Moin Bloch      Changed Old To New Billing Table
-- EXEC RPT_GetCreditMemoById 32

************************************************************************/
CREATE   PROCEDURE [dbo].[RPT_GetCreditMemoById]
	@CreditMemoHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

	 DECLARE @WOModuleId INT
	 SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

	 DECLARE @SOModuleId INT
	 SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

	Declare @ModuleID int = 61
	SELECT CM.[CreditMemoHeaderId]
      ,CM.[CreditMemoNumber]
      ,CM.[RMAHeaderId]
      ,CM.[RMANumber]
      ,CM.[InvoiceId]
      ,CM.[InvoiceNumber]
      ,CM.[InvoiceDate]
      ,CM.[StatusId]
      ,CM.[Status]
      ,CM.[CustomerId]
      ,CM.[CustomerName]
      ,CM.[CustomerCode]
      ,CM.[CustomerContactId]
      ,CM.[CustomerContact]
      ,CM.[CustomerContactPhone]
      ,CM.[IsWarranty]
      ,CM.[IsAccepted]
      ,CM.[ReasonId]
	  ,CM.[Reason]
      ,CM.[DeniedMemo]
      ,CM.[RequestedById]
      ,CM.[RequestedBy]
      ,CM.[ApproverId]
      ,CM.[ApprovedBy]
      ,CM.[WONum]
      ,CM.[WorkOrderId]
      ,CM.[Originalwosonum]
      ,CM.[Memo]
      ,CM.[Notes]
      ,CM.[ManagementStructureId]
      ,CM.[IsEnforce]
      ,CM.[MasterCompanyId]
      ,CM.[CreatedBy]
      ,CM.[UpdatedBy]
      ,CM.[CreatedDate]
      ,CM.[UpdatedDate]
      ,CM.[IsActive]
      ,CM.[IsDeleted]
	  ,MS.[LastMSLevel]
      ,MS.[AllMSlevels]
	  ,CR.[CreditMemoDetailId]
	  ,CM.[IsWorkOrder]
	  ,CM.[ReferenceId]
	  ,CM.[ReturnDate]
	  ,CM.[PDFPath]
	  ,CM.[FreightBilingMethodId]
      ,CM.[TotalFreight]
	  ,CM.[ChargesBilingMethodId]
      ,CM.[TotalCharges]
	  ,CRMA.[ValidDate]
	  ,CRMA.[CreatedDate] 'RMAIssueDate'
	  ,CASE WHEN CM.[IsWorkOrder]=1 THEN (SELECT ISNULL(WB.PostedDate,NULL) FROM [dbo].[BillingInvoicing] WB WITH (NOLOCK) 
	                                      WHERE WB.[BillingInvoicingId] = CM.[InvoiceId] AND WB.[ModuleId] = @WOModuleId)
									ELSE (SELECT ISNULL(SB.PostedDate,NULL) FROM [dbo].[BillingInvoicing] SB WITH (NOLOCK) 
	                                      WHERE SB.[BillingInvoicingId] = CM.[InvoiceId] AND ISNULL(SB.[IsPerformaInvoice],0) = 0  AND SB.[ModuleId] = @SOModuleId)
								    END AS 'PostedDate'	

      ,
	      CASE WHEN CM.[IsWorkOrder]=1 THEN  
				CASE WHEN 
					LEN(
						STUFF((SELECT ', ' + WP.CustomerReference
						FROM dbo.BillingInvoicing WI WITH (NOLOCK)
						INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.ReferenceId=WP.WorkOrderId AND WI.[ModuleId] = @WOModuleId
						WHERE WI.BillingInvoicingId = CM.[InvoiceId]
						FOR XML PATH('')), 1, 1, '')
						) < 20 
				THEN
					STUFF((SELECT ', ' + WP.CustomerReference
						FROM dbo.BillingInvoicing WI WITH (NOLOCK)
						INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.ReferenceId=WP.WorkOrderId AND WI.[ModuleId] = @WOModuleId
						WHERE WI.BillingInvoicingId = CM.[InvoiceId]
						FOR XML PATH('')), 1, 1, '')
				ELSE
					LEFT(STUFF((SELECT ', ' + WP.CustomerReference
						FROM dbo.BillingInvoicing WI WITH (NOLOCK)
						INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.ReferenceId=WP.WorkOrderId AND WI.[ModuleId] = @WOModuleId
						WHERE WI.BillingInvoicingId = CM.[InvoiceId]
						FOR XML PATH('')), 1, 1, ''), 20) + '....'
				END
		  ELSE 
				CASE WHEN
					LEN(
				 TRIM(STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.BillingInvoicing SI WITH (NOLOCK)
						INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.ReferenceId = SO.SalesOrderId
						WHERE SI.BillingInvoicingId = CM.[InvoiceId] AND ISNULL(SI.[IsPerformaInvoice],0) = 0 AND SI.[ModuleId] = @SOModuleId
						FOR XML PATH('')), 1, 1, '')) 
						) < 20
				THEN
					TRIM(STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.BillingInvoicing SI WITH (NOLOCK)
						INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.ReferenceId = SO.SalesOrderId
						WHERE SI.BillingInvoicingId = CM.[InvoiceId] AND ISNULL(SI.[IsPerformaInvoice],0) = 0 AND SI.[ModuleId] = @SOModuleId
						FOR XML PATH('')), 1, 1, '')) 
				ELSE
					LEFT(TRIM(STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.BillingInvoicing SI WITH (NOLOCK)
						INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.ReferenceId = SO.SalesOrderId
						WHERE SI.BillingInvoicingId = CM.[InvoiceId] AND ISNULL(SI.[IsPerformaInvoice],0) = 0 AND SI.[ModuleId] = @SOModuleId
						FOR XML PATH('')), 1, 1, '')), 20) + '....'
				END
		 END AS 'PORONum'
		, CASE WHEN CM.[IsWorkOrder]=1 THEN (SELECT ISNULL(WD.WayBillRef,NULL) FROM [dbo].[BillingInvoicing] WB WITH (NOLOCK) 
											left join [dbo].[BillingInvoicingDetails] WD WITH (NOLOCK) ON WB.BillingInvoicingId = WD.BillingInvoicingId
	                                      WHERE WB.[BillingInvoicingId] = CM.[InvoiceId] AND  WB.[ModuleId] = @WOModuleId)
						    ELSE 
								(SELECT TOP 1 ISNULL(SAOS.AirwayBill,NULL) FROM [dbo].[BillingInvoicing] SB WITH (NOLOCK) 
									LEFT JOIN dbo.BillingInvoicingItems SABI ON SB.BillingInvoicingId = SABI.BillingInvoicingId AND ISNULL(SABI.[IsPerformaInvoice],0) = 0
									LEFT JOIN dbo.SalesOrderShipping SAOS ON SABI.ShippingId = SAOS.SalesOrderShippingId  --and  SAOS.SalesOrderId = 192
	                                      WHERE SB.[BillingInvoicingId] = CM.[InvoiceId] AND ISNULL(SB.[IsPerformaInvoice],0) = 0 AND SB.[ModuleId] = @SOModuleId)
						    END AS 'Awb'	

  FROM [dbo].[CreditMemo] CM WITH (NOLOCK) 
	   INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MS WITH (NOLOCK) ON CM.CreditMemoHeaderId = MS.ReferenceID AND MS.ModuleID = @ModuleID
	   LEFT JOIN [dbo].[CustomerRMAHeader] CRMA ON CRMA.RMAHeaderId = CM.RMAHeaderId
	   OUTER APPLY (SELECT TOP 1 CreditMemoDetailId FROM  CreditMemoDetails CD WITH (NOLOCK) WHERE CD.CreditMemoHeaderId = CM.CreditMemoHeaderId) CR 
  WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId;

END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'RPT_GetCreditMemoById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CreditMemoHeaderId, '') + ''
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