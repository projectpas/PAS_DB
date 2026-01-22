
/*********************             
 ** File:   [GetCreditMemoById]             
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to Get Credit Memo Details  
 ** Purpose:           
 ** Date:   18/04/2022        
            
 ** PARAMETERS: @CreditMemoHeaderId bigint  
           
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    18/04/2022  Moin Bloch			Created  
	2    20/05/2022  Subhash Saliya     Updated  
	3    12/09/2022  AMIT GHEDIYA		Updated for get IsStandAloneCM value.
    4    18/10/2023  BHARGAV SALIYA     Get CurrencyId   
	5	 01/02/2024	 AMIT GHEDIYA	    added isperforma Flage for SO
	6	 19/04/2024	 Devendra Shekh	    added isExchange to select
	7	 19/04/2024	 Devendra Shekh	    added InvoiceTypeId to select and removed isExchange
	8	 27/06/2024	 Moin Bloch	        added AcctingPeriodId 
	9    07-07-2025  Moin Bloch         Changed Old To New Billing Table
	10   19-11-2025  Vishal Suthar      Fixed subquery with TOP 1 when it was returning more than 1 row

-- EXEC GetCreditMemoById 103  
  
************************/  
CREATE   PROCEDURE [dbo].[GetCreditMemoById]  
@CreditMemoHeaderId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  
 Declare @ModuleID int = 61  
 Declare @WOInvoiceTypeId int = 0;
 Declare @SOInvoiceTypeId int = 0;
 Declare @ExchangeInvoiceTypeId int = 0;

  DECLARE @WOModuleId INT
  SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

  DECLARE @SOModuleId INT
  SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

 SELECT @WOInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WHERE UPPER([ModuleName]) = 'WORKORDER';
 SELECT @SOInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WHERE UPPER([ModuleName]) = 'SALESORDER';
 SELECT @ExchangeInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WHERE UPPER([ModuleName]) = 'EXCHANGE';
 
 SELECT CM.[CreditMemoHeaderId]  
      ,CM.[CreditMemoNumber]  
      ,CM.[RMAHeaderId]  
      ,CM.[RMANumber]  
      ,CM.[InvoiceId]  
      ,CM.[InvoiceNumber]  
      ,ISNULL(CM.[InvoiceDate],NULL) AS 'InvoiceDate'
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
	  ,ISNULL(CM.[ReturnDate],NULL) AS 'ReturnDate'
	  ,CM.[PDFPath]  
	  ,CM.[FreightBilingMethodId]  
      ,CM.[TotalFreight]  
	  ,CM.[ChargesBilingMethodId]  
      ,CM.[TotalCharges] 
	  ,CM.[AcctingPeriodId] 	  
	  ,CRMA.[ValidDate]  
	  ,CRMA.[CreatedDate] 'RMAIssueDate'  
	  ,CF.CurrencyId
	  ,CASE WHEN CM.[IsWorkOrder]=1 THEN (SELECT ISNULL(WB.PostedDate,NULL) FROM [dbo].[BillingInvoicing] WB WITH (NOLOCK) WHERE WB.[BillingInvoicingId] = CM.[InvoiceId])  
			WHEN ISNULL(CM.InvoiceTypeId, 0) = @ExchangeInvoiceTypeId THEN (SELECT ISNULL(ESB.PostedDate,NULL) FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESB WITH (NOLOCK) WHERE ESB.[SOBillingInvoicingId] = CM.[InvoiceId])
			ELSE (SELECT ISNULL(SB.PostedDate,NULL) FROM [dbo].[BillingInvoicing] SB WITH (NOLOCK) WHERE SB.[BillingInvoicingId] = CM.[InvoiceId] AND ISNULL(SB.[IsPerformaInvoice],0) = 0)  
			END AS 'PostedDate'   
      ,CASE WHEN CM.[IsWorkOrder]=1 THEN  STUFF((SELECT ', ' + WP.CustomerReference  
			   FROM dbo.BillingInvoicing WI WITH (NOLOCK)  
			   INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.ReferenceId=WP.WorkOrderId AND WI.[ModuleId] = @WOModuleId
			   WHERE WI.BillingInvoicingId = CM.[InvoiceId]  
			   FOR XML PATH('')), 1, 1, '')   
	   WHEN ISNULL(CM.InvoiceTypeId, 0) = @ExchangeInvoiceTypeId THEN STUFF((SELECT ', ' + ESO.CustomerReference  
			   FROM dbo.[ExchangeSalesOrderBillingInvoicing] ESBI WITH (NOLOCK)  
			   INNER JOIN dbo.ExchangeSalesOrder ESO WITH (NOLOCK) ON ESBI.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId  
			   WHERE ESBI.SOBillingInvoicingId = CM.[InvoiceId]  
			   GROUP BY ESBI.ExchangeSalesOrderId,ESO.CustomerReference
			   FOR XML PATH('')), 1, 1, '')   
       ELSE   
			   STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.BillingInvoicing SI WITH (NOLOCK)  
			   INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.ReferenceId = SO.SalesOrderId  AND SI.[ModuleId] = @SOModuleId
			   WHERE SI.BillingInvoicingId = CM.[InvoiceId] AND ISNULL(SI.[IsPerformaInvoice],0) = 0
			   FOR XML PATH('')), 1, 1, '')   
			   END AS 'PORONum'  
	  ,CASE WHEN CM.[IsWorkOrder]=1 THEN (SELECT TOP 1 ISNULL(SABD.WayBillRef,NULL) FROM [dbo].[BillingInvoicing] WB WITH (NOLOCK) 
		    LEFT JOIN dbo.BillingInvoicingDetails SABD WITH (NOLOCK)  ON SABD.BillingInvoicingId = WB.BillingInvoicingId
			WHERE WB.[BillingInvoicingId] = CM.[InvoiceId])  
			WHEN ISNULL(CM.InvoiceTypeId, 0) = @ExchangeInvoiceTypeId THEN '' 
			ELSE   
			(SELECT TOP 1 ISNULL(SAOS.AirwayBill,NULL) FROM [dbo].[BillingInvoicing] SB WITH (NOLOCK)   
			 LEFT JOIN dbo.BillingInvoicingItems SABI WITH (NOLOCK)  ON SB.BillingInvoicingId = SABI.BillingInvoicingId AND ISNULL(SABI.[IsPerformaInvoice],0) = 0  
			 LEFT JOIN dbo.SalesOrderShipping SAOS WITH (NOLOCK)  ON SABI.ShippingId = SAOS.SalesOrderShippingId  --and  SAOS.SalesOrderId = 192  
										   WHERE SB.[BillingInvoicingId] = CM.[InvoiceId] AND ISNULL(SB.[IsPerformaInvoice],0) = 0 )  
          END AS 'Awb' 
	  ,ISNULL(CM.Amount,0) Amount,
	  CM.[IsStandAloneCM]
	 ,ISNULL(CM.InvoiceTypeId, 0) AS InvoiceTypeId
  
  FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
    INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MS WITH (NOLOCK) ON CM.CreditMemoHeaderId = MS.ReferenceID AND MS.ModuleID = @ModuleID  
    LEFT JOIN [dbo].[CustomerRMAHeader] CRMA ON CRMA.RMAHeaderId = CM.RMAHeaderId  
	LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON  CM.CustomerId = CF.CustomerId
    OUTER APPLY (SELECT TOP 1 CreditMemoDetailId FROM  CreditMemoDetails CD WITH (NOLOCK) WHERE CD.CreditMemoHeaderId = CM.CreditMemoHeaderId) CR   
  WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId;  
  
END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoById'   
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